//
//  TestViewController.h
//  CordovaTest
//
//  Created by Magnus on 2015-03-27.
//
//

#import <UIKit/UIKit.h>
#import "WebViewJavascriptBridge.h"
#import "ZBarSDK.h"
//#import "iflyMSC/IFlySpeechUtility.h"
//#import "iflyMSC/IFlyRecognizerViewDelegate.h"
//#import "iflyMSC/IFlyRecognizerView.h"
//#import "iflyMSC/IFlySpeechConstant.h"
#import "LinkViewController.h"
#import "MBProgressHUD.h"
#import <AVFoundation/AVFoundation.h>
#import <AFNetworking.h>
#import <iflyMSC/iflyMSC.h>

//#import "Scanner.h"


@protocol EMCDelegate
@optional

- (void)doVoiceToText;
- (void)scanBarcode;
- (void)openPage:(NSString *)urlString;


@end

@interface EMCViewController : UIViewController <UIWebViewDelegate, ZBarReaderDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate, IFlyRecognizerViewDelegate, UIAlertViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate> {
    WebViewJavascriptBridge *bridge;
    ZBarReaderViewController *reader;
    UIImagePickerController *imagePicker;
    BOOL isScanBarCode;
    BOOL firstLoadingIsDone;
    BOOL reloadPage;
    BOOL pageLoaded;
    BOOL scanOldBarcode;
    BOOL isOpeningWebView;
    LinkViewController *intLinkVC;
    MBProgressHUD *HUD;
    NSString *finalURL;
    NSTimer *webLoadTimeout;
    UIAlertView *loadingAlertView;

    UIView *datePickerView;
    UIDatePicker *datePicker;
    UIView *timePickerView;
    UIDatePicker *timePicker;

    UIPickerView *listSelectionPicker;
    NSArray *pickerViewItems;
    UIView *listSelectionPickerView;
    NSInteger selectedRowInPicker;
}
@property (strong, nonatomic) IBOutlet UIWebView *myWebView;
@property (weak, nonatomic) id delegate;
@property BOOL alwaysFromStartPage;
@property BOOL animateScannerLine;
@property (strong, nonatomic) NSDictionary *SSO;
@property (strong, nonatomic) NSString *startURL;
@property float alertLoadTimeout;
@property float cancelLoadTimeout;

@property (nonatomic, strong) IFlyRecognizerView *iflyRecognizerView;


- (void)closeMe;
- (void)sendText:(NSString *)text;
- (void)sendBarcode:(NSString *)barCode;
- (void)openURL:(NSString *)urlString withTarget:(NSString *)target useNavigation:(NSString *)navigation;
- (NSString *)encodeParameter:(NSString *)parameter;
- (void)presentDatePickerWithDefaultDate:(NSString *)defaultDate andMinDate:(NSString *)minDate andMaxDate:(NSString *)maxDate;

- (void)updatePageLoadText:(UIAlertView *)alertView;

- (BOOL)isCameraAvailable;
- (BOOL)isMicrophoneAvailable;

@end
