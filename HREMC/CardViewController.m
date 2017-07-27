//
//  CardViewController.m
//  EMC
//
//  Created by 王帅 on 16/7/15.
//  Copyright © 2016年 王帅. All rights reserved.
//

#import "CardViewController.h"

#import "QRViewController.h"
//#import "Reachability.h"
#import <CoreLocation/CoreLocation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AssetsLibrary/ALAssetsGroup.h>
#import <AssetsLibrary/ALAssetRepresentation.h>

#import <AFNetworking/AFNetworking.h>

#import "NSData+CommonCrypto.h"


#ifdef DEBUG
#define NSLog(...) NSLog(__VA_ARGS__)
#define debugMethod() NSLog(@"EMC_%s"__func__)
#else
#define NSLog(...)
#define debugMethod()
#endif


//选择相机还是相册
typedef enum : NSUInteger {
    SelectedByCamera,
    SelectedByPhoto,
} ImageSelectedType;


NSString * const ceshiUrl = @"http://123.103.113.64/";
NSString * const zhengshiUrl = @"http://emc-web.haier.net:9000/";


@interface CardViewController ()<UIWebViewDelegate,UIActionSheetDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,CLLocationManagerDelegate,QRcodeDelegate,NSURLSessionDelegate>
{
    NSString *_uploadImageMethod;
    NSString *_methodName;
    
    CLLocationManager *_locationManager;
    ImageSelectedType chooseImageType; //选择打开相机还是相册
}
@property (nonatomic, strong) UIWebView *emcWebView;
@property (nonatomic, strong) NSMutableString *recordsResult;
@property (nonatomic, copy) NSString *HMAC_sha1_string;

@end

@implementation CardViewController

- (void)initRecognizer {
    if (_iflyRecognizerView == nil) {
        //UI显示剧中
        _iflyRecognizerView= [[IFlyRecognizerView alloc] initWithCenter:self.view.center];
        
        [_iflyRecognizerView setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
        
        //设置听写模式
        [_iflyRecognizerView setParameter:@"iat" forKey:[IFlySpeechConstant IFLY_DOMAIN]];
        
    }
    _iflyRecognizerView.delegate = self;
}

- (void)checkMIC {
    
}

//判断是否允许使用麦克风7.0新增的方法requestRecordPermission
-(BOOL)canRecord
{
    __block BOOL bCanRecord = YES;
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0"] != NSOrderedAscending)
    {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
            [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
                if (granted) {
                    bCanRecord = YES;
                }
                else {
                    bCanRecord = NO;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[[UIAlertView alloc] initWithTitle:@"录音未启用"
                                                    message:@"录音功能未启用，请在设置中打开麦克风"
                                                   delegate:nil
                                          cancelButtonTitle:@"关闭"
                                          otherButtonTitles:nil] show];
                    });
                }
            }];
        }
    }
    
    return bCanRecord;
}

- (void)startBtnHandler {
    if ([self canRecord]) {
        if(_iflyRecognizerView == nil)
        {
            [self initRecognizer ];
        }
        //设置音频来源为麦克风
        [_iflyRecognizerView setParameter:IFLY_AUDIO_SOURCE_MIC forKey:@"audio_source"];
        
        //设置听写结果格式为json
        [_iflyRecognizerView setParameter:@"plain" forKey:[IFlySpeechConstant RESULT_TYPE]];
        
        //保存录音文件，保存在sdk工作路径中，如未设置工作路径，则默认保存在library/cache下
        [_iflyRecognizerView setParameter:@"asr.pcm" forKey:[IFlySpeechConstant ASR_AUDIO_PATH]];
        
        [_iflyRecognizerView start];
    }
}

- (void)onResult: (NSArray *)resultArray isLast:(BOOL) isLast
{
    NSLog(@"EMC_%@",resultArray);
    NSDictionary *dic = [resultArray objectAtIndex:0];
    NSLog(@"EMC_%@",resultArray);
    for (NSString *key in dic) {
        [self.recordsResult appendFormat:@"%@",key];
    }
    NSLog(@"EMC_result = %@",self.recordsResult);

}
/*识别会话错误返回代理
 @ param  error 错误码
 */
