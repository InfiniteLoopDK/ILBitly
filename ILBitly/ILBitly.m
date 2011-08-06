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

static NSString *kShortenURL = @"http://api.bitly.com/v3/shorten?%@&longUrl=%@&format=json";

@interface ILBitly()

- (NSString*)localizedStatusText:(NSString*)bitlyStatusTxt;

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

// Request formatted according to http://code.google.com/p/bitly-api/wiki/ApiDocumentation#/v3/shorten

- (void)shorten:(NSString*)longURLString result:(void (^)(NSString *shortURLString))result {
	[self shorten:longURLString result:result error:nil];
}

- (void)shorten:(NSString*)longURLString result:(void (^)(NSString *shortURLString))result error:(void (^)(NSError*))error {
	NSString *escString = [longURLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSString *urlString = [NSString stringWithFormat:kShortenURL, _auth, escString];
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation operationWithRequest:request success:^(id json) {
		NSNumber *statusCode = [json valueForKeyPath:@"status_code"];
		NSString *statusText = [json valueForKeyPath:@"status_txt"];
		if(([statusCode intValue] == 200) && [statusText isEqualToString:@"OK"]) {
			if(result)
				result([json valueForKeyPath:@"data.url"]);
		}
		else {
			NSDictionary *userDict = [NSDictionary dictionaryWithObject:[self localizedStatusText:statusText]
																 forKey:NSLocalizedDescriptionKey];
			NSError *bitlyError = [NSError errorWithDomain:@"com.bitly.error"
														code:[statusCode integerValue] 
													userInfo:userDict];
			if(error)
				error(bitlyError);
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

- (NSString*)localizedStatusText:(NSString*)bitlyStatusTxt {
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *status = [bundle localizedStringForKey:bitlyStatusTxt value:bitlyStatusTxt table:@"ILBitlyErrors"];
	
	return status;
}

@end
