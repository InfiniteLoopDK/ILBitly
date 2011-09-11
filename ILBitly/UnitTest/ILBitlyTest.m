//
//  ILBitlyTest.m
//
//  Created by Claus Broch on 08/09/11.
//  Copyright 2011 Infinite Loop. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are permitted
//  provided that the following conditions are met:
//
//  - Redistributions of source code must retain the above copyright notice, this list of conditions 
//    and the following disclaimer.
//  - Redistributions in binary form must reproduce the above copyright notice, this list of 
//    conditions and the following disclaimer in the documentation and/or other materials provided 
//    with the distribution.
//  - Neither the name of Infinite Loop nor the names of its contributors may be used to endorse or 
//    promote products derived from this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR 
//  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR 
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
//  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY 
//  WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import <OCMock/OCMock.h>
#import <Foundation/NSObjCRuntime.h>

#import "ILBitlyTest.h"
#import "ILCannedURLProtocol.h"
#import "JSONKit.h"
#import "AFJSONRequestOperation.h"

@interface ILBitly(SupressCompilerWarnings)
- (NSURLRequest*)requestForURLString:(NSString*)urlString;
@end

@interface ILBitlyTest()
- (NSData*)cannedDataWithName:(NSString*)cannedName;
- (BOOL)waitForCompletion:(NSTimeInterval)timeoutSecs;
@end

@implementation ILBitlyTest

- (void)setUp
{
    [super setUp];
    
	// Init bitly proxy using test id and key - not valid for real use
	bitly = [[ILBitly alloc] initWithLogin:@"LOGIN" apiKey:@"KEY"];
	bitlyMock = nil;
	done = NO;
	
	[NSURLProtocol registerClass:[ILCannedURLProtocol class]];
	[ILCannedURLProtocol setCannedStatusCode:200];
	[ILCannedURLProtocol setCannedHeaders:nil];
	[ILCannedURLProtocol setCannedResponseData:nil];
}

- (void)tearDown
{
	[NSURLProtocol unregisterClass:[ILCannedURLProtocol class]];
	[ILCannedURLProtocol setCannedHeaders:nil];
	[ILCannedURLProtocol setCannedResponseData:nil];
	
    [bitly release];
	bitlyMock = nil;
	
    [super tearDown];
}

- (NSData*)cannedDataWithName:(NSString*)cannedName {
	NSData *data = [[NSData alloc] initWithContentsOfFile:
					[[NSBundle bundleForClass:[self class]] pathForResource:cannedName ofType:@"json"]];
	STAssertNotNil(data, @"Failed to load canned result '%@'", cannedName);
	
	return [data autorelease];
}

- (BOOL)waitForCompletion:(NSTimeInterval)timeoutSecs
{
	NSDate	*timeoutDate = [NSDate dateWithTimeIntervalSinceNow:timeoutSecs];
	
	do {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.001]];
		if([timeoutDate timeIntervalSinceNow] < 0.0)
			break;
	} while (!done);
	
	return done;
}

