//
//  FNKPermission.m
//  FNKPermission
//
//  Created by LWW on 2019/8/8.
//  Copyright © 2019 FNK. All rights reserved.
//

#import "FNKPermission.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import <EventKit/EventKit.h>
#import <AddressBook/AddressBook.h>
#import <Contacts/Contacts.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <HealthKit/HealthKit.h>
#import <MediaPlayer/MediaPlayer.h>

#define IOS_10_OR_LATER    ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0)

@interface FNKPermission()<CLLocationManagerDelegate,CBCentralManagerDelegate>

@property(nonatomic,copy)FNKPermissionCallBack block;

@property (strong, nonatomic) CLLocationManager *locationManager; //定位

@property (strong, nonatomic) CBCentralManager *centralManager;    //蓝牙

@property (nonatomic, strong) HKHealthStore *healthStore;          //健康

@end
@implementation FNKPermission
static FNKPermission *_instance;

/*
 * 单例
 */
+(instancetype)shareInstance{
    static dispatch_once_t onceToken ;
    dispatch_once(&onceToken, ^{
        _instance = [[super allocWithZone:NULL] init];
    }) ;
    return _instance;
}

+(id) allocWithZone:(struct _NSZone *)zone
{
    return [FNKPermission shareInstance] ;
}

-(id) copyWithZone:(struct _NSZone *)zone
{
    return [FNKPermission shareInstance] ;
}

/*
 * 获取权限
 * @param  type       类型
 * @param  block      回调
 */
- (void)permissonType:(PermissionType)type withHandle:(FNKPermissionCallBack)block{
    self.block = block;
    
    switch (type) {
        case PermissionTypePhoto:
        {
            [self permissionTypePhotoAction];
        }
            break;
        case PermissionTypeCamera:
        {
            [self permissionTypeCameraAction];
        }
            break;
        case PermissionTypeMic:
        {
            [self permissionTypeMicAction];
        }
            break;
        case PermissionTypeLocationWhen:
        {
            [self permissionTypeLocationWhenAction];
        }
            break;
        case PermissionTypeCalendar:
        {
            [self permissionTypeCalendarAction];
        }
            break;
        case PermissionTypeContacts:
        {
            [self permissionTypeContactsAction];
        }
            break;
        case PermissionTypeBlue:
        {
            [self permissionTypeBlueAction];
        }
            break;
        case PermissionTypeRemaine:
        {
            [self permissionTypeRemainerAction];
        }
            break;
        case PermissionTypeHealth:
        {
            [self permissionTypeHealthAction];
        }
            break;
        case PermissionTypeMediaLibrary:
        {
            [self permissionTypeMediaLibraryAction];
        }
            break;
        default:
            break;
    }
}

/*
 *相册权限
 */
- (void)permissionTypePhotoAction{
    PHAuthorizationStatus photoStatus = [PHPhotoLibrary authorizationStatus];
    __block FNKPermission *weakSelf = self;
    if (photoStatus == PHAuthorizationStatusNotDetermined) {
        
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (status == PHAuthorizationStatusAuthorized) {
                if ( weakSelf.block) {
                    weakSelf.block(YES, @(photoStatus));
                }
            } else {
                if ( weakSelf.block) {
                    weakSelf.block(NO, @(photoStatus));
                }
            }
        }];
    } else if (photoStatus == PHAuthorizationStatusAuthorized) {
        if ( self.block) {
            self.block(YES, @(photoStatus));
        }
    } else if(photoStatus == PHAuthorizationStatusRestricted||photoStatus == PHAuthorizationStatusDenied){
        [self pushSetting:@"相册权限"];
        
    }else{
        if ( self.block) {
            self.block(NO, @(photoStatus));
        }
    }
}

/*
 *相机权限
 */
