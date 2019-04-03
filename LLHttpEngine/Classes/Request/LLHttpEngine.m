//
//  LLHttpEngine.m
//  LLHttpEngine
//
//  Created by lifuqing on 2018/3/28.
//

#import "LLHttpEngine.h"
#import <YYModel/YYModel.h>

@interface LLHttpEngine()

@property (nonatomic, strong) AFURLSessionManager *manager;
@property (nonatomic, strong) NSMutableArray<NSURLSessionDataTask *> *requestTasks;
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
        _manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
        
        _requestTasks = [NSMutableArray array];
    }
    return self;
}

- (void)cancelAllRequestTasks {
    [self.requestTasks enumerateObjectsUsingBlock:^(NSURLSessionDataTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj cancel];
    }];
    [self.requestTasks removeAllObjects];
}

- (void)cancelRequestTaskByTarget:(id)target
{
    [self.requestTasks enumerateObjectsUsingBlock:^(NSURLSessionDataTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.taskDescription isEqualToString:[NSString stringWithFormat:@"%lu",[target hash]]]) {
            [obj cancel];
        }
        [self.requestTasks removeObject:obj];
    }];
}

- (NSURLSessionDataTask *)sendRequestWithLLURL:(LLURL *)llurl target:(id)target success:(void (^)(NSDictionary *result, LLBaseResponseModel *model, BOOL isLocalCache))success failure:(void (^)(LLBaseResponseModel *model))failure {
    
    if ([[llurl.method lowercaseString] isEqualToString:@"post"]) {
        return [self postRequestWithURLPath:llurl.url params:llurl.params modelClass:NSClassFromString(llurl.modelClass) target:target success:^(NSDictionary *result, LLBaseResponseModel *model, BOOL isLocalCache) {
            if (success) {
                success(result, model, NO);
            }
        } failure:^(LLBaseResponseModel *model) {
            if (failure) {
                NSDictionary *errMapping = [llurl.baseConfig errorCodeMessageMapping];
                NSString *originKey = [NSString stringWithFormat:@"%@", @(model.errorCode)];
                if ([errMapping.allKeys containsObject:originKey]) {
                    model.errorMsg = errMapping[originKey];
                }
                failure(model);
            }
        }];
    }
    else {//!OCLint
        NSDictionary *localdata = nil;
        if (llurl.needCache && llurl.curRequestType == LLRequestTypeRefresh) {//读取缓存数据
            NSDictionary *localJson = [[LLURLCacheManager sharedInstance] getCacheData:llurl.dataCacheIdentifier];
            
            if (localJson && success) {
                Class modelClass = [LLBaseResponseModel class];
                if (llurl.modelClass.length > 0) {
                    modelClass = NSClassFromString(llurl.modelClass);
                }
                localdata = localJson[@"data"];
                LLBaseResponseModel *localModel = [LLBaseResponseModel yy_modelWithJSON:localdata];
                success(localJson, localModel, YES);
            }
        }
        
        void(^failureBlock)(LLBaseResponseModel *model) = ^(LLBaseResponseModel *model) {
            if (failure) {
                NSDictionary *errMapping = [llurl.baseConfig errorCodeMessageMapping];
                NSString *originKey = [NSString stringWithFormat:@"%@", @(model.errorCode)];
                if ([errMapping.allKeys containsObject:originKey]) {
                    model.errorMsg = errMapping[originKey];
                }
                failure(model);
            }
        };
        
        return [self getRequestWithURLPath:llurl.url params:llurl.params modelClass:NSClassFromString(llurl.modelClass) target:target success:^(NSDictionary *result, LLBaseResponseModel *model, BOOL isLocalCache) {
            if (success) {
                NSDictionary *onlinedata = result[@"data"];
                //有本地缓存
                if (localdata) {
                    //且本地缓存和线上请求的数据一致
                    if ([onlinedata isEqualToDictionary:localdata]) {
                        //每次都回调的时候才回调，否则不再回调
                        if (llurl.cacheType == ELLURLCacheTypeAlwaysRefresh) {
                            success(result, model, NO);
                        }
                    }
                    else {
                        //数据不一致，再回调一次
                        if (llurl.cacheType == ELLURLCacheTypeDefault) {
                            success(result, model, NO);
                        }
                        else if (llurl.cacheType == ELLURLCacheTypeAlwaysRefresh) {
                            success(result, model, NO);
                        }
                    }
                }
                else {
                    success(result, model, NO);
                }
            }
            if (result && model.errorCode == 0 && llurl.curRequestType == LLRequestTypeRefresh) {
                [[LLURLCacheManager sharedInstance] storeData:result withFileName:llurl.dataCacheIdentifier];
            }
        } failure:^(LLBaseResponseModel *model) {
            if (llurl.needCache && llurl.curRequestType == LLRequestTypeRefresh) {
                if (localdata) {
                    //有缓存回调到这肯定是第二次网络请求失败了，一直刷新回调，否则不回调
                    if (llurl.cacheType == ELLURLCacheTypeAlwaysRefresh) {
                        failureBlock(model);
                    }
                }
                else {
                    //无缓存直接回调
                    failureBlock(model);
                }
            }
            else {
                //不支持缓存或者不是下拉刷新
                failureBlock(model);
            }
        }];
    }
    
}

