//
//  POSilentInitParams.h
//  PingOneSignals
//
//  Copyright (c) 2022 PingIdentity. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "POInitParams.h"

NS_ASSUME_NONNULL_BEGIN

@interface POSilentInitParams : POInitParams

- (instancetype _Nonnull)__unavailable init;
- (instancetype _Nonnull)initWithEnvId:(NSString *_Nonnull)envId __attribute__((deprecated("Use POInitParams() instead")));

@end

NS_ASSUME_NONNULL_END
