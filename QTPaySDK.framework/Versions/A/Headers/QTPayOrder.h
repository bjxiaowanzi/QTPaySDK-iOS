//
//  QTPayOrder.h
//  Pods
//
//  Created by Blues on 16/5/26.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, QTPayType) {
    QTPayTypeWeChat = 1,
    QTPayTypeAliPay = 2
};

@interface QTPayOrder : NSObject

@property (nonatomic, strong) NSString *appcode;

@property (nonatomic, strong) NSString *ext;

@property (nonatomic, strong) NSString *goods_id;

@property (nonatomic, strong) NSString *goods_name;

@property (nonatomic, strong) NSString *out_trade_no;

@property (nonatomic, strong) NSString *sign;

@property (nonatomic, strong) NSString *txamt;

@property (nonatomic, strong) NSString *txdtm;

@property (nonatomic, strong) NSString *pay_type;

@property (nonatomic, strong) NSString *userid;

@property (nonatomic, strong) NSString *type;

- (NSDictionary *)dicOrderInfo;

@end
