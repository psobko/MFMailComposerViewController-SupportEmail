//
//  MFMailComposeViewController+SupportEmail.m
//  SupportEmail
//
//  Created by Peter Sobkowski on 2014-10-30.
//  Copyright (c) 2014 psobko. All rights reserved.
//

#import "MFMailComposeViewController+SupportEmail.h"
#import <objc/runtime.h>
#import <mach/mach.h>
#import <mach/mach_host.h>
#include <sys/sysctl.h>
#include <sys/utsname.h>

static char offlineIndicatorKey;

enum SupportDataOption const defaultOptions = SupportDataOptionAppName | SupportDataOptionAppVersion | SupportDataOptionDeviceModel | SupportDataOptionDeviceName | SupportDataOptionDeviceLocaleCountryCode | SupportDataOptionDeviceBattery | SupportDataOptionDeviceMemory | SupportDataOptionDeviceStorage | SupportDataOptionOSVersion;

@interface MFMailComposeViewController ()

@property (copy, nonatomic) SupportEmailControllerCompletionHandler completionHandler;

@end

@implementation MFMailComposeViewController (SupportEmail)

#pragma mark - Initialization

+ (MFMailComposeViewController *)supportMailControllerWithSubject:(NSString *)subject message:(NSString *)message recepients:(NSArray *)recepients completion:(SupportEmailControllerCompletionHandler)completionHandler
{
    return [MFMailComposeViewController supportMailControllerWithSubject:subject
                                                          message:message
                                                       recepients:recepients
                                                          options:defaultOptions
                                                       completion:completionHandler];
}

+ (MFMailComposeViewController *)supportMailControllerWithSubject:(NSString *)subject message:(NSString *)message recepients:(NSArray *)recepients options:(enum SupportDataOption)options completion:(SupportEmailControllerCompletionHandler)completionHandler
{
    if(![MFMailComposeViewController canSendMail])
    {
        if(completionHandler)
        {
            completionHandler(MFMailComposeResultFailed, nil, NO);
        }
        return nil;
    }
    
    MFMailComposeViewController *mailComposeVC = [[MFMailComposeViewController alloc] init];

    [mailComposeVC setSubject:subject];
    [mailComposeVC setMessageBody:[mailComposeVC emailBodyWithMessageString:message
                                                                    options:options]
                           isHTML:NO];
    [mailComposeVC setToRecipients:recepients];
    mailComposeVC.mailComposeDelegate = mailComposeVC;
    mailComposeVC.completionHandler = completionHandler;

    return mailComposeVC;
}

#pragma mark - Accessors

- (SupportEmailControllerCompletionHandler)completionHandler
{
    return objc_getAssociatedObject(self, &offlineIndicatorKey);
}

- (void)setCompletionHandler:(SupportEmailControllerCompletionHandler)completionHandler
{
    objc_setAssociatedObject(self, &offlineIndicatorKey, completionHandler, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

#pragma mark - MFMailComposer Delegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    if(self.completionHandler)
    {
        self.completionHandler(result, nil, YES);
    }
}

#pragma mark - Private

- (NSString *)emailBodyWithMessageString:(NSString *)string options:(enum SupportDataOption)options
{
    int i = 1;

    NSMutableString *bodyText = [NSMutableString stringWithString:string ? [string stringByAppendingString:@"\n"] : @""];
    
    while(options)
    {
        switch(options & i)
        {
            case SupportDataOptionAppName:
                [bodyText appendFormat:@"%@\n", [self appName]];
                break;
            case SupportDataOptionAppVersion:
                [bodyText appendFormat:@"Version: %@\n", [self appVersion]];
                break;
            case SupportDataOptionDeviceModel:
                [bodyText appendFormat:@"Device: %@\n", [self deviceModel]];
                break;
            case SupportDataOptionDeviceName:
                [bodyText appendFormat:@"Device Name: %@\n", [UIDevice currentDevice].name];
                break;
            case SupportDataOptionDeviceLocaleCountryCode:
                [bodyText appendFormat:@"Country: %@\n", [self deviceCountryCode]];
                break;
            case SupportDataOptionDeviceBattery:
                [bodyText appendFormat:@"Battery: %1.2f%%\n", [self deviceBatteryLevel]];
                break;
            case SupportDataOptionDeviceMemory:
                [bodyText appendFormat:@"Memory Free: %@\n", [self deviceMemory]];
                break;
            case SupportDataOptionDeviceStorage:
                [bodyText appendFormat:@"Storage Free: %@\n", [self deviceStorage]];
                break;
            case SupportDataOptionOSVersion:
                [bodyText appendFormat:@"OS: %@\n", [self deviceOS]];
                break;
        }
        options &= ~i;
        i <<= 1;
    }
    
    return [NSString stringWithString:bodyText];
}

#pragma mark - App info

-(NSString *)appName
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
}

