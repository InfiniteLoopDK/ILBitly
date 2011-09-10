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
}

- (void)tearDown
{
	[NSURLProtocol unregisterClass:[ILCannedURLProtocol class]];
	
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
		return [url isEqualToString:@"http://api.bitly.com/v3/shorten?login=LOGIN&apiKey=KEY&longUrl=http://www.infinite-loop.dk/&format=json"]; 
	}]];
	 
	// Execute the code under test
	[bitly shorten:@"http://www.infinite-loop.dk/" result:^(NSString *shortURLString) {
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

@end
