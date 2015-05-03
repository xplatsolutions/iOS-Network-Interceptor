//
//  NetworkModel.h
//  NetworkInterceptor
//
//  Created by G.Tas on 3/6/14.
//  Copyright (c) 2014 Xplat Solutions. All rights reserved.
//

@import Foundation;

@interface NetworkModel : NSObject

@property (nonatomic, strong) NSString* url;
@property (nonatomic, strong) NSString* protocol;
@property (nonatomic, strong) NSNumber* endTime;
@property (nonatomic, strong) NSNumber* duration;
@property (nonatomic, strong) NSNumber* statusCode;
@property (nonatomic, strong) NSNumber* contentLength;
@property (nonatomic, strong) NSNumber* requestLength;
@property (nonatomic, assign) BOOL failed;
@property (nonatomic, strong) NSMutableDictionary* reqHeaders;
@property (nonatomic, strong) NSMutableDictionary* respHeaders;
@property (nonatomic, strong) NSString* exception;
@property (nonatomic, strong) NSNumber* responseLength;
@property (nonatomic, strong) NSNumber* latency;
@property (nonatomic, strong) NSDate* startNetTime;
@property (nonatomic, strong) NSDate* endNetTime;
@property (nonatomic, strong) NSString* startTime;

- (void) appendWithStatusCode: (NSNumber*)statusCode;
- (void) appendStartTime;
- (void) appendEndTime;
- (void) appendRequestInfo:(NSURLRequest*)request;
- (void) appendResponseInfo:(NSURLResponse*)response;
- (void) appendResponseData:(NSData*)data;
- (void) appendResponseDataSize:(NSUInteger)dataSize;
- (void) appendWithError:(NSError*)error;
- (void) debugPrint;

@end
