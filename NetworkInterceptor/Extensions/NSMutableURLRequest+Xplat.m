//
//  NSMutableURLRequest+Xplat.m
//  NetworkInterceptor
//
//  Created by George Taskos on 6/24/14.
//  Copyright (c) 2014 Xplat Solutions. All rights reserved.
//

#import "NSMutableURLRequest+Xplat.h"

@implementation NSMutableURLRequest (Xplat)

static NSString* XplatHeader = @"X-XplatSolutions";

- (void) addXplatHeader
    {
    [self setValue:@"XplatMonitorRequest" forHTTPHeaderField:XplatHeader];
    }

- (void) removeXplatHeader
    {
    [self setValue:nil forHTTPHeaderField:XplatHeader];
    }

- (BOOL) isXplatRequest
    {
    return [self valueForHTTPHeaderField:XplatHeader] != nil;
    }

@end