-(NSString *)appVersion
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

#pragma mark - Device info

-(float)deviceBatteryLevel
{
    UIDevice *myDevice = [UIDevice currentDevice];
    [myDevice setBatteryMonitoringEnabled:YES];
    float batteryLevel = [myDevice batteryLevel];
    [myDevice setBatteryMonitoringEnabled:NO];
    
    return batteryLevel * 100;
}

-(NSString *)deviceCountryCode
{
    return [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
}

-(NSString *)deviceModel
{
    struct utsname systemInfo;
    uname(&systemInfo);
    return [self getDeviceNameFromSystemInfoString:[NSString stringWithCString:systemInfo.machine
                                                                      encoding:NSUTF8StringEncoding]];
}

-(NSString *)deviceMemory
{
    // http://stackoverflow.com/a/8540665/1549072
    mach_port_t hostPort;
    mach_msg_type_number_t hostSize;
    vm_size_t pageSize;
    
    hostPort = mach_host_self();
    hostSize = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(hostPort, &pageSize);
    
    vm_statistics_data_t vmStats;
    
    if (host_statistics(hostPort, HOST_VM_INFO, (host_info_t)&vmStats, &hostSize) != KERN_SUCCESS)
    {
        return @"Unknown";
    }
    
    u_int64_t usedMemory = (vmStats.active_count + vmStats.inactive_count + vmStats.wire_count) * pageSize;
    
    u_int64_t totalMemory = [NSProcessInfo processInfo].physicalMemory;
    
    return [self formattedStringWithValue:(totalMemory - usedMemory)
                               comparedTo:totalMemory];
}

// The total device storage seems to be accurate however the free space reported by NSFileManager seems to be offset by ~200 MB. Best guess is that this is due to reserved space by Apple. fstat also reports the same results.

-(NSString *)deviceStorage
{
    NSError *error;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory()
                                                                                       error:&error];
    
    return error ? @"Unknown"
    : [self formattedStringWithValue:[attributes[NSFileSystemFreeSize] longLongValue]
                          comparedTo:[attributes[NSFileSystemSize] longLongValue]];
}

-(NSString *)deviceOS
{
    return [NSString stringWithFormat:@"%@ %@", [UIDevice currentDevice].systemName, [UIDevice currentDevice].systemVersion];
}

#pragma mark - Device Model Lookup

typedef NSString * (^DeviceModelBlock)();

