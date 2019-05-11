//
//  LLHttpEngine.m
//  LLHttpEngine
//
//  Created by lifuqing on 2018/3/28.
//

#import "LLHttpEngine.h"
#import <YYModel/YYModel.h>

NSString *const kResponseDataKey = @"data";
NSString *const kResponseCodeKey = @"code";
NSString *const kResponseErrorMsgKey = @"errorMsg";

@interface LLHttpEngine() <AFURLResponseSerialization>

@property (nonatomic, strong) AFURLSessionManager *manager;
@property (nonatomic, strong) NSMutableArray<NSURLSessionDataTask *> *requestTasks;
@property (nonatomic, strong) NSLock *lock;
@end

@implementation LLHttpEngine

+ (instancetype)sharedInstance
{
    static id obj = nil;
    if (obj == nil)
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            obj = [[[self class] alloc] init];
        });
    }
    return obj;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.timeoutIntervalForRequest = 30;
        _manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
        
        AFHTTPResponseSerializer *serializer = [AFJSONResponseSerializer serializer];
        serializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", @"text/json", @"application/json", @"text/javascript", @"text/html",  nil];
        _manager.responseSerializer = serializer;
        
        _requestTasks = [NSMutableArray array];
        _lock = [[NSLock alloc] init];
    }
    return self;
}

- (void)cancelAllRequestTasks {
    [self.lock lock];
    [self.requestTasks enumerateObjectsUsingBlock:^(NSURLSessionDataTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj cancel];
    }];
    [self.requestTasks removeAllObjects];
    [self.lock unlock];
}

- (void)cancelRequestTaskByTarget:(id)target
{
    [self.lock lock];
    [self.requestTasks enumerateObjectsUsingBlock:^(NSURLSessionDataTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.taskDescription isEqualToString:[NSString stringWithFormat:@"%lu",[target hash]]]) {
            [obj cancel];
        }
        [self.requestTasks removeObject:obj];
    }];
    [self.lock unlock];
}

- (NSURLSessionDataTask *)sendRequestWithLLURL:(LLURL *)llurl target:(id)target success:(void (^)(NSURLResponse * _Nullable response, NSDictionary * _Nullable result, LLBaseResponseModel * _Nonnull model, BOOL isLocalCache))success failure:(void (^)(NSURLResponse * _Nonnull response, NSError * _Nullable error,  LLBaseResponseModel * _Nonnull model))failure {
    
    if ([[llurl.method lowercaseString] isEqualToString:@"post"]) {
        return [self postRequestWithURLPath:llurl.url params:llurl.params modelClass:NSClassFromString(llurl.modelClass) target:target success:^(NSURLResponse * _Nullable response, NSDictionary * _Nullable result, LLBaseResponseModel * _Nonnull model, BOOL isLocalCache) {
            if (success) {
                success(response, result, model, NO);
            }
        } failure:^(NSURLResponse * _Nonnull response, NSError * _Nullable error,  LLBaseResponseModel * _Nonnull model) {
            if (failure) {
                NSDictionary *errMapping = [llurl.baseConfig errorCodeMessageMapping];
                NSString *originKey = [NSString stringWithFormat:@"%@", @(model.errorCode)];
                if ([errMapping.allKeys containsObject:originKey]) {
                    model.errorMsg = errMapping[originKey];
                }
                failure(response, error, model);
            }
        }];
    }
    else {//!OCLint
        NSDictionary *localdata = nil;
        if (llurl.needCache && llurl.curRequestType == LLRequestTypeRefresh) {//读取缓存数据
            NSDictionary *localJson = [[LLURLCacheManager sharedInstance] getCacheData:llurl.dataCacheIdentifier];
            
            Class modelClass = [LLBaseResponseModel class];
            if (llurl.modelClass.length > 0) {
                modelClass = NSClassFromString(llurl.modelClass);
            }
            if (localJson && success && [modelClass respondsToSelector:@selector(yy_modelWithJSON:)]) {
                localdata = localJson[kResponseDataKey];
                LLBaseResponseModel *localModel = [modelClass yy_modelWithJSON:localdata];
                
                if (!localModel) {
                    localModel = [[LLBaseResponseModel alloc] init];
                }
                if (localdata[kResponseCodeKey]) {
                    localModel.errorCode = [localdata[kResponseCodeKey] integerValue];
                }
                if (localdata[kResponseErrorMsgKey]) {
                    localModel.errorMsg = localdata[kResponseErrorMsgKey];
                }
                
                success(nil, localJson, localModel, YES);
            }
        }
        
        void(^failureBlock)(NSURLResponse * _Nonnull response, NSError * _Nullable error,  LLBaseResponseModel * _Nonnull model) = ^(NSURLResponse * _Nonnull response, NSError * _Nullable error,  LLBaseResponseModel * _Nonnull model) {
            if (failure) {
                NSDictionary *errMapping = [llurl.baseConfig errorCodeMessageMapping];
                NSString *originKey = [NSString stringWithFormat:@"%@", @(model.errorCode)];
                if ([errMapping.allKeys containsObject:originKey]) {
                    model.errorMsg = errMapping[originKey];
                }
                failure(response, error, model);
            }
        };
        
        return [self getRequestWithURLPath:llurl.url params:llurl.params modelClass:NSClassFromString(llurl.modelClass) target:target success:^(NSURLResponse * _Nullable response, NSDictionary * _Nullable result, LLBaseResponseModel * _Nonnull model, BOOL isLocalCache) {
            if (success) {
                NSDictionary *onlinedata = result[kResponseDataKey];
                //有本地缓存
                if (localdata) {
                    //且本地缓存和线上请求的数据一致
                    if ([onlinedata isEqualToDictionary:localdata]) {
                        //每次都回调的时候才回调，否则不再回调
                        if (llurl.cacheType == ELLURLCacheTypeAlwaysRefresh) {
                            success(response, result, model, NO);
                        }
                    }
                    else {
                        //数据不一致，再回调一次
                        if (llurl.cacheType == ELLURLCacheTypeDefault) {
                            success(response, result, model, NO);
                        }
                        else if (llurl.cacheType == ELLURLCacheTypeAlwaysRefresh) {
                            success(response, result, model, NO);
                        }
                    }
                }
                else {
                    success(response, result, model, NO);
                }
            }
            if (result && model.errorCode == kRequestSuccessCode && llurl.curRequestType == LLRequestTypeRefresh) {
                [[LLURLCacheManager sharedInstance] storeData:result withFileName:llurl.dataCacheIdentifier];
            }
        } failure:^(NSURLResponse * _Nonnull response, NSError * _Nullable error,  LLBaseResponseModel * _Nonnull model) {
            if (llurl.needCache && llurl.curRequestType == LLRequestTypeRefresh) {
                if (localdata) {
                    //有缓存回调到这肯定是第二次网络请求失败了，一直刷新回调，否则不回调
                    if (llurl.cacheType == ELLURLCacheTypeAlwaysRefresh) {
                        failureBlock(response, error, model);
                    }
                }
                else {
                    //无缓存直接回调
                    failureBlock(response, error, model);
                }
            }
            else {
                //不支持缓存或者不是下拉刷新
                failureBlock(response, error, model);
            }
        }];
    }
    
}

