//
//  QFOfflineH5Proxy.m
//  NearMerchant
//
//  Created by Blues on 1/27/16.
//  Copyright © 2016 qmm. All rights reserved.
//

static NSString * const strNativeSchema     = @"near-merchant-native://";           // **** H5 调本地功能，类似 拍照，下载等本地功能 或者 打开本地页面
static NSString * const strH5PageSchema     = @"near-merchant-h5://";               // **** H5 打开 H5 页面
static NSString * const strH5APIJSSchema    = @"near-merchant-offlineAPIJS://";     // **** H5 通过本地调API接口
static NSString * const strH5ParamsJSSchema = @"near-merchant-offlineParamsJS://";  // **** H5 在页面跳转时 传递参数

#import "QFOfflineH5Proxy.h"
#import <objc/runtime.h>
#import <QTPaySDK/QTPaySDK.h>

@interface QFOfflineH5Proxy () <UIWebViewDelegate> {
    
    NSString *_strDomain;
    UIWebView *_webView;
    id _dataParamsForNextPage;
    WebViewJavascriptBridge *_bridge;
    NSURLSessionDataTask *_task;
}

@end

@implementation QFOfflineH5Proxy

+ (instancetype)shareInstance {
    static QFOfflineH5Proxy *obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[QFOfflineH5Proxy alloc] init];
    });
    return obj;
}

- (void)setWebViewDelegate:(id)webViewDelegate {
    if (_bridge != nil) {
        [_bridge setWebViewDelegate:webViewDelegate];
    }
}

- (void)injectJSBridgeBase:(WebViewJavascriptBridgeBase *)base {
    unsigned int count = 0;
    Ivar *members = class_copyIvarList([_bridge class], &count);
    Ivar _baseMember = members[count - 1];
    base.delegate = _bridge;
    object_setIvar(_bridge, _baseMember, base);
    free(members);
}

- (void)setDataToH5:(NSDictionary *)dicParams {
    _dataParamsForNextPage = dicParams;
}

- (void)cancelTask {
    if (_task != nil && _task.state == NSURLSessionTaskStateRunning) {
        [_task cancel];
    }
}

// **** Offline H5 -> Native
- (void)initWebView:(UIWebView *)webView withPath:(NSString *)strPath {
    [self setupWebViewUA];
    _webView = webView;
    
    [WebViewJavascriptBridge enableLogging];
    _bridge = [WebViewJavascriptBridge bridgeForWebView:_webView];
    
    [self injectJSBridgeBase:_base];
    
    [_bridge registerHandler:@"QFH5CallNative" handler:^(id data, WVJBResponseCallback responseCallback) {
        
        _task = nil;
        NSString *strSchema = data[@"schema"];
        NSString *strPath = data[@"path"];
        NSDictionary *dicParams = data[@"params"];
        NSString *strAction = data[@"action"];
        if ([strSchema isEqualToString:strH5APIJSSchema] == YES) {  // **** 调API
            _task = [self handleOfflineAPIJSSchemaWithPath:strPath method:strAction params:dicParams callback:responseCallback];
        }
        if ([strSchema isEqualToString:strH5PageSchema] == YES) {   // **** 打开h5页面
            [self handleH5SchemaWithPath:strPath dicParams:dicParams];
        }
        if ([strSchema isEqualToString:strH5ParamsJSSchema]) {      // **** 传递h5页面跳转所需参数
            [self handleOfflineParamsJSSchemaWithCallBack:responseCallback];
        }
        if ([strSchema isEqualToString:strNativeSchema]) {          // **** 调APP原生功能
            [self handleNativeSchemaWithPath:strPath action:strAction params:dicParams callback:responseCallback];
        }
    }];
    
    // **** 初始化本地的 domain 路径
    NSString *strResourcePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Offline"]; //[[NSBundle mainBundle] bundlePath];
    _strDomain = [strResourcePath stringByAppendingPathComponent:@"website"]; // **** 应该可配置
    
    NSURLRequest *req = nil;
    if ([strPath hasPrefix:@"http"] == YES) { // **** 打开线上H5页面
        req = [NSURLRequest requestWithURL:[NSURL URLWithString:strPath]];
    }
    else { // **** 打开离线H5页面
        if ([strPath hasPrefix:@"/"] == NO) { // **** 传入的 不 是离线页面的地址，而是固定配好的地址
            strPath = _dicPages[strPath][@"offline"];
        }
        if (strPath == nil) {
            return;
        }
        NSString *strURL = [_strDomain stringByAppendingString:strPath];
        req = [NSURLRequest requestWithURL:[NSURL URLWithString:strURL]];
    }
    [_webView loadRequest:req];
}

- (void)callHandlerWithParams:(NSDictionary *)dicParams completeBlock:(QFCallHandlerCompleteBlock)completeBlock {
    [_bridge callHandler:@"QFNativeCallH5" data:dicParams responseCallback:^(id responseData) {
        completeBlock(responseData);
    }];
}

