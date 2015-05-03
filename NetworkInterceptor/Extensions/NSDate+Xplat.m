//
//  NSDate+Xplat.m
//  NetworkInterceptor
//
//  Created by George Taskos on 6/16/14.
//  Copyright (c) 2014 Xplat Solutions. All rights reserved.
//

#import <sys/time.h>

#import "NSDate+Xplat.h"

@implementation NSDate (Xplat)

+ (int64_t) nowAsMilliseconds
    {
    struct timeval t;
    gettimeofday(&t, NULL);
    
    return (((int64_t) t.tv_sec) * kXplatMillisecondsPerSecond) + (((int64_t) t.tv_usec) / kXplatMillisecondsPerSecond);
    }

- (int64_t) dateAsMilliseconds
    {
    return (int64_t) ([self timeIntervalSince1970] * kXplatMillisecondsPerSecond);
    }

+ (NSDate*) dateFromMilliseconds:(int64_t) milliseconds
    {
    return [NSDate dateWithTimeIntervalSince1970:(milliseconds / kXplatMillisecondsPerSecond)];
    }

+ (NSString *) stringFromMilliseconds:(int64_t) milliseconds
    {
    return [[NSNumber numberWithLongLong:milliseconds] stringValue];
    }

+ (NSString*) unixTimestampAsString
    {
    return [NSDate stringFromMilliseconds:[NSDate nowAsMilliseconds]];
    }

+ (int64_t) unixTimestampAsLong
    {
    return [self nowAsMilliseconds];
    }

@end
