#import "MPKitOptimizely.h"

#if defined(__has_include) && __has_include(<Optimizely/Optimizely-Swift.h>)
#import <Optimizely/Optimizely-Swift.h>
#elif defined(__has_include) && __has_include(<Optimizely-Swift.h>)
#import "Optimizely-Swift.h"
#elif defined(__has_include) && __has_include(<Optimizely/Optimizely.h>)
#import <Optimizely/Optimizely.h>
#elif defined(__has_include) && __has_include(<Optimizely.h>)
#import "Optimizely.h"
#else
@import Optimizely;
#endif

NSString *const optimizelyCustomEventName = @"Optimizely.EventName";
NSString *const optimizelyTrackedValue = @"Optimizely.Value";
NSString *const optimizelyCustomUserId = @"Optimizely.UserId";

@implementation MPKitOptimizely

static OptimizelyClient *optimizelyClient;

static NSString *const oiAPIKey = @"projectId";
static NSString *const oiEventInterval = @"eventInterval";
static NSString *const oiDataFileInterval = @"datafileInterval";
static NSString *const oiuserIdKey = @"userIdField";

static NSString *const oiuserIdCustomerIDValue = @"customerId";
static NSString *const oiuserIdEmailValue = @"email";
static NSString *const oiuserIdOther = @"otherid";
static NSString *const oiuserIdOther2 = @"otherid2";
static NSString *const oiuserIdOther3 = @"otherid3";
static NSString *const oiuserIdOther4 = @"otherid4";
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

+ (OptimizelyClient *)optimizelyClient {
    return optimizelyClient;
}

+ (void)setOptimizelyClient:(OptimizelyClient *)client {
    if (client != nil) {
        optimizelyClient = client;
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
    
    _configuration = configuration;
    
    if (optimizelyClient == nil) {
        optimizelyClient = [[OptimizelyClient alloc] initWithSdkKey:sdkKey];
        
        self->_started = YES;
        NSDictionary *userInfo = @{mParticleKitInstanceKey:[[self class] kitCode]};
        
        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                            object:nil
                                                          userInfo:userInfo];
    } else {
        _started = YES;
    }
    
    return [self execStatus:MPKitReturnCodeSuccess];
}

- (id const)providerKitInstance {
    return [self started] ? self : nil;
}

- (NSString *)activateWithExperimentKey:(nonnull NSString *)key customUserId:(nullable NSString *)customUserID {
    if (!optimizelyClient) return nil;
    
    FilteredMParticleUser *currentUser = [[self kitApi] getCurrentUserWithKit:self];
    NSString *userId = customUserID != nil ? customUserID : [self userIdForOptimizely:currentUser];
    
    if (!userId) {
        return nil;
    }
    
    NSDictionary *transformedUserInfo = [currentUser.userAttributes transformValuesToString];
    
    return [optimizelyClient activateWithExperimentKey:key userId:userId attributes:transformedUserInfo error:nil];
}

- (MPKitExecStatus *)logBaseEvent:(MPBaseEvent *)event {
    if ([event isKindOfClass:[MPEvent class]]) {
        return [self routeEvent:(MPEvent *)event];
    } else if ([event isKindOfClass:[MPCommerceEvent class]]) {
        return [self routeCommerceEvent:(MPCommerceEvent *)event];
    } else {
        return [self execStatus:MPKitReturnCodeFail];
    }
}

- (MPKitExecStatus *)routeCommerceEvent:(MPCommerceEvent *)commerceEvent {
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
            
            NSDictionary *transactionAttributes = commerceEventInstruction.event.customAttributes;
            
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
        
        [optimizelyClient trackWithEventKey:commerceEventInstruction.event.name userId:userId attributes:currentUser.userAttributes eventTags:transformedEventInfo error:nil];
        [execStatus incrementForwardCount];
    }
    
    return execStatus;
}

