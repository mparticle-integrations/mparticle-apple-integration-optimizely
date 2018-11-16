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

#if defined(__has_include) && __has_include(<OptimizelySDKShared/OptimizelySDKShared.h>)
#import <OptimizelySDKShared/OptimizelySDKShared.h>
#else
#import "OptimizelySDKShared.h"
#endif

#endif

#if defined(__has_include) && __has_include(<OptimizelySDKDatafileManager/OPTLYDatafileManager.h>)
#import <OptimizelySDKDatafileManager/OPTLYDatafileManager.h>
#else
#import "OPTLYDatafileManager.h"
#endif



NSString *const optimizelyCustomEventName = @"Optimizely.EventName";
NSString *const optimizelyTrackedValue = @"Optimizely.Value";
NSString *const optimizelyCustomUserId = @"Optimizely.UserId";

@implementation MPKitOptimizely

static OPTLYClient *MPKitOptimizelyClient;

static NSString *const oiAPIKey = @"projectId";
static NSString *const oiEventInterval = @"eventInterval";
static NSString *const oiDataFileInterval = @"eventInterval";
static NSString *const oiuserIdKey = @"userIdField";

static NSString *const oiuserIdCustomerIDValue = @"customerId";
static NSString *const oiuserIdEmailValue = @"email";
static NSString *const oiuserIdMPIDValue = @"mpid";
static NSString *const oiuserIdDeviceStampValue = @"deviceApplicationStamp";

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
    NSString *sdkKey = configuration[oiAPIKey];
    if (!sdkKey) {
        return [self execStatus:MPKitReturnCodeRequirementsNotMet];
    }
    
    NSNumber *eventInterval = self.configuration[oiEventInterval];
    NSNumber *dataFileInterval = self.configuration[oiDataFileInterval];

    _configuration = configuration;
    
    if (MPKitOptimizelyClient == nil) {
        static dispatch_once_t optimizelyPredicate;
        
        dispatch_once(&optimizelyPredicate, ^{
            OPTLYDatafileManagerDefault *datafileManager;
            if (dataFileInterval != nil) {
                datafileManager =
                [[OPTLYDatafileManagerDefault alloc] initWithBuilder:[OPTLYDatafileManagerBuilder builderWithBlock:^(OPTLYDatafileManagerBuilder * _Nullable builder) {
                    builder.datafileConfig = [[OPTLYDatafileConfig alloc] initWithProjectId:nil withSDKKey:sdkKey];
                    builder.datafileFetchInterval = dataFileInterval != nil ? [dataFileInterval doubleValue] : 120.0;
                }]];
            }
            
            OPTLYManager *manager = [[OPTLYManager alloc] initWithBuilder:[OPTLYManagerBuilder  builderWithBlock:^(OPTLYManagerBuilder * _Nullable builder) {
                
                builder.sdkKey = sdkKey;
                if (datafileManager != nil) {
                    builder.datafileManager = datafileManager;
                }
                if (eventInterval != nil) {
                    builder.eventDispatchInterval = [eventInterval doubleValue];
                }
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
    } else {
        _started = YES;
    }

    return [self execStatus:MPKitReturnCodeSuccess];
}

- (id const)providerKitInstance {
    return [self started] ? self : nil;
}

- (OPTLYVariation *)variationForExperimentKey:(nonnull NSString *)key customUserId:(nullable NSString *)customUserID {
    if (!MPKitOptimizelyClient) return nil;
    
    FilteredMParticleUser *currentUser = [[self kitApi] getCurrentUserWithKit:self];
    NSString *userId = customUserID != nil ? customUserID : [self userIdForOptimizely:currentUser];
    
    if (!userId) {
        return nil;
    }

    NSDictionary *transformedUserInfo = [currentUser.userAttributes transformValuesToString];
    
    return [MPKitOptimizelyClient activate:key
                                    userId:userId
                 attributes:transformedUserInfo];
}

- (MPKitExecStatus *)logCommerceEvent:(MPCommerceEvent *)commerceEvent {
    MPKitExecStatus *execStatus = [self execStatus:MPKitReturnCodeSuccess];
    
    FilteredMParticleUser *currentUser = [[self kitApi] getCurrentUserWithKit:self];
    NSString *userId = [self userIdForOptimizely:currentUser];
    if (!userId) {
        return [self execStatus:MPKitReturnCodeFail];
    }
    NSArray *expandedInstructions = [commerceEvent expandedInstructions];
    NSDictionary<NSString *, __kindof NSArray<NSString *> *> *customFlags = commerceEvent.customFlags;
    
    for (MPCommerceEventInstruction *commerceEventInstruction in expandedInstructions) {
        NSMutableDictionary *baseProductAttributes = [[NSMutableDictionary alloc] init];

        if (commerceEventInstruction.event.type == MPEventTypeTransaction && [commerceEventInstruction.event.name isEqualToString:@"eCommerce - purchase - Total"]) {
            
            NSString *customCommerceEventName;
            if (customFlags) {
                if (customFlags[optimizelyCustomEventName].count != 0) {
                    customCommerceEventName = customFlags[optimizelyCustomEventName][0];
                }
            }
            
            NSDictionary *transactionAttributes = commerceEventInstruction.event.info;
            
            if (commerceEvent.transactionAttributes.revenue != nil) {
                NSNumber *revenueInCents = [NSNumber numberWithLong:[commerceEvent.transactionAttributes.revenue integerValue]*100];
                [baseProductAttributes setObject:revenueInCents forKey: @"revenue"];
            }
            
            if (transactionAttributes) {
                [baseProductAttributes addEntriesFromDictionary:transactionAttributes];
            }
            
            if (customCommerceEventName) {
                commerceEventInstruction.event.name = customCommerceEventName;
            }
        }
        
        if (customFlags) {
            if (customFlags[optimizelyCustomUserId].count != 0 & customFlags[optimizelyCustomUserId][0] != nil) {
                userId = customFlags[optimizelyCustomUserId][0];
            }
        }
                
        NSDictionary *transformedEventInfo = [baseProductAttributes transformValuesToString];

        [MPKitOptimizelyClient track:commerceEventInstruction.event.name
                              userId:userId
                          attributes:currentUser.userAttributes
                           eventTags:transformedEventInfo];
        [execStatus incrementForwardCount];
    }
    
    return execStatus;
}

- (MPKitExecStatus *)logEvent:(MPEvent *)event {
    if (!MPKitOptimizelyClient || !event) return [self execStatus:MPKitReturnCodeFail];
    
    FilteredMParticleUser *currentUser = [[self kitApi] getCurrentUserWithKit:self];
    NSString *userId = [self userIdForOptimizely:currentUser];
    
    if (!userId) {
        return [self execStatus:MPKitReturnCodeFail];
    }

    NSDictionary<NSString *, __kindof NSArray<NSString *> *> *customFlags = event.customFlags;
    
    NSString *customTrackedValue;
    if (customFlags) {
        if (customFlags[optimizelyTrackedValue].count != 0) {
            customTrackedValue = customFlags[optimizelyTrackedValue][0];
        }
        if (customFlags[optimizelyCustomUserId].count != 0 & customFlags[optimizelyCustomUserId][0] != nil) {
            userId = customFlags[optimizelyCustomUserId][0];
        }
    }
    
    NSMutableDictionary *baseProductAttributes = [[NSMutableDictionary alloc] init];
    NSDictionary *transactionAttributes = event.info;
    
    if (customTrackedValue != nil) {
        [baseProductAttributes setObject:customTrackedValue forKey: @"value"];
    }
    
    if (transactionAttributes) {
        [baseProductAttributes addEntriesFromDictionary:transactionAttributes];
    }
    
    NSDictionary *transformedEventInfo = [baseProductAttributes transformValuesToString];
    
    [MPKitOptimizelyClient track:event.name
                          userId:userId
                      attributes:currentUser.userAttributes
                       eventTags:transformedEventInfo];
    
    return [self execStatus:MPKitReturnCodeSuccess];
}

- (NSString *)userIdForOptimizely:(FilteredMParticleUser *)currentUser {
    NSString *userId = [[[MParticle sharedInstance] identity] deviceApplicationStamp];
    if (currentUser != nil && self.configuration[oiuserIdKey] != nil) {
        NSString *key = self.configuration[oiuserIdKey];
        if ([key isEqualToString:oiuserIdCustomerIDValue] && currentUser.userIdentities[@(MPUserIdentityCustomerId)] != nil) {
            userId = currentUser.userIdentities[@(MPUserIdentityCustomerId)];
        } else if ([key isEqualToString:oiuserIdEmailValue] && currentUser.userIdentities[@(MPUserIdentityEmail)] != nil) {
            userId = currentUser.userIdentities[@(MPUserIdentityEmail)];
        } else if ([key isEqualToString:oiuserIdMPIDValue] && currentUser.userId != nil) {
            userId = currentUser.userId != 0 ? [currentUser.userId stringValue] : @"0" ;
        } else if ([key isEqualToString:oiuserIdDeviceStampValue]) {
            userId = [[[MParticle sharedInstance] identity] deviceApplicationStamp];
        }
    }
    return userId;
}

@end
