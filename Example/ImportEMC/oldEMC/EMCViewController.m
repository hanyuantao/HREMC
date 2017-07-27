//
//  EMCViewController.m
//
//
//  Created by Magnus on 2015-03-27.
//
//

#import "EMCViewController.h"
#import "ScannerOverlayView.h"

@interface EMCViewController ()<UINavigationControllerDelegate,UIImagePickerControllerDelegate>

@end

@implementation EMCViewController

#define APPID_VALUE @"578743ed" //54db5405"
#define URL_VALUE @"" // url
#define TIMEOUT_VALUE @"20000" // timeout      连接超时的时间，以ms为单位
#define BEST_URL_VALUE @"1" // best_search_url 最优搜索路径

#define SEARCH_AREA_VALUE @"安徽省合肥市"
#define ASR_PTT_VALUE @"1"
#define VAD_BOS_VALUE @"5000"
#define VAD_EOS_VALUE @"1800"
#define PLAIN_RESULT_VALUE @"1"
#define ASR_SCH_VALUE @"1"


static NSString *const kScanBarCode = @"scanBarcode";
static NSString *const kVoiceRecognition = @"startVoiceRecognition";
static NSString *const kGetImage = @"getImage";
static NSString *const kOpenURL = @"openURL";
static NSString *const kCloseMe = @"closeMe";
static NSString *const kGetDate = @"getDate";
static NSString *const kGetTime = @"getTime";
static NSString *const kSelectionList = @"selectionList";
static NSString *const kStartURL = @"";

//static int maximumImageFileSize = 100000;

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSString *initString = [[NSString alloc] initWithFormat:@"appid=%@,timeout=%@", APPID_VALUE, TIMEOUT_VALUE];

    [IFlySpeechUtility createUtility:initString];

    //_myWebView= [[UIWebView alloc ] init];
    //[self.view addSubview:_myWebView];

    bridge = [WebViewJavascriptBridge
        bridgeForWebView:_myWebView
         webViewDelegate:self
                 handler:^(id data, WVJBResponseCallback responseCallback) {

                   NSString *jsonString =
                       [NSString stringWithFormat:@"%@", data];

                   NSData *bridgeData =
                       [jsonString dataUsingEncoding:NSUTF8StringEncoding];
                   id json = [NSJSONSerialization JSONObjectWithData:bridgeData
                                                             options:0
                                                               error:nil];

                   NSMutableDictionary *dataDict = (NSMutableDictionary *)json;


                   NSString *command = [dataDict objectForKey:@"command"];

                   /*
                   *  Scan Bar code
                   */
                   if ([command isEqualToString:kScanBarCode]) {
                       [self selectScanMethod];
                   }
                   /*
                   *  Get Image
                   */
                   if ([command isEqualToString:kGetImage]) {
                       [self selectImageMethod];
                   }

                   /*
                   *  Open external URL
                   */
                   if ([command isEqualToString:kOpenURL]) {

                       NSString *target = [dataDict objectForKey:@"target"];
                       NSString *urlString = [dataDict objectForKey:@"url"];
                       NSString *navigation = [dataDict objectForKey:@"navigation"];

                       if (!target)
                           target = @"internal";
                       if (!navigation)
                           navigation = @"include";

                       [self openURL:urlString withTarget:target useNavigation:navigation];
                   }

                   /**
                   *  Use iFlyTek Voice Recognition Service
                   */
                   if ([command isEqualToString:kVoiceRecognition]) {

                       [self doVoiceToText];
                   }

                   /**
                   *  Get Date with Date Picker
                   */
                   if ([command isEqualToString:kGetDate]) {

                       NSString *defaultDate = [dataDict objectForKey:@"defaultDate"];
                       NSString *minDate = [dataDict objectForKey:@"minDate"];
                       NSString *maxDate = [dataDict objectForKey:@"maxDate"];


                       [self presentDatePickerWithDefaultDate:defaultDate andMinDate:minDate andMaxDate:maxDate];
                   }

                   /**
                   *  Get Time with Date Picker
                   */
                   if ([command isEqualToString:kGetTime]) {

                       NSString *step = [dataDict objectForKey:@"step"];

                       [self presentTimePickerWithStep:step];
                   }

                   /**
                   *  Get List Selection value
                   */
                   if ([command isEqualToString:kSelectionList]) {

                       NSArray *items = [dataDict objectForKey:@"items"];

                       [self presentListSelection:items];
                   }

                   /**
                   *  Close the EMC component
                   */
                   if ([command isEqualToString:kCloseMe]) {

                       [self closeMe];
                   }


                 }];
    reloadPage = YES;
    _animateScannerLine = YES; //The default, can be overridden by calling view controller

    //_myWebView.scrollView.bounces = NO;
}


