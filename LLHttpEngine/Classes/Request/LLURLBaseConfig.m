//
//  LLURLBaseConfig.m
//  LLHttpEngine
//
//  Created by lifuqing on 2018/3/28.
//

#import "LLURLBaseConfig.h"

@implementation LLURLBaseConfig

+ (instancetype)sharedInstance
{
    static id config = nil;
    if (config == nil)
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            config = [[[self class] alloc] init];
        });
    }

    return config;
}

- (NSArray *)loadUrlInfo{
    NSArray *arr = @[
#pragma mark -示例普通接口
                     @{
                         @"parser"     : @"ExampleRequestParser", //parser用来区分不同的请求,命名XXXXParser
                         @"server"     : @"domain",//domain，子类自行维护传入
                         @"url"        : @"/index.php",   //short url，不带host
                         @"method"     : @"get",      //支持post和get
                         @"cache"      : @(NO),     //是否存取json数据
                         @"params"     : @{},          //该接口默认参数
                         //@"modelClass" : @"LLXXXResponseModel"  //继承自LLBaseResponseModel（普通请求）的类名，普通接口可选参数,列表必选
                         },
#pragma mark -示例列表接口
                     @{
                         @"parser"     : @"ExampleListParser",//,命名规则XXXXListParser
                         @"server"     : @"domain",//domain，子类自行维护传入
                         @"url"        : @"/zhuanti.php",
                         @"method"     : @"get",
                         @"cache"      : @(NO),
                         @"params"     : @{},
                         @"modelClass" : @"LLXXXListResponseModel"  //继承自LLListResponseModel(列表页)或者LLBaseResponseModel（普通请求）的类名，普通接口可选参数,列表必选
                         },
                     ];
    return arr;
}

- (NSDictionary *)commonParams {
    return nil;
}

- (NSDictionary *)errorCodeMessageMapping{
    return @{
             @"originErrorCode" : @"FormatErrorMessage",
             @"-1012" : @"当前无网络",
             @"-1009" : @"当前无网络",
             };
}
@end
