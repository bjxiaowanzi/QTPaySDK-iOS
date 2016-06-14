//
//  ViewController.m
//  Example
//
//  Created by Blues on 16/6/13.
//  Copyright © 2016年 Blues. All rights reserved.
//

#import "MainViewController.h"
#import "NMEHybridViewController.h"
#import <QTPaySDK/QTPaySDK.h>

@interface MainViewController ()

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[QTPaySDK shareInstance] setAppSchema:@"QTDemo"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Actions

- (IBAction)clickPayBtn:(id)sender {
    [self login];
}

- (void)login {
    NSDictionary *requestDic = @{@"username" : @"17000000000",
                                 @"password" : @"123456",
                                 @"expire_time" : @"864000",
                                 @"udid":@"ADFDEFAFEAFAEGAAWGA"
                                 };
    
    AFHTTPSessionManager *httpManager = [[AFHTTPSessionManager alloc] initWithBaseURL:nil];
    httpManager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/json"];
    httpManager.requestSerializer.timeoutInterval = 10.0f;
    
    AFSecurityPolicy *securityPolicy = [[AFSecurityPolicy alloc] init];
    [securityPolicy setAllowInvalidCertificates:YES];
    [httpManager setSecurityPolicy:securityPolicy];
    httpManager.requestSerializer = [AFHTTPRequestSerializer serializer];
    httpManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [httpManager POST:@"http://172.100.111.115:2002/mchnt/user/login" parameters:requestDic success:^(NSURLSessionDataTask *task, id responseObject) {
        
        NSDictionary *dicResp = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
        NSLog(@"dicResp %@",dicResp);
        if (![dicResp[@"respcd"] isEqualToString:@"0000"]) {
            return ;
        }
        [self createOrderRequest:dicResp[@"data"][@"userid"]];
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
    }];
}

- (void)createOrderRequest:(NSString *)strUserid {
    
    AFHTTPSessionManager *httpManager = [[AFHTTPSessionManager alloc] initWithBaseURL:nil];
    httpManager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/json"];
    httpManager.requestSerializer.timeoutInterval = 10.0f;
    
    AFSecurityPolicy *securityPolicy = [[AFSecurityPolicy alloc] init];
    [securityPolicy setAllowInvalidCertificates:YES];
    [httpManager setSecurityPolicy:securityPolicy];
    httpManager.requestSerializer = [AFHTTPRequestSerializer serializer];
    httpManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    NSDictionary *dicInfo = @{@"goods_code" : @"card" , @"price_code" : @"month" };
    [httpManager POST:@"http://172.100.111.115:2002/mchnt/recharge/v1/create_order" parameters:dicInfo success:^(NSURLSessionDataTask *task, id responseObject) {
        
        NSDictionary *dicResp = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
        NSLog(@"dicResp %@",dicResp);
        if (![dicResp[@"respcd"] isEqualToString:@"0000"]) {
            return ;
        }
        NSMutableDictionary *dicData = [NSMutableDictionary dictionaryWithDictionary:dicResp[@"data"]];
        [dicData setValue:strUserid forKey:@"userid"];
        [[QTPaySDK shareInstance] setQTPaySDKEnv:QTPaySDKAppSandBox];
        [[QTPaySDK shareInstance] showWithInfo:dicData onVC:self completeBlock:^(NSDictionary *dicPayResult) {
            ;
        }];
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
    }];
}

- (IBAction)clickWebViewBtn:(id)sender {
    NMEHybridViewController *hybridViewController = [[NMEHybridViewController alloc] init];
    hybridViewController.strTitle = @"checkout";
    hybridViewController.strH5PagePath = @"http://work.jove.im:15194/checkout";
    [self.navigationController pushViewController:hybridViewController animated:YES];
}

@end
