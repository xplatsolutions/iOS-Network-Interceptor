//
//  XplatNSURLSessionDownloadTaskManager.m
//  NetworkInterceptor
//
//  Created by George Taskos on 11/20/14.
//  Copyright (c) 2014 Xplat Solutions. All rights reserved.
//

#import "XplatNSURLSessionDownloadTaskManager.h"
#import "NetworkModel.h"

@interface XplatNSURLSessionDownloadTaskManager ()

@property (strong) NSMutableDictionary* registeredDownloadTasks;
@property (strong) NSRecursiveLock* recursiveLock;

@end

@implementation XplatNSURLSessionDownloadTaskManager

#pragma mark - 
#pragma mark Singleton

+ (instancetype) sharedInstance
    {
    static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,
        ^{
        _sharedInstance = [[self alloc] init];
        });
    return _sharedInstance;
    }

#pragma mark -
#pragma mark Initialization

- (id) init
    {
    if (self = [super init])
        {
        _recursiveLock = [NSRecursiveLock new];
        _registeredDownloadTasks = [NSMutableDictionary dictionary];
        }
    return self;
    }

#pragma mark -
#pragma mark Public Methods

- (id) generateIdentifierForDownloadTask
    {
    NSDate* identifier = nil;
    
    [self.recursiveLock lock];
    identifier = [NSDate date];
    [self.recursiveLock unlock];
    
    return identifier;
    }

- (void) registerDownloadTaskInfo:(XplatNSURLSessionDownloadTaskInfo*)downloadTaskInfo withIdentifier:(id)identifier
    {
    [self.recursiveLock lock];
    [self.registeredDownloadTasks setObject:downloadTaskInfo forKey:identifier];
    [self.recursiveLock unlock];
    }

- (XplatNSURLSessionDownloadTaskInfo*) downloadTaskInfoForIdentifier:(id)identifier
    {
    XplatNSURLSessionDownloadTaskInfo* sessionDownloadTaskInfo = nil;
    
    [self.recursiveLock lock];
    sessionDownloadTaskInfo = [self.registeredDownloadTasks objectForKey:identifier];
    [self.recursiveLock unlock];
    
    return sessionDownloadTaskInfo;
    }

- (XplatNSURLSessionDownloadTaskInfo*) downloadTaskInfoForTask:(NSURLSessionTask*)task
    {
    XplatNSURLSessionDownloadTaskInfo* sessionDownloadTaskInfo = nil;
    
    [self.recursiveLock lock];
    NSArray* allDataTaskInfos = [self.registeredDownloadTasks allValues];
    for (XplatNSURLSessionDownloadTaskInfo* dataTaskInfo in allDataTaskInfos)
        {
        if (dataTaskInfo.sessionDownloadTask == task)
            {
            sessionDownloadTaskInfo = dataTaskInfo;
            break;
            }
        }
    [self.recursiveLock unlock];
    return sessionDownloadTaskInfo;
    }

- (void) removeDownloadTaskInfoForIdentifier:(id)identifier
    {
    [self.recursiveLock lock];
    [self.registeredDownloadTasks removeObjectForKey:identifier];
    [self.recursiveLock unlock];
    }

- (void) removeDownloadTaskInfoForTask:(NSURLSessionTask *)task
    {
    [self.recursiveLock lock];
    NSArray* allDownloadTaskInfos = [self.registeredDownloadTasks allValues];
    for (XplatNSURLSessionDownloadTaskInfo* downloadTaskInfo in allDownloadTaskInfos)
        {
        if (downloadTaskInfo.sessionDownloadTask == task)
            {
            [self.registeredDownloadTasks removeObjectForKey:downloadTaskInfo.key];
            break;
            }
        }
    [self.recursiveLock unlock];
    }

- (void) recordStartTimeForSessionDownloadTask:(NSURLSessionDownloadTask *)downloadTask
    {
    if (downloadTask)
        {
        [self.recursiveLock lock];
        NSArray* downloadTaskInfoKeys = [self.registeredDownloadTasks allKeys];
        
        for (NSDate* date in downloadTaskInfoKeys)
            {
            XplatNSURLSessionDownloadTaskInfo* downloadTaskInfo = [self.registeredDownloadTasks objectForKey:date];
            if (downloadTaskInfo && (downloadTaskInfo.sessionDownloadTask == downloadTask))
                {
                [downloadTaskInfo.networkData appendStartTime];
                [self.recursiveLock unlock];
                return;
                }
            }
        [self.recursiveLock unlock];
        }
    }

@end
