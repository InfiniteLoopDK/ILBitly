//
//  ShortenViewController.m
//  ILBitlySample
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

#import "ShortenViewController.h"
#import "ILBitly.h"

@interface ShortenViewController()
- (void)clicks:(NSString*)text;
- (void)shorten:(NSString*)text;
@end

@implementation ShortenViewController

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload
{
    [longUrlField release];
    longUrlField = nil;
	[shortUrl release];
	shortUrl = nil;
	[errorCode release];
	errorCode = nil;
	[errorReason release];
	errorReason = nil;
    [clicksField release];
    clicksField = nil;
    [super viewDidUnload];
}

- (void)dealloc {
    [longUrlField release];
	[shortUrl release];
	[errorCode release];
	[errorReason release];
    [clicksField release];
    [super dealloc];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	if(textField == longUrlField) {
		[self shorten:textField.text];
	}
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

- (void)clicks:(NSString*)text {
	NSString *login = [[NSUserDefaults standardUserDefaults] objectForKey:@"login"];
	NSString *apiKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"apiKey"];
	ILBitly *bitly = [[ILBitly alloc] initWithLogin:login apiKey:apiKey];
	[bitly clicks:text result:^(NSInteger userClicks, NSInteger globalClicks) {
		clicksField.text = [NSString stringWithFormat:@"%d of %d", userClicks, globalClicks];
		errorCode.text = @"";
		errorReason.text = @"";
	} error:^(NSError *err) {
		clicksField.text = @"";
		errorCode.text = [NSString stringWithFormat:@"%d", [err code]];
		errorReason.text = [err localizedDescription];
	}];
	[bitly release];
}

- (void)shorten:(NSString*)longURLString {
	NSString *login = [[NSUserDefaults standardUserDefaults] objectForKey:@"login"];
	NSString *apiKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"apiKey"];
	ILBitly *bitly = [[ILBitly alloc] initWithLogin:login apiKey:apiKey];
	[bitly shorten:longURLString result:^(NSString *shortURLString) {
		shortUrl.text = shortURLString;
		clicksField.text = @"...";
		errorCode.text = @"";
		errorReason.text = @"";
		[self performSelectorOnMainThread:@selector(clicks:) withObject:shortURLString waitUntilDone:NO];
	} error:^(NSError *err) {
		shortUrl.text = @"";
		clicksField.text = @"";
		errorCode.text = [NSString stringWithFormat:@"%d", [err code]];
		errorReason.text = [err localizedDescription];
	}];
	[bitly release];
}

@end
