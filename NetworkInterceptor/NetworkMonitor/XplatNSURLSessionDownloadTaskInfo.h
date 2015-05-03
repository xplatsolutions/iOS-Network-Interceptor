//
//  XplatNSURLSessionDownloadTaskInfo.h
//  NetworkInterceptor
//
//  Created by George Taskos on 11/20/14.
//  Copyright (c) 2014 Xplat Solutions. All rights reserved.
//

@import Foundation;

@class NetworkModel;

@interface XplatNSURLSessionDownloadTaskInfo : NSObject

typedef void (^DownloadTaskCompletionBlock)(NSURL*, NSURLResponse*, NSError*);

@property (strong, nonatomic) NSURLSessionDownloadTask* sessionDownloadTask;
@property (strong, nonatomic) NetworkModel* networkData;
@property (copy, nonatomic) DownloadTaskCompletionBlock completionHandler;
@property (assign, nonatomic) NSUInteger dataSize;
@property (copy, nonatomic) id key;

@end
