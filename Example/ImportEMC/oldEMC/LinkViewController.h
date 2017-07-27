//
//  TestViewController.h
//  HaierWrapper
//
//  Created by Magnus on 2015-04-07.
//  Copyright (c) 2015 Ebuilder. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LinkViewController : UIViewController <UIWebViewDelegate>

@property (strong, nonatomic) NSString *urlString;
@property (strong, nonatomic) NSString *navigation;
@property (strong, nonatomic) IBOutlet UIWebView *myWebView;


@property (strong, nonatomic) IBOutlet UIButton *closeBtn;
@property (strong, nonatomic) IBOutlet UIButton *fwdBtn;
@property (strong, nonatomic) IBOutlet UIButton *backBtn;

- (IBAction)closeMe:(id)sender;
- (IBAction)goBack:(id)sender;
- (IBAction)goForward:(id)sender;

@end
