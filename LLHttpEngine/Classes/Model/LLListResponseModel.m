//
//  LLListResponseModel.m
//  LLHttpEngine
//
//  Created by lifuqing on 2018/4/28.
//

#import "LLListResponseModel.h"

@implementation LLListResponseModel
+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{@"list" : [LLBaseModel class]};
}
@end