- (void)permissionTypeCameraAction{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    __block FNKPermission *weakSelf = self;
    if(authStatus == AVAuthorizationStatusNotDetermined){
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if ( weakSelf.block) {
                weakSelf.block(granted, @(authStatus));
            }
        }];
    }  else if (authStatus == AVAuthorizationStatusAuthorized) {
        if ( self.block) {
            self.block(YES, @(authStatus));
        }
    } else if(authStatus == AVAuthorizationStatusRestricted||authStatus == AVAuthorizationStatusDenied){
        [self pushSetting:@"相机权限"];
        
    }else{
        if ( self.block) {
            self.block(NO, @(authStatus));
        }
    }
}

/*
 *麦克风权限
 */
- (void)permissionTypeMicAction{
    AVAudioSessionRecordPermission micPermisson = [[AVAudioSession sharedInstance] recordPermission];
    __block FNKPermission *weakSelf = self;
    if (micPermisson == AVAudioSessionRecordPermissionUndetermined) {
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            if ( weakSelf.block) {
                weakSelf.block(granted, @(micPermisson));
            }
        }];
    } else if (micPermisson == AVAudioSessionRecordPermissionGranted) {
        if ( self.block) {
            self.block(YES, @(micPermisson));
        }
    } else {
        [self pushSetting:@"麦克风权限"];
    }
}


/*
 *获取地理位置When
 */
- (void)permissionTypeLocationWhenAction{
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusNotDetermined) {
        
        if (!self.locationManager) {
            self.locationManager = [[CLLocationManager alloc] init];
            self.locationManager.delegate = self;
        }
        [self.locationManager requestAlwaysAuthorization];
        
    } else if (status == kCLAuthorizationStatusAuthorizedWhenInUse||status == kCLAuthorizationStatusAuthorizedAlways){
        if (self.block) {
            self.block (YES, @(status));
        }
    } else {
        [self pushSetting:@"定位服务"];
    }
}

/*
 *日历
 */
- (void)permissionTypeCalendarAction{
    EKEntityType type  = EKEntityTypeEvent;
    __block FNKPermission *weakSelf = self;
    EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:type];
    if (status == EKAuthorizationStatusNotDetermined) {
        EKEventStore *eventStore = [[EKEventStore alloc] init];
        [eventStore requestAccessToEntityType:type completion:^(BOOL granted, NSError * _Nullable error) {
            if (weakSelf.block) {
                weakSelf.block(granted,@(status));
            }
        }];
    } else if (status == EKAuthorizationStatusAuthorized) {
        if (self.block) {
            self.block(YES,@(status));
        }
    } else {
        [self pushSetting:@"日历权限"];
    }
}


/*
 *联系人
 */
- (void)permissionTypeContactsAction{
    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    __block FNKPermission *weakSelf = self;
    if (status == CNAuthorizationStatusNotDetermined) {
        CNContactStore *store = [[CNContactStore alloc] init];
        [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (granted) {
                if (weakSelf.block) {
                    weakSelf.block(granted,[weakSelf openContact]);
                }
            }else{
                if (weakSelf.block) {
                    weakSelf.block(granted,@(status));
                }
            }
        }];
    } else if (status == CNAuthorizationStatusAuthorized) {
        if (self.block) {
            self.block(YES,[self openContact]);
        }
    } else {
        [self pushSetting:@"联系人权限"];
    }
}


/*
 *蓝牙
 */
- (void)permissionTypeBlueAction{
    if (!self.centralManager) {
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
    }
}

/*
 * 提醒
 */
- (void)permissionTypeRemainerAction{
    EKEntityType type  = EKEntityTypeReminder;
    __block FNKPermission *weakSelf = self;
    EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:type];
    if (status == EKAuthorizationStatusNotDetermined) {
        EKEventStore *eventStore = [[EKEventStore alloc] init];
        [eventStore requestAccessToEntityType:type completion:^(BOOL granted, NSError * _Nullable error) {
            if (weakSelf.block) {
                weakSelf.block(granted,@(status));
            }
        }];
    } else if (status == EKAuthorizationStatusAuthorized) {
        if (self.block) {
            self.block(YES,@(status));
        }
    } else {
        [self pushSetting:@"日历权限"];
    }
}