- (NSURLSessionDataTask *)getRequestWithURLPath:(NSString *)url params:(NSDictionary *)params modelClass:(Class)modelClass target:(id)target success:(void (^)(NSDictionary *result, LLBaseResponseModel *model, BOOL isLocalCache))success failure:(void (^)(LLBaseResponseModel *model))failure {
    if (!url || ![url isKindOfClass:[NSString class]]) {
        if (failure) {
            failure(nil);
        }
        return nil;
    }
    
    __weak typeof(self) weakSelf = self;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    NSURLSessionDataTask *dataTask = [self.manager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
//            NSLog(@"Error: %@", error);
            if (failure) {
                LLBaseResponseModel *failedResModel = [[LLBaseResponseModel alloc] init];
                failedResModel.errorMsg = @"接口请求失败";
                failedResModel.errorCode = error.code;
                failure(failedResModel);
            }
        } else {
//            NSLog(@"%@ %@", response, responseObject);
            if (success) {
                NSDictionary *json = [responseObject isKindOfClass:[NSDictionary class]] ? responseObject : nil;
                LLBaseResponseModel *responseModel = nil;
                Class clazz = modelClass?:[LLBaseResponseModel class];
                if ([clazz respondsToSelector:@selector(yy_modelWithJSON:)]) {
                    responseModel = [clazz yy_modelWithJSON:json];
                }
                success(json, responseModel, NO);
            }
            
        }
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.requestTasks removeObject:dataTask];
    }];
    dataTask.taskDescription = [NSString stringWithFormat:@"%lu", [target hash]];
    [self.requestTasks addObject:dataTask];
    [dataTask resume];
    return dataTask;
}

- (NSURLSessionDataTask *)postRequestWithURLPath:(NSString *)url params:(NSDictionary *)params modelClass:(Class)modelClass target:(id)target success:(void (^)(NSDictionary *result, LLBaseResponseModel *model, BOOL isLocalCache))success failure:(void (^)(LLBaseResponseModel *model))failure {
    return [self postRequestWithURLPath:url params:params constructingBodyWithBlock:nil modelClass:modelClass progress:nil target:target success:success failure:failure];
}

- (NSURLSessionUploadTask *)postRequestWithURLPath:(NSString *)url
                                          params:(NSDictionary *)params
                       constructingBodyWithBlock:(void (^)(id<AFMultipartFormData> formData))block
                                      modelClass:(Class)modelClass
                                        progress:(void (^)(NSProgress *uploadProgress))progress
                                          target:(id)target
                                         success:(void (^)(NSDictionary *result, LLBaseResponseModel *model, BOOL isLocalCache))success
                                         failure:(void (^)(LLBaseResponseModel *model))failure {
    if (!url || ![url isKindOfClass:[NSString class]]) {
        if (failure) {
            failure(nil);
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
                              failure(failedResModel);
                          }
                      } else {
//                          NSLog(@"%@ %@", response, responseObject);
                          if (success) {
                              NSDictionary *json = [responseObject isKindOfClass:[NSDictionary class]] ? responseObject : nil;
                              LLBaseResponseModel *responseModel = nil;
                              Class clazz = modelClass?:[LLBaseResponseModel class];
                              if ([clazz respondsToSelector:@selector(yy_modelWithJSON:)]) {
                                  responseModel = [clazz yy_modelWithJSON:json];
                              }
                              success(json, responseModel, NO);
                          }
                      }
                      __strong typeof(weakSelf) strongSelf = weakSelf;
                      [strongSelf.requestTasks removeObject:uploadTask];
                  }];
    
    uploadTask.taskDescription = [NSString stringWithFormat:@"%lu", [target hash]];
    [self.requestTasks addObject:uploadTask];
    [uploadTask resume];

    return uploadTask;
}

@end
