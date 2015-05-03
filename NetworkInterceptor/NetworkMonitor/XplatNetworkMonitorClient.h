//
//  XplatNetworkMonitorClient.h
//  NetworkInterceptor
//
//  Created by George Taskos on 6/13/14.
//  Copyright (c) 2014 Xplat Solutions. All rights reserved.
//

@import Foundation;

#import "NetworkModel.h"

@interface XplatNetworkMonitorClient : NSObject

extern NSString* const kXPLNetworkMonitorNotification;
extern NSString* const kXPLNetworkMonitorDataKey;

+ (instancetype) sharedInstance;

- (void) startMonitoring;
- (void) notifyObserverWithNetworkData:(NetworkModel*)networkData;

@end
