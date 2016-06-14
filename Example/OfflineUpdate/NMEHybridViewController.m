//
//  NMEHybridViewController.m
//  NearMerchant
//
//  Created by Blues on 16/4/6.
//  Copyright © 2016年 qmm. All rights reserved.
//

#import "NMEHybridViewController.h"
#import "WebViewJavascriptBridge.h"
#import "QFOfflineH5Proxy.h"
#import <QTPaySDK/QTPaySDK.h>

@interface NMEHybridViewController () <UIWebViewDelegate> {
    IBOutlet UIWebView *_webView;
    WebViewJavascriptBridgeBase *_base;
}

@end

@implementation NMEHybridViewController

#pragma mark - Life cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _isConfigNav = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title =_strTitle;
    _base = [[WebViewJavascriptBridgeBase alloc] init];
    [[QFOfflineH5Proxy shareInstance] setBase:_base];
    [[QFOfflineH5Proxy shareInstance] initWebView:_webView withPath:_strH5PagePath];
    [[QFOfflineH5Proxy shareInstance] setWebViewDelegate:self];
    
    // **** proxy 发过来的消息
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(exitHybridViewController) name:@"ExitHybridViewController" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showQTPaySDKUI:) name:@"showQTPaySDKUI" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[QFOfflineH5Proxy shareInstance] cancelTask];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Notification method

- (void)exitHybridViewController {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)showQTPaySDKUI:(NSNotification *)notification {
    NSDictionary *dicInfo = notification.object;
    NSMutableDictionary *dicOrderInfo = dicInfo[@"order"];
    WVJBResponseCallback callback = dicInfo[@"h5callback"];
    [[QTPaySDK shareInstance] setQTPaySDKEnv:QTPaySDKWebSandBox];
    [[QTPaySDK shareInstance] showWithInfo:dicOrderInfo onVC:self completeBlock:^(NSDictionary *dicPayResult) {
        callback(dicPayResult);
    }];
}

#pragma mark - Private Method
#pragma mark -- UI

#pragma mark - NMEWebViewProgressDelegate

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    NSLog(@"start load");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if (_strTitle.length == 0) {
        NSString *strTitle = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
        self.title = strTitle;
    }
    
    [self injectJSBridge];
    NSLog(@"finish load");
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [[QFOfflineH5Proxy shareInstance] webView:webView didFailLoadWithError:error];
}

- (void)dealloc {
    _webView = nil;
}

- (void)injectJSBridge {
    [_base performSelector:@selector(injectJavascriptFile)];
}

#pragma mark - UINavigation Bar

- (void)popViewController {
    if ([_webView canGoBack] == YES) {
        [_webView goBack];
    }
    else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