- (void)onError: (IFlySpeechError *) error
{
    NSLog(@"EMC_%s",__func__);
    NSLog(@"EMC_%@",self.recordsResult);
    //errorcode=0表示正常，非0表示错误。
    NSLog(@"EMC_%d",error.errorCode);
    
    if (error.errorCode == 0) {
        //上传录音结果：showRecordeResult
        [self uploadRecordResult];
    } else {
        
    }
    
    [self.recordsResult setString:@""];
}


#pragma mark - 上传录音结果
- (void)uploadRecordResult {
    
    NSString *showRecord = [NSString stringWithFormat:@"%@('%@')", _methodName, self.recordsResult];
//    [Hint showAlertIn:self.view WithMessage:showRecord];
    [self.emcWebView stringByEvaluatingJavaScriptFromString:showRecord];
}


#pragma mark -
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationController.navigationBarHidden = YES;
    
    self.recordsResult = [[NSMutableString alloc]init];
    
//    [self initWebView];
    [self getCode];
    
    [self.view addSubview:self.emcWebView];
    
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 20)];
    view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:view];
    
    [self initializeLocationService];
    
    NSString *initString = [[NSString alloc] initWithFormat:@"appid=%@",@"551142c5"];
    [IFlySpeechUtility createUtility:initString];

    /*
    self.Reach = [Network reachabilityForInternetConnection];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    [self.Reach startNotifier];
    */
    
    [self afnCheckNetwork];
    
}

//得到用户中心需要的code
- (void)getCode {
    
    NSURL *url = [NSURL URLWithString:@"http://account.haier.com/oauth/authorize?client_id=aftersale&response_type=code&redirect_uri=http://123.103.113.64"];
    NSMutableURLRequest *quest = [NSMutableURLRequest requestWithURL:url];
    quest.HTTPMethod = @"GET";
    
    //ee2a2388-2042-4123-86ed-f961b09872c9
    NSString *value = [NSString stringWithFormat:@"Bearer %@",self.sdToken];
    [quest setValue:value forHTTPHeaderField:@"Authorization"];//请求header
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue currentQueue]];
    
    //拦截重定向
    NSURLSessionDataTask *task = [urlSession dataTaskWithRequest:quest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *)response;
        
        NSLog(@"%ld",urlResponse.statusCode);
        NSLog(@"%@",urlResponse.allHeaderFields);
        
        NSDictionary *dic = urlResponse.allHeaderFields;
        NSLog(@"%@",dic[@"Location"]);
        NSString *code = dic[@"Location"];
        if ([code rangeOfString:@"="].location == NSNotFound) {
            NSLog(@"code 不存在 =");
        } else {
            NSRange range = [code rangeOfString:@"="];
            code = [code substringFromIndex:range.location + 1];
            NSLog(@"%@",code);
            
            //post请求获取用户中心的accessToken
            NSString *text = @"aftersale:af7sktsA1g1u_s";
            NSData *data2 = [text dataUsingEncoding:NSUTF8StringEncoding];
            NSString *base64String = [data2 base64EncodedStringWithOptions:0];
            
            //
            AFHTTPSessionManager *manager =[AFHTTPSessionManager manager];
            manager.responseSerializer = [AFHTTPResponseSerializer serializer];
            manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html",@"text/html",@"text/plain",@"application/x-www-form-urlencoded", nil];
            NSString *value = [NSString stringWithFormat:@"Basic %@",base64String];
            [manager.requestSerializer setValue:value forHTTPHeaderField:@"Authorization"];
            
            NSString *url = [NSString stringWithFormat:@"http://account.haier.com/oauth/token?grant_type=authorization_code&code=%@&redirect_uri=http://123.103.113.64",code];
            
            [manager POST:url parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
                NSString *result = [[NSString alloc]initWithData:responseObject encoding:NSUTF8StringEncoding];
                NSLog(@"%@",responseObject);
                
                NSData *jsonData = [result dataUsingEncoding:NSUTF8StringEncoding];
                NSError *err;
                NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
                NSLog(@"%@",dic);
                
                self.accessToken = [dic objectForKey:@"access_token"];
                [self getInfo];
                
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                NSLog(@"%@",error);
            }];
        }
        
    }];
    
    [task resume];
    
}

