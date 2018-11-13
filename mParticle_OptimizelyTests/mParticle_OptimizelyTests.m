//
//  mParticle_OptimizelyTests.m
//  mParticle_OptimizelyTests
//
//  Created by Brandon Stalnaker on 10/23/18.
//  Copyright © 2018 mparticle. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MPKitOptimizely.h"
#if TARGET_OS_IOS == 1
#import <OptimizelySDKiOS/OptimizelySDKiOS.h>
#elif TARGET_OS_TV == 1
#import <OptimizelySDKTVOS/OptimizelySDKTVOS.h>
#endif


NSString *const eabAPIKey = @"sdk_key";
NSString *const eabEventInterval = @"event_interval";
NSString *const eabUserIDKey = @"userIdField";

@interface mParticle_OptimizelyTests : XCTestCase

@end

@implementation mParticle_OptimizelyTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testLaunch {
    NSDictionary *configuration = @{
                                    @"id":@42,
                                    eabAPIKey:@"274279246429244297",
                                    eabEventInterval:@23,
                                    @"as":@{
                                            @"appId":@"MyAppId"
                                            }
                                    };
    
    MPKitOptimizely *kitInstance = [[MPKitOptimizely alloc] init];
    
    MPKitExecStatus *execStatus = [kitInstance didFinishLaunchingWithConfiguration:configuration];
    
    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);
}

- (void)testLaunchFailure {
    NSDictionary *configuration = @{
                                    @"id":@42,
                                    eabEventInterval:@23,
                                    @"as":@{
                                            @"appId":@"MyAppId"
                                            }
                                    };
    
    MPKitOptimizely *kitInstance = [[MPKitOptimizely alloc] init];
    
    MPKitExecStatus *execStatus = [kitInstance didFinishLaunchingWithConfiguration:configuration];
    
    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeRequirementsNotMet);
}

- (void)testManualClient {
    OPTLYClient *testClient = [[OPTLYClient alloc] init];
    [MPKitOptimizely setOptimizelyClient:testClient];
    
    NSDictionary *configuration = @{
                                    @"id":@42,
                                    eabAPIKey:@"274279246429244297",
                                    eabEventInterval:@23,
                                    @"as":@{
                                            @"appId":@"MyAppId"
                                            }
                                    };
    
    MPKitOptimizely *kitInstance = [[MPKitOptimizely alloc] init];
    
    MPKitExecStatus *execStatus = [kitInstance didFinishLaunchingWithConfiguration:configuration];
    
    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);
    XCTAssertEqualObjects(testClient, [MPKitOptimizely optimizelyClient]);
}

@end