- (void)testShorten {
	// Prepare the canned test result
	[ILCannedURLProtocol setCannedResponseData:[self cannedDataWithName:@"shorten"]];
	[ILCannedURLProtocol setCannedHeaders:[NSDictionary dictionaryWithObject:@"application/json; charset=utf-8" forKey:@"Content-Type"]];
	bitlyMock = [OCMockObject partialMockForObject:bitly];
	[[[bitlyMock expect] andReturn:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://"]]]
									requestForURLString:[OCMArg checkWithBlock:^(id url) {
		return [url isEqualToString:@"http://api.bitly.com/v3/shorten?login=LOGIN&apiKey=KEY&longUrl=http%3A%2F%2Fwww.infinite-loop.dk%2Fblog%2F%3Fa%3D1%26b%3D2%23with%20spaces&format=json"]; 
	}]];
	 
	// Execute the code under test
	[bitly shorten:@" http://www.infinite-loop.dk/blog/?a=1&b=2#with spaces " result:^(NSString *shortURLString) {
		STAssertEqualObjects(shortURLString, @"http://j.mp/qA7S4Q", @"Unexpected short url");
		done = YES;
	} error:^(NSError *err) {
		STFail(@"Shorten failed with error: %@", [err localizedDescription]);
		done = YES;
	}];
	
	// Verify the result
	STAssertTrue([self waitForCompletion:5.0], @"Shorten didn't complete within expected time");
	[bitlyMock verify];
}

- (void)testShortenRateLimit {
	// Prepare the canned test result
	[ILCannedURLProtocol setCannedResponseData:[self cannedDataWithName:@"shorten+limit"]];
	[ILCannedURLProtocol setCannedHeaders:[NSDictionary dictionaryWithObject:@"application/json; charset=utf-8" forKey:@"Content-Type"]];
	bitlyMock = [OCMockObject partialMockForObject:bitly];
	[[[bitlyMock expect] andReturn:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://"]]]
	 requestForURLString:[OCMArg checkWithBlock:^(id url) {
		return [url isEqualToString:@"http://api.bitly.com/v3/shorten?login=LOGIN&apiKey=KEY&longUrl=http%3A%2F%2Fwww.infinite-loop.dk%2Fblog&format=json"]; 
	}]];
	
	// Execute the code under test
	[bitly shorten:@"http://www.infinite-loop.dk/blog" result:^(NSString *shortURLString) {
		STFail(@"Should have failed with rate limit");
		done = YES;
	} error:^(NSError *err) {
		STAssertEquals([err code], 403, @"Unexpected error code");
		STAssertEqualObjects([err domain], kILBitlyErrorDomain, @"Unexpected error domain");
		STAssertEqualObjects([[err userInfo] objectForKey:kILBitlyStatusTextKey], @"RATE_LIMIT_EXCEEDED", @"Unexpected error status");
		done = YES;
	}];
	
	// Verify the result
	STAssertTrue([self waitForCompletion:5.0], @"Shorten didn't complete within expected time");
	[bitlyMock verify];
}

- (void)testShortenTimeout {
	// Prepare the canned test result
	[ILCannedURLProtocol setCannedError:[NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorTimedOut userInfo:nil]];
	bitlyMock = [OCMockObject partialMockForObject:bitly];
	[[[bitlyMock expect] andReturn:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://"]]]
	 requestForURLString:[OCMArg checkWithBlock:^(id url) {
		return [url isEqualToString:@"http://api.bitly.com/v3/shorten?login=LOGIN&apiKey=KEY&longUrl=http%3A%2F%2Fwww.infinite-loop.dk%2Fblog&format=json"]; 
	}]];
	
	// Execute the code under test
	[bitly shorten:@"http://www.infinite-loop.dk/blog" result:^(NSString *shortURLString) {
		STFail(@"Should have failed with timeout");
		done = YES;
	} error:^(NSError *err) {
		STAssertEquals([err code], kCFURLErrorTimedOut, @"Unexpected error code");
		STAssertEqualObjects([err domain], NSURLErrorDomain, @"Unexpected error domain");
		done = YES;
	}];
	
	// Verify the result
	STAssertTrue([self waitForCompletion:5.0], @"Shorten didn't complete within expected time");
	[bitlyMock verify];
}

- (void)testExpand {
	// Prepare the canned test result
	[ILCannedURLProtocol setCannedResponseData:[self cannedDataWithName:@"expand"]];
	[ILCannedURLProtocol setCannedHeaders:[NSDictionary dictionaryWithObject:@"application/json; charset=utf-8" forKey:@"Content-Type"]];
	bitlyMock = [OCMockObject partialMockForObject:bitly];
	[[[bitlyMock expect] andReturn:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://"]]]
	 requestForURLString:[OCMArg checkWithBlock:^(id url) {
		return [url isEqualToString:@"http://api.bitly.com/v3/expand?login=LOGIN&apiKey=KEY&shortUrl=http%3A%2F%2Fj.mp%2Fits-your-round&format=json"]; 
	}]];
	
	// Execute the code under test
	[bitly expand:@"http://j.mp/its-your-round" result:^(NSString *longURLString) {
		STAssertEqualObjects(longURLString, @"http://itunes.apple.com/us/app/its-your-round/id448750786?mt=8&uo=4", @"Unexpected long url");
		done = YES;
	} error:^(NSError *err) {
		STFail(@"Expand failed with error: %@", [err localizedDescription]);
		done = YES;
	}];
	
	// Verify the result
	STAssertTrue([self waitForCompletion:5.0], @"Expand didn't complete within expected time");
	[bitlyMock verify];
}

- (void)testExpandNotFound {
	// Prepare the canned test result
	[ILCannedURLProtocol setCannedResponseData:[self cannedDataWithName:@"expand+notfound"]];
	[ILCannedURLProtocol setCannedHeaders:[NSDictionary dictionaryWithObject:@"application/json; charset=utf-8" forKey:@"Content-Type"]];
	bitlyMock = [OCMockObject partialMockForObject:bitly];
	[[[bitlyMock expect] andReturn:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://"]]]
	 requestForURLString:[OCMArg checkWithBlock:^(id url) {
		return [url isEqualToString:@"http://api.bitly.com/v3/expand?login=LOGIN&apiKey=KEY&shortUrl=http%3A%2F%2Fj.mp%2Fdoesnt-exist&format=json"]; 
	}]];
	
	// Execute the code under test
	[bitly expand:@"http://j.mp/doesnt-exist" result:^(NSString *longURLString) {
		STFail(@"Should have failed with not found");
		done = YES;
	} error:^(NSError *err) {
		STAssertEquals([err code], -1, @"Unexpected error code");
		STAssertEqualObjects([err domain], kILBitlyErrorDomain, @"Unexpected error domain");
		STAssertEqualObjects([[err userInfo] objectForKey:kILBitlyStatusTextKey], @"NOT_FOUND", @"Unexpected error status");
		done = YES;
	}];
	
	// Verify the result
	STAssertTrue([self waitForCompletion:5.0], @"Expand didn't complete within expected time");
	[bitlyMock verify];
}

- (void)testExpandInvalidKey {
	// Prepare the canned test result
	[ILCannedURLProtocol setCannedResponseData:[self cannedDataWithName:@"expand+badkey"]];
	[ILCannedURLProtocol setCannedHeaders:[NSDictionary dictionaryWithObject:@"application/json; charset=utf-8" forKey:@"Content-Type"]];
	bitlyMock = [OCMockObject partialMockForObject:bitly];
	[[[bitlyMock expect] andReturn:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://"]]]
	 requestForURLString:[OCMArg checkWithBlock:^(id url) {
		return [url isEqualToString:@"http://api.bitly.com/v3/expand?login=LOGIN&apiKey=KEY&shortUrl=http%3A%2F%2Fj.mp%2Fits-your-round&format=json"]; 
	}]];
	
	// Execute the code under test
	[bitly expand:@"http://j.mp/its-your-round" result:^(NSString *longURLString) {
		STFail(@"Should have failed with invalid apikey");
		done = YES;
	} error:^(NSError *err) {
		STAssertEquals([err code], 500, @"Unexpected error code");
		STAssertEqualObjects([err domain], kILBitlyErrorDomain, @"Unexpected error domain");
		STAssertEqualObjects([[err userInfo] objectForKey:kILBitlyStatusTextKey], @"INVALID_APIKEY", @"Unexpected error status");
		done = YES;
	}];
	
	// Verify the result
	STAssertTrue([self waitForCompletion:5.0], @"Expand didn't complete within expected time");
	[bitlyMock verify];
}

- (void)testExpandTimeout {
	// Prepare the canned test result
	[ILCannedURLProtocol setCannedError:[NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorTimedOut userInfo:nil]];
	bitlyMock = [OCMockObject partialMockForObject:bitly];
	[[[bitlyMock expect] andReturn:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://"]]]
	 requestForURLString:[OCMArg checkWithBlock:^(id url) {
		return [url isEqualToString:@"http://api.bitly.com/v3/expand?login=LOGIN&apiKey=KEY&shortUrl=http%3A%2F%2Fj.mp%2Fits-your-round&format=json"]; 
	}]];
	
	// Execute the code under test
	[bitly expand:@"http://j.mp/its-your-round" result:^(NSString *longURLString) {
		STFail(@"Should have failed with timeout");
		done = YES;
	} error:^(NSError *err) {
		STAssertEquals([err code], kCFURLErrorTimedOut, @"Unexpected error code");
		STAssertEqualObjects([err domain], NSURLErrorDomain, @"Unexpected error domain");
		done = YES;
	}];
	
	// Verify the result
	STAssertTrue([self waitForCompletion:5.0], @"Expand didn't complete within expected time");
	[bitlyMock verify];
}


@end
