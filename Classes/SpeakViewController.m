//
//  SpeakViewController.m
//  iSpeak
//
//  Created by Junqiang You on 5/6/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SpeakViewController.h"
#import "GlobalConfiguration.h"
#import "iSpeakAppDelegate.h"
#import "CitySelectionView2.h"
#import "InternetUtility.h"
//#import "MyStore.h"
#import <StoreKit/SKProductsRequest.h>
#import <StoreKit/SKPaymentTransaction.h>
#import <StoreKit/SKPayment.h>
#import <StoreKit/SKRequest.h>

@interface SpeakViewController()
@property(nonatomic,retain) IBOutlet UIButton *cityButton;
@property(nonatomic,retain) IBOutlet UILabel *statusMessage;
@property(nonatomic,retain) IBOutlet UIButton *shoutButton;
@property(nonatomic,retain) NSString *currentRegisteredListeningLocationId;
@property(nonatomic,retain) NSArray *dirtyrWords;
@property(nonatomic, retain) CitySelectionView2 *pickerView;
@property(nonatomic, retain) NSThread *listenerThread;
@property(nonatomic, retain) NSThread *redrawThread;
@property(nonatomic, retain) NSString *myCity;
@property(nonatomic, retain) NSString *myCountry;
@property(retain) IBOutlet UITextField *speakMessage;
@property(retain) NSMutableArray *receivedMessages;
@property(nonatomic, retain) IBOutlet UITextView *messagesView;
@property(nonatomic, retain) NSString *shoutTo;
//@property(nonatomic, retain) MyStore *store;
//store kit
//@property(nonatomic) BOOL paidSuccess;
//@property(nonatomic) BOOL paymentProcessingDone;
@property(nonatomic, retain) NSMutableString *displayMessage;


-(void)listen;
-(void)redrawTextView;
-(void)redrawPlease:(NSString*)messageForDisplay;

- (void)registerForKeyboardNotifications;
- (void)didSetMyCountry:(NSString*)country city:(NSString*)city;
- (void)registerListenerWithLocation:(NSString*)newId replaceOldLocation:(NSString*)oldId;
- (void)stopListening;
- (void)startListening;
- (void)startRefreshingMessages;
- (void)stopRefreshingMessages;
- (NSString*)findLocationIdWithCountry:(NSString*)country city:(NSString*)city;
- (int)checkDirtyLevel:(NSString*)message;
-(void)donePickCountryStateCity:(id)sender;
-(void)displayShoutsQuota;
- (void)removePickerView:(NSString *)animationID finished:(BOOL)finished context:(void *)context;
-(void)showTheCityPicker:(int)purpose;
//-(void)showStatusBarMessage:(NSString*)message animated:(BOOL)animated temporary:(BOOL)temporary;
//-(void)showStatusBarMessage:(NSString*)message animated:(BOOL)animated temporary:(BOOL)temporary afterDelay:(int)delay;
-(void)applicationWillBecomeActive:(NSNotification *)notification;
-(void)applicationWillResignActive:(NSNotification *)notification;
-(void)displayPurchaseView;
-(void)processPurchase:(NSString*)productId;
-(int)showBillboardTemporaryMessage:(NSString *)msg;
-(void)showBillboardStayMessage:(NSString *)msg;
-(void)updateShoutQuotaAfterPayment:(NSString*)productId;

//-------- store kit
-(void)showProgressMessage:(NSString*)msg;
-(void)completeTransaction:(SKPaymentTransaction*)transaction;
-(void)failedTransaction:(SKPaymentTransaction*)transaction;
-(void)recordTransaction:(SKPaymentTransaction*)transaction;
-(void)provideContent:(NSString*)productIdentifier;
-(void)registerStoreProcess;
-(void)purchase:(NSString*)kMyFeatureIdentifier;

@end
@implementation SpeakViewController
@synthesize speakMessage;
@synthesize receivedMessages;
@synthesize messagesView;
@synthesize shoutTo;
@synthesize dirtyrWords;
@synthesize myCity;
@synthesize myCountry;
@synthesize currentRegisteredListeningLocationId;
@synthesize pickerView;
@synthesize listenerThread;
@synthesize redrawThread;
@synthesize shoutButton;
@synthesize statusMessage;
@synthesize cityButton;
//@synthesize store;
@synthesize displayMessage;


NSString *shout99ProductId=@"shout99";
NSString *shoutUnlimitedProductId = @"shout199";