/*
 * 健康
 */
- (void)permissionTypeHealthAction{
    //查看healthKit在设备上是否可用，ipad不支持HealthKit
    if (![HKHealthStore isHealthDataAvailable]) {
        NSLog(@"设备不支持healthKit");
        self.block(NO, nil);
        return;
    }
    
    if (!self.healthStore) {
        self.healthStore = [HKHealthStore new];
    }
    
    
    HKQuantityType *stepType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    __block FNKPermission *weakSelf = self;
    NSSet *readDataTypes =  [NSSet setWithObjects:stepType, nil];
    [self.healthStore requestAuthorizationToShareTypes:nil readTypes:readDataTypes completion:^(BOOL success, NSError * _Nullable error) {
        
        if (success) {
            [weakSelf readStepCount];
        }else{
            weakSelf.block(NO, nil);
        }
    }];
    
    
}

/*
 * 多媒体
 */
- (void)permissionTypeMediaLibraryAction{
    __block FNKPermission *weakSelf = self;
    [MPMediaLibrary requestAuthorization:^(MPMediaLibraryAuthorizationStatus status){
        switch (status) {
            case MPMediaLibraryAuthorizationStatusNotDetermined: {
                if (weakSelf.block) {
                    weakSelf.block(NO, @(status));
                }
                break;
            }
            case MPMediaLibraryAuthorizationStatusRestricted: {
                if (weakSelf.block) {
                    weakSelf.block(NO, @(status));
                }
                break;
            }
            case MPMediaLibraryAuthorizationStatusDenied: {
                if (weakSelf.block) {
                    weakSelf.block(NO, @(status));
                }
                break;
            }
            case MPMediaLibraryAuthorizationStatusAuthorized: {
                // authorized
                if (weakSelf.block) {
                    weakSelf.block(YES, @(status));
                }
                break;
            }
            default: {
                break;
            }
        }
        
    }];
}

/*
 * 查询步数数据
 */
- (void)readStepCount
{
    HKQuantityType *stepType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierEndDate ascending:NO];
    
    __block FNKPermission *weakSelf = self;
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:stepType predicate:[FNKPermission predicateForSamplesToday] limit:HKObjectQueryNoLimit sortDescriptors:@[timeSortDescriptor] resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
        if(error)
        {
            
            weakSelf.block(NO, error);
        }
        else
        {
            NSInteger totleSteps = 0;
            for(HKQuantitySample *quantitySample in results)
            {
                HKQuantity *quantity = quantitySample.quantity;
                HKUnit *heightUnit = [HKUnit countUnit];
                double usersHeight = [quantity doubleValueForUnit:heightUnit];
                totleSteps += usersHeight;
            }
            NSLog(@"当天行走步数 = %ld",(long)totleSteps);
            weakSelf.block(YES,@(totleSteps));
        }
    }];
    
    [self.healthStore executeQuery:query];
    
    
}

/*!
 *  @brief  当天时间段(可以获取某一段时间)
 *
 *  @return 时间段
 */
+ (NSPredicate *)predicateForSamplesToday {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
    [components setHour:0];
    [components setMinute:0];
    [components setSecond: 0];
    
    NSDate *startDate = [calendar dateFromComponents:components];
    NSDate *endDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startDate options:0];
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];
    return predicate;
}