- (void)webViewDidStartLoad:(UIWebView *)webView
{

    if ([self networkAvailable]) {

        // If we have network connection show activity indicator

        loadingAlertView = [[UIAlertView alloc] initWithTitle:@"加载中 ..." message:nil delegate:self cancelButtonTitle:@"返回" otherButtonTitles:nil];

        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [indicator startAnimating];
        [loadingAlertView setTag:300];

        [loadingAlertView setValue:indicator forKey:@"accessoryView"];
        [loadingAlertView show];

        [self performSelector:@selector(updatePageLoadText:) withObject:loadingAlertView afterDelay:_alertLoadTimeout]; // Show alert to ask user if load should continue
    }
    else {

        // No network available ...

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"网络连接问题", nil)
                                                        message:NSLocalizedString(@"请检查您的网络连接", nil)
                                                       delegate:self
                                              cancelButtonTitle:@"返回"
                                              otherButtonTitles:@"重试", nil];

        [alert show];
    }


    /* Not used anymore, will keep for future ...
   
    
    [self performSelector:@selector(askForContinueLoad) withObject:nil afterDelay:_alertLoadTimeout];  // Show alert to ask user if load should continue
    
    webLoadTimeout = [NSTimer scheduledTimerWithTimeInterval:_cancelLoadTimeout target:self selector:@selector(cancelWebLoad) userInfo:nil repeats:NO]; // Will cancel load and ask user if reload
    
    */
}

- (void)updatePageLoadText:(UIAlertView *)alertView
{

    [alertView setTitle:@"您的连接速度较慢，请耐心等待..."];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{

    [loadingAlertView dismissWithClickedButtonIndex:1 animated:YES];
    pageLoaded = YES;
}

/* Not used anymore, will keep for future
-(void) askForContinueLoad {
    
    if (!pageLoaded) {
        UIAlertView *alert =[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"继续？", nil)
                                                   message:NSLocalizedString(@"加载需要一定时间，您要继续等待或返回到前面的页面？", nil)
                                                  delegate:self
                                         cancelButtonTitle:@"继续加载"
                                         otherButtonTitles:@"返回", nil];
        [alert setTag:100];
        [alert show];
    }
    
}

-(void) cancelWebLoad{
    
    UIAlertView *alert =[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"功能加载失败", nil)
                                                   message:NSLocalizedString(@"您想要重试还是返回到之前的页面", nil)
                                                  delegate:self
                                         cancelButtonTitle:nil
                                         otherButtonTitles:@"重试",@"返回", nil];
    [alert setTag:200];
    [alert show];
    
}

*/

- (void)viewWillAppear:(BOOL)animated
{

    if (reloadPage) {
        // Always reload unless view was hidden by modal views (when doing barcode scanning or pop image capture)

        pageLoaded = NO;

        // Set the frame here when the view has it's frame set in presenting viewcontroller
        [_myWebView setFrame:CGRectMake(0, 20.0, self.view.frame.size.width, self.view.frame.size.height - 20.0)];
        _myWebView.opaque = YES;
        _myWebView.backgroundColor = [UIColor clearColor];

        if (!_iflyRecognizerView) {
            //Voice Dictation Delegate
            _iflyRecognizerView = [[IFlyRecognizerView alloc] initWithCenter:self.view.center];
            _iflyRecognizerView.delegate = self;
        }


        NSString *urlString;
        if (!_startURL) {
            urlString = kStartURL;
        }
        else {
            urlString = _startURL;
        }

        NSMutableString *qpString = [[NSMutableString alloc] init];

        if (_SSO) {
            for (NSString *key in _SSO) {
                [qpString appendFormat:@"%@=%@&", key, [_SSO objectForKey:key]];
            }
        }

        finalURL = [NSString stringWithFormat:@"%@?%@mode=uplus", urlString, qpString];

        //finalURL = [NSString stringWithFormat:@"%@", urlString];

        [self loadPage];
    }
    else {
        // Reset reLoad flag
        reloadPage = YES;
    }
}

- (void)loadPage
{

    NSURL *url = [NSURL URLWithString:finalURL];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    [_myWebView loadRequest:urlRequest];
}


- (BOOL)isCameraAvailable
{

    // Check if camera is enabled

    BOOL __block cameraIsAvailable = NO;

    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusAuthorized) {
        // do your logic
        cameraIsAvailable = YES;
    }
    else if (authStatus == AVAuthorizationStatusDenied) {
        // denied
        cameraIsAvailable = NO;
    }
    else if (authStatus == AVAuthorizationStatusRestricted) {
        // restricted, normally won't happen
        cameraIsAvailable = NO;
    }
    else if (authStatus == AVAuthorizationStatusNotDetermined) {
        // not determined?!
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
                                 completionHandler:^(BOOL granted) {
                                   if (granted) {
                                       NSLog(@"Granted access to %@", AVMediaTypeVideo);
                                       cameraIsAvailable = YES;
                                   }
                                   else {
                                       NSLog(@"Not granted access to %@", AVMediaTypeVideo);
                                       cameraIsAvailable = NO;
                                   }
                                 }];
    }
    else {
        // impossible, unknown authorization status
    }

    return cameraIsAvailable;
}

- (BOOL)isMicrophoneAvailable
{

    // Check if microphone is enabled

    BOOL __block microphoneIsAvailable = NO;

    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (authStatus == AVAuthorizationStatusAuthorized) {
        // do your logic
        microphoneIsAvailable = YES;
    }
    else if (authStatus == AVAuthorizationStatusDenied) {
        // denied
        microphoneIsAvailable = NO;
    }
    else if (authStatus == AVAuthorizationStatusRestricted) {
        // restricted, normally won't happen
        microphoneIsAvailable = NO;
    }
    else if (authStatus == AVAuthorizationStatusNotDetermined) {
        // not determined?!
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio
                                 completionHandler:^(BOOL granted) {
                                   if (granted) {
                                       NSLog(@"Granted access to %@", AVMediaTypeAudio);
                                       microphoneIsAvailable = YES;
                                   }
                                   else {
                                       NSLog(@"Not granted access to %@", AVMediaTypeAudio);
                                       microphoneIsAvailable = NO;
                                   }
                                 }];
    }
    else {
        // impossible, unknown authorization status
    }

    return microphoneIsAvailable;
}

