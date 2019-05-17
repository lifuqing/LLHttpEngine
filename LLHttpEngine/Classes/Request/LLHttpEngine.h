//
//  LLHttpEngine.h
//  LLHttpEngine
//
//  Created by lifuqing on 2018/3/28.
//

#import <Foundation/Foundation.h>
#import "LLURL.h"
#import "LLBaseResponseModel.h"
#import "LLURLCacheManager.h"
#import <AFNetworking/AFNetworking.h>

extern NSString *const kResponseDataKey;
extern NSString *const kResponseCodeKey;
extern NSString *const kResponseErrorMsgKey;

@interface LLHttpEngine : NSObject
/*
 !!!!!!!!
 需要在程序启动后先配置LLURLCacheManager里面的userID，才可以正常使用缓存。
 !!!!!!!!
 */

+ (instancetype)sharedInstance;


/**
 注意循环引用，block里面用weak,基于LLURL模型来实现的网络请求，url配置可参考LLURLBaseConfig及其子类来实现
 
 @param llurl llurl 模型
 @param target target
 @param success 请求成功返回json，以及基本model，isLocalCache代表该数据是否为本地缓存
 @param failure 失败block
 @return 如果是网络请求为NSURLSessionDataTask object，如果isLocalCache = yes 则返回nil
 */
- (NSURLSessionDataTask *)sendRequestWithLLURL:(LLURL *)llurl
                                        target:(id)target
                                       success:(void (^)(NSURLResponse * _Nullable response, NSDictionary * _Nullable result, LLBaseResponseModel * _Nullable model, BOOL isLocalCache))success
                                       failure:(void (^)(NSURLResponse * _Nullable response, NSError * _Nullable error,  LLBaseResponseModel * _Nullable model))failure;


/**
 get请求，需要传入完整的url，不支持缓存，仅针对未在LLURLBaseConfig及其子类配置的情况
 
 @param url 完整的url path
 @param params params description
 @param modelClass modelClass如果传入nil，默认为[LLBaseResponseModel class]
 @param target target description
 @param success 请求成功返回json，以及基本model，isLocalCache固定为NO
 @param failure 失败block
 @return NSURLSessionDataTask object
 */
- (NSURLSessionDataTask *)getRequestWithURLPath:(NSString *)url
                                         params:(NSDictionary *)params
                                     modelClass:(Class)modelClass
                                         target:(id)target
                                        success:(void (^)(NSURLResponse * _Nullable response, NSDictionary * _Nullable result, LLBaseResponseModel * _Nullable model, BOOL isLocalCache))success
                                        failure:(void (^)(NSURLResponse * _Nullable response, NSError * _Nullable error,  LLBaseResponseModel * _Nullable model))failure;


/**
 post请求，需要传入完整的url，不支持缓存，仅针对未在LLURLBaseConfig及其子类配置的情况
 
 @param url 完整的url path
 @param params params description
 @param modelClass modelClass如果传入nil，默认为[LLBaseResponseModel class]
 @param target target description
 @param success 请求成功返回json，以及基本model，isLocalCache固定为NO
 @param failure 失败block
 @return NSURLSessionDataTask object
 */
- (NSURLSessionDataTask *)postRequestWithURLPath:(NSString *)url
                                          params:(NSDictionary *)params
                                      modelClass:(Class)modelClass
                                          target:(id)target
                                         success:(void (^)(NSURLResponse * _Nullable response, NSDictionary * _Nullable result, LLBaseResponseModel * _Nullable model, BOOL isLocalCache))success
                                         failure:(void (^)(NSURLResponse * _Nullable response, NSError * _Nullable error,  LLBaseResponseModel * _Nullable model))failure;


/**
 post请求，需要传入完整的url，支持进度,FormData
 
 @param url 完整的url path
 @param params params description
 @param block 上传的数据，文件或者视频 图片
 @param modelClass modelClass如果传入nil，默认为[LLBaseResponseModel class]
 @param progress 进度block
 @param target target description
 @param success 请求成功返回json，以及基本model，isLocalCache固定为NO
 @param failure 失败block
 @return NSURLSessionUploadTask object
 */
- (NSURLSessionUploadTask *)postRequestWithURLPath:(NSString *)url
                                            params:(NSDictionary *)params
                         constructingBodyWithBlock:(void (^)(id<AFMultipartFormData> formData))block
                                        modelClass:(Class)modelClass
                                          progress:(void (^)(NSProgress *uploadProgress))progress
                                            target:(id)target
                                           success:(void (^)(NSURLResponse * _Nullable response, NSDictionary * _Nullable result, LLBaseResponseModel * _Nullable model, BOOL isLocalCache))success
                                           failure:(void (^)(NSURLResponse * _Nullable response, NSError * _Nullable error,  LLBaseResponseModel * _Nullable model))failure;

/**
 取消全部网络请求
 */
- (void)cancelAllRequestTasks;


/**
 根据Target来取消对应Target全部网络请求
 
 @param target target
 */
- (void)cancelRequestTaskByTarget:(id)target;

@end