- (void)getInfo {
    
    //get请求获取用户中心的用户信息
    //
    AFHTTPSessionManager *manager =[AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html",@"text/html",@"text/plain",@"application/x-www-form-urlencoded", nil];
    NSString *value = [NSString stringWithFormat:@"Bearer %@",self.accessToken];
    [manager.requestSerializer setValue:value forHTTPHeaderField:@"Authorization"];
    
    NSString *url = [NSString stringWithFormat:@"http://account-api.haier.net/userinfo"];
    
    [manager GET:url parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        NSString *result = [[NSString alloc]initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSLog(@"%@",responseObject);
        
        NSData *jsonData = [result dataUsingEncoding:NSUTF8StringEncoding];
        NSError *err;
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
        NSLog(@"%@",dic);
        
        self.phoneNumber = [dic objectForKey:@"phone_number"];
        self.userName = [dic objectForKey:@"username"];
        
        NSString *data = [NSString stringWithFormat:@"sdToken=%@&coSessionId=%@&appName=%@&phoneNumber=%@&username=%@",self.accessToken,self.coSessionId,self.phoneNumber,self.phoneNumber,self.userName];
        [self Base_HmacSha1:@"Uplus!>0&EMC" data:data];
        
        [self initWebView];
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"%@",error);
    }];
    
}

//HmacSHA1加密
- (NSString *)Base_HmacSha1:(NSString *)key data:(NSString *)data{
    const char *cKey  = [key cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [data cStringUsingEncoding:NSASCIIStringEncoding];
    //Sha256:
    // unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    //CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    //sha1
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC
                                          length:sizeof(cHMAC)];
    
    NSString *hash = [HMAC base64EncodedStringWithOptions:0];//将加密结果进行一次BASE64编码。
    
    self.HMAC_sha1_string = hash;
    
    return hash;
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest * __nullable))completionHandler{
    completionHandler(nil);
}

- (void)initWebView {
//    self.emcWebView = [[UIWebView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 20)];
    self.emcWebView = [[UIWebView alloc]initWithFrame:self.view.frame];
    self.emcWebView.scrollView.bounces = NO;
    self.emcWebView.delegate = self;
    [self.view addSubview:self.emcWebView];
    
    NSString *urlString;
    if (self.isOffical) {
//        urlString = [NSString stringWithFormat:@"%@?sdToken=%@&coSessionId=%@&appName=%@&phoneNumber=%@&username=%@&signature=%@&entryPoint=%@", zhengshiUrl, self.sdToken, self.coSessionId, self.appName, self.phoneNumber, self.userName, self.signature, self.entryPoint];
        urlString = [NSString stringWithFormat:@"%@?sdToken=%@&coSessionId=%@&appName=%@&phoneNumber=%@&username=%@&signature=%@&entryPoint=%@", zhengshiUrl, self.accessToken, self.coSessionId, self.phoneNumber, self.phoneNumber, self.userName, self.HMAC_sha1_string, self.entryPoint];
    } else {
        urlString = [NSString stringWithFormat:@"%@?sdToken=%@&coSessionId=%@&appName=%@&phoneNumber=%@&username=%@&signature=%@&entryPoint=%@", ceshiUrl, self.accessToken, self.coSessionId, self.appName, self.phoneNumber, self.userName, self.signature, self.entryPoint];
    }
    NSLog(@"EMC_URL = %@",[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]);
    NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.emcWebView loadRequest:request];
    
}


- (void)afnCheckNetwork {
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusUnknown:
            {
                NSLog(@"EMC_afn - 未知");
            }
                break;
            case AFNetworkReachabilityStatusNotReachable:
            {
                NSLog(@"EMC_afn - 无网络");
                NSString *jsMethod = [NSString stringWithFormat:@"noNetwork()"];
                [self.emcWebView stringByEvaluatingJavaScriptFromString:jsMethod];
            }
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
            {
                NSLog(@"EMC_afn - 3G/4G");
            }
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
            {
                NSLog(@"EMC_afn - WIFi");
            }
                break;
                
            default:
                break;
        }
    }];
    [manager startMonitoring];
}

