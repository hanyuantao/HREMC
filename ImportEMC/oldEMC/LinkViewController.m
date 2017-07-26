//
//  TestViewController.m
//  HaierWrapper
//
//  Created by Magnus on 2015-04-07.
//  Copyright (c) 2015 Ebuilder. All rights reserved.
//

#import "LinkViewController.h"

@interface LinkViewController ()

@end

@implementation LinkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [_myWebView setFrame:CGRectMake(0, 0, self.view.frame.size.width,
                                    self.view.frame.size.height)];
    
    [_myWebView setDelegate:self];
    
    [self.view setBackgroundColor:[UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0]];
    
    [_closeBtn setBackgroundColor:[UIColor colorWithRed:230.0/255.0 green:230.0/255.0 blue:230.0/255.0 alpha:1.0]];
    [_closeBtn.layer setCornerRadius:15.0];
    [_backBtn setBackgroundColor:[UIColor colorWithRed:230.0/255.0 green:230.0/255.0 blue:230.0/255.0 alpha:1.0]];
    [_backBtn.layer setCornerRadius:15.0];
    [_fwdBtn setBackgroundColor:[UIColor colorWithRed:230.0/255.0 green:230.0/255.0 blue:230.0/255.0 alpha:1.0]];
    [_fwdBtn.layer setCornerRadius:15.0];
    
    [_closeBtn setTitle:@"X" forState:UIControlStateNormal];
    
    
}

-(void)viewWillAppear:(BOOL)animated {
    NSURL *url = [NSURL URLWithString:_urlString];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    [_myWebView loadRequest:urlRequest];
    
    if ([_navigation isEqualToString:@"exclude"]) {
        [_fwdBtn setHidden:YES];
        [_backBtn setHidden:YES];
        
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)closeMe:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)goBack:(id)sender {
    
    if ([_myWebView canGoBack]) {
        [_myWebView goBack];
    }
}

- (IBAction)goForward:(id)sender {
    
    if ([_myWebView canGoForward]) {
        [_myWebView goForward];
    }
}
@end
