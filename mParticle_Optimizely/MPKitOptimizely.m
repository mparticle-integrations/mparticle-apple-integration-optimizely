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
#if TARGET_OS_IOS == 1
#import <OptimizelySDKiOS/OptimizelySDKiOS.h>
#elif TARGET_OS_TV == 1
#import <OptimizelySDKTVOS/OptimizelySDKTVOS.h>
#endif

@implementation MPKitOptimizely

static OPTLYClient *MPKitOptimizelyClient;

static NSString *const oiAPIKey = @"sdk_key";
static NSString *const oiEventInterval = @"event_interval";
static NSString *const oiUserIDKey = @"userIdField";

static NSString *const oiUserIDCustomerIDValue = @"customerId";
static NSString *const oiUserIDEmailValue = @"email";
static NSString *const oiUserIDMPIDValue = @"mpid";

static NSString *const optimizelyCustomEventName = @"Optimizely.EventName";
static NSString *const optimizelyTrackedValue = @"Optimizely.EventKey.Value";

#pragma mark Static Methods

+ (NSNumber *)kitCode {
    return @(MPKitInstanceOptimizely);
}

+ (void)load {
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"Optimizely" className:@"MPKitOptimizely"];
    [MParticle registerExtension:kitRegister];
}

+ (OPTLYClient *)optimizelyClient {
    return MPKitOptimizelyClient;
}

+ (void)setOptimizelyClient:(OPTLYClient *)client {
    if (client != nil) {
        MPKitOptimizelyClient = client;
    }
}

- (MPKitExecStatus *)execStatus:(MPKitReturnCode)returnCode {
    return [[MPKitExecStatus alloc] initWithSDKCode:self.class.kitCode returnCode:returnCode];
}

#pragma mark MPKitInstanceProtocol methods
- (MPKitExecStatus *)didFinishLaunchingWithConfiguration:(NSDictionary *)configuration {
    if (!configuration[oiAPIKey] || !configuration[oiEventInterval]) {
        return [self execStatus:MPKitReturnCodeRequirementsNotMet];
    }

    _configuration = configuration;
    _started = YES;
    
    if (MPKitOptimizelyClient == nil) {
        static dispatch_once_t optimizelyPredicate;
        
        dispatch_once(&optimizelyPredicate, ^{
            OPTLYManager *manager = [[OPTLYManager alloc] initWithBuilder:[OPTLYManagerBuilder  builderWithBlock:^(OPTLYManagerBuilder * _Nullable builder) {
                
                NSString *sdkKey = self.configuration[oiAPIKey];
                NSNumber *eventInterval = self.configuration[oiEventInterval];
                
                builder.sdkKey = sdkKey;
                builder.eventDispatchInterval = [eventInterval doubleValue];
            }]];
            
            MPKitOptimizelyClient = [manager initialize];
            self->_started = YES;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSDictionary *userInfo = @{mParticleKitInstanceKey:[[self class] kitCode]};
                
                [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                                    object:nil
                                                                  userInfo:userInfo];
            });
        });
    }

    return [self execStatus:MPKitReturnCodeSuccess];
}

- (OPTLYVariation *)variationForExperimentKey:(nonnull NSString *)key {
    if (!MPKitOptimizelyClient) return nil;
    
    FilteredMParticleUser *currentUser = [[self kitApi] getCurrentUserWithKit:self];

    NSDictionary *transformedUserInfo = [currentUser.userIdentities transformValuesToString];
    
    return [MPKitOptimizelyClient activate:key
                     userId:[self userIDForOptimizely]
                 attributes:transformedUserInfo];
}

