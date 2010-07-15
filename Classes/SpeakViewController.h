//
//  SpeakViewController.h
//  iSpeak
//
//  Created by Junqiang You on 5/6/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/SKPaymentQueue.h>
#import <StoreKit/SKProductsRequest.h>
enum CityPickerPurpose {
	listenerSwithTuredOn=999421,
	shoutButtonClicked=999422,
	locationEditButtonClicked=999423
};

enum AlertViewTags{
	purchaseView=999434
};


@class CitySelectionView2;
@class InternetUtility;
//@class MyStore;
@interface SpeakViewController : UIViewController  <SKProductsRequestDelegate,SKPaymentTransactionObserver>{
	@private
	NSString *myCity;
	NSString *myCountry;
	
	IBOutlet UITextField *speakMessage;
	NSMutableArray *receivedMessages;
	IBOutlet UILabel *statusMessage;
	IBOutlet UITextView *messagesView;
	NSString *shoutTo;

	IBOutlet UIButton *shoutButton;
	IBOutlet UIButton *cityButton;
	NSString *currentRegisteredListeningLocationId;
	NSThread *listenerThread;
	NSThread *redrawThread;

	CitySelectionView2 *pickerView;
	
	NSArray *dirtyrWords;
	
	//store kit
	NSMutableString *displayMessage;
//	BOOL paymentProcessingDone;
//	BOOL paidSuccess;
}
-(IBAction)goToSetMyCountryAndCity:(id)sender;
-(IBAction)shoutButtonTouchedDown:(id)sender;
-(IBAction)textFieldDoneEditing:(id)sender;
-(IBAction)shout:(id)sender;
@end