#pragma mark - List Selection Picker

- (void)presentListSelection:(NSArray *)items
{
    pickerViewItems = items;
    if (!listSelectionPickerView) {

        CGRect viewRect = CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, self.view.bounds.size.height / 3.0 + 40.0);
        listSelectionPickerView = [[UIView alloc] initWithFrame:viewRect];
        [listSelectionPickerView setBackgroundColor:[UIColor colorWithRed:240.0 / 255.0 green:240.0 / 255.0 blue:240.0 / 255.0 alpha:1.0]];

        CGRect pickerRect = CGRectMake(0, 40.0, self.view.bounds.size.width, self.view.bounds.size.height / 3.0);
        listSelectionPicker = [[UIPickerView alloc] initWithFrame:pickerRect];

        CGRect buttonRect = CGRectMake(self.view.bounds.size.width - 120.0, 0.0, 100.0, 40.0);
        UIButton *confirmButton = [[UIButton alloc] initWithFrame:buttonRect];
        [confirmButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [confirmButton addTarget:self action:@selector(confirmListSelection) forControlEvents:UIControlEventTouchUpInside];
        [confirmButton setTitle:@"Done" forState:UIControlStateNormal];

        [listSelectionPicker setBackgroundColor:[UIColor colorWithRed:240.0 / 255.0 green:240.0 / 255.0 blue:240.0 / 255.0 alpha:1.0]];
        [listSelectionPicker setDataSource:self];
        [listSelectionPicker setDelegate:self];


        [listSelectionPickerView addSubview:listSelectionPicker];
        [listSelectionPickerView addSubview:confirmButton];
    }
    else {
        [listSelectionPicker reloadAllComponents];
    }

    [self.view addSubview:listSelectionPickerView];

    [UIView animateWithDuration:0.1
                     animations:^{

                       listSelectionPickerView.frame = CGRectMake(0, self.view.bounds.size.height * (1.0 - 1.0 / 3.0) - 40.0, self.view.bounds.size.width, self.view.bounds.size.height / 3.0 + 40.0);

                     }];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [pickerViewItems count];
}


- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [[pickerViewItems objectAtIndex:row] objectForKey:@"text"];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{

    selectedRowInPicker = row;
}

- (void)confirmListSelection
{

    NSString *selectedItemID = [[pickerViewItems objectAtIndex:selectedRowInPicker] objectForKey:@"value"];

    [UIView animateWithDuration:0.2
        animations:^{

          listSelectionPickerView.frame = CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, self.view.bounds.size.height / 3.0 + 40.0);

        }
        completion:^(BOOL finished) {
          [listSelectionPickerView removeFromSuperview];
        }];

    [self sendListSelection:selectedItemID];
}


#pragma mark - DatePicker

- (void)presentDatePickerWithDefaultDate:(NSString *)defaultDate andMinDate:(NSString *)minDate andMaxDate:(NSString *)maxDate
{


    if (!datePickerView) {
        CGRect pickerRect = CGRectMake(0, 40.0, self.view.bounds.size.width, self.view.bounds.size.height / 3.0);


        datePicker = [[UIDatePicker alloc] initWithFrame:pickerRect];
        [datePicker setBackgroundColor:[UIColor colorWithRed:240.0 / 255.0 green:240.0 / 255.0 blue:240.0 / 255.0 alpha:1.0]];
        datePicker.datePickerMode = UIDatePickerModeDate;

        CGRect viewRect = CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, self.view.bounds.size.height / 3.0 + 40.0);
        //CGRect labelRect = CGRectMake(5.0, 0.0, self.view.bounds.size.width-105.0,40.0);
        CGRect buttonRect = CGRectMake(self.view.bounds.size.width - 100.0, 0.0, 80.0, 40.0);

        datePickerView = [[UIView alloc] initWithFrame:viewRect];

        [datePickerView setBackgroundColor:[UIColor colorWithRed:240.0 / 255.0 green:240.0 / 255.0 blue:240.0 / 255.0 alpha:1.0]];


        UIButton *confirmButton = [[UIButton alloc] initWithFrame:buttonRect];
        [confirmButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [confirmButton setTitle:@"Done" forState:UIControlStateNormal];

        [confirmButton addTarget:self action:@selector(handleSelectedDate) forControlEvents:UIControlEventTouchUpInside];

        [datePickerView addSubview:confirmButton];
        [datePickerView addSubview:datePicker];
    }


    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"YYYY-MM-dd"];
    [dateFormat setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];


    NSDate *defaultD = [dateFormat dateFromString:defaultDate];
    NSDate *minD = [dateFormat dateFromString:minDate];
    NSDate *maxD = [dateFormat dateFromString:maxDate];

    datePicker.minimumDate = minD;
    datePicker.maximumDate = maxD;
    datePicker.date = defaultD;

    [self.view addSubview:datePickerView];

    [UIView animateWithDuration:0.1
                     animations:^{

                       datePickerView.frame = CGRectMake(0, self.view.bounds.size.height * (1.0 - 1.0 / 3.0) - 40.0, self.view.bounds.size.width, self.view.bounds.size.height / 3.0 + 40.0);

                     }];
}

