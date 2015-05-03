//
//  XplatNSURLSessionDataTaskManager.m
//  NetworkInterceptor
//
//  Created by George Taskos on 6/18/14.
//  Copyright (c) 2014 Xplat Solutions. All rights reserved.
//

#import "XplatNSURLSessionDataTaskManager.h"
#import "NetworkModel.h"

@interface XplatNSURLSessionDataTaskManager ()

@property (strong) NSMutableDictionary* registeredDataTasks;
@property (strong) NSRecursiveLock* recursiveLock;

@end

@implementation XplatNSURLSessionDataTaskManager

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
        _registeredDataTasks = [NSMutableDictionary dictionary];
        }
    return self;
    }

#pragma mark -
#pragma mark Public Methods

- (id) generateIdentifierForDataTask
    {
    NSDate* identifier = nil;
    
    [self.recursiveLock lock];
    identifier = [NSDate date];
    [self.recursiveLock unlock];
    
    return identifier;
    }

- (void) registerDataTaskInfo:(XplatNSURLSessionDataTaskInfo*)dataTaskInfo withIdentifier:(id)identifier
    {
    [self.recursiveLock lock];
    [self.registeredDataTasks setObject:dataTaskInfo forKey:identifier];
    [self.recursiveLock unlock];
    }

- (XplatNSURLSessionDataTaskInfo*) dataTaskInfoForIdentifier:(id)identifier
    {
    XplatNSURLSessionDataTaskInfo* sessionDataTaskInfo = nil;
    
    [self.recursiveLock lock];
    sessionDataTaskInfo = [self.registeredDataTasks objectForKey:identifier];
    [self.recursiveLock unlock];
    
    return sessionDataTaskInfo;
    }

- (XplatNSURLSessionDataTaskInfo*) dataTaskInfoForTask:(NSURLSessionTask*)task
    {
    XplatNSURLSessionDataTaskInfo* sessionDataTaskInfo = nil;
    
    [self.recursiveLock lock];
    NSArray* allDataTaskInfos = [self.registeredDataTasks allValues];
    for (XplatNSURLSessionDataTaskInfo* dataTaskInfo in allDataTaskInfos)
        {
        if (dataTaskInfo.sessionDataTask == task)
            {
            sessionDataTaskInfo = dataTaskInfo;
            break;
            }
        }
    [self.recursiveLock unlock];
    return sessionDataTaskInfo;
    }

- (void) removeDataTaskInfoForIdentifier:(id)identifier
    {
    [self.recursiveLock lock];
    [self.registeredDataTasks removeObjectForKey:identifier];
    [self.recursiveLock unlock];
    }

- (void) removeDataTaskInfoForTask:(NSURLSessionTask *)task
    {
    [self.recursiveLock lock];
    NSArray* allDataTaskInfos = [self.registeredDataTasks allValues];
    for (XplatNSURLSessionDataTaskInfo* dataTaskInfo in allDataTaskInfos)
        {
        if (dataTaskInfo.sessionDataTask == task)
            {
            [self.registeredDataTasks removeObjectForKey:dataTaskInfo.key];
            break;
            }
        }
    [self.recursiveLock unlock];
    }

- (void) recordStartTimeForSessionDataTask:(NSURLSessionDataTask *)dataTask
    {
    if (dataTask)
        {
        [self.recursiveLock lock];
        NSArray* dataTaskInfoKeys = [self.registeredDataTasks allKeys];
        
        for (NSDate* date in dataTaskInfoKeys)
            {
            XplatNSURLSessionDataTaskInfo* dataTaskInfo = [self.registeredDataTasks objectForKey:date];
            if (dataTaskInfo && (dataTaskInfo.sessionDataTask == dataTask))
                {
                [dataTaskInfo.networkData appendStartTime];
                [self.recursiveLock unlock];
                return;
                }
            }
        [self.recursiveLock unlock];
        }
    }

@end
