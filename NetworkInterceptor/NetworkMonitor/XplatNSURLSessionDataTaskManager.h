//
//  XplatNSURLSessionDataTaskManager.h
//  NetworkInterceptor
//
//  Created by George Taskos on 6/18/14.
//  Copyright (c) 2014 Xplat Solutions. All rights reserved.
//

@import Foundation;

#import "XplatNSURLSessionDataTaskInfo.h"

@interface XplatNSURLSessionDataTaskManager : NSObject

+ (instancetype) sharedInstance;

- (id) generateIdentifierForDataTask;
- (void) registerDataTaskInfo:(XplatNSURLSessionDataTaskInfo*)dataTaskInfo withIdentifier:(id)identifier;
- (XplatNSURLSessionDataTaskInfo*) dataTaskInfoForIdentifier:(id)identifier;
- (XplatNSURLSessionDataTaskInfo*) dataTaskInfoForTask:(NSURLSessionTask*)task;
- (void) removeDataTaskInfoForIdentifier:(id)identifier;
- (void) removeDataTaskInfoForTask:(NSURLSessionTask*)task;
- (void) recordStartTimeForSessionDataTask:(NSURLSessionDataTask*)dataTask;


@end