- (void)handleSelectedDate
{

    [UIView animateWithDuration:0.2
        animations:^{

          datePickerView.frame = CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, self.view.bounds.size.height / 3.0 + 40.0);

        }
        completion:^(BOOL finished) {
          [datePickerView removeFromSuperview];
        }];

    NSDate *selectedDate = datePicker.date;

    [self sendDate:selectedDate];
}

#pragma mark - Time Picker

- (void)presentTimePickerWithStep:(NSString *)step
{

    if (!timePickerView) {
        CGRect pickerRect = CGRectMake(0, 40.0, self.view.bounds.size.width, self.view.bounds.size.height / 3.0);


        timePicker = [[UIDatePicker alloc] initWithFrame:pickerRect];
        [timePicker setBackgroundColor:[UIColor colorWithRed:240.0 / 255.0 green:240.0 / 255.0 blue:240.0 / 255.0 alpha:1.0]];
        timePicker.datePickerMode = UIDatePickerModeTime;
        timePicker.minuteInterval = [step integerValue];

        CGRect viewRect = CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, self.view.bounds.size.height / 3.0 + 40.0);
        //CGRect labelRect = CGRectMake(5.0, 0.0, self.view.bounds.size.width-105.0,40.0);
        CGRect buttonRect = CGRectMake(self.view.bounds.size.width - 100.0, 0.0, 80.0, 40.0);

        timePickerView = [[UIView alloc] initWithFrame:viewRect];

        [timePickerView setBackgroundColor:[UIColor colorWithRed:240.0 / 255.0 green:240.0 / 255.0 blue:240.0 / 255.0 alpha:1.0]];


        UIButton *confirmButton = [[UIButton alloc] initWithFrame:buttonRect];
        [confirmButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [confirmButton setTitle:@"Done" forState:UIControlStateNormal];

        [confirmButton addTarget:self action:@selector(handleSelectedTime) forControlEvents:UIControlEventTouchUpInside];

        [timePickerView addSubview:confirmButton];
        [timePickerView addSubview:timePicker];
    }


    [self.view addSubview:timePickerView];

    [UIView animateWithDuration:0.1
                     animations:^{

                       timePickerView.frame = CGRectMake(0, self.view.bounds.size.height * (1.0 - 1.0 / 3.0) - 40.0, self.view.bounds.size.width, self.view.bounds.size.height / 3.0 + 40.0);

                     }];
}

- (void)handleSelectedTime
{

    [UIView animateWithDuration:0.2
        animations:^{

          timePickerView.frame = CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, self.view.bounds.size.height / 3.0 + 40.0);

        }
        completion:^(BOOL finished) {
          [timePickerView removeFromSuperview];
        }];

    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    [outputFormatter setDateFormat:@"HH:mm"];

    NSString *selectedTime = [outputFormatter stringFromDate:timePicker.date];


    [self sendTime:selectedTime];
}


#pragma mark - action sheet

- (void)selectImageMethod
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"选择方法", nil)
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"取消", nil)
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:NSLocalizedString(@"使用摄像头", nil), NSLocalizedString(@"从图片库中选择", nil), nil];

    [actionSheet setTag:111];
    [actionSheet showInView:self.view];
}

- (void)selectScanMethod
{

    if ([self isCameraAvailable]) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"选择扫描目标", nil)
                                                                 delegate:self
                                                        cancelButtonTitle:NSLocalizedString(@"取消", nil)
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:NSLocalizedString(@"二维码", nil), NSLocalizedString(@"条码", nil), nil];

        [actionSheet setTag:222];
        [actionSheet showInView:self.view];
    }
    else {
        // No camera

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"摄像头被禁止", nil)
                                                        message:NSLocalizedString(@"调用摄像头被禁止。请在设置中允许调用摄像头。", nil)
                                                       delegate:nil
                                              cancelButtonTitle:@"确定"
                                              otherButtonTitles:nil];

        [alert show];
    }
}


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == 111) {

        // The image selecion action sheet

        // the user clicked one of the OK/Cancel buttons
        if (buttonIndex == [actionSheet destructiveButtonIndex]) {
            //----- CLICKED OK -----
        }
        else if (buttonIndex == [actionSheet cancelButtonIndex]) {
            //----- CLICKED CANCEL -----
        }
        else if (buttonIndex == 0) {
            // Use camera
            reloadPage = NO;
            [self getImageWithCamera];
        }
        else if (buttonIndex == 1) {
            reloadPage = NO;
            [self getSavedImage];
        }
    }

    if (actionSheet.tag == 222) {

        // The scanner selecion action sheet

        // the user clicked one of the OK/Cancel buttons
        if (buttonIndex == [actionSheet destructiveButtonIndex]) {
            //----- CLICKED OK -----
        }
        else if (buttonIndex == [actionSheet cancelButtonIndex]) {
            //----- CLICKED CANCEL -----
        }
        else if (buttonIndex == 0) {
            // QR code
            scanOldBarcode = NO;
            [self scanBarCode];
        }
        else if (buttonIndex == 1) {
            // Old barcode
            scanOldBarcode = YES;
            [self scanBarCode];
        }
    }
}


