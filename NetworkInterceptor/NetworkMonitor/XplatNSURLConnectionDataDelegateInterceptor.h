//
//  XplatNSURLConnectionDataDelegateInterceptor.h
//  NetworkInterceptor
//
//  Created by George Taskos on 6/17/14.
//  Copyright (c) 2014 Xplat Solutions. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XplatNSURLConnectionDataDelegateInterceptor : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate, NSURLConnectionDownloadDelegate>

@property (assign) BOOL isConnectionAlive;

- (id) initAndInterceptFor:(id)target withRequest:(NSURLRequest*)request;
- (void) recordStartTime;

@end
