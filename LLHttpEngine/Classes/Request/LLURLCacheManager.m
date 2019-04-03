//
//  LLURLCacheManager.m
//  LLHttpEngine
//
//  Created by lifuqing on 2018/3/28.
//

#import "LLURLCacheManager.h"

@implementation LLURLCacheManager

+ (instancetype)sharedInstance {
    static id sSharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sSharedInstance = [[[self class] alloc] init];
    });

    return sSharedInstance;
}


/**
 * 获取本地缓存的数据,通过fileName来查找
 */
- (NSDictionary *)getCacheData:(NSString *)fileName {
    NSString *documentDir = [self getCompleteCacheDataPath:fileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:documentDir])
    {
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:documentDir];
        if ([dict count] > 0)
        {
            return dict;
        }
    }
    return nil;
}

/**
 * 缓存数据到本地,通过fileName来存储
 */
- (void)storeData:(NSDictionary *)dict withFileName:(NSString *)fileName {
    NSString *documentDir = [self getCompleteCacheDataPath:fileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(documentDir && ![fileManager fileExistsAtPath:documentDir])//!OCLint
    {
        if(![fileManager createFileAtPath:documentDir contents:nil attributes:nil])
        {
            NSLog(@"create file error: %@", documentDir);
        }
    }

    BOOL success = documentDir ? [dict writeToFile:documentDir atomically:YES] : NO;
    if(!success)
    {
        NSLog(@"%@ write %@ data error!", [self class], fileName);
    }
}

/**
 * 删除缓存数据到本地,通过fileName来删除
 */
- (void)removeCacheData:(NSString *)fileName {
    [self removePath:[self getCompleteCacheDataPath:fileName]];
}

/**
 *  清空所有用户网络请求数据缓存
 */
- (void)clearAllCacheData{
    [self removePath:[self getDirectoryWithPath:[self getRootCacheDataDir]]];
}

/**
 *  清除指定用户的URL数据缓存,考虑注销登录可能需要
 */
- (void)clearCacheDataForUser:(NSString *)uid {
    NSString *path = [self getCacheDataPathForUser:uid];
    [self removePath:path];
}

/**
 * 清除当前用户数据缓存
 */
- (void)clearCurrentUserCacheData {
    NSString *userId = nil;
    if (self.userID) {
        userId = self.userID();
    }
    if (userId) {
        [self clearCacheDataForUser:userId];
    }
    else {
        [self clearNoUserCacheData];
    }
    
}

#pragma mark -protect
- (void)clearNoUserCacheData{
    NSString *path = [self currentNoUserCacheDataPath];
    [self removePath:path];
}

#pragma mark - private

- (void)removePath:(NSString *)documentDir
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory = YES;
    if([fileManager fileExistsAtPath:documentDir isDirectory:&isDirectory])
    {
        NSError *err;
        if(![fileManager removeItemAtPath:documentDir error:&err])//!OCLint
        {
            if (err) {
                NSLog(@"remove path failed : %@", [err localizedDescription]);
            }
        }
    }
}


- (NSString *)getCompleteCacheDataPath:(NSString *)fileName {
    NSString *cacheDir = nil;
    NSString *userId = nil;
    
    if (self.userID) {
        userId = self.userID();
    }
    
    if (userId) {
        cacheDir = [self getCacheDataPathForUser:userId];
    }
    else {
        cacheDir = [self currentNoUserCacheDataPath];
    }
    NSString *documentDir = [cacheDir stringByAppendingPathComponent:fileName];
    return documentDir;
}


- (NSString *)getCacheDataPathForUser:(NSString *)uid{
    NSString *path = [self getRootCacheDataDir];
    if (uid) {
        path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", uid]];
        return [self getDirectoryWithPath:path];
    }
    return nil;

}

- (NSString *)currentNoUserCacheDataPath{
    NSString *path = [self getRootCacheDataDir];
    path = [path stringByAppendingPathComponent:@"noUser"];
    return [self getDirectoryWithPath:path];
}

- (NSString *)getRootCacheDataDir{
    return [self pathForCacheResource:@"com.urlcache.CacheData"];
}

- (NSString *)getDirectoryWithPath:(NSString *)path{
    NSError *error = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {//!OCLint
        if (![[NSFileManager defaultManager] createDirectoryAtPath:path//!OCLint
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:&error]) {
            if (error) {
                NSLog(@"Create user dir error: %@", error.description);
            }
        }
    }
    return path;
}


- (NSString *)pathForCacheResource:(NSString *)relativePath{
    NSString *cachesPath = nil;
    cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    if (relativePath) {
        cachesPath = [cachesPath stringByAppendingPathComponent:relativePath];
    }
    return cachesPath;
}
@end
