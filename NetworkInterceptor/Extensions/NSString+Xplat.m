//
//  NSString+Xplat.m
//  NetworkInterceptor
//
//  Created by G.Tas on 11/5/13.
//  Copyright (c) 2013 Xplat Solutions. All rights reserved.
//

#import "NSString+Xplat.h"

@implementation NSString (Xplat)

- (BOOL) containsString: (NSString*)string options: (NSStringCompareOptions)options
    {
    NSRange rng = [self rangeOfString:string options:options];
    return rng.location != NSNotFound;
    }

- (BOOL) containsString: (NSString*)string
    {
    return [self containsString:string options:0];
    }

- (NSNumber*) toNSNumber
    {
    NSNumberFormatter* numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    NSNumber* errorId = [numberFormatter numberFromString:self];
    return errorId;
    }
    
- (NSInteger) indexOf: (NSString*)text
    {
    NSRange range = [self rangeOfString:text];
    if (range.length > 0)
        {
        return range.location;
        }
    else
        {
        return -1;
        }
    }

- (NSString*) uriEncoded
    {
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self, NULL, CFSTR(":/?#[]@!$&’()*+,;="), kCFStringEncodingUTF8));
    }

- (NSString*) uriDecoded
    {
    return (NSString*) CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, (CFStringRef)self, CFSTR(""), kCFStringEncodingUTF8));
    }

@end