- (NSURLSessionDataTask *)getRequestWithURLPath:(NSString *)url params:(NSDictionary *)params modelClass:(Class)modelClass target:(id)target success:(void (^)(NSURLResponse * _Nullable response, NSDictionary * _Nullable result, LLBaseResponseModel * _Nonnull model, BOOL isLocalCache))success failure:(void (^)(NSURLResponse * _Nonnull response, NSError * _Nullable error,  LLBaseResponseModel * _Nonnull model))failure {
    if (!url || ![url isKindOfClass:[NSString class]]) {
        if (failure) {
            failure(nil, nil, nil);
        }
        return nil;
    }
    
    __weak typeof(self) weakSelf = self;
    
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET" URLString:url parameters:params error:nil];
    NSURLSessionDataTask *dataTask = [self.manager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
//            NSLog(@"Error: %@", error);
            if (failure) {
                LLBaseResponseModel *failedResModel = [[LLBaseResponseModel alloc] init];
                failedResModel.errorMsg = @"接口请求失败";
                failedResModel.errorCode = error.code;
                failure(response, error, failedResModel);
            }
        } else {
//            NSLog(@"%@ %@", response, responseObject);
            LLBaseResponseModel *responseModel = nil;
            NSDictionary *json = [responseObject isKindOfClass:[NSDictionary class]] ? responseObject : nil;
            Class clazz = modelClass?:[LLBaseResponseModel class];
            if (json && [clazz respondsToSelector:@selector(yy_modelWithJSON:)]) {
                responseModel = [clazz yy_modelWithJSON:json[kResponseDataKey]];
                if (!responseModel) {
                    responseModel = [[LLBaseResponseModel alloc] init];
                }
                if (json[kResponseCodeKey]) {
                    responseModel.errorCode = [json[kResponseCodeKey] integerValue];
                }
                if (json[kResponseErrorMsgKey]) {
                    responseModel.errorMsg = json[kResponseErrorMsgKey];
                }
            }
            else {
                responseModel = [[LLBaseResponseModel alloc] init];
                responseModel.errorMsg = @"数据请求失败";
                responseModel.errorCode = error.code;
            }
            
            if (responseModel.errorCode == kRequestSuccessCode) {
                if (success) {
                    success(response, json, responseModel, NO);
                }
            }
            else {
                if (failure) {
                    failure(response, error, responseModel);
                }
            }
            
        }
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.lock lock];
        [strongSelf.requestTasks removeObject:dataTask];
        [strongSelf.lock unlock];
    }];
    dataTask.taskDescription = [NSString stringWithFormat:@"%lu", [target hash]];
    [self.lock lock];
    [self.requestTasks addObject:dataTask];
    [self.lock unlock];
    [dataTask resume];
    return dataTask;
}

