//
//  CardViewController.h
//  EMC
//
//  Created by 王帅 on 16/7/15.
//  Copyright © 2016年 王帅. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "iflyMSC/IFlyMSC.h"




@interface CardViewController : UIViewController <IFlyRecognizerViewDelegate>
{
    IFlyRecognizerView      *_iflyRecognizerView;
}

/**
 *boolean类型（true,为正式环境；false，为测试环境）
 */
@property (nonatomic, assign) BOOL isOffical;

/**
 *登录IDS时的skToken
 */
@property (nonatomic, strong) NSString *sdToken;

/**
 *登录IDS时的coSessionID
 */
@property (nonatomic, strong) NSString *coSessionId;

/**
 *用户手机号码
 */
@property (nonatomic, strong) NSString *appName;

/**
 *用户手机号码，作为用户唯一身份识别，11位数字
 */
@property (nonatomic, strong) NSString *phoneNumber;

/**
 *用户的姓名，目前为空
 */
@property (nonatomic, strong) NSString *userName;

/**
 *用外部app与EMC同意的密钥生成的签名，详细信息见4“数据类型的定义”
 */
@property (nonatomic, strong) NSString *signature;

/**
 *进入EMC后直接进入某功能，例如“OldforNew”
 */
@property (nonatomic, strong) NSString *entryPoint;

/**
 *手机型号，例如，“iPhone 6S”
 */
@property (nonatomic, strong) NSString *deviceModel;

//从用户中心获取到的token
@property (nonatomic, strong) NSString *accessToken;

@end
