//
//  XplatNSURLSessionDataTaskInfo.h
//  NetworkInterceptor
//
//  Created by George Taskos on 6/18/14.
//  Copyright (c) 2014 Xplat Solutions. All rights reserved.
//

@import Foundation;

@class NetworkModel;

typedef void (^DataTaskCompletionBlock)(NSData*, NSURLResponse*, NSError*);

@interface XplatNSURLSessionDataTaskInfo : NSObject

@property (strong, nonatomic) NSURLSessionDataTask* sessionDataTask;
@property (strong, nonatomic) NetworkModel* networkData;
@property (copy, nonatomic) DataTaskCompletionBlock completionHandler;
@property (assign, nonatomic) NSUInteger dataSize;
@property (copy, nonatomic) id key;

@end