- (NSURLSessionDataTask *)postRequestWithURLPath:(NSString *)url params:(NSDictionary *)params modelClass:(Class)modelClass target:(id)target success:(void (^)(NSURLResponse * _Nullable response, NSDictionary * _Nullable result, LLBaseResponseModel * _Nonnull model, BOOL isLocalCache))success failure:(void (^)(NSURLResponse * _Nonnull response, NSError * _Nullable error,  LLBaseResponseModel * _Nonnull model))failure {
    return [self postRequestWithURLPath:url params:params constructingBodyWithBlock:nil modelClass:modelClass progress:nil target:target success:success failure:failure];
}

- (NSURLSessionUploadTask *)postRequestWithURLPath:(NSString *)url
                                          params:(NSDictionary *)params
                       constructingBodyWithBlock:(void (^)(id<AFMultipartFormData> formData))block
                                      modelClass:(Class)modelClass
                                        progress:(void (^)(NSProgress *uploadProgress))progress
                                          target:(id)target
                                         success:(void (^)(NSURLResponse * _Nullable response, NSDictionary * _Nullable result, LLBaseResponseModel * _Nonnull model, BOOL isLocalCache))success
                                         failure:(void (^)(NSURLResponse * _Nonnull response, NSError * _Nullable error,  LLBaseResponseModel * _Nonnull model))failure {
    if (!url || ![url isKindOfClass:[NSString class]]) {
        if (failure) {
            failure(nil, nil, nil);
        }
        return nil;
    }
    
    __weak typeof(self) weakSelf = self;
    
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST" URLString:url parameters:params constructingBodyWithBlock:block error:nil];
    NSURLSessionUploadTask *uploadTask;
    uploadTask = [self.manager
                  uploadTaskWithStreamedRequest:request
                  progress:^(NSProgress * _Nonnull uploadProgress) {
                      // This is not called back on the main queue.
                      // You are responsible for dispatching to the main queue for UI updates
                      dispatch_async(dispatch_get_main_queue(), ^{
                          //Update the progress view
                          if (progress) {
                              progress(uploadProgress);
                          }
                      });
                  }
                  completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                      if (error) {
//                          NSLog(@"Error: %@", error);
                          if (failure) {
                              LLBaseResponseModel *failedResModel = [[LLBaseResponseModel alloc] init];
                              failedResModel.errorMsg = @"接口请求失败";
                              failedResModel.errorCode = error.code;
                              failure(response, error, failedResModel);
                          }
                      } else {
//                          NSLog(@"%@ %@", response, responseObject);
                          NSDictionary *json = [responseObject isKindOfClass:[NSDictionary class]] ? responseObject : nil;
                          LLBaseResponseModel *responseModel = nil;
                          Class clazz = modelClass?:[LLBaseResponseModel class];
                          if (json && [clazz respondsToSelector:@selector(yy_modelWithJSON:)]) {
                              responseModel = [clazz yy_modelWithJSON:json[kResponseDataKey]];
                              if (!responseModel) {
                                  responseModel = [[LLBaseResponseModel alloc] init];
                              }
                              if (json[kResponseCodeKey]) {
                                  responseModel.errorCode = [json[kResponseCodeKey] integerValue];
                              }
                              if (json[kResponseErrorMsgKey]) {
                                  responseModel.errorMsg = json[kResponseErrorMsgKey];
                              }
                          }
                          else {
                              responseModel = [[LLBaseResponseModel alloc] init];
                              responseModel.errorMsg = @"数据请求失败";
                              responseModel.errorCode = error.code;
                          }
                          
                          if (responseModel.errorCode == kRequestSuccessCode) {
                              if (success) {
                                  success(response, json, responseModel, NO);
                              }
                          }
                          else {
                              if (failure) {
                                  failure(response, error, responseModel);
                              }
                          }
                      }
                      __strong typeof(weakSelf) strongSelf = weakSelf;
                      [strongSelf.lock lock];
                      [strongSelf.requestTasks removeObject:uploadTask];
                      [strongSelf.lock unlock];
                  }];
    
    uploadTask.taskDescription = [NSString stringWithFormat:@"%lu", [target hash]];
    [self.lock lock];
    [self.requestTasks addObject:uploadTask];
    [self.lock unlock];
    [uploadTask resume];

    return uploadTask;
}

@end
