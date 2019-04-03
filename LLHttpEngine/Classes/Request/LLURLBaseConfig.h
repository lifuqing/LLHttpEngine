//
//  LLURLBaseConfig.h
//  LLHttpEngine
//
//  Created by lifuqing on 2018/3/28.
//

#import <Foundation/Foundation.h>

@interface LLURLBaseConfig : NSObject

+ (instancetype)sharedInstance;

/**
 子类重写此方法，格式如下

 -(NSArray *)loadUrlInfo {
 NSArray *superArr = [super loadUrlInfo];

 NSMutableArray *currentArr = [NSMutableArray arrayWithArray:superArr];
 NSArray *arr = @[
 #pragma mark -示例普通接口
 @{
 @"parser"     : @"ExampleRequestParser", //parser用来区分不同的请求,命名XXXXParser
 @"server"     : @"domain"      //domain，子类自行维护传入
 @"url"        : @"/index.php",   //short url，不带host
 @"method"     : @"get",      //支持post和get
 @"cache"      : @(NO),     //是否存取json数据
 @"params"     : @{},          //该接口默认参数
 //@"modelClass" : @"LLXXXResponseModel"  //继承自LLBaseResponseModel（普通请求）的类名，普通接口可选参数,列表必选
 },
 #pragma mark -示例列表接口
 @{
 @"parser"     : @"ExampleListParser",//,命名规则XXXXListParser
 @"server"     : @"domain", //domain，子类自行维护传入
 @"url"        : @"/zhuanti.php",
 @"method"     : @"get",
 @"cache"      : @(NO),
 @"params"     : @{},
 @"modelClass" : @"LLXXXListResponseModel"  //继承自LLListResponseModel(列表页)或者LLBaseResponseModel（普通请求）的类名，普通接口可选参数,列表必选
 },
 ];
 [currentArr addObjectsFromArray:arr];
 return [currentArr copy];;

 }

 @return array
 */
- (NSArray *)loadUrlInfo;


/**
 错误Code Message 映射表 子类重写此方法，格式如下
 
 -(NSDictionary *)errorCodeMessageMapping {
 NSDictionary *superDic = [self errorCodeMessageMapping];

 NSMutableDictionary *currentDic = [NSMutableDictionary dictionaryWithDictionary:superDic];
 NSDictionary *dic = @{
 @"originErrorCode" : @"FormatErrorMessage",//示例 key 为ResponseModel errCode, value为映射对应的错误信息
 @"xxx" : @"xxxx",
 };
 [currentDic addEntriesFromDictionary:dic];
 return [currentDic copy];
 }

 @return 错误Code Message 映射表 dic
 */
- (NSDictionary *)errorCodeMessageMapping;
@end
