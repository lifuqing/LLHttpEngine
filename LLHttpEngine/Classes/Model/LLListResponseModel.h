//
//  LLListResponseModel.h
//  LLHttpEngine
//
//  Created by lifuqing on 2018/4/28.
//

#import "LLBaseResponseModel.h"

@class LLBaseModel;
/**
 子类可继承重写，
 */
@interface LLListResponseModel : LLBaseResponseModel
@property (nonatomic, copy  ) NSArray <LLBaseModel *> *list;
@property (nonatomic, assign) NSUInteger total;
@property (nonatomic, assign) BOOL       hasMore;
///空页面提示文案
@property (nonatomic, copy  ) NSString  *prompt;
@end