#pragma mark - Bridge functions

- (void)scanBarCode
{


    if ([_delegate respondsToSelector:@selector(scanBarcode)]) {
        /*
             * If the Delegate implements the method 'scanBarcode' call
             * this method to delegate the barcode scanning to the Delegate object
             */

        reloadPage = NO;
        [_delegate scanBarcode];
    }
    else {
        /*
             * Otherwise do the barcode scanning "locally" in EMC View Controller
             */


        isScanBarCode = YES;
        reloadPage = NO;

        if (!reader) {

            [self createReader];
        }

        [self presentViewController:reader animated:YES completion:nil];
    }
}


/*
-(void)handleScannerResult:(NSString *)result {
 
    NSLog(@"SCANNER RESULT %@", result);
}
*/

- (void)doVoiceToText
{

    if ([self isMicrophoneAvailable]) {
        if ([_delegate respondsToSelector:@selector(doVoiceToText)]) {
            /*
             * If the Delegate implements the method 'startVoiceToText' call
             * this method to delegate the voice to text to the Delegate object
             */

            [_delegate doVoiceToText];
        }
        else {

            [self startListening:self];
        }
    }
    else {

        // No microphone

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"录音被禁止", nil)
                                                        message:NSLocalizedString(@"录音功能被禁止。请在设置中允许录音功能。", nil)
                                                       delegate:nil
                                              cancelButtonTitle:@"确定"
                                              otherButtonTitles:nil];

        [alert show];
    }
}

- (void)openURL:(NSString *)urlString withTarget:(NSString *)target useNavigation:(NSString *)navigation
{


    reloadPage = NO;

    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *req = [NSURLRequest requestWithURL:url];

    if ([target isEqualToString:@"external"]) {
        [[UIApplication sharedApplication] openURL:req.URL];
    }

    if (isOpeningWebView) {
        // Don't do anything to prevent strange crash
    }
    else {
        isOpeningWebView = YES;
        if ([target isEqualToString:@"internal"]) {
            if ([_delegate respondsToSelector:@selector(openPage:)]) {

                [_delegate openPage:urlString];
            }
            else {
                NSLog(@"Open internal");
                if (!intLinkVC) {
                    intLinkVC = [[LinkViewController alloc] initWithNibName:@"LinkViewController" bundle:nil];

                    intLinkVC.urlString = urlString;
                    intLinkVC.navigation = navigation;

                    [self presentViewController:intLinkVC
                                       animated:YES
                                     completion:^{
                                       isOpeningWebView = NO;
                                     }];
                }
                else {
                    intLinkVC.urlString = urlString;
                    intLinkVC.navigation = navigation;
                    [self presentViewController:intLinkVC
                                       animated:YES
                                     completion:^{
                                       isOpeningWebView = NO;
                                     }];
                }
            }
        }
    }
}


- (void)closeMe
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Communication back to web view via bridge

- (void)sendBarcode:(NSString *)barCode
{

    NSMutableDictionary *data = [NSMutableDictionary
        dictionaryWithObjectsAndKeys:barCode, @"barcode", nil];
    //NSLog(@"Sending %@", data);
    [bridge callHandler:(NSString *)@"scannedBarcode" data:(id)data];
}

/* Send image */

- (void)sendImage:(NSString *)image
{

    NSMutableDictionary *data = [NSMutableDictionary
        dictionaryWithObjectsAndKeys:image, @"image", nil];
    [bridge callHandler:(NSString *)@"image" data:(id)data];
}

- (void)sendText:(NSString *)text
{

    NSMutableDictionary *data = [NSMutableDictionary
        dictionaryWithObjectsAndKeys:text, @"text", nil];
    [bridge callHandler:(NSString *)@"voiceToText" data:(id)data];
}

- (void)sendDate:(NSDate *)date
{

    //NSLog(@"%@", date);

    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"YYYY-MM-dd"];
    [dateFormat setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];

    NSString *selectedDate = [dateFormat stringFromDate:date];

    NSMutableDictionary *data = [NSMutableDictionary
        dictionaryWithObjectsAndKeys:selectedDate, @"selectedDate", nil];
    //NSLog(@"Sending %@", data);
    [bridge callHandler:(NSString *)@"handleSelectedDate" data:(id)data];
}

- (void)sendTime:(NSString *)selectedTime
{

    NSMutableDictionary *data = [NSMutableDictionary
        dictionaryWithObjectsAndKeys:selectedTime, @"selectedTime", nil];
    [bridge callHandler:(NSString *)@"handleSelectedTime" data:(id)data];
}

- (void)sendListSelection:(NSString *)selectedValue
{

    NSMutableDictionary *data = [NSMutableDictionary
        dictionaryWithObjectsAndKeys:selectedValue, @"value", nil];
    [bridge callHandler:(NSString *)@"handleSelectedListValue" data:(id)data];
}


#pragma mark - Get image

/* GET Image */

