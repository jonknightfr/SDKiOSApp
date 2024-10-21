//
//  POInitParams.h
//  PingOneSignals
//
//  Copyright (c) 2017 PingIdentity. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface POInitParams : NSObject

@property(nonatomic, copy) NSString *_Nullable envId;
@property(nonatomic, copy) NSArray<NSString *> *_Nullable deviceAttributesToIgnore;
@property(nonatomic) BOOL consoleLogEnabled;
@property(nonatomic, copy) NSString *_Nullable customHost;
@property(nonatomic) BOOL lazyMetadata;
@property(nonatomic) BOOL behavioralDataCollection;

@end
