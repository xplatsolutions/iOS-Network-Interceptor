//
//  XplatNSURLSessionDownloadTaskManager.h
//  NetworkInterceptor
//
//  Created by George Taskos on 11/20/14.
//  Copyright (c) 2014 Xplat Solutions. All rights reserved.
//

@import Foundation;

#import "XplatNSURLSessionDownloadTaskInfo.h"

@interface XplatNSURLSessionDownloadTaskManager : NSObject

+ (instancetype) sharedInstance;

- (id) generateIdentifierForDownloadTask;
- (void) registerDownloadTaskInfo:(XplatNSURLSessionDownloadTaskInfo*)downloadTaskInfo withIdentifier:(id)identifier;
- (XplatNSURLSessionDownloadTaskInfo*) downloadTaskInfoForIdentifier:(id)identifier;
- (XplatNSURLSessionDownloadTaskInfo*) downloadTaskInfoForTask:(NSURLSessionTask*)task;
- (void) removeDownloadTaskInfoForIdentifier:(id)identifier;
- (void) removeDownloadTaskInfoForTask:(NSURLSessionTask*)task;
- (void) recordStartTimeForSessionDownloadTask:(NSURLSessionDownloadTask*)downloadTask;

@end
