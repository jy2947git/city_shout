//
//  iSpeakAppDelegate.m
//  iSpeak
//
//  Created by Junqiang You on 5/6/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "iSpeakAppDelegate.h"
#import "SpeakViewController.h"
#import "GlobalConfiguration.h"

// Class extension for private properties and methods.
@interface iSpeakAppDelegate()
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) SpeakViewController *viewControllerSpeak;

-(BOOL)isTermSigned;
-(void)startUp;
-(void)showTerms;
@end

@implementation iSpeakAppDelegate

@synthesize window;
@synthesize viewControllerSpeak;
@synthesize configuration;



- (void)applicationDidFinishLaunching:(UIApplication *)application {    
	//check terms and conditions
	if(![self isTermSigned]){
		[self showTerms];
	}
	else{
		[self startUp];
	}


}

-(void)startUp{
	GlobalConfiguration *c = [[GlobalConfiguration alloc] init];
	self.configuration=c;
	[c release];
	SpeakViewController *v = [[SpeakViewController alloc] initWithNibName:@"SpeakView" bundle:nil];
	self.viewControllerSpeak = v;
	[v release];
	[window addSubview:self.viewControllerSpeak.view];
	[window makeKeyAndVisible];
}

-(void)showTerms{
	NSBundle *mainBundle = [NSBundle mainBundle];
	NSString *tf = [mainBundle pathForResource:@"terms-conditions" ofType:@"txt"];
	NSString *s = [[NSString alloc] initWithContentsOfFile:tf];
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Terms and Conditions",@"Terms and Conditions")
														message:s
													   delegate:self
											  cancelButtonTitle:NSLocalizedString(@"I Disagree",@"I Disagre")
											  otherButtonTitles:NSLocalizedString(@"I Agree",@"I Agree"),nil];
	alertView.opaque=YES;
	[alertView show];
	[alertView release];
	[s release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex  { 
		if (buttonIndex == 1) {  
			// agree
			
			NSBundle *mainBundle = [NSBundle mainBundle];
			NSString *tf = [mainBundle pathForResource:@"terms-conditions" ofType:@"txt"];
			NSString *s = [[NSString alloc] initWithContentsOfFile:tf];
			NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
			NSString *documentDirectory = [paths objectAtIndex:0];
			NSString *settingPath = [documentDirectory stringByAppendingPathComponent:@"terms-conditions.txt"];
			NSError *error = nil;
			[s writeToFile:settingPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
			[s release];
			if(error){
				NSLog(@"could not save term-condition file to path %@, shutdown.", settingPath);
			}else{
				[self startUp];
			}
		}  
		else {  
			//disagree 
			
		}  
	
}
-(BOOL)isTermSigned{

	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentDirectory = [paths objectAtIndex:0];
	NSString *settingPath = [documentDirectory stringByAppendingPathComponent:@"terms-conditions.txt"];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if([fileManager fileExistsAtPath:settingPath]){
		return YES;
	}else{
		return NO;
	}
}
- (void)dealloc {

	[viewControllerSpeak release];
	[configuration release];
    [window release];
    [super dealloc];
}


@end
