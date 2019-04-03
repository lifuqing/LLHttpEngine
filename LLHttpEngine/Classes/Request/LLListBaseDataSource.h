//
//  LLListBaseDataSource.h
//  LLHttpEngine
//
//  Created by lifuqing on 2018/4/23.
//

#import <Foundation/Foundation.h>
#import "LLHttpEngine.h"
#import "LLListResponseModel.h"

@class LLListBaseDataSource;
@protocol LLListBaseDataSourceDelegate <NSObject>

@required
///获取数据成功或者失败的回调
- (void)finishOfDataSource:(LLListBaseDataSource *)dataSource;

@end

@interface LLListBaseDataSource : NSObject

#pragma mark - 网路请求、数据相关
@property (nonatomic, strong, readonly) LLURL           *llurl;//请求相关的对象
@property (nonatomic, strong, readonly) NSMutableArray  *list;//数据源
@property (nonatomic, strong, readonly) NSError         *error;//error domain为 model.errorMsg -----  error code为 model.errorCode
@property (nonatomic, assign, readonly) LLRequestType   type;//请求类型
@property (nonatomic, assign, readonly) BOOL            isLocalCache;//当前数据是否为本地缓存数据(如果在线和本地数据相同，则第二次网络请求回调回来的内容isLocalCache也为YES)

#pragma mark - 辅助
@property (nonatomic, strong, readonly) LLListResponseModel *listResponselModel;//LLListResponseModel子类

#pragma mark - 分页相关
@property (nonatomic, assign, readonly) NSInteger       page;//当前是第几页，从1开始
@property (nonatomic, assign, readonly) NSInteger       totalSize;//总共多少数据
@property (nonatomic, assign, readonly) BOOL            hasMore;//是否还有更多数据

#pragma mark - 子类可赋值
@property (nonatomic, assign          ) NSInteger       pageSize;//每页数据，默认30

/**
 创建一个datasource来处理解析数据

 @param delegate 接收回调的对象
 @param parser 与LLURLBaseConfig或者其子类里面的parser同名
 @param configClass url配置类，需要是LLURLBaseConfig子类
 @return object
 */
- (instancetype)initWithDelegate:(id<LLListBaseDataSourceDelegate>)delegate parser:(NSString *)parser urlConfigClass:(Class)configClass;


#pragma mark - 网路请求数据
///重置参数，如果需要通过llurl.params添加参数，为避免出问题，请先调用此方法，再设置参数，最后在执行load
- (void)resetParams;

///第一次请求数据,默认GET方法
- (void)load;

///加载更多数据,默认GET方法
- (void)loadMore;

#pragma mark - 子类解析数据，根据需要重写，
/***************示例**************
NSUInteger reqPage = (type == LLRequestTypeLoadMore) ? (self.page + 1) : 1;
return @{@"offset" : @(self.pageSize * (reqPage - 1))};
 ********************************/
///配置分页参数
- (NSDictionary *)getPageParams:(LLRequestType)type;

#pragma mark -需要解析其他数组的时候自己维护。

/***************示例**************
 [self.activityList removeAllObjects];
 ********************************/
///默认清空list，如果有自定义的多个list，不需要维护父类的list
- (void)clearLists;

/***************示例**************
 LLBaseResponseModel *baseModel =
 [MTLLSONAdapter modelOfClass:[MTLModel class] fromJSONDictionary:result[@"list2"] error:nil];
 [self.activityList addObjectsFromArray:baseModel.list2];

 ********************************/
///如果需要解析多个list请自行解析，无需解析已有的。只维护自己创建的list即可
- (void)parseOtherResultsOnlyRefresh:(NSDictionary *)result;
@end