- (void)initializeLocationService {
    // 初始化定位管理器
    _locationManager = [[CLLocationManager alloc] init];
    // 设置代理
    _locationManager.delegate = self;
    // 设置定位精确度到米
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    // 设置过滤器为无
    _locationManager.distanceFilter = kCLDistanceFilterNone;
    
    // 开始定位
    UIDevice *device = [UIDevice currentDevice];
    float sysVersion = [device.systemVersion floatValue];
    if (sysVersion >= 8.0) {
//        [_locationManager requestAlwaysAuthorization];//这句话ios8以上版本使用。
        [_locationManager requestWhenInUseAuthorization];
    } else {
        [_locationManager startUpdatingLocation];
    }
    
}


- (void)dealloc {
//    [self.Reach stopNotifier];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - 网路监测
- (void) reachabilityChanged:(NSNotification *)note
{
    Network* curReach = [note object];
    NSParameterAssert([curReach isKindOfClass:[Network class]]);
    [self updateInterfaceWithReachability:curReach];
}

- (void)updateInterfaceWithReachability:(Network *)reachability
{
    NetworkStatus netStatus = [reachability currentReachabilityStatus];
    switch (netStatus) {
        case NotReachable:
        {
            NSLog(@"====当前网络状态不可达=======http://www.cnblogs.com/xiaofeixiang");
            NSString *jsMethod = [NSString stringWithFormat:@"noNetwork()"];
            [self.emcWebView stringByEvaluatingJavaScriptFromString:jsMethod];
        }
            break;
        case ReachableViaWiFi:
            NSLog(@"====当前网络状态为Wifi=======博客园-Fly_Elephant");
            break;
        case ReachableViaWWAN:
            NSLog(@"====当前网络状态为3G=======keso");
            break;
    }
}
*/
 
#pragma mark - UIWebView Delegate
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    NSString *requestString = [[[request URL] absoluteString] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSLog(@"EMC_%@",requestString);
    
    NSArray *array = [requestString componentsSeparatedByString:@"+"];
    
    
    if ([[array firstObject] isEqual:@"ios:getQRCode"]) {
        //扫描二维码
        _methodName = [array lastObject];
        QRViewController *qrVC = [[QRViewController alloc]init];
        qrVC.delegate = self;
        [self presentViewController:qrVC animated:YES completion:NULL];
        return NO;
    } else if ([[array firstObject] isEqual:@"ios:getPhoto"]) {
        //打开相机or相册
        _methodName = [array lastObject];
        _uploadImageMethod = [array lastObject];
        [self openCamera];
        return NO;
    } else if ([[array firstObject] isEqual:@"ios:getRecord"]) {
        //录音
        _methodName = [array lastObject];
        [self startBtnHandler];
        return NO;
    } else if ([[array firstObject] isEqual:@"ios:getAddress"]) {
        //调地址
        _methodName = [array lastObject];
        [_locationManager startUpdatingLocation];
        return NO;
    } else if ([[array firstObject] isEqual:@"ios:getNetState"]) {
        //网络状态
        
        return NO;
    } else if ([[array firstObject] isEqual:@"ios:makePhone"]) {
        //打电话
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"telprompt://%@", [array lastObject]]];
        [[UIApplication sharedApplication] openURL:url];
        return NO;
    } else if ([[array firstObject] isEqual:@"ios:getCloseAll"]) {
        //保修卡首页关闭,回到主U+
        [self dismissViewControllerAnimated:YES completion:NULL];
        return NO;
    }
    
    return YES;
    
}


