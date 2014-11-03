//
//  ViewController.m
//  SupportEmailExample
//
//  Created by Peter Sobkowski on 2014-11-03.
//  Copyright (c) 2014 psobko. All rights reserved.
//

#import "ViewController.h"
#import "MFMailComposeViewController+SupportEmail.h"

@interface ViewController ()

@end

@implementation ViewController

- (IBAction)sendButtonWasTapped:(id)sender
{
    MFMailComposeViewController *mailVC;
    mailVC = [MFMailComposeViewController supportMailControllerWithSubject:@"Test Subject"
                                                                   message:@"A test message"
                                                                recepients:@[@"test@test.com"]
                                                                completion:^(MFMailComposeResult result, NSError *error, BOOL canSendMail)
              {
                  NSLog(@"Result: %d", result);
                  NSLog(@"Error: %@ %ld", error.domain, (long)error.code);
                  NSLog(@"Can Send Mail: %d", canSendMail);
                  
                  [self dismissViewControllerAnimated:YES
                                           completion:^{ NSLog(@"Dismissed"); }];
                  
              }];
    
    [self presentViewController:mailVC
                       animated:YES
                     completion:^{ NSLog(@"Displayed"); }];
}

@end
