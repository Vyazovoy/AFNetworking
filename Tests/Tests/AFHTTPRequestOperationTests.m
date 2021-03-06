// AFHTTPRequestOperationTests.m
//
// Copyright (c) 2013 AFNetworking (http://afnetworking.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "AFTestCase.h"

#import "AFHTTPRequestOperation.h"

@interface AFHTTPRequestOperationTests : AFTestCase
@end

@implementation AFHTTPRequestOperationTests

- (void)testThatOperationInvokesSuccessCompletionBlockWithResponseObjectOnSuccess {
    __block id blockResponseObject = nil;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/get" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    // AFHTTPOperation currently does not have a default response serializer
    [operation setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        blockResponseObject = responseObject;
    } failure:nil];
    
    [operation start];

    expect([operation isFinished]).will.beTruthy();
    expect(blockResponseObject).willNot.beNil();
}

- (void)testThatOperationInvokesFailureCompletionBlockWithErrorOnFailure {
    __block NSError *blockError = nil;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/status/404" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    // AFHTTPOperation currently does not have a default response serializer
    [operation setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    
    [operation setCompletionBlockWithSuccess:nil failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        blockError = error;
    }];
    
    [operation start];
    expect([operation isFinished]).will.beTruthy();
    expect(blockError).willNot.beNil();
}

- (void)testThatCancellationOfRequestOperationSetsError {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/delay/5" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    // AFHTTPOperation currently does not have a default response serializer
    [operation setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    
    [operation start];
    expect([operation isExecuting]).will.beTruthy();
    
    [operation cancel];
    expect(operation.error).willNot.beNil();
    expect(operation.error.code).to.equal(NSURLErrorCancelled);
}

- (void)testThatCancellationOfRequestOperationInvokesFailureCompletionBlock {
    __block NSError *blockError = nil;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/delay/5" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    // AFHTTPOperation currently does not have a default response serializer
    [operation setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    
    [operation setCompletionBlockWithSuccess:nil failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        blockError = error;
    }];
    
    [operation start];
    expect([operation isExecuting]).will.beTruthy();
    
    [operation cancel];
    expect(operation.error).willNot.beNil();
    expect(blockError).willNot.beNil();
    expect(blockError.code).will.equal(NSURLErrorCancelled);
}

- (void)testThat500StatusCodeInvokesFailureCompletionBlockWithErrorOnFailure {
    __block NSError *blockError = nil;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/status/500" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    // AFHTTPOperation currently does not have a default response serializer
    [operation setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    
    [operation setCompletionBlockWithSuccess:nil failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        blockError = error;
    }];
    
    [operation start];
    expect([operation isFinished]).will.beTruthy();
    expect(blockError).willNot.beNil();
}

- (void)testThatRedirectBlockIsCalledWhen302IsEncountered {
    __block BOOL success;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/redirect/1" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    // AFHTTPOperation currently does not have a default response serializer
    [operation setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    
    [operation setCompletionBlockWithSuccess:nil failure:nil];
    [operation setRedirectResponseBlock:^NSURLRequest *(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse) {
        if(redirectResponse){
            success = YES;
        }
        
        return request;
    }];
    
    [operation start];
    expect([operation isFinished]).will.beTruthy();
    expect(success).will.beTruthy();
}

- (void)testThatRedirectBlockIsCalledMultipleTimesWhenMultiple302sAreEncountered {
    [Expecta setAsynchronousTestTimeout:5.0];
    __block NSInteger numberOfRedirects = 0;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/redirect/5" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    // AFHTTPOperation currently does not have a default response serializer
    [operation setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    
    [operation setCompletionBlockWithSuccess:nil failure:nil];
    [operation setRedirectResponseBlock:^NSURLRequest *(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse) {
        if(redirectResponse){
            numberOfRedirects++;
        }
        
        return request;
    }];
    
    [operation start];
    expect([operation isFinished]).will.beTruthy();
    expect(numberOfRedirects).will.equal(5);
}

#pragma mark - Pause

- (void)testThatOperationCanBePaused {
    [Expecta setAsynchronousTestTimeout:3.0];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/delay/1" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    // AFHTTPOperation currently does not have a default response serializer
    [operation setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    
    [operation start];
    expect([operation isExecuting]).will.beTruthy();
    
    [operation pause];
    expect([operation isPaused]).will.beTruthy();
    [operation cancel];
}

- (void)testThatPausedOperationCanBeResumed {
    [Expecta setAsynchronousTestTimeout:3.0];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/delay/1" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    // AFHTTPOperation currently does not have a default response serializer
    [operation setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    
    [operation start];
    expect([operation isExecuting]).will.beTruthy();
    
    [operation pause];
    expect([operation isPaused]).will.beTruthy();
    
    [operation resume];
    expect([operation isExecuting]).will.beTruthy();
    
    [operation cancel];
}

- (void)testThatPausedOperationCanBeCompleted {
    [Expecta setAsynchronousTestTimeout:3.0];
    
    __block id blockResponseObject = nil;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/delay/1" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        blockResponseObject = responseObject;
    } failure:nil];
    
    // AFHTTPOperation currently does not have a default response serializer
    [operation setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    
    [operation start];
    expect([operation isExecuting]).will.beTruthy();
    
    [operation pause];
    expect([operation isPaused]).will.beTruthy();
    
    [operation resume];
    expect([operation isExecuting]).will.beTruthy();
    expect([operation isFinished]).will.beTruthy();
    expect(blockResponseObject).willNot.beNil();
}

- (void)testThatOperationPostsDidStartNotificationWhenStarted{

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/get" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    __block BOOL notificationFound;
    
    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:AFNetworkingOperationDidStartNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        if([[[note object] request] isEqual:operation.request]){
            notificationFound = YES;
        }
    }];
    
    // AFHTTPOperation currently does not have a default response serializer
    [operation setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    
    [operation start];
    expect(notificationFound).will.beTruthy();
    
    [[NSNotificationCenter defaultCenter] removeObserver:observer];
}

- (void)testThatOperationPostsDidFinishNotificationWhenFinished {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/get" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    __block BOOL notificationFound;

    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:AFNetworkingOperationDidFinishNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        if([[[note object] request] isEqual:operation.request]){
            notificationFound = YES;
        }
    }];
    
    // AFHTTPOperation currently does not have a default response serializer
    [operation setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    
    [operation start];
    expect(notificationFound).will.beTruthy();
    
    [[NSNotificationCenter defaultCenter] removeObserver:observer];
}

@end