- (void)getImageWithCamera
{

    if ([self isCameraAvailable]) {

        isScanBarCode = NO;

        if (!imagePicker) {

            imagePicker = [[UIImagePickerController alloc] init];
            imagePicker.delegate = self;
            imagePicker.allowsEditing = NO;
        }

        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;

        [self presentViewController:imagePicker animated:YES completion:NULL];
    }
    else {
        // No camera

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"摄像头被禁止", nil)
                                                        message:NSLocalizedString(@"调用摄像头被禁止。请在设置中允许调用摄像头。", nil)
                                                       delegate:nil
                                              cancelButtonTitle:@"确定"
                                              otherButtonTitles:nil];

        [alert show];
    }
}

- (void)getSavedImage
{

    isScanBarCode = NO;
    //NSLog(@"Getting saved image");

    if (!imagePicker) {
        //NSLog(@"No image picker");

        if (([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary] == NO)) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"无法使用", nil)
                                                            message:NSLocalizedString(@"图像库不可用", nil)
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"行", nil)
                                                  otherButtonTitles:nil];

            [alert show];
        }
        else {
            imagePicker = [[UIImagePickerController alloc] init];
            imagePicker.delegate = self;
            imagePicker.allowsEditing = NO;
        }
    }

    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:imagePicker animated:YES completion:NULL];
}


#pragma mark - Alert view delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{

    if (buttonIndex == 1) {
        // Try to re-load

        [self loadPage];
    }

    if (buttonIndex == 0) {

        /* Not used anymore
        if (alertView.tag == 200) {
            
            // Try to reload page
            [_myWebView stopLoading];
            [self loadPage];
            
        }
        */


        // Stop loading and close the view

        [_myWebView stopLoading];
        [webLoadTimeout invalidate];
        [self closeMe];
    }
}

#pragma mark - Zbar delegate


- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info
{

    //NSLog(@"Imagepicker finished %@", info);

    [self dismissViewControllerAnimated:YES
                             completion:^{

                               if (isScanBarCode) {
                                   isScanBarCode = NO;

                                   id<NSFastEnumeration> results = [info objectForKey:ZBarReaderControllerResults];

                                   ZBarSymbol *symbol = nil;
                                   for (symbol in results)

                                       break;
                                   NSString *barcode = symbol.data;

                                   [self sendBarcode:barcode];
                               }
                               else {


                                   UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];

                                   chosenImage = [self scaleAndRotateImage:chosenImage];

                                   NSData *imageData = [self compressImage:chosenImage];

                                   NSString *encodedImg = [imageData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];

                                   [self sendImage:encodedImg];
                               }


                             }];


    reader = nil;
}

/**
 *  Dismiss image picker view controller of scan bar
 *
 *  @param picker delegate object
 */
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{

    [picker dismissViewControllerAnimated:YES completion:nil];
}

/**
 *  Dismiss model view controller which presented for scanning
 */
- (void)closeScanner
{
    [self dismissViewControllerAnimated:YES completion:nil];

    reader = nil;
}


#pragma mark - Compress image


- (NSData *)compressImage:(UIImage *)image
{

    CGFloat minimumQuality = 0.0f;

    NSData *imageData = UIImageJPEGRepresentation(image, minimumQuality);
    return imageData;
}


#pragma mark - ZBAR reader