NSString *defaultNullLocationId=@"99999";
int messageNumber=0;
NSString *requestToken=@"fopa032939478201020929";
NSString *serverHost=@"ishout-app.appspot.com";
//NSString *serverHost=@"localhost:8080";
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
		NSMutableArray *m = [[NSMutableArray alloc] init];
		self.receivedMessages=m;
		[m release];
		//load previously selected country and city
		iSpeakAppDelegate *delegate = (iSpeakAppDelegate*)[UIApplication sharedApplication].delegate;
		self.myCountry= delegate.configuration.myCountry;
		self.myCity=delegate.configuration.myCity;
		//load dirty words
		NSBundle *mainBundle = [NSBundle mainBundle];
		NSString *dirtyWordsPfile = [mainBundle pathForResource:@"dirty-words" ofType:@"plist"];
		NSArray *n = [[NSArray alloc] initWithContentsOfFile:dirtyWordsPfile];
		self.dirtyrWords=n;
		[n release];
		DebugLog(@"find %i dirty words",[self.dirtyrWords count]);
		
		
    }
    return self;
}
- (void)dealloc {
	[displayMessage release];
//	[store release];
	[cityButton release];
	[shoutButton release];
	[currentRegisteredListeningLocationId release];
	[pickerView release];
	[listenerThread release];
	[redrawThread release];
	[dirtyrWords release];
	[myCity release];
	[myCountry release];
	[speakMessage release];
	[receivedMessages release];
	[messagesView release];
	[shoutTo release];
	[statusMessage release];
	[super dealloc];
}
/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	//register shut-down event
	UIApplication *app = [UIApplication sharedApplication];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:app];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:app];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:app];
	[self registerForKeyboardNotifications];
	//
	self.currentRegisteredListeningLocationId=defaultNullLocationId;
	self.view.backgroundColor=[UIColor blackColor];
	self.messagesView.font=[UIFont systemFontOfSize:13];
	self.messagesView.textColor=[UIColor whiteColor];
	self.statusMessage.font=[UIFont systemFontOfSize:14];
	self.statusMessage.textColor=[UIColor whiteColor];
	if(self.myCity==nil){
		[self showBillboardStayMessage:NSLocalizedString(@"Please select city",@"Please select city")];
		[self performSelector:@selector(displayShoutsQuota) withObject:nil afterDelay:12];
	}else{
		[self performSelector:@selector(displayShoutsQuota) withObject:nil afterDelay:1];
	}
	iSpeakAppDelegate *delegate = (iSpeakAppDelegate*)[UIApplication sharedApplication].delegate;
	NSMutableString *m = [[NSMutableString alloc] initWithString:@""];
	self.displayMessage = m;
	[m release];
	if([delegate.configuration isOS3OrLater]){
//		paymentProcessingDone = YES;
		[self showProgressMessage:@"Register process handler\n"];
		[self registerStoreProcess];
	}
}

