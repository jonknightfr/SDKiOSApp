//
//  PingOneSignals.h
//  PingOneSignals
//
//  Copyright (c) 2017 PingIdentity. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "POInitParams.h"
#import "POSilentInitParams.h"

@interface PingOneSignals : NSObject

- (instancetype _Nonnull)__unavailable init;

+ (instancetype _Nonnull)initSDK:(POInitParams *_Nullable)initParams NS_SWIFT_NAME(initSDK(initParams:));

+ (instancetype _Nonnull)initSilent:(POSilentInitParams *_Nonnull)silentInitParams __attribute__((deprecated("Use initSDK instead")));

+ (PingOneSignals *_Nullable)sharedInstance;

- (void)pauseBehavioralData;

- (void)resumeBehavioralData;

- (void)sendEvent:(UIEvent *_Nullable)event NS_SWIFT_NAME(send(event:));

- (void)setTokenReadyListener:(void (^_Nonnull)(void))listener;

- (void)setInitCallback:(void (^_Nonnull)(NSError *_Nullable error))callback;

- (NSString *_Nonnull)getToken;

- (NSString *_Nonnull)getInstanceUUID;

- (void)getData:(void (^_Nonnull)(NSString *_Nullable data, NSError *_Nullable error))getDataCallback;

@end
