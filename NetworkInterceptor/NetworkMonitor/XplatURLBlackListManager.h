//
//  XplatURLBlackListManager.h
//  NetworkInterceptor
//
//  Created by George Taskos on 7/15/14.
//  Copyright (c) 2014 Xplat Solutions. All rights reserved.
//

@import Foundation;

@interface XplatURLBlackListManager : NSObject

+ (instancetype) sharedInstance;

- (void) addURLToBlackList:(NSString*)url;
- (BOOL) containsURL:(NSURL*)url;

@property (strong, nonatomic) NSMutableArray* urls;

@end
