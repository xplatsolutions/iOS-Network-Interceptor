//
//  NetworkInterceptorTests.m
//  NetworkInterceptor
//
//  Created by Georgios Taskos on 5/3/15.
//  Copyright (c) 2015 Xplat Solutions. All rights reserved.
//

#import "XplatNetworkMonitorClient.h"

#import <GRUnit/GRUnit.h>
#import <AFNetworking/AFNetworking.h>

@interface NetworkInterceptorTests : GRTestCase

@property (nonatomic, copy) dispatch_block_t completion;

@end

@implementation NetworkInterceptorTests

- (void)setUp {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkDataIntercepted:) name:kXPLNetworkMonitorNotification object:nil];
    [[XplatNetworkMonitorClient sharedInstance] startMonitoring];
}

- (void)tearDown {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) testNSURLConnectionWithCompletion:(dispatch_block_t)completion {
    self.completion = completion;
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:@"http://headers.jsontest.com/" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (void) testNSURLSessionWithCompletion:(dispatch_block_t)completion {
    self.completion = completion;
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithURL:[NSURL URLWithString:@"http://headers.jsontest.com/"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            NSLog(@"NSURLSession Response");
    }] resume];
}

- (void) networkDataIntercepted:(NSNotification*)notification {
    GRAssertNotNil(notification);
    if (notification) {
        GRAssertNotNil(notification.userInfo);
        if (notification.userInfo) {
            NetworkModel* networkData = [notification.userInfo objectForKey:kXPLNetworkMonitorDataKey];
            GRAssertNotNil(networkData);
            if (networkData) {
                NSLog(@"%@", networkData.description);
                self.completion();
            }
        }
    }
}

@end
