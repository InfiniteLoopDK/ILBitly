# ILBitly

ILBitly provides an Objective C wrapper class for accessing the free URL shortening services at [bit.ly](http://www.bitly.com) from iOS 4.0 or newer.

## Dependencies

- [AFNetworking](https://github.com/gowalla/AFNetworking) - Used for the underlying network access
- [JSONKit](https://github.com/johnezang/JSONKit) - Needed for parsing the response from bit.ly
- [OCMock](http://ocmock.org) - Only needed for running the unit tests
- You will also need an account at bit.ly including an [API key](http://bitly.com/a/your_api_key)

For the sample project to build, you need to place AFNetworking and JSONKit inside the folder called 3rdParty.

If you also intense to run the unit tests you will need to download the latest version of OCMock (1.77 or newer), unpack it and place it in the 3rdParty folder. You may need to remove the version from the folder name so it's just called OCMock.

## Example Usage
###Shortening an URL
	ILBitly *bitly = [[ILBitly alloc] initWithLogin:login apiKey:apiKey];
	[bitly shorten:@"http://www.infinite-loop.dk" result:^(NSString *shortURLString) {
		NSLog(@"The shortened URL: %@", shortURLString);
	} error:^(NSError *err) {
		NSLog(@"An error occurred %@", err);
	}];
	[bitly release];

###Expanding an URL
	[bitly expand:@"http://j.mp/its-your-round" result:^(NSString *longURLString) {
		NSLog(@"The expanded URL: %@", longURLString);
	} error:^(NSError *err) {
		NSLog(@"An error occurred %@", err);
	}];

###Getting statistics on number of clicks
	[bitly clicks:@"http://j.mp/qnpNBs" result:^(NSInteger userClicks, NSInteger globalClicks) {
		NSLog(@"This link has been clicked %d times out of %d clicks globally: %d", userClicks, globalClicks);
	} error:^(NSError *err) {
		NSLog(@"An error occurred %@", err);
	}];


See more examples in the attached sample project.

## Building Xcode Documentation

ILBitly is documented in the header files using the appledoc syntax. The sample app contains a target called "Documentation" which will build the documentation and install it for use inside Xcode as a searchable and browsable docset.
In order to be able to build it you will need to install appledoc on your own computer. You can get appledoc from [GitHub](https://github.com/tomaz/appledoc).
For more information about how to setup and build the documentation you can read this [short tutorial](http://wp.me/p1xKtH-52).

Feel free to add enhanchements, bug fixes, changes and provide them back to the community!


Thanks,

Claus Broch
