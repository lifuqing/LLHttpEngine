//
//  LLBaseResponseModel.m
//  LLHttpEngine
//
//  Created by lifuqing on 2019/4/3.
//  Copyright © 2019 lifuqing. All rights reserved.
//

#import "LLBaseResponseModel.h"
NSInteger const kRequestSuccessCode = 100;

@implementation LLBaseResponseModel
- (instancetype)init {
    self = [super init];
    if (self) {
        _errorMsg = @"";
        _errorCode = -1;
    }
    return self;
}
@end
