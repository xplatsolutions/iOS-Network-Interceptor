//
//  NSString+Xplat.h
//  NetworkInterceptor
//
//  Created by G.Tas on 11/5/13.
//  Copyright (c) 2013 Xplat Solutions. All rights reserved.
//

@import Foundation;

@interface NSString (Xplat)

- (BOOL)containsString:(NSString *)string;
- (BOOL)containsString:(NSString *)string options:(NSStringCompareOptions)options;
- (NSNumber*) toNSNumber;
- (NSInteger) indexOf: (NSString*)text;
- (NSString*) uriEncoded;
- (NSString*) uriDecoded;

@end