-(NSString *)getDeviceNameFromSystemInfoString:(NSString *)string
{
    // http://stackoverflow.com/a/3950748/1549072
    NSDictionary *deviceNames = @{
                                  @"iPhone1,1":   ^{ return @"iPhone 1G"; },
                                  @"iPhone1,2":   ^{ return @"iPhone 3G"; },
                                  @"iPhone2,1":   ^{ return @"iPhone 3GS"; },
                                  @"iPhone3,1":   ^{ return @"iPhone 4"; },
                                  @"iPhone3,3":   ^{ return @"Verizon iPhone 4"; },
                                  @"iPhone4,1":   ^{ return @"iPhone 4S"; },
                                  @"iPhone5,1":   ^{ return @"iPhone 5 (GSM)"; },
                                  @"iPhone5,2":   ^{ return @"iPhone 5 (GSM+CDMA)"; },
                                  @"iPhone5,3":   ^{ return @"iPhone 5c (GSM)"; },
                                  @"iPhone5,4":   ^{ return @"iPhone 5c (GSM+CDMA)"; },
                                  @"iPhone6,1":   ^{ return @"iPhone 5s (GSM)"; },
                                  @"iPhone6,2":   ^{ return @"iPhone 5s (GSM+CDMA)"; },
                                  @"iPhone7,1":   ^{ return @"iPhone 6 Plus"; },
                                  @"iPhone7,2":   ^{ return @"iPhone 6"; },
                                  @"iPod1,1":     ^{ return @"iPod Touch 1G"; },
                                  @"iPod2,1":     ^{ return @"iPod Touch 2G"; },
                                  @"iPod3,1":     ^{ return @"iPod Touch 3G"; },
                                  @"iPod4,1":     ^{ return @"iPod Touch 4G"; },
                                  @"iPod5,1":     ^{ return @"iPod Touch 5G"; },
                                  @"iPad1,1":     ^{ return @"iPad"; },
                                  @"iPad2,1":     ^{ return @"iPad 2 (WiFi)"; },
                                  @"iPad2,2":     ^{ return @"iPad 2 (GSM)"; },
                                  @"iPad2,3":     ^{ return @"iPad 2 (CDMA)"; },
                                  @"iPad2,4":     ^{ return @"iPad 2 (WiFi)"; },
                                  @"iPad2,5":     ^{ return @"iPad Mini (WiFi)"; },
                                  @"iPad2,6":     ^{ return @"iPad Mini (GSM)"; },
                                  @"iPad2,7":     ^{ return @"iPad Mini (GSM+CDMA)"; },
                                  @"iPad3,1":     ^{ return @"iPad 3 (WiFi)"; },
                                  @"iPad3,2":     ^{ return @"iPad 3 (GSM+CDMA)"; },
                                  @"iPad3,3":     ^{ return @"iPad 3 (GSM)"; },
                                  @"iPad3,4":     ^{ return @"iPad 4 (WiFi)"; },
                                  @"iPad3,5":     ^{ return @"iPad 4 (GSM)"; },
                                  @"iPad3,6":     ^{ return @"iPad 4 (GSM+CDMA)"; },
                                  @"iPad4,1":     ^{ return @"iPad Air (WiFi)"; },
                                  @"iPad4,2":     ^{ return @"iPad Air (Cellular)"; },
                                  @"iPad4,3":     ^{ return @"iPad Air (Rev)"; },
                                  @"iPad4,4":     ^{ return @"iPad mini 2G (WiFi)"; },
                                  @"iPad4,5":     ^{ return @"iPad mini 2G (Cellular)"; },
                                  @"iPad4,6":     ^{ return @"iPad Mini 2G (Rev)"; },
                                  @"iPad4,7":     ^{ return @"iPad Mini 3 (WiFi)"; },
                                  @"iPad4,8":     ^{ return @"iPad Mini 3 (CDMA)"; },
                                  @"iPad4,9":     ^{ return @"iPad Mini 3 (GSM)"; },
                                  @"iPad5,3":     ^{ return @"iPad Air 2 (WiFi)"; },
                                  @"iPad5,4":     ^{ return @"iPad Air 2 (GSM)"; },
                                  @"i386":        ^{ return @"Simulator"; },
                                  @"x86_64":      ^{ return @"Simulator"; },
                                  @"unknown":     ^{ return @"Unknown"; }
                                  };
    
     NSString *lookupString =  @"unknown";
    if(string && deviceNames[string])
    {
        lookupString = string;
    }
    
    return ((DeviceModelBlock)deviceNames[lookupString])();
}

#pragma mark - Helper Methods

-(NSString *)formattedStringWithValue:(unsigned long long)denominator comparedTo:(unsigned long long)divisor
{
    return [[self formattedByteCount:denominator] stringByAppendingFormat:@"/%@", [self formattedByteCount:divisor]];
}

- (NSString *)formattedByteCount:(unsigned long long)value
{
    return  [NSByteCountFormatter stringFromByteCount:value
                                           countStyle:NSByteCountFormatterCountStyleMemory];
}
@end
