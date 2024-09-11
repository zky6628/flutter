#import "SysGravitySensorPlugin.h"
#import "SysGravitySensorEventSink.h"
#import <AVKit/AVKit.h>
#import <Flutter/Flutter.h>
#import <CoreMotion/CoreMotion.h>

@interface SysGravitySensorPlugin ()
@property (nonatomic,strong)CMMotionManager *motionManager;
@end

#define iOS10 ([[UIDevice currentDevice].systemVersion doubleValue] >= 10.0)

@implementation SysGravitySensorPlugin {
    NSObject<FlutterPluginRegistrar> *_registrar;
    FlutterEventChannel *_eventChannel;
    SysGravitySensorEventSink *_eventSink; // 事件通道
    
    BOOL _eventListening; //是否开启事件监听
    BOOL _isOPenGravity; //是否开启重力感应
    NSString *_oldOrientation; //之前的设备方向
}
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"com.gzygxy.method.sys_gravity_sensor"
                                     binaryMessenger:[registrar messenger]];
    SysGravitySensorPlugin* instance = [[SysGravitySensorPlugin alloc] initWithRegistrar: registrar];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    self = [super init];
    if (self) {
        _registrar = registrar;
        _eventListening = NO;
        _isOPenGravity = YES;
        _oldOrientation = @"orientationUnknown";
        NSLog(@"======registrar");
        _eventSink = [[SysGravitySensorEventSink alloc] init];
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSDictionary *argsMap = call.arguments;
    
    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    } else if ([@"setOpenGravity" isEqualToString:call.method]) {
        _isOPenGravity = [argsMap[@"isOPenGravity"] boolValue];
        result(@(_isOPenGravity));
        
    } else if ([@"enable_gravity_watch" isEqualToString:call.method]) {
        [self enableGravityWatch];
        result(nil);
    } else if ([@"disable_gravity_watch" isEqualToString:call.method]) {
        [self disableGravityWatch];
        result(nil);
    } else if ([@"setPhotoPermission" isEqualToString:call.method]) {
        NSString * _packageName = argsMap[@"packageName"];
        result(@([self setApplicationPermission: _packageName withPathRoot: @"Photos"]));
   } else if ([@"setLocationPermission" isEqualToString:call.method]) {
       NSString * _packageName = argsMap[@"packageName"];
       result(@([self setApplicationPermission: _packageName withPathRoot: @"LOCATION_SERVICES"]));
  } else if ([@"setCameraPermission" isEqualToString:call.method]) {
      NSString * _packageName = argsMap[@"packageName"];
      result(@([self setApplicationPermission: _packageName withPathRoot: @"Photos"]));
 }
    else {
        result(nil);
    }
    
}

- (void)enableGravityWatch {
    if (_eventListening == NO) {
        _eventListening = YES;
        
        _eventChannel = [FlutterEventChannel
                         eventChannelWithName:@"com.gzygxy.event.sys_gravity_sensor"
                         binaryMessenger:[_registrar messenger]];
        [_eventChannel setStreamHandler:self];
        
        //开始生成 设备旋转 通知
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        
        //添加 设备旋转 通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
        
    }
}

- (void)disableGravityWatch {
    if (_eventListening == YES) {
        _eventListening = NO;
        
        //销毁 设备旋转 通知
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UIDeviceOrientationDidChangeNotification
                                                      object:nil
         ];
        
        
        //结束 设备旋转通知
        [[UIDevice currentDevice]endGeneratingDeviceOrientationNotifications];
        NSLog(@"======disableGravityWatch");
        [_eventChannel setStreamHandler:nil];
        _eventChannel = nil;
    }
}

/**屏幕旋转的通知回调*/
- (void)orientChange:(NSNotification *)noti {
    UIDeviceOrientation  orient = [UIDevice currentDevice].orientation;
    NSString *tempOrientation = @"orientationUnknown";
    switch (orient) {
        case UIDeviceOrientationPortrait:
            NSLog(@"竖直屏幕");
            tempOrientation = @"orientationPortrait";
            break;
        case UIDeviceOrientationLandscapeLeft:
            NSLog(@"手机左转");
            tempOrientation = @"orientationLandscapeLeft";
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            NSLog(@"手机竖直");
            tempOrientation = @"orientationPortraitUpsideDown";
            break;
        case UIDeviceOrientationLandscapeRight:
            NSLog(@"手机右转");
            tempOrientation = @"orientationLandscapeRight";
            break;
        case UIDeviceOrientationUnknown:
            NSLog(@"未知");
            tempOrientation = @"orientationUnknown";
            break;
        case UIDeviceOrientationFaceUp:
            NSLog(@"手机屏幕朝上");
            tempOrientation = @"orientationFaceUp";
            break;
        case UIDeviceOrientationFaceDown:
            NSLog(@"手机屏幕朝下");
            tempOrientation = @"orientationFaceDown";
            break;
        default:
            break;
    }

    if([tempOrientation isEqual: _oldOrientation]) return;
    
    _oldOrientation = tempOrientation;
    [self sendGravityChange: tempOrientation];
}

- (void)sendGravityChange:(NSString *)orientation {
    if (_eventListening && _isOPenGravity) {
//        NSLog(@"Gravity val %@\n", orientation);
        [_eventSink success:@{@"event" : @"watch", @"orientation" : orientation}];
    }
}

- (bool)setApplicationPermission:(NSString *)packageName withPathRoot:(NSString *)proot {
    
    NSLog(@"--11--%d---%@--%@", iOS10, packageName, proot);
    if(iOS10){
        NSURL *url = [NSURL URLWithString: UIApplicationOpenSettingsURLString];

        NSLog(@"--22--%@", url);

        if( [[UIApplication sharedApplication]canOpenURL:url] ) {
         [[UIApplication sharedApplication]openURL:url];
        }
        
    } else{
        NSString *tempPackageName = @"";
        if(![self isNullString: packageName]){
            tempPackageName = [NSString stringWithFormat:@"&path=%@", packageName];
        }
        NSLog(@"--33--%@", tempPackageName);
        NSURL *url= [NSURL URLWithString:[NSString stringWithFormat: @"App-Prefs:root=%@%@", proot, tempPackageName] ];
        if( [[UIApplication sharedApplication]canOpenURL:url] ) {
         [[UIApplication sharedApplication]openURL:url];
        }
    }
    
    return YES;
    
}


// FlutterStreamHandler 协议方法
- (FlutterError* _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    
    [_eventSink setDelegate:nil];
    return nil;
}

- (FlutterError* _Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(FlutterEventSink)events {
    [_eventSink setDelegate:events];
    return nil;
}


// 判断空字符串
- (BOOL)isNullString:(NSString *)aStr {
    if (!aStr) {
        return YES;
    }
    if ([aStr isKindOfClass:[NSNull class]]) {
        return YES;
    }
    NSCharacterSet *set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *trimmedStr = [aStr stringByTrimmingCharactersInSet:set];
    if (!trimmedStr.length) {
        return YES;
    }
    return NO;
}

@end
