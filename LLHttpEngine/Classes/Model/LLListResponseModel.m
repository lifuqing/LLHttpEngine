//
//  LLListResponseModel.m
//  LLHttpEngine
//
//  Created by lifuqing on 2018/4/28.
//

#import "LLListResponseModel.h"

@implementation LLListResponseModel
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{@"hasMore" : @"more",
             @"list" : [LLBaseModel class]};
}
@end