- (MPKitExecStatus *)routeEvent:(MPEvent *)event {
    if (!optimizelyClient || !event) return [self execStatus:MPKitReturnCodeFail];
    
    FilteredMParticleUser *currentUser = [[self kitApi] getCurrentUserWithKit:self];
    NSString *userId = [self userIdForOptimizely:currentUser];
    
    if (!userId) {
        return [self execStatus:MPKitReturnCodeFail];
    }
    
    NSDictionary<NSString *, __kindof NSArray<NSString *> *> *customFlags = event.customFlags;
    
    NSString *customEventName;
    NSString *customTrackedValue;
    if (customFlags) {
        if (customFlags[optimizelyCustomEventName].count != 0) {
            customEventName = customFlags[optimizelyCustomEventName][0];
        }
        if (customFlags[optimizelyTrackedValue].count != 0) {
            customTrackedValue = customFlags[optimizelyTrackedValue][0];
        }
        if (customFlags[optimizelyCustomUserId].count != 0 & customFlags[optimizelyCustomUserId][0] != nil) {
            userId = customFlags[optimizelyCustomUserId][0];
        }
    }
    
    NSMutableDictionary *baseProductAttributes = [[NSMutableDictionary alloc] init];
    NSDictionary *transactionAttributes = event.customAttributes;
    
    if (customEventName != nil) {
        event.name = customEventName;
    }
    
    if (customTrackedValue != nil) {
        [baseProductAttributes setObject:customTrackedValue forKey: @"value"];
    }
    
    if (transactionAttributes) {
        [baseProductAttributes addEntriesFromDictionary:transactionAttributes];
    }
    
    NSDictionary *transformedEventInfo = [baseProductAttributes transformValuesToString];
    
    [optimizelyClient trackWithEventKey:event.name userId:userId attributes:currentUser.userAttributes eventTags:transformedEventInfo error:nil];
    
    MPKitExecStatus *execStatus = [self execStatus:MPKitReturnCodeSuccess];
    return execStatus;
}

- (NSString *)userIdForOptimizely:(FilteredMParticleUser *)currentUser {
    NSString *userId = [[[MParticle sharedInstance] identity] deviceApplicationStamp];
    if (currentUser != nil && self.configuration[oiuserIdKey] != nil) {
        NSString *key = self.configuration[oiuserIdKey];
        if ([key isEqualToString:oiuserIdCustomerIDValue] && currentUser.userIdentities[@(MPUserIdentityCustomerId)] != nil) {
            userId = currentUser.userIdentities[@(MPUserIdentityCustomerId)];
        } else if ([key isEqualToString:oiuserIdEmailValue] && currentUser.userIdentities[@(MPUserIdentityEmail)] != nil) {
            userId = currentUser.userIdentities[@(MPUserIdentityEmail)];
        } else if ([key isEqualToString:oiuserIdOther] && currentUser.userIdentities[@(oiuserIdOther)] != nil) {
            userId = currentUser.userIdentities[@(MPUserIdentityOther)];
        } else if ([key isEqualToString:oiuserIdOther2] && currentUser.userIdentities[@(oiuserIdOther2)] != nil) {
            userId = currentUser.userIdentities[@(MPUserIdentityOther2)];
        } else if ([key isEqualToString:oiuserIdOther3] && currentUser.userIdentities[@(oiuserIdOther3)] != nil) {
            userId = currentUser.userIdentities[@(MPUserIdentityOther3)];
        } else if ([key isEqualToString:oiuserIdOther4] && currentUser.userIdentities[@(oiuserIdOther4)] != nil) {
            userId = currentUser.userIdentities[@(MPUserIdentityOther4)];
        } else if ([key isEqualToString:oiuserIdMPIDValue] && currentUser.userId != nil) {
            userId = currentUser.userId != 0 ? [currentUser.userId stringValue] : @"0" ;
        } else if ([key isEqualToString:oiuserIdDeviceStampValue]) {
            userId = [[[MParticle sharedInstance] identity] deviceApplicationStamp];
        }
    }
    return userId;
}

@end