-(void)applicationWillBecomeActive:(NSNotification *)notification{
	DebugLog(@"become active....");
}
-(void)applicationWillResignActive:(NSNotification *)notification{
	DebugLog(@"resign active...");
}
-(void)viewWillAppear:(BOOL)animated{
	[self.cityButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[self.cityButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
	[self.shoutButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[self.shoutButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
	if(self.myCity!=nil){
		[self.cityButton setTitle:self.myCity forState:UIControlStateNormal];
		[self.cityButton setTitle:self.myCity forState:UIControlStateHighlighted];
	}else{
		[self.cityButton setTitle:NSLocalizedString(@"City Not Set",@"City Not Set") forState:UIControlStateNormal];
		[self.cityButton setTitle:NSLocalizedString(@"City Not Set",@"City Not Set") forState:UIControlStateHighlighted];
	}
	[self.shoutButton setTitle:NSLocalizedString(@"Shout",@"Shout") forState:UIControlStateNormal];
	[self.shoutButton setTitle:NSLocalizedString(@"Shout",@"Shout") forState:UIControlStateHighlighted];
	
	if(self.myCountry!=nil){
		//turn on
		NSString *newLocationId = [self findLocationIdWithCountry:self.myCountry city:self.myCity];
		[self registerListenerWithLocation:newLocationId replaceOldLocation:defaultNullLocationId];
		[newLocationId release];
		[self startListening];
		[self startRefreshingMessages];
	}
}



- (NSString*)findLocationIdWithCountry:(NSString*)country city:(NSString*)city{
	if(city==nil){
		return defaultNullLocationId;
	}
	return [[NSString alloc] initWithFormat:@"%@-%i",country,[city hash]];
}

- (void)registerListenerWithLocation:(NSString*)newId replaceOldLocation:(NSString*)oldId{
	//create send to server
	NSString *messageString = [[NSString alloc] initWithFormat:@"token=%@&command=register&locationId=%@&replaceLocationId=%@",requestToken,newId,oldId];
	DebugLog(@"request:%@", messageString);
    //NSString *encodedMessageString = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)messageString, CFSTR(""), CFSTR(" %\"?=&+<>;:-"),  kCFStringEncodingUTF8);
	NSString *urlString = [[NSString alloc] initWithFormat:@"http://%@/serve?%@",serverHost, messageString];
	NSError *error = nil;
	InternetUtility *u = [[InternetUtility alloc] init];
	NSString *replyString = [u sendGetMethod:urlString error:error];
	[urlString release];
	[messageString release];
	DebugLog(@"response:%@",replyString);
	[u release];
	self.currentRegisteredListeningLocationId = newId;
}

- (void)startListening{
	DebugLog(@"prepare to start listening......");
	if(self.listenerThread!=nil){
		if([self.listenerThread isFinished]){
			DebugLog(@"it is finished, but not null");
			self.listenerThread=nil;
		}else{
			DebugLog(@"it is not null, and it is not finished, do nothig, please click later");
			return;
		}
	}
	if(self.listenerThread==nil){
		DebugLog(@"creating new thread of Listener...");
		NSThread *t = [[NSThread alloc] initWithTarget:self selector:@selector(listen) object:nil];
		self.listenerThread=t;
		[t release];
	}
	[self.listenerThread start];
}
- (void)stopListening{
	DebugLog(@"prepare to stop listening...");
	if(self.listenerThread!=nil){
		DebugLog(@"cancelling listener thread...");
		[self.listenerThread cancel];
	}


}

- (void)startRefreshingMessages{
	DebugLog(@"prepare to start redraw thread text-area...");
	if(self.redrawThread!=nil){
		if([self.redrawThread isFinished]){
			DebugLog(@"it is finished, but not null");
			self.redrawThread=nil;
		}else{
			DebugLog(@"it is not null, and it is not finished, do nothig, please click later");
			return;
		}
	}
	if(self.redrawThread==nil){
		DebugLog(@"creating redraw thread...");
		NSThread *t = [[NSThread alloc] initWithTarget:self selector:@selector(redrawTextView) object:nil];
		self.redrawThread=t;
		[t release];
	}

	[self.redrawThread start];
	
}
- (void)stopRefreshingMessages{
	DebugLog(@"prepare to stop redraw-text thread...");
	if(self.redrawThread!=nil){
		DebugLog(@"cancelling redraw-text thread...");
		[self.redrawThread cancel];
	}
}

-(void)listen{
	NSAutoreleasePool* p = [[NSAutoreleasePool alloc] init];
	DebugLog(@"lister thread is running....");
	InternetUtility *internetUtility=[[InternetUtility alloc] init];

	iSpeakAppDelegate *delegate = (iSpeakAppDelegate*)[UIApplication sharedApplication].delegate;
	double lastQueryS = 0;
	double delayS=5.0;
	NSString *latestMessageId=defaultNullLocationId;
	int prevId=[self.currentRegisteredListeningLocationId hash];
	while(![self.listenerThread isCancelled]){
		//query?
		double currentS = [NSDate timeIntervalSinceReferenceDate];
		if(currentS-lastQueryS<delayS){
			//no time to query server yet
			continue;
		}
		else{
			if([self.currentRegisteredListeningLocationId hash]!=prevId){
				//listener city changed
				DebugLog(@"listener city changed!");
				[self.receivedMessages removeAllObjects];
				latestMessageId=defaultNullLocationId;
				prevId = [self.currentRegisteredListeningLocationId hash];
			}
			
			//send request to server and update text-view
			NSString *messageString = [[NSString alloc] initWithFormat:@"token=%@&command=download&locationId=%@&lastMessageId=%@",requestToken, self.currentRegisteredListeningLocationId,latestMessageId];
//			DebugLog(@"request:%@", messageString);
			NSString *urlString = [[NSString alloc] initWithFormat:@"http://%@/serve?%@",serverHost,messageString];
			NSError *error = nil;
			//replyString format SUCCESS|lastMessageId|3test^4test
			NSString *replyString = [internetUtility sendGetMethod:urlString error:error];
			[urlString release];
			[messageString release];
			if(error){
				DebugLog(@"connection failed &@", error.localizedDescription);
				[self.receivedMessages addObject:@"Connection failed or server was too busy"];
				delayS = 10;
			}else{
//				DebugLog(@"response:%@",replyString);
				if(replyString!=nil && [replyString rangeOfString:@"SUCCESS"].location!=NSNotFound){
					NSArray *components = [[replyString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByString:@"|"];
					if(components!=nil && [components count]>=2){
						if([[components objectAtIndex:0] caseInsensitiveCompare:@"SUCCESS"]==0){
							latestMessageId = [components objectAtIndex:1];
							if([components count]>2){
								NSString *m = [components objectAtIndex:2];
								if([m caseInsensitiveCompare:@""]!=0){
									NSArray *newMessages = [m componentsSeparatedByString:@"^"];
									if([newMessages count]>0){
										//filter dirty ones based on allowed-number
										int dirtyCount=0;
										int displayCount=0;
										for(int i=0;i<[newMessages count];i++){
											NSString *msg = [newMessages objectAtIndex:i];
											if([msg length]>1){
												NSString *s = [msg substringToIndex:1];
												if([s intValue] > 3){
													//dirty!
													dirtyCount++;
													if(dirtyCount<delegate.configuration.dirtyLevel){
														//display this message
														displayCount++;
														[self.receivedMessages addObject:[msg substringFromIndex:1]];
													}
												}else{
													//not dirty
													displayCount++;
													[self.receivedMessages addObject:[msg substringFromIndex:1]];
												}
											}else{
												//empty string, igore
											}
										}
										//not figure out the time before next call based on display count
										if(displayCount<5){
											delayS=5;
										}else{
											delayS=(int)(displayCount/1.0*0.75);
										}
									}
								}
							}
						}
					}
				}else{
					[self.receivedMessages addObject:@"Connection failed or server was too busy"];
					delayS = 10;
				}
				[replyString release];
				//DebugLog(@"sleeping %i seconds", delayS);
			}
			
			lastQueryS = currentS;
		}
		[NSThread sleepForTimeInterval:1];
	}
	//exit
	[internetUtility release];
	//check redraw thread to make sure listener always stop AFTER redraw
	int waitCount=0;
	while(waitCount<10 && self.redrawThread!=nil && ![self.redrawThread isFinished]){
		[NSThread sleepForTimeInterval:2];
		waitCount++;
	}
	DebugLog(@"listener thread stoped");
	[p release];
}

-(void)redrawTextView{
	NSAutoreleasePool* p = [[NSAutoreleasePool alloc] init];
	DebugLog(@"redraw-text thread is running....");
	int lastMessageToDisplay=0;
	NSMutableString *messagesForDisplay = [[NSMutableString alloc] initWithString:@""];
	while(![self.redrawThread isCancelled]){
		//check received messages array
		//DebugLog(@"message total %i",[self.receivedMessages count]);
		if(lastMessageToDisplay>15){
			//cut off the old string from the text view
			[messagesForDisplay deleteCharactersInRange:NSMakeRange(0, [messagesForDisplay length])];
			lastMessageToDisplay=0;
		}
		if([self.receivedMessages count]>0){
			NSString *s = [self.receivedMessages objectAtIndex:0];
			if([s length]>1){
				[messagesForDisplay appendFormat:@"%@\n", s];
				lastMessageToDisplay++;
			}
			[self.receivedMessages removeObjectAtIndex:0];
			//DebugLog(@"textview:%@", self.messagesForDisplay);
			
			[self performSelectorOnMainThread:@selector(redrawPlease:) withObject:messagesForDisplay waitUntilDone:NO];
		}
		//sleep  seconds
		[NSThread sleepForTimeInterval:1.0];
		
	}
	[messagesForDisplay release];
	[self.receivedMessages removeAllObjects];
	DebugLog(@"redraw-text thread stoped");
	[p release];
}

-(void)redrawPlease:(NSString*)messageForDisplay{
	//iSpeakAppDelegate *delegate = (iSpeakAppDelegate*)[UIApplication sharedApplication].delegate;
	self.messagesView.text=messageForDisplay;
	//DebugLog(@"will draw:%@", self.messagesView.text);
	[self.messagesView scrollRangeToVisible:NSMakeRange([self.messagesView.text length], 0)];
	[self.messagesView setNeedsDisplay];
	
}


- (void)didSetMyCountry:(NSString*)country city:(NSString*)city{
	self.myCity=city;
	self.myCountry=country;
	NSString *m = [[NSString alloc]initWithFormat:@"%@",self.myCity];
	[self.cityButton setTitle:m forState:UIControlStateNormal];
	[self.cityButton setTitle:m forState:UIControlStateHighlighted];
	[m release];
	if(self.listenerThread!=nil && [self.listenerThread isExecuting]){
		//already listening
		NSString *newLocationId = [self findLocationIdWithCountry:self.myCountry city:self.myCity];
		if([self.currentRegisteredListeningLocationId caseInsensitiveCompare:newLocationId]!=0){
			//change registered location to server and current registered id
			[self registerListenerWithLocation:newLocationId replaceOldLocation:self.currentRegisteredListeningLocationId];
		}
		[newLocationId release];
	}else{
		//start listening
		//turn on
		NSString *newLocationId = [self findLocationIdWithCountry:self.myCountry city:self.myCity];
		[self registerListenerWithLocation:newLocationId replaceOldLocation:defaultNullLocationId];
		[newLocationId release];
		[self startListening];
		[self startRefreshingMessages];
	}
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}




-(IBAction)textFieldDoneEditing:(id)sender{
	[sender resignFirstResponder];
	[self shout:sender];
}

-(void)updateShoutQuotaAfterPayment:(NSString*)productId{
	iSpeakAppDelegate *delegate = (iSpeakAppDelegate*)[UIApplication sharedApplication].delegate;

	if([productId caseInsensitiveCompare:shout99ProductId]==0){
		delegate.configuration.shoutQuota=99;
	}else if([productId caseInsensitiveCompare:shoutUnlimitedProductId]==0){
		delegate.configuration.shoutQuota=99999; //means UNLIMITED
	}else{
		//wrong!!!!
		return;
	}
	[delegate.configuration saveToFile];
	NSString *msg = [[NSString alloc] initWithFormat:@"%@", NSLocalizedString(@"Thank you for purchasing shouts",@"Thank you for purchasing shouts")]; 
	[self showBillboardTemporaryMessage:msg];
	[msg release];
	[self performSelector:@selector(displayShoutsQuota) withObject:nil afterDelay:12];
}

-(void)processPurchase:(NSString*)productId{
	//start the payment processing....
	[self purchase:productId];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex  {
	if (buttonIndex == 1) {  
		//.99 for 99
		[self processPurchase:shout99ProductId];
	}else if(buttonIndex == 2){
		//1.99 for unlimited
		[self processPurchase:shoutUnlimitedProductId];
	}else{
		//no buy
		return;
	}
}

-(void)displayPurchaseView{
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Purchase More Shouts",@"Purchase More Shouts")
														message:nil
													   delegate:self
											  cancelButtonTitle:NSLocalizedString(@"No, thanks",@"No, thanks")
											  otherButtonTitles:NSLocalizedString(@"99 shouts for $0.99",@"99 shouts for $0.99"),NSLocalizedString(@"Unlimited shouts for $1.99",@"Unlimited shouts for $1.99"),nil];
	alertView.opaque=YES;
	alertView.tag=purchaseView;
	[alertView show];
	[alertView release];

}

BOOL shoutButtonStillDown=NO;
-(IBAction)shoutButtonTouchedDown:(id)sender{
	//detect the user hold the button for 2 seconds
	shoutButtonStillDown=YES;
	[self performSelector:@selector(showPowerBallButton) withObject:nil afterDelay:2];
}

BOOL powerBall=NO;
-(void)showPowerBallButton{
	if(shoutButtonStillDown){
		powerBall=YES;
		[self.shoutButton setTitle:NSLocalizedString(@"Power Ball",@"Power Ball") forState:UIControlStateHighlighted];
		DebugLog(@"shout button changed to PowerBall");
	}
}
-(IBAction)shout:(id)sender{
	shoutButtonStillDown = NO;

	if(powerBall){
		DebugLog(@"send power ball message!! set back title-state");
		[self.shoutButton setTitle:NSLocalizedString(@"Shout",@"Shout") forState:UIControlStateHighlighted];
	}
	iSpeakAppDelegate *delegate = (iSpeakAppDelegate*)[UIApplication sharedApplication].delegate;
	if(delegate.configuration.shoutQuota!=99999 && delegate.configuration.shoutQuota<1){
		if([delegate.configuration isOS3OrLater]){
			//popup purchase
			[self displayPurchaseView];
			return;
		}else{
			NSString *msg = [[NSString alloc] initWithFormat:@"%@", NSLocalizedString(@"No shots left",@"No shots left")]; 
			[self showBillboardStayMessage:msg];
			[msg release];
			return;
		}
	}
	if(self.myCountry==nil){
		[self showTheCityPicker:shoutButtonClicked];
		return;
	}

	if(self.speakMessage==nil){
		DebugLog(@"speak message text field is null");
		//create a input text and move up with keyboard
		UITextField *t = [[UITextField alloc] initWithFrame:CGRectMake(10, 480, 300, 20)];
		t.borderStyle =  UITextBorderStyleBezel;
		t.textColor = [UIColor darkTextColor];
		t.backgroundColor = [UIColor grayColor];
		t.font=[UIFont systemFontOfSize:14];
		t.keyboardType=UIKeyboardTypeDefault;
		t.autocorrectionType=UITextAutocorrectionTypeNo;
		t.returnKeyType=UIReturnKeyDone;
		self.speakMessage=t;
		[t release];
		//register the keyboard DONE event
		[self.speakMessage addTarget:self action:@selector(textFieldDoneEditing:) forControlEvents:UIControlEventEditingDidEndOnExit];
		//add the view
		[self.view addSubview:self.speakMessage];
	}
	if(self.speakMessage.text==nil || [self.speakMessage.text caseInsensitiveCompare:@""]==0){
		DebugLog(@"speakmessage is empty");
		[self.speakMessage becomeFirstResponder];
		return;
	}
	
	//create send to server
//	 [UIApplication sharedApplication].networkActivityIndicatorVisible=YES;
	
	int dirtyLevelOfMessage = [self checkDirtyLevel:self.speakMessage.text];
	if(dirtyLevelOfMessage>3){
		//add the dirty-allow-count: the more dirty words you shout, the more you get
		delegate.configuration.dirtyLevel++;
	}
	
	NSMutableString *messageString = [[NSMutableString alloc] initWithFormat:@"token=%@&command=upload&msg=%i%@&locationId=%@",requestToken,dirtyLevelOfMessage,self.speakMessage.text,self.currentRegisteredListeningLocationId];
	if(powerBall){
		[messageString appendFormat:@"&%@",@"powerBall=YES"];
	}
	DebugLog(@"request:%@", messageString);
	NSString *urlString = [[NSString alloc] initWithFormat:@"http://%@/serve?%@",serverHost,messageString];
	InternetUtility *internetUtility=[[InternetUtility alloc] init];
	NSError *error = nil;
	NSString *replyString = [internetUtility sendGetMethod:urlString error:error];
	[urlString release];
	[messageString release];
	[internetUtility release];
	//clear the input
	self.speakMessage.text=@"";
//	[UIApplication sharedApplication].networkActivityIndicatorVisible=NO;
	if(error){
		DebugLog(@"error:%@",[error localizedDescription]);
		NSString *msg = [[NSString alloc] initWithFormat:@"%@", NSLocalizedString(@"Connection failed",@"Connection failed! Error")]; 
		[self showBillboardStayMessage:msg];
		[msg release];
	}else{
		DebugLog(@"response:%@",replyString);
		if(replyString!=nil && [replyString rangeOfString:@"SUCCESS"].location!=NSNotFound){
			//response starts with 1234SUCCESS 1234 is a unique code to represent the number of user who are listening
			NSString *numberOfHeard = [[replyString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] substringWithRange:NSMakeRange(0,[replyString rangeOfString:@"SUCCESS"].location)];
			if(numberOfHeard==nil || [numberOfHeard caseInsensitiveCompare:@""]==0){
				numberOfHeard = @"0";
			}
			NSString *p = NSLocalizedString(@"Shouted to",@"Shouted to");
			if(powerBall){
				p = NSLocalizedString(@"PowerBalled to",@"PowerBalled to");
			}
			
			NSString *m = [[NSString alloc] initWithFormat:@"%@ %@!!! %@ %@!!!",p, myCity,numberOfHeard,NSLocalizedString(@"people were listening",@"people were listening")];
			int delay=10;
			[self showBillboardTemporaryMessage:m];
			[m release];
			if(!powerBall){
				NSString *m = [[NSString alloc] initWithFormat:@"%@",NSLocalizedString(@"Wanna to bowb the city with your shouts? Try Power-Ball - hold the Shout Button for 2 seconds, and you will be able to send repeated messages (up to 10 times)",@"Wanna to bowb the city with your shouts? Try Power-Ball - hold the Shout Button for 2 seconds, and you will be able to send repeated messages (up to 10 times)")];
				[self performSelector:@selector(showBillboardTemporaryMessage:) withObject:m afterDelay:10];
				[m release];
				delay+=40;
			}
			//reduce shout quota if it is not UNLIMITED
			if(delegate.configuration.shoutQuota<99999){
				if(powerBall){
					delegate.configuration.shoutQuota=delegate.configuration.shoutQuota-10;
					if(delegate.configuration.shoutQuota<0){
						delegate.configuration.shoutQuota=0;
					}
				}else{
					delegate.configuration.shoutQuota--;
				}
			}
			[self performSelector:@selector(displayShoutsQuota) withObject:nil afterDelay:delay];	
		}else{
			NSString *m = [[NSString alloc] initWithFormat:@"%@",NSLocalizedString(@"Connection failed or server was too busy",@"Connection failed or server was too busy")];
			[self showBillboardStayMessage:m];
			[m release];
		}
		[replyString release];
	}
	powerBall=NO;
}

-(void)displayShoutsQuota{
	iSpeakAppDelegate *delegate = (iSpeakAppDelegate*)[UIApplication sharedApplication].delegate;
	NSString *s = nil;
	if(delegate.configuration.shoutQuota<99999){
		s = [[NSString alloc] initWithFormat:@"%@ %i %@",NSLocalizedString(@"You have",@"You have"),delegate.configuration.shoutQuota,NSLocalizedString(@"shouts left",@"shouts left")];
	}else{
		s = [[NSString alloc] initWithFormat:@"%@",NSLocalizedString(@"You have unlimited shouts",@"You have unlimited shouts")];
	}
	[self showBillboardStayMessage:s];
	[s release];
}

- (int)checkDirtyLevel:(NSString*)message{
	//1
	//5 dirty
	int dirtyLevel=1;
	for(int i=0;i<[self.dirtyrWords count];i++){
		if(message!=nil && [message rangeOfString:[self.dirtyrWords objectAtIndex:i]].location!=NSNotFound){
			//
			DebugLog(@"dirty! %@",[self.dirtyrWords objectAtIndex:i]);
			dirtyLevel=5;
			break;
		}
	}
	return dirtyLevel;
}


-(void)showTheCityPicker:(int)purpose{
	if(self.pickerView==nil){
		DebugLog(@"self.pickeView is null, creating new instance");
		CitySelectionView2 *p = [[CitySelectionView2 alloc]initWithFrame:CGRectMake(0, 460, 320, 300) country:self.myCountry city:self.myCity];
		self.pickerView = p;
		[p release];
	}
	//change everything
	self.pickerView.tag=purpose;
	
	[self.pickerView.doneButton addTarget:self action:@selector(donePickCountryStateCity:) forControlEvents:UIControlEventTouchUpInside];
	DebugLog(@"subview total %i",[[self.view subviews] count]);
	[self.view addSubview:self.pickerView];
	[ UIView beginAnimations: nil context: nil ]; // Tell UIView we're ready to start animations.
	[ UIView setAnimationCurve: UIViewAnimationCurveEaseInOut ];
	[ UIView setAnimationDuration: 1.0f ]; // Set the duration to 1 second.
	CGRect f2 = self.pickerView.frame;
	f2.origin.y=210;
	self.pickerView.frame=f2;
	[UIView commitAnimations];
}


-(IBAction)goToSetMyCountryAndCity:(id)sender{
	[self showTheCityPicker:locationEditButtonClicked];
}

-(void)donePickCountryStateCity:(id)sender{
	[ UIView beginAnimations: nil context: nil ]; // Tell UIView we're ready to start animations.
	[ UIView setAnimationCurve: UIViewAnimationCurveEaseInOut ];
	[ UIView setAnimationDuration: 1.0f ]; // Set the duration to 1 second.
	[ UIView setAnimationDidStopSelector:@selector(removePickerView:)];
	CGRect f2 = self.pickerView.frame;
	f2.origin.y=490;
	self.pickerView.frame=f2;
	[UIView commitAnimations];
	//handle the change of location - to change listener registration
	[self didSetMyCountry:self.pickerView.selectedCountry city:self.pickerView.selectedCity];
	//continue whatever the user meaned to do based on the purpose
	if(self.pickerView.tag==shoutButtonClicked){
		[self shout:self.shoutButton];
	}else{
		//do nothing
	}
}

- (void)removePickerView:(NSString *)animationID finished:(BOOL)finished context:(void *)context{
	[self.pickerView removeFromSuperview];
}

-(void)applicationWillTerminate:(NSNotification *)notification{
	//remove from listener
	if(self.currentRegisteredListeningLocationId!=defaultNullLocationId){
		[self registerListenerWithLocation:defaultNullLocationId replaceOldLocation:self.currentRegisteredListeningLocationId];
	}
	//save the selected country and city
	iSpeakAppDelegate *delegate = (iSpeakAppDelegate*)[UIApplication sharedApplication].delegate;
	delegate.configuration.myCountry=self.myCountry;
	delegate.configuration.myCity=self.myCity;
	//DebugLog(@"saving country and cities %@ %@ %@ %@",delegate.configuration.myCountry, delegate.configuration.myCity, delegate.configuration.shoutCountry, delegate.configuration.shoutCity);
	[delegate.configuration saveToFile];
}



-(int)showBillboardTemporaryMessage:(NSString *)msg{
	self.statusMessage.text=msg;
	CGRect originalFrame = CGRectMake(20, self.statusMessage.frame.origin.y, [msg length]*10, self.statusMessage.frame.size.height);
	//move to right side
	int animationDuration=[msg length]*0.3;
	self.statusMessage.frame = CGRectMake(320+[msg length]*0.7, originalFrame.origin.y, [msg length]*10, originalFrame.size.height);
		//move to left then disaapear
		[ UIView beginAnimations: nil context: nil ]; // Tell UIView we're ready to start animations.
		[ UIView setAnimationCurve: UIViewAnimationCurveEaseInOut ];
		[ UIView setAnimationDuration: animationDuration]; // Set the duration.
		CGRect f2 = self.statusMessage.frame;
		f2.origin.x=(int)[msg length]*(-7)+10;
		self.statusMessage.frame=f2;
		[UIView commitAnimations];
	return animationDuration;
}

-(void)showBillboardStayMessage:(NSString *)msg{
	self.statusMessage.text=msg;
	CGRect originalFrame = CGRectMake(20, self.statusMessage.frame.origin.y, [msg length]*10, self.statusMessage.frame.size.height);
	//move to right side
	self.statusMessage.frame = CGRectMake(360, originalFrame.origin.y, [msg length]*10, originalFrame.size.height);	
	//move to left and stay
	[ UIView beginAnimations: nil context: nil ]; // Tell UIView we're ready to start animations.
	[ UIView setAnimationCurve: UIViewAnimationCurveEaseInOut ];
	[ UIView setAnimationDuration: 12 ]; // Set the duration to 1 second.
	CGRect f2 = self.statusMessage.frame;
	f2.origin.x=originalFrame.origin.x;
	self.statusMessage.frame=f2;
	[UIView commitAnimations];
}


//-----------------store kit-----------------
-(void)registerStoreProcess{
	[[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

-(void)purchase:(NSString*)kMyFeatureIdentifier{
//	if(!self.paymentProcessingDone){
//		//not done yet
//		[self showProgressMessage:NSLocalizedString(@"Current purchasement not processed yet, please wait",@"Current purchasement not processed yet, please wait\n")];
//		return;
//	}
//	self.paymentProcessingDone=NO;
//	self.paidSuccess=NO;
	SKPayment *payment = [SKPayment paymentWithProductIdentifier:kMyFeatureIdentifier];
	[[SKPaymentQueue defaultQueue] addPayment:payment];
}

-(void)showProgressMessage:(NSString*)msg{
	[self.displayMessage insertString:msg atIndex:0];
} 

-(void)recordTransaction:(SKPaymentTransaction*)transaction{
	[self showProgressMessage:[NSString stringWithFormat:@"transaction recorded....\n"]];
}
-(void)provideContent:(NSString*)productIdentifier{
	
	[self showProgressMessage:[NSString stringWithFormat:@"add content to user....\n"]];
	[self updateShoutQuotaAfterPayment:productIdentifier];
}

- (void) requestProductData:(NSString*)kMyFeatureIdentifier
{
	[self showProgressMessage:[NSString stringWithFormat:@"requesting prod info....\n"]];
	SKProductsRequest *request= [[SKProductsRequest alloc] initWithProductIdentifiers: [NSSet setWithObject: kMyFeatureIdentifier]];
	request.delegate = self;
	[request start];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSArray *myProduct = response.products;
    [self showProgressMessage:[NSString stringWithFormat:@"recived product info....\n"]];
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
	[self showProgressMessage:[NSString stringWithFormat:@"updating tranasctions....\n"]];
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
				[self showProgressMessage:[NSString stringWithFormat:@"state SKPaymentTransactionStatePurchased....\n"]];
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
				[self showProgressMessage:[NSString stringWithFormat:@"state SKPaymentTransactionStateFailed....\n"]];
                [self failedTransaction:transaction];
                break;
            default:
                break;
        }
    }
}

- (void) completeTransaction: (SKPaymentTransaction *)transaction
{
//	self.paymentProcessingDone=YES;
//	self.paidSuccess=YES;
	[self showProgressMessage:[NSString stringWithFormat:@"transaction success....\n"]];
    [self recordTransaction: transaction];
    [self provideContent: transaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Payment Details",@"Payment Details")
														message:self.displayMessage
													   delegate:self
											  cancelButtonTitle:NSLocalizedString(@"Close",@"Close")
											  otherButtonTitles:nil,nil];
	alertView.opaque=YES;
	[alertView show];
	[alertView release];
	
}

- (void) failedTransaction: (SKPaymentTransaction *)transaction
{
//	self.paymentProcessingDone=YES;
//	self.paidSuccess=NO;
	[self showProgressMessage:[NSString stringWithFormat:@"transaction failed....\n"]];
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Payment Details",@"Payment Details")
														message:self.displayMessage
													   delegate:self
											  cancelButtonTitle:NSLocalizedString(@"Close",@"Close")
											  otherButtonTitles:nil,nil];
	alertView.opaque=YES;
	[alertView show];
	[alertView release];
	
}



//----------------- move text field and button up when keyboard displays
BOOL keyboardShown=NO;
- (void)registerForKeyboardNotifications 
{ 
    [[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(keyboardWasShown:) 
												 name:UIKeyboardDidShowNotification object:nil]; 
    [[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(keyboardWasHidden:) 
												 name:UIKeyboardDidHideNotification object:nil]; 
} 
// Called when the UIKeyboardDidShowNotification is sent. 
CGRect originalFrame;
- (void)keyboardWasShown:(NSNotification*)aNotification 
{ 
    if (keyboardShown) 
        return; 
    NSDictionary* info = [aNotification userInfo]; 
    // Get the size of the keyboard. 
    NSValue* aValue = [info objectForKey:UIKeyboardBoundsUserInfoKey]; 
    CGSize keyboardSize = [aValue CGRectValue].size; 
    originalFrame = self.speakMessage.frame;
	self.speakMessage.frame=CGRectMake(originalFrame.origin.x, originalFrame.origin.y-keyboardSize.height + 480 - originalFrame.size.height - originalFrame.origin.y, originalFrame.size.width, originalFrame.size.height);
	
    keyboardShown = YES; 
} 
// Called when the UIKeyboardDidHideNotification is sent 
- (void)keyboardWasHidden:(NSNotification*)aNotification 
{ 
	self.speakMessage.frame=originalFrame;

    keyboardShown = NO; 
} 
@end
