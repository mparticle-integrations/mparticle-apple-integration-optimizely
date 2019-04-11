#import <Foundation/Foundation.h>
#if defined(__has_include) && __has_include(<mParticle_Apple_SDK/mParticle.h>)
#import <mParticle_Apple_SDK/mParticle.h>
#else
#import "mParticle.h"
#endif

extern NSString * _Nonnull const optimizelyCustomEventName;
extern NSString * _Nonnull const optimizelyTrackedValue;
extern NSString * _Nonnull const optimizelyCustomUserId;

@class OPTLYClient;
@class OPTLYVariation;

extern NSString * _Nonnull const MPKitOptimizelyEventName;
extern NSString * _Nonnull const MPKitOptimizelyEventKeyValue;

@interface MPKitOptimizely : NSObject <MPKitProtocol>

@property (nonatomic, strong, nonnull) NSDictionary *configuration;
@property (nonatomic, strong, nullable) NSDictionary *launchOptions;
@property (nonatomic, unsafe_unretained, readonly) BOOL started;
@property (nonatomic, strong, nullable) MPKitAPI *kitApi;

- (OPTLYVariation *_Nullable)variationForExperimentKey:(nonnull NSString *)key customUserId:(nullable NSString *)customUserID;
+ (OPTLYClient *_Nullable)optimizelyClient;
+ (void)setOptimizelyClient:(OPTLYClient *_Nullable)client;
@end