- (MPKitExecStatus *)logCommerceEvent:(MPCommerceEvent *)commerceEvent {
    MPKitExecStatus *execStatus = [self execStatus:MPKitReturnCodeSuccess];
    
    NSString *userID = [self userIDForOptimizely];
    NSArray *expandedInstructions = [commerceEvent expandedInstructions];
    
    for (MPCommerceEventInstruction *commerceEventInstruction in expandedInstructions) {
        if (commerceEventInstruction.instruction == MPCommerceInstructionTransaction) {
            NSMutableDictionary *baseProductAttributes = [[NSMutableDictionary alloc] init];
            
            NSDictionary<NSString *, __kindof NSArray<NSString *> *> *customFlags = commerceEvent.customFlags;
            
            NSString *customCommerceEventName;
            NSString *customCommerceTrackedValue;
            if (customFlags) {
                if (customFlags[optimizelyCustomEventName].count != 0) {
                    customCommerceEventName = customFlags[optimizelyCustomEventName][0];
                }
                if (customFlags[optimizelyTrackedValue].count != 0) {
                    customCommerceTrackedValue = customFlags[optimizelyTrackedValue][0];
                }
            }
            
            NSDictionary *transactionAttributes = commerceEventInstruction.event.info;
            
            if (transactionAttributes[kMPExpTARevenue] != nil) {
                [baseProductAttributes setObject:transactionAttributes[kMPExpTARevenue] forKey: @"revenue"];
            }
            
            if (customCommerceTrackedValue != nil && transactionAttributes[customCommerceTrackedValue]) {
                [baseProductAttributes setObject:transactionAttributes[customCommerceTrackedValue] forKey: @"value"];
            }
            
            if (transactionAttributes) {
                [baseProductAttributes addEntriesFromDictionary:transactionAttributes];
            }
            
            commerceEventInstruction.event.info = baseProductAttributes;
            if (customCommerceEventName) {
                commerceEventInstruction.event.name = customCommerceEventName;
            }
        }
        
        NSDictionary *transformedEventInfo = [commerceEventInstruction.event.info transformValuesToString];

        [MPKitOptimizelyClient track:commerceEventInstruction.event.name
                              userId:userID
                          attributes:transformedEventInfo];
        [execStatus incrementForwardCount];
    }
    
    return execStatus;
}

- (MPKitExecStatus *)logEvent:(MPEvent *)event {
    if (!MPKitOptimizelyClient) [self execStatus:MPKitReturnCodeFail];
    
    NSDictionary<NSString *, __kindof NSArray<NSString *> *> *customFlags = event.customFlags;
    
    NSString *customTrackedValue;
    if (customFlags) {
        if (customFlags[optimizelyTrackedValue].count != 0) {
            customTrackedValue = customFlags[optimizelyTrackedValue][0];
        }
    }
    
    NSMutableDictionary *baseProductAttributes = [[NSMutableDictionary alloc] init];
    NSDictionary *transactionAttributes = event.info;
    
    if (customTrackedValue != nil && transactionAttributes[customTrackedValue]) {
        [baseProductAttributes setObject:transactionAttributes[customTrackedValue] forKey: @"value"];
    }
    
    if (transactionAttributes) {
        [baseProductAttributes addEntriesFromDictionary:transactionAttributes];
    }
    
    NSDictionary *transformedEventInfo = [baseProductAttributes transformValuesToString];
    
    [MPKitOptimizelyClient track:event.name
                          userId:[self userIDForOptimizely]
                      attributes:transformedEventInfo];
    
    return [self execStatus:MPKitReturnCodeSuccess];
}

- (NSString *)userIDForOptimizely {
    FilteredMParticleUser *currentUser = [[self kitApi] getCurrentUserWithKit:self];
    
    NSString *userID = nil;
    if (currentUser != nil && self.configuration[oiUserIDKey] != nil) {
        NSString *key = self.configuration[oiUserIDKey];
        if (key == oiUserIDCustomerIDValue) {
            userID = currentUser.userIdentities[@(MPUserIdentityCustomerId)];
        } else if (key == oiUserIDEmailValue) {
            userID = currentUser.userIdentities[@(MPUserIdentityEmail)];
        } else if (key == oiUserIDMPIDValue) {
            userID = [currentUser.userId stringValue];
        }
    }
    return userID;
}

@end
