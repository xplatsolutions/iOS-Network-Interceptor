//
//  NSMutableURLRequest+Xplat.h
//  NetworkInterceptor
//
//  Created by George Taskos on 6/24/14.
//  Copyright (c) 2014 Xplat Solutions. All rights reserved.
//

@import Foundation;

@interface NSMutableURLRequest (Xplat)

@property (nonatomic, assign, readonly) BOOL isXplatRequest;

- (void) addXplatHeader;
- (void) removeXplatHeader;

@end