// **** Web页面区别是通过JS请求还是通过本地APP进行API请求
- (void)setupWebViewUA {
    UIWebView *webView1 = [[UIWebView alloc] initWithFrame:CGRectZero];
    NSString *oldAgent = [webView1 stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
    NSString *newAgent = [oldAgent stringByAppendingString:@" QMMWD/2.2.5 iPhone/iOS9.1 AFNetwork/1.1"];
    
    NSDictionary *dictionnary = [[NSDictionary alloc] initWithObjectsAndKeys:newAgent, @"UserAgent", nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionnary];
}

#pragma mark - near-merchant-offlineAPIJS://

- (NSString *)onApiUserAgent {
    return [NSString stringWithFormat:@"QMMWD/%@ %@/%@ AFNetwork/1.1", @"2.6.4", @"iPhone", @"9.3.2"];
}

- (NSURLSessionDataTask *)handleOfflineAPIJSSchemaWithPath:(NSString *)strPath method:(NSString *)strMethod params:(NSDictionary *)dicParams callback:(WVJBResponseCallback)callback {
    NSString *strUserAgent = [self onApiUserAgent];
    AFHTTPSessionManager *httpManager = [[AFHTTPSessionManager alloc] initWithBaseURL:nil];
    [httpManager.requestSerializer setValue:strUserAgent forHTTPHeaderField:@"User-Agent"];
    httpManager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/json"];
    httpManager.requestSerializer.timeoutInterval = 10.0f;
    
    AFSecurityPolicy *securityPolicy = [[AFSecurityPolicy alloc] init];
    [securityPolicy setAllowInvalidCertificates:YES];
    [httpManager setSecurityPolicy:securityPolicy];
    httpManager.requestSerializer = [AFHTTPRequestSerializer serializer];
    httpManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    if ([[strMethod lowercaseString] isEqualToString:@"get"]) {
        return [httpManager GET:strPath parameters:dicParams success:^(NSURLSessionDataTask *task, id responseObject) {
            [self handleAPIData:responseObject andCallBack:callback];
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"\n\n\n *** 请求错误: %@ *** \n\n\n", error);
        }];
    }
    if ([[strMethod lowercaseString] isEqualToString:@"post"]) {
        return [httpManager POST:strPath parameters:dicParams success:^(NSURLSessionDataTask *task, id responseObject) {
            [self handleAPIData:responseObject andCallBack:callback];
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"\n\n\n *** 请求错误: %@ *** \n\n\n", error);
        }];
    }
    if ([[strMethod lowercaseString] isEqualToString:@"put"]) {
        return [httpManager PUT:strPath parameters:dicParams success:^(NSURLSessionDataTask *task, id responseObject) {
            [self handleAPIData:responseObject andCallBack:callback];
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"\n\n\n *** 请求错误: %@ *** \n\n\n", error);
        }];
    }
    if ([[strMethod lowercaseString] isEqualToString:@"delete"]) {
        return [httpManager DELETE:strPath parameters:dicParams success:^(NSURLSessionDataTask *task, id responseObject) {
            [self handleAPIData:responseObject andCallBack:callback];
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"\n\n\n *** 请求错误: %@ *** \n\n\n", error);
        }];
    }
    return nil;
}

- (void)handleAPIData:(id)responseObject andCallBack:(WVJBResponseCallback)callback {
    NSDictionary *responseDic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
    NSData *dataJSON = [NSJSONSerialization dataWithJSONObject:responseDic options:NSJSONWritingPrettyPrinted error:nil];
    NSString *strRespJSON = [[NSString alloc] initWithData:dataJSON encoding:NSUTF8StringEncoding];
    callback(strRespJSON);
}

#pragma mark - near-merchant-h5://

- (void)handleH5SchemaWithPath:(NSString *)strPath dicParams:(NSDictionary *)dicParams {
    NSURLRequest *req = nil;
    if ([strPath hasPrefix:@"http"] == YES) { // **** online h5
        req = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:strPath]];
        [_webView loadRequest:req];
    }
    else {
        NSString *strURL = [_strDomain stringByAppendingString:strPath];
        req = [NSURLRequest requestWithURL:[NSURL URLWithString:strURL]];
    }
    [_webView loadRequest:req];
    _dataParamsForNextPage = dicParams;
}

#pragma mark - near-merchant-offlineParamsJS://

- (void)handleOfflineParamsJSSchemaWithCallBack:(WVJBResponseCallback)callback {
    callback(_dataParamsForNextPage);
}

#pragma mark - near-merchant-native://

- (void)handleNativeSchemaWithPath:(NSString *)strPath action:(NSString *)strAction params:(NSDictionary *)dicParams callback:(WVJBResponseCallback)callback {
    if ([[strAction lowercaseString] isEqualToString:@"back"]) { // **** 返回退出整个web页面
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ExitHybridViewController" object:nil];
    }
    if ([[strAction lowercaseString] isEqualToString:@"checkout"]) { // **** 调起收银台
        NSMutableDictionary *dicOrderInfo = [NSMutableDictionary dictionaryWithDictionary:dicParams];
        dicOrderInfo[@"userid"] = @"338758";   // **** 填写登录的userid，暂时使用艳春的userid
        
        NSDictionary *dicInfo = @{@"order" : dicOrderInfo, @"h5callback" : callback};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"showQTPaySDKUI" object:dicInfo];
    }
}

#pragma - UIWebView delegate

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSString *strURL = error.userInfo[NSURLErrorFailingURLStringErrorKey];
    if ([strURL hasPrefix:@"http"] == NO) { // **** 请求离线H5失败
        NSArray *arr = [strURL componentsSeparatedByString:@"/"];
        NSInteger count = arr.count;
        if (count < 3) {
            return;
        }
        NSString *strPath = [@"/" stringByAppendingString:arr[count - 2]];
        strPath = [strPath stringByAppendingString:@"/"];
        strPath = [strPath stringByAppendingString:arr[count - 1]];
        NSString *strOnlinePath = _dicPages[strPath][@"online"];
        if (strOnlinePath != nil) { // **** 有对应的线上地址
            [self initWebView:_webView withPath:strOnlinePath];
        }
    }
}

@end
