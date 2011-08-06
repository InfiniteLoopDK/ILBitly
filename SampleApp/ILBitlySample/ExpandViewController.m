//
//  ExpandViewController.m
//  ILBitlySample
//
//  Created by Claus Broch on 07/08/11.
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

#import "ExpandViewController.h"
#import "ILBitly.h"

@interface ExpandViewController()
- (void)expand:(NSString*)text;
@end

@implementation ExpandViewController

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidUnload
{
    [shortUrlField release];
    shortUrlField = nil;
    [expandedUrlField release];
    expandedUrlField = nil;
    [errorField release];
    errorField = nil;
    [reasonField release];
    reasonField = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [shortUrlField release];
    [expandedUrlField release];
    [errorField release];
    [reasonField release];
    [super dealloc];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	if(textField == shortUrlField) {
		[self expand:textField.text];
	}
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

- (void)expand:(NSString*)text {
	NSString *login = [[NSUserDefaults standardUserDefaults] objectForKey:@"login"];
	NSString *apiKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"apiKey"];
	ILBitly *bitly = [[ILBitly alloc] initWithLogin:login apiKey:apiKey];
	[bitly expand:text result:^(NSString *longURLString) {
		expandedUrlField.text = longURLString;
		errorField.text = @"";
		reasonField.text = @"";
	} error:^(NSError *err) {
		expandedUrlField.text = @"";
		errorField.text = [NSString stringWithFormat:@"%d", [err code]];
		reasonField.text = [err localizedDescription];
	}];
	[bitly release];
}

@end