- (void)createReader
{

    reader = [ZBarReaderViewController new];

    reader.supportedOrientationsMask = ZBarOrientationMaskAll;
    reader.showsZBarControls = NO;
    reader.tracksSymbols = YES;
    reader.view.bounds = [[UIScreen mainScreen] bounds];
    ZBarImageScanner *scanner = reader.scanner;
    CGRect appFrame = [[UIScreen mainScreen] bounds];

    if (isScanBarCode) {
        // Using reader as barcode/qr-code scanner

        CGRect cutOut;
        float startY, startX;
        float endY, endX;
        UILabel *scanLabel;
        UIButton *closeButton;

        if (scanOldBarcode) {
            startX = (self.view.bounds.size.width / 2.0);
            endX = (self.view.bounds.size.width / 4.0);
            cutOut = CGRectMake(startX, 10.0, endX, self.view.bounds.size.height - 20.0);

            scanLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.bounds.size.width / 2.0 - (self.view.bounds.size.height - 100.0) / 2.0 - 40.0, self.view.bounds.size.height / 2.0 - 40.0, self.view.bounds.size.height - 100.0, 80.0)];
            [scanLabel setText:@"将二维码/条码放入框内，即可自动扫描"];
            [scanLabel setNumberOfLines:2];
            [scanLabel setLineBreakMode:NSLineBreakByWordWrapping];
            [scanLabel setTextAlignment:NSTextAlignmentCenter];
            [scanLabel setTextColor:[UIColor whiteColor]];

            scanLabel.transform = CGAffineTransformMakeRotation(M_PI_2);

            [scanner setSymbology:0 config:ZBAR_CFG_ENABLE to:0];
            [scanner setSymbology:0 config:ZBAR_CFG_X_DENSITY to:0];
            [scanner setSymbology:0 config:ZBAR_CFG_Y_DENSITY to:1];
            [scanner setSymbology:ZBAR_CODE128 config:ZBAR_CFG_ENABLE to:1];
            reader.scanCrop = CGRectMake(0, 0.35, 1, 0.45);

            closeButton = [[UIButton alloc]
                initWithFrame:CGRectMake(-10.0, self.view.bounds.size.height / 2.0 - 30.0, 120.0, 60.0)];
            [closeButton.layer setBorderColor:[UIColor colorWithRed:104.0 / 255.0 green:104.0 / 255.0 blue:104.0 / 255.0 alpha:1.0].CGColor];
            [closeButton.layer setBackgroundColor:[UIColor colorWithRed:204.0 / 255.0 green:204.0 / 255.0 blue:204.0 / 255.0 alpha:1.0].CGColor];
            [closeButton.layer setCornerRadius:20.0];
            [closeButton.layer setBorderWidth:1.0];

            [closeButton setTitle:NSLocalizedString(@"返回", nil) //關閉掃描儀", nil)
                         forState:UIControlStateNormal];

            //[closeButton addTarget:reader  action:@selector(cancel)                   forControlEvents:UIControlEventTouchUpInside];
            [closeButton addTarget:self action:@selector(closeScanner) forControlEvents:UIControlEventTouchUpInside];
            [closeButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            [closeButton.titleLabel setFont:[UIFont boldSystemFontOfSize:20.0]];

            closeButton.transform = CGAffineTransformMakeRotation(M_PI_2);
        }
        else {
            startY = (self.view.bounds.size.height / 2) * (1 - 0.7);
            endY = (self.view.bounds.size.height / 2) * (1 - 0.7) + self.view.bounds.size.height / 2;
            cutOut = CGRectMake(10.0, startY, self.view.bounds.size.width - 20.0, self.view.bounds.size.height / 2.0);
            scanLabel = [[UILabel alloc] initWithFrame:CGRectMake(30.0, endY, self.view.bounds.size.width - 60.0, 80.0)];

            scanLabel.text = @"将二维码/条码放入框内，即可自动扫描";

            [scanLabel setNumberOfLines:2];
            [scanLabel setLineBreakMode:NSLineBreakByWordWrapping];
            [scanLabel setTextAlignment:NSTextAlignmentCenter];

            [scanLabel setTextColor:[UIColor whiteColor]];

            [scanner setSymbology:0 config:ZBAR_CFG_ENABLE to:0];
            [scanner setSymbology:ZBAR_QRCODE config:ZBAR_CFG_ENABLE to:1];

            closeButton = [[UIButton alloc]
                initWithFrame:CGRectMake(70.0, endY + 80.0, self.view.bounds.size.width - 140.0, 60)];
            [closeButton.layer setBorderColor:[UIColor colorWithRed:104.0 / 255.0 green:104.0 / 255.0 blue:104.0 / 255.0 alpha:1.0].CGColor];
            [closeButton.layer setBackgroundColor:[UIColor colorWithRed:204.0 / 255.0 green:204.0 / 255.0 blue:204.0 / 255.0 alpha:1.0].CGColor];
            [closeButton.layer setCornerRadius:20.0];
            [closeButton.layer setBorderWidth:1.0];

            [closeButton setTitle:NSLocalizedString(@"返回", nil) //關閉掃描儀", nil)
                         forState:UIControlStateNormal];

            //[closeButton addTarget:reader  action:@selector(cancel)                  forControlEvents:UIControlEventTouchUpInside];

            [closeButton addTarget:self action:@selector(closeScanner) forControlEvents:UIControlEventTouchUpInside];

            [closeButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            [closeButton.titleLabel setFont:[UIFont boldSystemFontOfSize:20.0]];
        }


        NSArray *transparentRects = [[NSArray alloc] initWithObjects:[NSValue valueWithCGRect:cutOut], nil];

        ScannerOverlayView *overlayView = [[ScannerOverlayView alloc] initWithFrame:appFrame backgroundColor:[UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.8] andTransparentRects:transparentRects];

        overlayView.scanOldBarcode = scanOldBarcode;


        [overlayView addSubview:scanLabel];
        [overlayView addSubview:closeButton];

        if (_animateScannerLine) {
            [overlayView addScannerLine];
            [overlayView performSelector:@selector(animateScannerLine) withObject:nil afterDelay:0.1];
        }

        reader.cameraOverlayView = overlayView;
    }
    else {

        /*
        // Using reader for taking picture
        
        
        UIView *overlayView = [[UIView alloc] initWithFrame:appFrame];
        UIButton *closeButton = [[UIButton alloc]
                                 initWithFrame:CGRectMake(self.view.bounds.size.width - 100.0, self.view.bounds.size.height -100.0, 80.0, 80.0)];
        [closeButton.layer setBorderColor:[UIColor colorWithRed:104.0/255.0 green:104.0/255.0 blue:104.0/255.0 alpha:1.0].CGColor];
        [closeButton.layer setBackgroundColor:[UIColor colorWithRed:204.0/255.0 green:204.0/255.0 blue:204.0/255.0 alpha:1.0].CGColor];
        [closeButton.layer setCornerRadius:40.0];
        [closeButton.layer setBorderWidth:1.0];
        
        [closeButton setTitle:NSLocalizedString(@"返回", nil) //關閉掃描儀", nil)
                     forState:UIControlStateNormal];
        
        [closeButton addTarget:reader  action:@selector(cancel)
              forControlEvents:UIControlEventTouchUpInside];
        [closeButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        [closeButton.titleLabel setFont:[UIFont boldSystemFontOfSize:20.0]];
        
        UIButton *captureButton = [[UIButton alloc]
                                   initWithFrame:CGRectMake(20, self.view.bounds.size.height - 95, 80,                                                      80)];
        [captureButton.layer setBorderColor:[UIColor colorWithRed:224.0/255.0 green:224.0/255.0 blue:224.0/255.0 alpha:1.0].CGColor];
        [captureButton.layer setBackgroundColor:[UIColor colorWithRed:117.0/255.0 green:202.0/255.0 blue:255.0/255.0 alpha:1.0].CGColor];
        [captureButton.layer setCornerRadius:40.0];
        [captureButton.layer setBorderWidth:2.0];
        
        [captureButton setTitle:NSLocalizedString(@"拍照", nil)
                       forState:UIControlStateNormal];
        
        [captureButton addTarget:reader action:@selector(takePicture)
                forControlEvents:UIControlEventTouchUpInside];
        
        [captureButton.titleLabel setTextColor:[UIColor whiteColor]];
        [captureButton.titleLabel setFont:[UIFont boldSystemFontOfSize:16.0]];
        
        [overlayView addSubview:closeButton];
        [overlayView addSubview:captureButton];
        
        reader.cameraOverlayView = overlayView;
       */
    }

    [scanner setSymbology:0 config:ZBAR_CFG_ENABLE to:0];
    //[scanner setSymbology:0 config:ZBAR_CFG_X_DENSITY to:0];
    //[scanner setSymbology:0 config:ZBAR_CFG_Y_DENSITY to:1];
    [scanner setSymbology:ZBAR_CODE128 config:ZBAR_CFG_ENABLE to:1];
    [scanner setSymbology:ZBAR_QRCODE config:ZBAR_CFG_ENABLE to:1];

    //reader.scanCrop = CGRectMake(0, 0.3, 1, 0.4);


    reader.readerDelegate = self;
}

