//
//  LLURL.m
//  LLHttpEngine
//
//  Created by lifuqing on 2018/3/28.
//

#import "LLURL.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>

@implementation NSString (MD5)
- (NSString *)llurlMd5Digest {
    const char *cStr = [self UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), result );
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15]
            ];
}
@end

@interface LLURL()


@property (nonatomic, copy, readwrite) NSString *url;
@property (nonatomic, strong, readwrite) NSMutableDictionary *params;//外部可以增加参数
@property (nonatomic, copy) NSDictionary *originBaseParams;//urlconfig里面配置的基础参数
@property (nonatomic, copy) NSDictionary *firstExtendParams;//第一次网络请求所带的参数，为缓存的核心标识
@property (nonatomic, copy) NSString *server;
@property (nonatomic, copy, readwrite) NSString *type;
@property (nonatomic, assign, readwrite) BOOL needCache;
@property (nonatomic, copy) NSString *parser;
@property (nonatomic, copy, readwrite) NSString *modelClass;
@property (nonatomic, copy, readwrite) NSString *dataCacheIdentifier;

@property (nonatomic, assign) LLRequestType curRequestType;

@end

@implementation LLURL

- (instancetype)initWithParser:(NSString *)parser {
    return [self initWithParser:parser urlConfigClass:[LLURLBaseConfig class]];
}

- (instancetype)initWithParser:(NSString *)parser urlConfigClass:(Class)configClass {//!OCLint
    if (self = [super init]) {
        Class realConfigClass = configClass;
        if ([configClass isKindOfClass:[NSString class]]) {
            realConfigClass = NSClassFromString((NSString *)configClass);
        }
        _baseConfig = [[realConfigClass alloc] init];
        if ([_baseConfig respondsToSelector:@selector(loadUrlInfo)]) {
            NSArray *json = [_baseConfig loadUrlInfo];
            for (NSDictionary *dict in json) {
                if ([parser isEqualToString:dict[@"parser"]]) {
                    _server = dict[@"server"];
                    _originBaseParams = dict[@"params"];
                    _params = [NSMutableDictionary dictionaryWithDictionary:_originBaseParams];
                    NSDictionary *common = [_baseConfig commonParams];
                    if (common) {
                        [_params addEntriesFromDictionary:common];
                    }
                    
                    _needCache = [dict[@"cache"] boolValue];
                    _method = dict[@"method"];
                    NSString *shortUrl = [self url:[dict[@"url"] copy] Args:nil];
                    NSAssert([shortUrl hasPrefix:@"/"], ([NSString stringWithFormat:@"%@-url请配置/开头", parser]));//!OCLint
                    _url = [NSString stringWithFormat:@"%@%@", _server, shortUrl];
                    _modelClass = dict[@"modelClass"] ?: @"LLBaseResponseModel";
                    break;
                }
            }
        }

        NSAssert(_server, ([NSString stringWithFormat:@"%@-接口信息解析错误，请查证", parser]));//!OCLint
        _parser = [parser copy];
        _cacheType = ELLURLCacheTypeDefault;
    }
    return self;
}

- (void)clearExtendParams {
    [_params removeAllObjects];
    [_params addEntriesFromDictionary:_originBaseParams];
    NSDictionary *common = [_baseConfig commonParams];
    if (common) {
        [_params addEntriesFromDictionary:common];
    }
}

///第一次配置完llurl之后生成唯一的标识
- (NSString *)dataCacheIdentifier {
    //如果已经请求过，此次非第一次请求，则不用缓存
    if (_firstExtendParams && ![_firstExtendParams isEqualToDictionary:_params]) {
        return nil;
    }
    if (!_dataCacheIdentifier) {
        _firstExtendParams = [_params copy];
        NSString *originIdentifier = [_url stringByAppendingString:self.parser];
        NSString *paramStr = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:_params
                                                           options:kNilOptions
                                                             error:NULL];
        if (jsonData) {
            paramStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        if (paramStr) {
            originIdentifier = [originIdentifier stringByAppendingString:paramStr];
        }
        _dataCacheIdentifier = [originIdentifier llurlMd5Digest];
    }
    return _dataCacheIdentifier;
}

-(NSString *)url:(NSString *)url Args:(NSArray *)args
{
    BOOL done = FALSE;
    NSString *temp = url;
    NSInteger counter = 0;
    while (!done) {
        NSRange range = [temp rangeOfString:@"%@"];
        done = range.location == NSNotFound;
        if (done) {
            break;
        }
        if (args.count > 0) {
            temp = [temp stringByReplacingCharactersInRange:range withString:[NSString stringWithFormat:@"%@",args[counter]]];
        }
        done = range.location == NSNotFound;
        counter ++;
    }
    NSString *results = [temp stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    return results;
}

@end
