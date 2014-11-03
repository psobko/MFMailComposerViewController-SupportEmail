//
//  MFMailComposeViewController+SupportEmail.h
//  SupportEmail
//
//  Created by Peter Sobkowski on 2014-10-30.
//  Copyright (c) 2014 psobko. All rights reserved.
//

#import <MessageUI/MessageUI.h>

NS_OPTIONS(NSUInteger , SupportDataOption)
{
    SupportDataOptionAppName = 1 << 0, // SupportEmailTestApp
    SupportDataOptionAppVersion = 1 << 1, // 1.0
    SupportDataOptionDeviceModel = 1 << 2, // iPhone 5s
    SupportDataOptionDeviceName = 1 << 3, // John Doe's iPhone
    SupportDataOptionDeviceLocaleCountryCode = 1 << 4, // CA
    SupportDataOptionDeviceBattery = 1 << 5, // 50%
    SupportDataOptionDeviceMemory = 1 << 6, // 603 MB/1,015.7 MB
    SupportDataOptionDeviceStorage = 1 << 7, // 4.2 GB/12.72 GB
    SupportDataOptionOSVersion = 1 << 8, // iPhone OS 8.1
};

typedef void (^SupportEmailControllerCompletionHandler) (MFMailComposeResult result, NSError *error, BOOL canSendMail);

@interface MFMailComposeViewController (SupportEmail) <MFMailComposeViewControllerDelegate>

+ (MFMailComposeViewController *)supportMailControllerWithSubject:(NSString *)subject message:(NSString *)message recepients:(NSArray *)recepients completion:(SupportEmailControllerCompletionHandler)completionHandler;

+ (MFMailComposeViewController *)supportMailControllerWithSubject:(NSString *)subject message:(NSString *)message recepients:(NSArray *)recepients options:(enum SupportDataOption)options completion:(SupportEmailControllerCompletionHandler)completionHandler;

- (NSString *)emailBodyWithMessageString:(NSString *)string options:(enum SupportDataOption)options;

@end
