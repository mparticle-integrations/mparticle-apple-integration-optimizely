//
//  MPKitOptimizely.m
//
//  Copyright 2018 mParticle, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "MPKitOptimizely.h"
#import <OptimizelySDKiOS/OptimizelySDKiOS.h>

#ifdef COCOAPODS

#if defined(__has_include) && __has_include(<OptimizelySDKCore/OptimizelySDKCore.h>)
#import <OptimizelySDKCore/OptimizelySDKCore.h>
#else
#import "OptimizelySDKCore.h"
#endif

#if defined(__has_include) && __has_include(<OptimizelySDKDatafileManager/OptimizelySDKDatafileManager.h>)
#import <OptimizelySDKDatafileManager/OptimizelySDKDatafileManager.h>
#else
#import "OptimizelySDKDatafileManager.h"
#endif

#if defined(__has_include) && __has_include(OptimizelySDKEventDispatcher/OptimizelySDKEventDispatcher.h>)
#import <OptimizelySDKEventDispatcher/OptimizelySDKEventDispatcher.h>
#else
#import "OptimizelySDKEventDispatcher.h"
#endif

#if defined(__has_include) && __has_include(<OptimizelySDKShared/OptimizelySDKShared.h>)
#import <OptimizelySDKShared/OptimizelySDKShared.h>
#else
#import "OptimizelySDKShared.h"
#endif

#if defined(__has_include) && __has_include(<OptimizelySDKUserProfileService/OptimizelySDKUserProfileService.h>)
#import <OptimizelySDKUserProfileService/OptimizelySDKUserProfileService.h>
#else
#import "OptimizelySDKUserProfileService.h"
#endif

#if TARGET_OS_IOS == 1
#if defined(__has_include) && __has_include(<OptimizelySDKiOS/OptimizelySDKiOS.h>)
#import <OptimizelySDKiOS/OptimizelySDKiOS.h>
#else
#import "OptimizelySDKiOS.h"
#endif
#elif TARGET_OS_TV == 1
#if defined(__has_include) && __has_include(<OptimizelySDKTVOS/OptimizelySDKTVOS.h>)
#import <OptimizelySDKTVOS/OptimizelySDKTVOS.h>
#else
#import "OptimizelySDKTVOS.h"
#endif
#endif
#else

#endif

NSString *const eabAPIKey = @"sdk_key";
NSString *const eabEventInterval = @"event_interval";
NSString *const eabUserIDKey = @"userIdField";

NSString *const eabUserIDCustomerIDValue = @"customerId";
NSString *const eabUserIDEmailValue = @"email";
NSString *const eabUserIDMPIDValue = @"mpid";

NSString *const optimizelyCustomEventName = @"Optimizely.EventName";
NSString *const optimizelyTrackedValue = @"Optimizely.EventKey.Value";

@implementation MPKitOptimizely

+ (NSNumber *)kitCode {
    return @(MPKitInstanceOptimizely);
}

+ (void)load {
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"Optimizely" className:@"MPKitOptimizely"];
    [MParticle registerExtension:kitRegister];
}

#pragma mark MPKitInstanceProtocol methods
- (MPKitExecStatus *)didFinishLaunchingWithConfiguration:(NSDictionary *)configuration {
    MPKitExecStatus *execStatus = nil;
    
    if (!configuration[eabAPIKey]) {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeRequirementsNotMet];
        return execStatus;
    }

    _configuration = configuration;
    _started = NO;

    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (void)start {
    static dispatch_once_t optimizelyPredicate;

    dispatch_once(&optimizelyPredicate, ^{
        self.manager = [[OPTLYManager alloc] initWithBuilder:[OPTLYManagerBuilder  builderWithBlock:^(OPTLYManagerBuilder * _Nullable builder) {
            
            NSString *sdkKey = self.configuration[eabAPIKey];
            NSNumber *eventInterval = self.configuration[eabEventInterval];
            
            builder.sdkKey = sdkKey;
            builder.eventDispatchInterval = [eventInterval doubleValue];
        }]];
        
        self->_started = YES;

        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *userInfo = @{mParticleKitInstanceKey:[[self class] kitCode]};

            [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                                object:nil
                                                              userInfo:userInfo];
        });
    });
}

- (OPTLYVariation *)variationForExperimentKey:(nonnull NSString *)key {
    NSDictionary *transformedUserInfo = [[[MParticle sharedInstance].identity currentUser].userIdentities transformValuesToString];
    
    OPTLYClient *client = [self.manager initialize];
    
    return [client activate:key
                     userId:[self userIDForOptimizely]
                 attributes:transformedUserInfo];
}

- (MPKitExecStatus *)logCommerceEvent:(MPCommerceEvent *)commerceEvent {
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceOptimizely) returnCode:MPKitReturnCodeSuccess forwardCount:0];
    
    NSArray *expandedInstructions = [commerceEvent expandedInstructions];
    
    for (MPCommerceEventInstruction *commerceEventInstruction in expandedInstructions) {
        if (commerceEventInstruction.instruction == MPCommerceInstructionTransaction) {
            NSMutableDictionary *baseProductAttributes = [[NSMutableDictionary alloc] init];
            NSDictionary *transactionAttributes = commerceEventInstruction.event.info;
            
            if (transactionAttributes[kMPExpTARevenue] != nil) {
                [baseProductAttributes setObject:transactionAttributes[kMPExpTARevenue] forKey: @"revenue"];
            }
            
            if (transactionAttributes) {
                [baseProductAttributes addEntriesFromDictionary:transactionAttributes];
            }
            
            NSMutableDictionary *customAttributes = commerceEvent.userDefinedAttributes;
            
            NSString *customCommerceEventName;
            if (customAttributes) {
                customCommerceEventName = customAttributes[optimizelyCustomEventName];
                
                [customAttributes removeObjectForKey:optimizelyCustomEventName];
                
                [baseProductAttributes addEntriesFromDictionary:customAttributes];
            }
            
            commerceEventInstruction.event.info = baseProductAttributes;
            if (customCommerceEventName) {
                commerceEventInstruction.event.name = customCommerceEventName;
            }
        }
        
        [self logEvent:commerceEventInstruction.event];
        [execStatus incrementForwardCount];
    }
    
    return execStatus;
}

- (MPKitExecStatus *)logEvent:(MPEvent *)event {
    NSDictionary *transformedEventInfo = [event.info transformValuesToString];

    [[self.manager getOptimizely] track:event.name
                                  userId:[self userIDForOptimizely]
                              attributes:transformedEventInfo];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceOptimizely) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (NSString *)userIDForOptimizely {
    MParticleUser *currentUser = [[MParticle sharedInstance].identity currentUser];
    
    NSString *userID = nil;
    if (currentUser != nil && self.configuration[eabUserIDKey] != nil) {
        NSString *key = self.configuration[eabUserIDKey];
        if (key == eabUserIDCustomerIDValue) {
            userID = currentUser.userIdentities[@(MPUserIdentityCustomerId)];
        } else if (currentUser != nil && key == eabUserIDEmailValue) {
            userID = currentUser.userIdentities[@(MPUserIdentityEmail)];
        } else if (currentUser != nil && key == eabUserIDMPIDValue) {
            userID = [currentUser.userId stringValue];
        }
    }
    return self.configuration[eabUserIDKey] ? [currentUser.userId stringValue] : currentUser.userIdentities[@(MPUserIdentityEmail)];
}

@end
