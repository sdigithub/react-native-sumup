//
//  RNSumup.m
//  RNSumup
//
//  Created by Alvaro Medina Ballester on 11/02/16.
//  Copyright © 2016 APSL. All rights reserved.
//


#import "RNSumup.h"

@implementation RCTConvert (SMPPaymentOptions)

RCT_ENUM_CONVERTER(SMPPaymentOptions, (
                                       @{@"SMPPaymentOptionAny"           : @(SMPPaymentOptionAny),
                                         @"SMPPaymentOptionCardReader"    : @(SMPPaymentOptionCardReader),
                                         @"SMPPaymentOptionMobilePayment" : @(SMPPaymentOptionMobilePayment)
                                         }), SMPPaymentOptionAny, integerValue);

@end

@implementation RNSumup

RCT_EXPORT_MODULE();

- (NSDictionary *)constantsToExport
{
    return @{ @"SMPPaymentOptionAny": @(SMPPaymentOptionAny),
              @"SMPPaymentOptionCardReader": @(SMPPaymentOptionCardReader),
              @"SMPPaymentOptionMobilePayment": @(SMPPaymentOptionMobilePayment)};
}

RCT_EXPORT_METHOD(setupWithAPIKey:(NSString *)apiKey completionBlock:(RCTPromiseResolveBlock)completionBlock errorBlock:(RCTPromiseRejectBlock)errorBlock)
{
    dispatch_sync(dispatch_get_main_queue(),^ {
        BOOL successfulSetup = [SumupSDK setupWithAPIKey:apiKey];
        if (successfulSetup) {
            completionBlock(nil);
        } else {
            errorBlock(@"000", @"Error setting up SumupSDK", nil);
        }
    });
}

RCT_EXPORT_METHOD(prepareForCheckout)
{
    dispatch_sync(dispatch_get_main_queue(),^ {
        [SumupSDK prepareForCheckout];
    });
}

RCT_EXPORT_METHOD(loginWithToken:(NSString *)aToken completionBlock:(RCTPromiseResolveBlock)completionBlock error:(RCTPromiseRejectBlock)errorBlock)
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        [SumupSDK loginWithToken:aToken
                      completion:^(BOOL success, NSError *error) {
                          if (error) {
                              errorBlock(@"001", @"Error during login", error);
                          } else {
                              completionBlock(@{@"success": @(success)});
                          }
                      }];
    });
}

RCT_EXPORT_METHOD(presentLoginFromViewController:(RCTPromiseResolveBlock)completionBlock error:(RCTPromiseRejectBlock)errorBlock)
{
    UIViewController *rootViewController = UIApplication.sharedApplication.delegate.window.rootViewController;
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        [SumupSDK presentLoginFromViewController:rootViewController
                                        animated:YES
                                 completionBlock:^(BOOL success, NSError *error) {
                                     if (error) {
                                         // Force view controller dismissal to avoid a RN error for the completion block
                                         [rootViewController dismissViewControllerAnimated:YES completion:nil];
                                         errorBlock(@"001", @"Error authenticating", error);
                                     } else {
                                         completionBlock(@{@"success": @(success)});
                                     }
                                 }];
    });
}

RCT_EXPORT_METHOD(checkoutWithRequest:(NSDictionary *)request completionBlock:(RCTPromiseResolveBlock)completionBlock errorBlock:(RCTPromiseRejectBlock)errorBlock)
{
    UIViewController *rootViewController = UIApplication.sharedApplication.delegate.window.rootViewController;
    NSDecimalNumber *total = [NSDecimalNumber decimalNumberWithString:[RCTConvert NSString:request[@"totalAmount"]]];
    NSString *title = [RCTConvert NSString:request[@"title"]];
    NSString *currencyCode = [RCTConvert NSString:request[@"currencyCode"]];
    NSUInteger paymentOption = [RCTConvert SMPPaymentOptions:request[@"paymentOption"]];
    
    SMPCheckoutRequest *checkoutRequest = [SMPCheckoutRequest requestWithTotal:total
                                                                         title:title
                                                                  currencyCode:currencyCode
                                                                paymentOptions:paymentOption];
    dispatch_sync(dispatch_get_main_queue(), ^{
        //@try {
        [SumupSDK checkoutWithRequest:checkoutRequest
                   fromViewController:rootViewController
                           completion:^(SMPCheckoutResult *result, NSError *error) {
                               if (error) {
                                   errorBlock(@"002", @"Error performing checkout", error);
                               } else if (result) {
                                   completionBlock(@{@"success": @([result success]), @"transactionCode": [result transactionCode]});
                               }
                               else {
                                   errorBlock(@"002", @"Error performing checkout", nil);
                               }
                           }];
        //}
        //@catch (NSException *e) {
        //
        //}
    });
}

RCT_EXPORT_METHOD(isLoggedIn:(RCTPromiseResolveBlock)completionBlock error:(RCTPromiseRejectBlock)errorBlock)
{
    BOOL isLoggedIn = [SumupSDK isLoggedIn];
    completionBlock(@{@"isLoggedIn": @(isLoggedIn)});
}

@end