#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    // 获取当前所在的城市名
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    //根据经纬度反向地理编译出地址信息
    [geocoder reverseGeocodeLocation:newLocation completionHandler:^(NSArray *array, NSError *error){
        if (array.count > 0){
            CLPlacemark *placemark = [array objectAtIndex:0];
//            NSLog(@"EMC_%@",placemark.name);
//            NSLog(@"EMC_%@",placemark.thoroughfare);
//            NSLog(@"EMC_%@",placemark.locality);
//            NSLog(@"EMC_%@",placemark.subLocality);
//            NSLog(@"EMC_%@",placemark.administrativeArea);
//            NSLog(@"EMC_%@",placemark.subAdministrativeArea);
//            NSLog(@"EMC_%@",placemark.postalCode);
//            NSLog(@"EMC_%@",placemark.ISOcountryCode);
//            NSLog(@"EMC_%@",placemark.inlandWater);
//            NSLog(@"EMC_%@",placemark.ocean);
//            NSLog(@"EMC_%@",placemark.country);
//            
//            NSLog(@"EMC_%@",placemark.addressDictionary);

            
            NSString *locationString = [NSString stringWithFormat:@"%@ %@ %@",placemark.administrativeArea, placemark.locality, placemark.subLocality];
            NSString *uploadAddress = [NSString stringWithFormat:@"%@('%@')", _methodName, locationString];
//            [Hint showAlertIn:self.view WithMessage:uploadAddress];
            [self.emcWebView stringByEvaluatingJavaScriptFromString:uploadAddress];

            //获取城市
            NSString *city = placemark.locality;
            if (!city) {
                //四大直辖市的城市信息无法通过locality获得，只能通过获取省份的方法来获得（如果city为空，则可知为直辖市）
                city = placemark.administrativeArea;
            }
            NSLog(@"city = %@", city);
//            _cityLable.text = city;
//            [_cityButton setTitle:city forState:UIControlStateNormal];
        }
        else if (error == nil && [array count] == 0)
        {
            NSLog(@"EMC_No results were returned.");
        }
        else if (error != nil)
        {
            NSLog(@"EMC_An error occurred = %@", error);
        }
    }];
    //系统会一直更新数据，直到选择停止更新，因为我们只需要获得一次经纬度即可，所以获取之后就停止更新
    [manager stopUpdatingLocation];
}


#pragma mark - 打开相机、相册
- (void)openCamera {
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"拍照", @"从相册选取", nil];
    [actionSheet showInView:self.view];
}


#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSLog(@"EMC_%ld",(long)buttonIndex);
    switch (buttonIndex) {
        case 0:
        {
            NSLog(@"EMC_拍照");
            UIImagePickerController *controller = [[UIImagePickerController alloc] init];
            controller.sourceType = UIImagePickerControllerSourceTypeCamera;
//            NSMutableArray *mediaTypes = [[NSMutableArray alloc] init];
//            [mediaTypes addObject:(__bridge NSString *)kUTTypeImage];
//            controller.mediaTypes = mediaTypes;
            controller.delegate = self;
            [self presentViewController:controller
                               animated:YES
                             completion:^(void){
                                 NSLog(@"EMC_Picker View Controller is presented");
                             }];
            
        }
            break;
        case 1:
        {
            NSLog(@"EMC_从相册选择");
            UIImagePickerController *controller = [[UIImagePickerController alloc] init];
            controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
//            NSMutableArray *mediaTypes = [[NSMutableArray alloc] init];
//            [mediaTypes addObject:(__bridge NSString *)kUTTypeImage];
//            controller.mediaTypes = mediaTypes;
            controller.delegate = self;
            [self presentViewController:controller
                               animated:YES
                             completion:^(void){
                                 NSLog(@"EMC_Picker View Controller is presented");
                             }];

        }
            break;
            
        default:
            break;
    }
    
}


#pragma mark - UIImagePickerController Delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSLog(@"EMC_%@",info);
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    NSData *imageData = UIImageJPEGRepresentation(image, 0.1);
    NSString *base64Str = [imageData base64EncodedStringWithOptions:0];
    
    if (image !=nil) {
        
        //获取图片的名字
        NSURL *imageURL = [info valueForKey:UIImagePickerControllerReferenceURL];
        NSLog(@"EMC_%@", imageURL);
        __block NSString *fileName;
        ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset) {
            ALAssetRepresentation *representation = [myasset defaultRepresentation];
            NSLog(@"EMC_%@",representation.filename);
            fileName = [NSString stringWithFormat:@"%@",representation.filename];
            NSArray *array = [fileName componentsSeparatedByString:@"."];
            NSString *showRecord = [NSString stringWithFormat:@"%@('%@','%@','%@')", _methodName, base64Str, [array firstObject], [array lastObject]];
            [self.emcWebView stringByEvaluatingJavaScriptFromString:showRecord];
        };
        
        ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
        [assetslibrary assetForURL:imageURL
                       resultBlock:resultblock
                      failureBlock:nil];
    }
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark - QRcode Delegate
- (void)scanCompleteWithResult:(NSString *)resultValue {
    NSString *jsMethod = [NSString stringWithFormat:@"%@('%@')", _methodName, resultValue];
    [self.emcWebView stringByEvaluatingJavaScriptFromString:jsMethod];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