#pragma mark IFlyRecognizerViewDelegate

- (void)startListening:(id)sender
{


    [_iflyRecognizerView setParameter:@"iat" forKey:[IFlySpeechConstant IFLY_DOMAIN]];

    //设置结果数据格式，可设置为json，xml，plain，默认为json。
    [_iflyRecognizerView setParameter:@"plain" forKey:[IFlySpeechConstant RESULT_TYPE]];

    [_iflyRecognizerView setParameter:VAD_BOS_VALUE forKey:[IFlySpeechConstant VAD_BOS]];
    [_iflyRecognizerView setParameter:VAD_EOS_VALUE forKey:[IFlySpeechConstant VAD_EOS]];

    [_iflyRecognizerView start];

    //NSLog(@"start listening...");
}


/** 识别结果回调方法
 @param resultArray - Results list
 @param isLast YES 表示最后一个 (Represents the last one)，NO表示后面还有结果 (indicates there are results)
 */
- (void)onResult:(NSArray *)resultArray isLast:(BOOL)isLast
{
    NSMutableString *result = [[NSMutableString alloc] init];
    NSDictionary *dic = [resultArray objectAtIndex:0];

    for (NSString *key in dic) {
        [result appendFormat:@"%@", key];
    }

    // Send the result back to EMC
    [self sendText:result];
}

/** 识别结束回调方法
 @param error 识别错误
 */
- (void)onError:(IFlySpeechError *)error
{
    NSLog(@"errorCode:%d", [error errorCode]);
}


- (BOOL)networkAvailable
{
    //edit by gutao 使用Reachability会产生link error,用AFNetworkReachabilityManager替换
    return [[AFNetworkReachabilityManager sharedManager] isReachable];
}

#pragma mark

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)dealloc
{
    NSLog(@"viewcontroller is being deallocated");
}

- (NSString *)encodeParameter:(NSString *)parameter
{

    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                 (CFStringRef)parameter,
                                                                                 NULL,
                                                                                 (CFStringRef) @"!*'\"();:@&=+$,/?%#[]% ",
                                                                                 kCFStringEncodingUTF8));
}

- (UIImage *)scaleAndRotateImage:(UIImage *)image
{
    int kMaxResolution = 3000; // Or whatever

    CGImageRef imgRef = image.CGImage;

    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);

    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    if (width > kMaxResolution || height > kMaxResolution) {
        CGFloat ratio = width / height;
        if (ratio > 1) {
            bounds.size.width = kMaxResolution;
            bounds.size.height = bounds.size.width / ratio;
        }
        else {
            bounds.size.height = kMaxResolution;
            bounds.size.width = bounds.size.height * ratio;
        }
    }

    CGFloat scaleRatio = bounds.size.width / width;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGFloat boundHeight;
    UIImageOrientation orient = image.imageOrientation;
    switch (orient) {
        case UIImageOrientationUp: //EXIF = 1

            transform = CGAffineTransformIdentity;
            break;

        case UIImageOrientationUpMirrored: //EXIF = 2

            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;

        case UIImageOrientationDown: //EXIF = 3

            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;

        case UIImageOrientationDownMirrored: //EXIF = 4

            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;

        case UIImageOrientationLeftMirrored: //EXIF = 5

            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;

        case UIImageOrientationLeft: //EXIF = 6

            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;

        case UIImageOrientationRightMirrored: //EXIF = 7

            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;

        case UIImageOrientationRight: //EXIF = 8

            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;

        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
    }

    UIGraphicsBeginImageContext(bounds.size);

    CGContextRef context = UIGraphicsGetCurrentContext();

    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }

    CGContextConcatCTM(context, transform);

    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageCopy;
}

@end
