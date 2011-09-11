//
//  ILBitly.m
//
//  Created by Claus Broch on 04/08/11.
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

#import "ILBitly.h"
#import "AFJSONRequestOperation.h"

NSString *const kILBitlyErrorDomain = @"ILBitlyErrorDomain";

static NSString *kShortenURL = @"http://api.bitly.com/v3/shorten?%@&longUrl=%@&format=json";
static NSString *kExpandURL = @"http://api.bitly.com/v3/expand?%@&shortUrl=%@&format=json";
static NSString *kClicksURL = @"http://api.bitly.com/v3/clicks?%@&shortUrl=%@&format=json";

@interface ILBitly()

- (NSString*)localizedStatusText:(NSString*)bitlyStatusTxt;
- (NSError*)errorWithCode:(NSInteger)code status:(NSString*)status;
- (NSURLRequest*)requestForURLString:(NSString*)urlString;

@end

@implementation ILBitly

- (id)initWithLogin:(NSString*)login apiKey:(NSString*)apiKey {
    self = [super init];
    if (self) {
		_auth = [[NSString alloc] initWithFormat:@"login=%@&apiKey=%@", login, apiKey];
		_queue = [[NSOperationQueue alloc] init];
    }
    
    return self;
}

- (void)dealloc {
	[_auth release];
	[_queue release];
	
	[super dealloc];
}

- (NSString*)localizedStatusText:(NSString*)bitlyStatusTxt {
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *status = [bundle localizedStringForKey:bitlyStatusTxt value:bitlyStatusTxt table:@"ILBitlyErrors"];
	
	return status;
}

- (NSError*)errorWithCode:(NSInteger)code status:(NSString*)status {
	NSMutableDictionary *userDict = [NSMutableDictionary dictionary];
	status = [self localizedStatusText:status];
	if(status)
		[userDict setObject:status forKey:NSLocalizedDescriptionKey];
	NSError *bitlyError = [NSError errorWithDomain:kILBitlyErrorDomain code:code userInfo:userDict];
	
	return bitlyError;
}

- (NSURLRequest*)requestForURLString:(NSString*)urlString {
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
	return request;
}

#pragma mark - URL shortening



// Request formatted according to http://code.google.com/p/bitly-api/wiki/ApiDocumentation#/v3/shorten

- (void)shorten:(NSString*)longURLString result:(void (^)(NSString *shortURLString))result error:(void (^)(NSError*))error {
	NSString *trimmedLongURLString = [longURLString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	CFStringRef escString = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)trimmedLongURLString, nil, CFSTR("!*'();:@&=+$,/?#[]"), kCFStringEncodingUTF8);
	NSString *urlString = [NSString stringWithFormat:kShortenURL, _auth, escString];
	CFRelease(escString);
	NSURLRequest *request = [self requestForURLString:urlString];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation operationWithRequest:request success:^(id json) {
		NSNumber *statusCode = [json valueForKeyPath:@"status_code"];
		NSString *statusText = [json valueForKeyPath:@"status_txt"];
		if(([statusCode intValue] == 200) && [statusText isEqualToString:@"OK"]) {
			if(result)
				result([json valueForKeyPath:@"data.url"]);
		}
		else {
			if(error)
				error([self errorWithCode:[statusCode integerValue] status:statusText]);
			else if(result)
				result(nil);
		}
	} failure:^(NSError *err) {
		if(error)
			error(err);
		else if(result)
			result(nil);
	}];
	[_queue addOperation:operation];
}

#pragma mark - URL expanding

// Request formatted according to http://code.google.com/p/bitly-api/wiki/ApiDocumentation#/v3/expand

- (void)expand:(NSString*)shortURLString result:(void (^)(NSString *longURLString))result error:(void (^)(NSError*))error {
	CFStringRef escString = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)shortURLString, nil, CFSTR("?&"), kCFStringEncodingUTF8);
	NSString *urlString = [NSString stringWithFormat:kExpandURL, _auth, escString];
	CFRelease(escString);
	NSURLRequest *request = [self requestForURLString:urlString];

	AFJSONRequestOperation *operation = [AFJSONRequestOperation operationWithRequest:request success:^(id json) {
		NSNumber *statusCode = [json valueForKeyPath:@"status_code"];
		NSString *statusText = [json valueForKeyPath:@"status_txt"];
		if(([statusCode intValue] == 200) && [statusText isEqualToString:@"OK"]) {
			if(result) {
				id entry = [[[json valueForKeyPath:@"data.expand"] objectEnumerator] nextObject];
				NSString *longUrl = [entry valueForKey:@"long_url"];
				if(longUrl) {
					result(longUrl);
				}
				else {
					if(error)
						error([self errorWithCode:-1 status:[entry valueForKey:@"error"]]);
					else
						result(nil);
				}
			}
		}
		else {
			if(error)
				error([self errorWithCode:[statusCode integerValue] status:statusText]);
			else if(result)
				result(nil);
		}
	} failure:^(NSError *err) {
		if(error)
			error(err);
		else if(result)
			result(nil);
	}];
	[_queue addOperation:operation];
}

#pragma mark - Statistics

// Request formatted according to http://code.google.com/p/bitly-api/wiki/ApiDocumentation#/v3/clicks

- (void)clicks:(NSString*)shortURLString result:(void (^)(NSInteger userClicks, NSInteger globalClicks))result error:(void (^)(NSError*))error {
	CFStringRef escString = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)shortURLString, nil, CFSTR("?&"), kCFStringEncodingUTF8);
	NSString *urlString = [NSString stringWithFormat:kClicksURL, _auth, escString];
	CFRelease(escString);
	NSURLRequest *request = [self requestForURLString:urlString];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation operationWithRequest:request success:^(id json) {
		NSNumber *statusCode = [json valueForKeyPath:@"status_code"];
		NSString *statusText = [json valueForKeyPath:@"status_txt"];
		if(([statusCode intValue] == 200) && [statusText isEqualToString:@"OK"]) {
			if(result) {
				id entry = [[[json valueForKeyPath:@"data.clicks"] objectEnumerator] nextObject];
				NSNumber *userClicks = [entry valueForKey:@"user_clicks"];
				NSNumber *globalClicks = [entry valueForKey:@"global_clicks"];
				if(userClicks && globalClicks) {
					result([userClicks integerValue], [globalClicks integerValue]);
				}
				else {
					if(error)
						error([self errorWithCode:-1 status:[entry valueForKey:@"error"]]);
					else
						result(-1, -1);
				}
			}
		}
		else {
			if(error)
				error([self errorWithCode:[statusCode integerValue] status:statusText]);
			else if(result)
				result(-1, -1);
		}
	} failure:^(NSError *err) {
		if(error)
			error(err);
		else if(result)
			result(-1, -1);
	}];
	[_queue addOperation:operation];
}

@end
