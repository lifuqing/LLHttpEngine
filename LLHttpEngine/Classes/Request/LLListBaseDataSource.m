//
//  LLListBaseDataSource.m
//  LLHttpEngine
//
//  Created by lifuqing on 2018/4/23.
//

#import "LLListBaseDataSource.h"
#import "LLURLBaseConfig.h"

@interface LLListBaseDataSource()

#pragma mark - 网路请求、数据相关
@property (nonatomic, strong, readwrite) LLURL           *llurl;//请求相关的对象
@property (nonatomic, strong, readwrite) NSMutableArray  *list;//数据源
@property (nonatomic, strong, readwrite) NSError         *error;//error domain为 model.errorMsg -----  error code为 model.errorCode
@property (nonatomic, assign, readwrite) LLRequestType   type;//请求类型
@property (nonatomic, assign, readwrite) BOOL            isLocalCache;//当前数据是否为本地缓存数据

#pragma mark - 辅助
@property (nonatomic, strong, readwrite) LLListResponseModel *listResponselModel;//LLListResponseModel子类

#pragma mark - 分页相关
@property (nonatomic, assign, readwrite) NSInteger       page;//当前是第几页，从1开始
@property (nonatomic, assign, readwrite) NSInteger       totalSize;//总共多少数据
@property (nonatomic, assign, readwrite) BOOL            hasMore;//是否还有更多数据

@property (nonatomic, assign) BOOL requestLock;
@property (nonatomic, weak) id<LLListBaseDataSourceDelegate>  delegate;
@end

@implementation LLListBaseDataSource

- (instancetype)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        _list = [NSMutableArray array];
        _page = 1;
        _pageSize = 30;
        _totalSize = -1;//默认是-1，这样如果未返回total的dic就能够和返回total为0的区分开来
    }
    return self;
}

- (instancetype)initWithDelegate:(id<LLListBaseDataSourceDelegate>)delegate parser:(NSString *)parser urlConfigClass:(Class)configClass {
    if (self = [self init]) {
        _delegate = delegate;
        _llurl = [[LLURL alloc] initWithParser:parser urlConfigClass:configClass];
    }
    return self;
}

- (void)dealloc {
    _delegate = nil;
    _list = nil;
    _error = nil;
    _llurl = nil;
}

- (void)reset {
    _requestLock = NO;
    [self clearListsAndSubClassList];
    self.error = nil;
}

- (void)clearListsAndSubClassList{
    [self.list removeAllObjects];
    [self clearLists];
}

- (void)resetParams {
    [self.llurl clearExtendParams];
}

- (void)load {
    if (_requestLock) {
        return;
    }
    [self reset];

    _requestLock = YES;
    [self startRequest:LLRequestTypeRefresh];
}

- (void)loadMore {
    //上次请求产生的error置空
    self.error = nil;

    if (_hasMore) {
        _requestLock = YES;
        [self startRequest:LLRequestTypeLoadMore];
    }else {
        [self endRequest];
    }
}

- (void)startRequest:(LLRequestType)type {
    _type = type;
    //获取page参数
    [_llurl.params addEntriesFromDictionary:[self getPageParams:type]];
    _llurl.curRequestType = type;
    __weak typeof(self) weakSelf = self;
    [[LLHttpEngine sharedInstance] sendRequestWithLLURL:_llurl target:self success:^(NSURLResponse * _Nullable response, NSDictionary * _Nullable result, LLBaseResponseModel * _Nullable model, BOOL isLocalCache) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (type == LLRequestTypeRefresh) {
            [strongSelf clearListsAndSubClassList];
        }
        [strongSelf parseResult:result responseModel:model type:type];
        strongSelf.isLocalCache = isLocalCache;
        [strongSelf endRequest];
    } failure:^(NSURLResponse * _Nullable response, NSError * _Nullable error,  LLBaseResponseModel * _Nullable model) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        weakSelf.error = [[NSError alloc] initWithDomain:model.errorMsg code:model.errorCode userInfo:nil];
        [strongSelf endRequest];
    }];
}

- (void)parseResult:(NSDictionary *)result responseModel:(LLBaseResponseModel *)responseModel type:(LLRequestType)type {
    if ([responseModel isKindOfClass:[LLListResponseModel class]]) {
        _listResponselModel = (LLListResponseModel *)responseModel;
        //解析列表
        [self.list addObjectsFromArray:_listResponselModel.list];
        //请求成功之后才计算分页
        [self calculateResult:_listResponselModel requestType:type];
    }

    if (type == LLRequestTypeRefresh) {
        [self parseOtherResultsOnlyRefresh:result];
    }
}

- (void)endRequest
{
    if (_delegate && [_delegate respondsToSelector:@selector(finishOfDataSource:)]) {
        [_delegate finishOfDataSource:self];
    }
    _requestLock = NO;
}

- (void)calculateResult:(LLListResponseModel *)listResponselModel requestType:(LLRequestType)type {
    if (type == LLRequestTypeRefresh) {
        _page = 1;
    }
    else if (type == LLRequestTypeLoadMore) {
        _page = _page + 1;
    }

    self.totalSize = listResponselModel.total;
    self.hasMore = listResponselModel.hasMore;
}

#pragma mark rewrite
- (NSDictionary *)getPageParams:(LLRequestType)type
{
    NSUInteger reqPage = (type == LLRequestTypeLoadMore) ? (self.page + 1) : 1;
    return @{@"offset" : @(self.pageSize * (reqPage - 1)), @"limit" : @(self.pageSize)};
}

- (void)clearLists{
}

- (void)parseOtherResultsOnlyRefresh:(NSDictionary *)result{
}
@end