//有通讯录权限-- 获取通讯录
- (NSArray*)openContact{
    // 获取指定的字段
    NSArray *keysToFetch = @[CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey];
    CNContactFetchRequest *fetchRequest = [[CNContactFetchRequest alloc] initWithKeysToFetch:keysToFetch];
    CNContactStore *contactStore = [[CNContactStore alloc] init];
    NSMutableArray *arr = [NSMutableArray new];
    [contactStore enumerateContactsWithFetchRequest:fetchRequest error:nil usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
        //拼接姓名
        NSString *nameStr = [NSString stringWithFormat:@"%@%@",contact.familyName,contact.givenName];
        
        NSArray *phoneNumbers = contact.phoneNumbers;
        
        for (CNLabeledValue *labelValue in phoneNumbers) {
            CNPhoneNumber *phoneNumber = labelValue.value;
            NSString * string = phoneNumber.stringValue ;
            //去掉电话中的特殊字符
            string = [string stringByReplacingOccurrencesOfString:@"+86" withString:@""];
            string = [string stringByReplacingOccurrencesOfString:@"-" withString:@""];
            string = [string stringByReplacingOccurrencesOfString:@"(" withString:@""];
            string = [string stringByReplacingOccurrencesOfString:@")" withString:@""];
            string = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
            string = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
            NSLog(@"姓名=%@, 电话号码是=%@", nameStr, string);
            [arr addObject:@{@"name":nameStr,@"phone":string}];
        }
    }];
    return [NSArray arrayWithArray:arr];
    
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    if (self.block) {
        self.block(YES, error);
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    if (self.block) {
        self.block(YES, newLocation);
    }
    [self stopLocationService];
}

- (void)stopLocationService
{
    [self.locationManager stopUpdatingLocation];
    self.locationManager.delegate=nil;
    self.locationManager = nil;
}

#pragma mark - CBCentralManagerDelegate
-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    //蓝牙第一次以及之后每次蓝牙状态改变都会调用这个函数
    if(central.state==CBCentralManagerStatePoweredOn)
    {
        NSLog(@"蓝牙设备开着");
        if (self.block) {
            self.block(YES, nil);
        }
    }
    else
    {
        NSLog(@"蓝牙设备关着");
        if (self.block) {
            self.block(NO, nil);
        }
    }
}


/*
 *跳转设置
 */
- (void)pushSetting:(NSString*)urlStr{
    __block FNKPermission *weakSelf = self;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:[NSString stringWithFormat:@"%@%@",urlStr,self.tip] preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        if (weakSelf.block) {
            weakSelf.block(NO, 0);
        }
    }];
    [alert addAction:cancelAction];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (weakSelf.block) {
            weakSelf.block(NO, 0);
        }
        NSURL *url= [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if (IOS_10_OR_LATER) {
            if( [[UIApplication sharedApplication]canOpenURL:url] ) {
                [[UIApplication sharedApplication]openURL:url options:@{}completionHandler:^(BOOL        success) {
                }];
            }
        }else{
            if( [[UIApplication sharedApplication]canOpenURL:url] ) {
                [[UIApplication sharedApplication]openURL:url];
            }
        }
    }];
    [alert addAction:okAction];
    [[FNKPermission getCurrentVC] presentViewController:alert animated:YES completion:nil];
}

//获取当前VC
+ (UIViewController *)getCurrentVC
{
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    UIViewController *currentVC = [self getCurrentVCFrom:rootViewController];
    
    return currentVC;
}

+ (UIViewController *)getCurrentVCFrom:(UIViewController *)rootVC
{
    UIViewController *currentVC;
    
    if ([rootVC presentedViewController]) {
        // 视图是被presented出来的
        rootVC = [rootVC presentedViewController];
    }
    
    if ([rootVC isKindOfClass:[UITabBarController class]]) {
        // 根视图为UITabBarController
        currentVC = [self getCurrentVCFrom:[(UITabBarController *)rootVC selectedViewController]];
        
    } else if ([rootVC isKindOfClass:[UINavigationController class]]){
        // 根视图为UINavigationController
        currentVC = [self getCurrentVCFrom:[(UINavigationController *)rootVC visibleViewController]];
        
    } else {
        // 根视图为非导航类
        currentVC = rootVC;
    }
    return currentVC;
}

- (NSString *)tip{
    if (!_tip) {
        _tip = @"尚未开启,请在系统设置中开启服务";
    }
    return _tip;
}
@end
