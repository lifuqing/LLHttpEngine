//
//  LLBaseResponseModel.h
//  LLHttpEngine
//
//  Created by lifuqing on 2019/4/3.
//  Copyright © 2019 lifuqing. All rights reserved.
//

#import "LLBaseModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface LLBaseResponseModel : LLBaseModel
@property (nonatomic, assign) NSInteger errorCode;
@property (nonatomic, copy  ) NSString *errorMsg;
@end

NS_ASSUME_NONNULL_END
