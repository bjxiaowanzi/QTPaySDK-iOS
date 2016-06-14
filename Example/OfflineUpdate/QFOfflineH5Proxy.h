//
//  QFOfflineH5Proxy.h
//  NearMerchant
//
//  Created by Blues on 1/27/16.
//  Copyright © 2016 qmm. All rights reserved.
//

typedef void(^QFCallHandlerCompleteBlock)(id callbackData);

#import <Foundation/Foundation.h>
#import "WebViewJavascriptBridge.h"

@interface QFOfflineH5Proxy : NSObject

@property (nonatomic, weak) id<UIWebViewDelegate> webViewDelegate;
@property (nonatomic, strong) WebViewJavascriptBridgeBase *base;
@property (nonatomic, strong) NSDictionary *dicPages; // **** 离线H5的线上/线下路由

+ (instancetype)shareInstance;
- (void)setDataToH5:(NSDictionary *)dicParams;
- (void)cancelTask;
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error;
- (void)initWebView:(UIWebView *)webView withPath:(NSString *)strPath;
- (void)callHandlerWithParams:(NSDictionary *)dicParams completeBlock:(QFCallHandlerCompleteBlock)completeBlock;

@end
