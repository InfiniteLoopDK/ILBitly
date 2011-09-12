//
//  SettingsViewController.m
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

#import "SettingsViewController.h"

@implementation SettingsViewController

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
	[loginField release];
	loginField = nil;
	[apiKeyField release];
	apiKeyField = nil;
    [super viewDidUnload];

    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewDidAppear:(BOOL)animated {
	loginField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"login"];
	apiKeyField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"apiKey"];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    if (([loginField isFirstResponder] && [touch view] != loginField) || ([apiKeyField isFirstResponder] && [touch view] != apiKeyField))  {
		[loginField resignFirstResponder];
		[apiKeyField resignFirstResponder];
    }
    [super touchesBegan:touches withEvent:event];
}

- (IBAction)setLogin:(id)sender {
	[[NSUserDefaults standardUserDefaults] setValue:[sender text] forKey:@"login"];
	[loginField resignFirstResponder];
	[apiKeyField resignFirstResponder];
	[self.view endEditing:YES];
}

- (IBAction)setAPIKey:(id)sender {
	[[NSUserDefaults standardUserDefaults] setValue:[sender text] forKey:@"apiKey"];
	[loginField resignFirstResponder];
	[apiKeyField resignFirstResponder];
	[self.view endEditing:YES];
}

- (void)dealloc {
	[loginField release];
	[apiKeyField release];
	[super dealloc];
}
@end
