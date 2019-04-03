//
//  LLURLCacheManager.h
//  LLHttpEngine
//
//  Created by lifuqing on 2018/3/28.
//

#import <Foundation/Foundation.h>

@interface LLURLCacheManager : NSObject
///涉及不同用户的请务必配置该用户数据缓存唯一标识block
@property (nonatomic, copy) NSString *(^userID)(void);

+ (instancetype)sharedInstance;

/**
 * 获取本地缓存的数据,通过fileName来查找,可以为LLURL的dataCacheIdentifier
 */
- (NSDictionary *)getCacheData:(NSString *)fileName;

/**
 * 缓存数据到本地,通过fileName来存储
 */
- (void)storeData:(NSDictionary *)dict withFileName:(NSString *)fileName;

/**
 * 删除缓存数据到本地,通过fileName来删除
 */
- (void)removeCacheData:(NSString *)fileName;

/**
 * 清空所有用户网络请求数据缓存
 */
- (void)clearAllCacheData;

/**
 * 清除当前用户数据缓存,未登录则清除"无用户"缓存
 */
- (void)clearCurrentUserCacheData;


@end
