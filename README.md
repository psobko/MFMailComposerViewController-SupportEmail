MFMailComposerViewController-SupportEmail
=========================================

A block-based MFMailComposerViewController category for sending a support email populated with a user's device data. 

Usage
-----

Import "MFMailComposeViewController+SupportEmail.h" and instantiate an instance of MFMailComposeViewController with:

`+ (MFMailComposeViewController *)supportMailControllerWithSubject:(NSString *)subject message:(NSString *)message recepients:(NSArray *)recepients completion:(SupportEmailControllerCompletionHandler)completionHandler`

which will use all of the available options, or:

`+ (MFMailComposeViewController *)supportMailControllerWithSubject:(NSString *)subject 
message:(NSString *)message recepients:(NSArray *)recepients options:(enum SupportDataOption)options completion:(SupportEmailControllerCompletionHandler)completionHandler`

which allows specific options to be passed.

Once instantiated the view controller needs to be presented just like any other view controller.

Available Options
-----------------

- SupportDataOptionAppName // SupportEmailTestApp
- SupportDataOptionAppVersion // 1.0
- SupportDataOptionDeviceModel // iPhone 5s
- SupportDataOptionDeviceName // John Doe's iPhone
- SupportDataOptionDeviceLocaleCountryCode // CA
- SupportDataOptionDeviceBattery // 50%
- SupportDataOptionDeviceMemory // 603 MB/1,015.7 MB
- SupportDataOptionDeviceStorage // 4.2 GB/12.72 GB
- SupportDataOptionOSVersion // iPhone OS 8.1

Completion Block
----------------

An optional completion block can be passed which will pass back the result of the `mailComposeController:didFinishWithResult:error:` delegate callback result as well as a BOOL value indicating whether the current device is able to send mail or not.

