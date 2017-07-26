//
//  QRViewController.h
//  QRWeiXinDemo
//
//  Created by lovelydd on 15/4/25.
//  Copyright (c) 2015年 lovelydd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol QRcodeDelegate <NSObject>

- (void)scanCompleteWithResult:(NSString *) resultValue;

@end


typedef void(^QRUrlBlock)(NSString *url);
@interface QRViewController : UIViewController

@property (nonatomic, assign) id<QRcodeDelegate>delegate;
@property (nonatomic, copy) QRUrlBlock qrUrlBlock;

@end
