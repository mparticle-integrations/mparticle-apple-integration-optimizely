#import <XCTest/XCTest.h>
#import "MPKitOptimizely.h"
#import <OCMock/OCMock.h>
#if TARGET_OS_IOS == 1
#import <OptimizelySDKiOS/OptimizelySDKiOS.h>
#elif TARGET_OS_TV == 1
#import <OptimizelySDKTVOS/OptimizelySDKTVOS.h>
#endif
#if defined(__has_include) && __has_include(<mParticle_Apple_SDK/mParticle.h>)
#import <mParticle_Apple_SDK/mParticle.h>
#else
#import "mParticle.h"
#endif

static NSString *const oiAPIKey = @"projectId";
static NSString *const oiEventInterval = @"eventInterval";
static NSString *const oiDataFileInterval = @"eventInterval";
static NSString *const oiuserIdKey = @"userIdField";

static NSString *const oiuserIdCustomerIDValue = @"customerId";
static NSString *const oiuserIdEmailValue = @"email";
static NSString *const oiuserIdMPIDValue = @"mpid";
static NSString *const oiuserIdDeviceStampValue = @"deviceApplicationStamp";

@interface mParticle_Optimizely_tvOSTests : XCTestCase

@end

@implementation mParticle_Optimizely_tvOSTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testStarted {
    MPKitOptimizely *exampleKit = [[MPKitOptimizely alloc] init];
    [exampleKit didFinishLaunchingWithConfiguration:@{oiAPIKey:@"12345", oiEventInterval:@12345}];
    XCTAssertTrue(exampleKit.started);
}

@end
