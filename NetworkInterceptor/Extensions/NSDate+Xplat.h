//
//  NSDate+Xplat.h
//  NetworkInterceptor
//
//  Created by George Taskos on 6/16/14.
//  Copyright (c) 2014 Xplat Solutions. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kXplatMillisecondsPerSecond 1000

@interface NSDate (Xplat)

+ (int64_t) nowAsMilliseconds;
- (int64_t) dateAsMilliseconds;
+ (NSDate *) dateFromMilliseconds:(int64_t) milliseconds;
+ (NSString *) stringFromMilliseconds:(int64_t) milliseconds;
+ (NSString*) unixTimestampAsString;
+ (int64_t) unixTimestampAsLong;

@end
