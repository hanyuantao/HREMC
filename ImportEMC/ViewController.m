//
//  ViewController.m
//  ImportEMC
//
//  Created by LingChun on 2016/11/8.
//  Copyright © 2016年 LingChun. All rights reserved.
//

#import "ViewController.h"
#import "CardViewController.h"  
#import "EMCViewController.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)ShowEmc:(id)sender {
    
    BOOL isNew;  //判断是否为新版本, YES为新版本，NO为旧版本
    isNew = YES; //根据项目需要给isNew赋值，
    if (isNew) {
        CardViewController *cardVC = [[CardViewController alloc]init];
        cardVC.isOffical = NO; //boolean类型（true,为正式环境；false，为测试环境）
        cardVC.sdToken = @"";//登录IDS时的skToken
        cardVC.coSessionId = @""; //登录IDS时的coSessionID
        cardVC.appName = @"";  //用户手机号码
        cardVC.phoneNumber = @""; //用户手机号码，作为用户唯一身份识别，11位数字
        cardVC.userName = @"";  //用户的姓名，目前为空
        cardVC.signature = @"";  //用外部app与EMC同意的密钥生成的签名，详细信息见4“数据类型的定义”
        cardVC.entryPoint = @"";  //进入EMC后直接进入某功能，例如“OldforNew”
        //<如果上述参数如果为空，请赋值 @"">
        UINavigationController *navc = [[UINavigationController alloc]initWithRootViewController:cardVC];
        [self presentViewController:navc animated:YES completion:^{
            NSLog(@"present success");
        }];
    } else {
        EMCViewController *emcVC = [[EMCViewController alloc]initWithNibName:@"EMCViewController" bundle:nil];
        emcVC.delegate = self;
        emcVC.alwaysFromStartPage = YES;
        NSDictionary *SSO = [NSDictionary dictionaryWithObjectsAndKeys:@"theToken", @"SSPTOKEN", @"theUID", @"UID", nil]; //token 和UID 根据老板的参数传值
        emcVC.SSO = SSO;
        emcVC.startURL = @"http://emc-web.haier.net";
        [self presentViewController:emcVC animated:YES completion:NULL];
    }

}

@end
