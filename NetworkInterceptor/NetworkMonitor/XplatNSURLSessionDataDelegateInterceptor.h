//
//  XplatNSURLSessionDataDelegateInterceptor.h
//  NetworkInterceptor
//
//  Created by George Taskos on 6/18/14.
//  Copyright (c) 2014 Xplat Solutions. All rights reserved.
//

@import Foundation;

@interface XplatNSURLSessionDataDelegateInterceptor : NSObject <NSURLSessionDelegate, NSURLSessionDataDelegate>//, NSURLSessionDownloadDelegate>

- (id) initAndInterceptFor: (id)target;

@end
