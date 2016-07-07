//
//  QTPaySDK.h
//  Pods
//
//  Created by Blues on 16/5/26.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, QTPaySDKEnv) {
    QTPaySDKWebSandBox      = 0, // **** Web沙盒环境
    QTPaySDKAppSandBox      = 1, // **** App沙盒环境
    QTPaySDKWebGray         = 2, // **** Web灰度环境
    QTPaySDKAppGray         = 3, // **** App灰度环境
    QTPaySDKWebProduction   = 4, // **** Web正式环境
    QTPaySDKAppProduction   = 5, // **** App正式环境
};

typedef NS_ENUM(NSInteger, QTPayType) {
    QTPayTypeWeChat = 1,
    QTPayTypeAliPay = 2
};

typedef void(^QTPaySDKCompleteBlock)(NSDictionary *dicPayResult);

@interface QTPaySDK : NSObject

@property (nonatomic, assign, readonly) QTPaySDKEnv payEnv;

/**
 *  创建支付单例
 *
 *  @return 支付单例对象
 */
+ (instancetype)shareInstance;

/**
 *  设置SDK环境
 *
 *  @param payEnv 环境参数，枚举类型（支持沙盒/灰度/正式）
 */
- (void)setQTPaySDKEnv:(QTPaySDKEnv)payEnv;

/**
 *  设置当前SDK能当前App调起的Schema，并注册WX的Schema
 *
 *  @param strSchema 从第三方App调起当前App的Schema
 */
- (void)setAppSchema:(NSString *)strSchema;

#pragma mark - API

/**
 *  支付订单
 *
 *  @param dicOrder      后台返回的需要支付的订单信息，因为后端返回的可能会加参数，所以不用model
 *  @param completeBlock 支付完后的回调
 */
- (void)payWithInfo:(NSDictionary *)dicOrderInfo completeBlock:(QTPaySDKCompleteBlock)completeBlock;

/**
 *  处理第三方app支付完后跳回商户app携带的支付结果
 *
 *  @param resultUrl     支付结果url
 *  @param completeBlock 保证商户app能通过这个回调拿到支付结果
 */
- (void)processOrderWithPaymentResult:(NSURL *)resultUrl completeBlock:(QTPaySDKCompleteBlock)completeBlock;

#pragma mark - UI

/**
 *  调起支付页面
 *
 *  @param dicOrderInfo  需要界面上显示的商品订单信息
 *  @param destVC        承载支付页面的视图控制器
 *  @param completeBlock 支付结果的回调
 */
- (void)showWithInfo:(NSDictionary *)dicOrderInfo onVC:(UIViewController *)destVC completeBlock:(QTPaySDKCompleteBlock)completeBlock;

@end
