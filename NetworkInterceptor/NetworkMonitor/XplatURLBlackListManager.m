//
//  XplatURLBlackListManager.m
//  NetworkInterceptor
//
//  Created by George Taskos on 7/15/14.
//  Copyright (c) 2014 Xplat Solutions. All rights reserved.
//

#import "XplatURLBlackListManager.h"
#import "NSString+Xplat.h"

@implementation XplatURLBlackListManager

+ (instancetype) sharedInstance
    {
    static XplatURLBlackListManager* sharedObject = nil;
    static dispatch_once_t onlyOnceToken;
    
    dispatch_once(&onlyOnceToken,
        ^{
        sharedObject = [[self alloc] init];
        });
    return sharedObject;
    }

- (id) init
    {
    if (self = [super init])
        {
        _urls = [NSMutableArray array];
        }
    return self;
    }

- (void) addURLToBlackList:(NSString*)url
    {
    if (![url isEqualToString:@""] &&
        ![_urls containsObject:url])
        {
        [_urls addObject:url];
        }
    }

- (BOOL) containsURL:(NSURL*)url
    {
    BOOL result = NO;
    if (url &&
        [url absoluteString])
        {
        NSString* path = [[NSString alloc] initWithString:[url absoluteString]];
        for (NSString* urlString in _urls)
            {
            if ([path containsString:urlString options:NSCaseInsensitiveSearch])
                {
                result = YES;
                break;
                }
            }
        }
    return result;
    }

@end
