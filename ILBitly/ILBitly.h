//
//  ILBitly.h
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

#import <Foundation/Foundation.h>

/** ILBitly provides methods for easily acccessing the URL-shortening service at http://bitly.com */
@interface ILBitly : NSObject {
@private
	NSString *_auth;
	NSOperationQueue *_queue;
}

/** Returns an intialized bitly wrapper object with the provided credentials.
 
 The credentials provided in _login_ and _apiKey_ will be used in all subsequent calls to the various bitly services.
 A free account can be created at http://bitly.com/a/sign_up
 @param login The bitly username
 @param apiKey The bitly API Key available from http://bitly.com/a/your_api_key
 */
- (id)initWithLogin:(NSString*)login apiKey:(NSString*)apiKey;

/** @name Shortening URLs */

/** Takes a long URL and returns a shortened version of it.
 
 Takes the long URL specfied in _longURLString_ and returns a shortened version in the block specified in _result_.
 
 In case of an error the block spefied by _error_ is executed with additional information of the cause of the failure.

 @param longURLString The long URL string to shorten
 @param result The block to execute upon success. The block should take a single NSString* parameter and have no return value
 @param error The block to execute upon failure. The block should take a single NSError* parameter and have no return value*/
- (void)shorten:(NSString*)longURLString result:(void (^)(NSString *shortURLString))result error:(void (^)(NSError*))error;

/** @name Expanding URLs */

/** Takes a short URL and returns an expanded version of it.
 
 Takes the short URL specfied in _shortURLString_ and returns an expanded version in the block specified in _result_. 
 
 In case of an error the block spefied by _error_ is executed with additional information of the cause of the failure.
 @param shortURLString The short URL string to expand
 @param result The block to execute upon success. The block should take a single NSString* parameter and have no return value
 @param error The block to execute upon failure. The block should take a single NSError* parameter and have no return value*/
- (void)expand:(NSString*)shortURLString result:(void (^)(NSString *longURLString))result error:(void (^)(NSError*))error;

/** @name Statistics */

/** Provides statistics about the numbers of clicks on a short URL.
 
 Takes the short URL specfied in _shortURLString_ and returns statistics about the number of clicks in the block specified in _result_. The value in _userClicks_ contains the count of clicks on this user's bitly link. The value in _globalClicks_ contains total count of clicks to all bitly links that point to the same same long URL.
 
 In case of an error the block spefied by _error_ is executed with additional information of the cause of the failure.
 @param shortURLString The short URL string to expand
 @param result The block to execute upon success. The block should take two NSInteger parameters and have no return value.
 @param error The block to execute upon failure. The block should take a single NSError* parameter and have no return value*/
- (void)clicks:(NSString*)shortURLString result:(void (^)(NSInteger userClicks, NSInteger globalClicks))result error:(void (^)(NSError*))error;

@end

extern NSString *const kILBitlyErrorDomain;