//
//  LLURL.h
//  LLHttpEngine
//
//  Created by lifuqing on 2018/3/28.
//

#import <Foundation/Foundation.h>
#import "LLURLBaseConfig.h"

///网络请求缓存使用方式，这里仅对urlconfig里面的cache=yes生效
typedef NS_ENUM(NSUInteger, ELLURLCacheType) {
    ///先取缓存回调，再走网络请求成功之后如果两次json不完全一致会再回调。也就是最多回调两次
    ELLURLCacheTypeDefault = 0,
    ///仅取缓存回调，取不到缓存再发请求，拿到数据之后回调。也就是回调一次
    ELLURLCacheTypeOnlyCache,
    ///先取缓存回调，再走网络请求成功之后无论两次数据是否一致都会再次回调。也就是最多回调两次
    ELLURLCacheTypeAlwaysRefresh,
};

///列表请求使用的请求第一页还是请求更多数据
typedef NS_ENUM(NSInteger, LLRequestType) {
    LLRequestTypeRefresh = 0,
    LLRequestTypeLoadMore
};

@interface NSString (MD5)
- (NSString *)llurlMd5Digest;
@end


@interface LLURL : NSObject

@property (nonatomic, copy, readonly) NSString *url;//完整的url（不包含自定义参数）
@property (nonatomic, copy, readonly) NSString *method;//get post
@property (nonatomic, strong, readonly) NSMutableDictionary *params;//外部可以增加参数
@property (nonatomic, assign, readonly) BOOL needCache;  //是否需要存取缓存数据
@property (nonatomic, copy, readonly) NSString *modelClass;//如果url配置里面未指定，则默认为@"LLBaseResponseModel"
@property (nonatomic, copy, readonly) NSString *dataCacheIdentifier;//缓存数据的唯一标示
@property (nonatomic, copy, readonly) LLURLBaseConfig *baseConfig;//LLURLBaseConfig子类，对应初始化configClass
///外部设置缓存类型,默认ELLURLCacheTypeDefault
@property (nonatomic, assign) ELLURLCacheType cacheType;

/**
 通过LLURLBaseConfig子类parser来配置创建LLURL model

 @param parser LLURLBaseConfig子类里面url模型parser
 @param configClass LLURLBaseConfig 子类
 @return llurl object
 */
- (instancetype)initWithParser:(NSString *)parser urlConfigClass:(Class)configClass;
@end

@interface LLURL (Private)

//private
///仅供LLListBaseDataSource内部调用设置，外部使用不要设置此参数
@property (nonatomic, assign) LLRequestType curRequestType;
///清除外部增加的扩展参数
- (void)clearExtendParams;
@end
