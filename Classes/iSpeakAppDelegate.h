//
//  iSpeakAppDelegate.h
//  iSpeak
//
//  Created by Junqiang You on 5/6/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SpeakViewController;
@class GlobalConfiguration;
@interface iSpeakAppDelegate : NSObject <UIApplicationDelegate> {
	@public
	GlobalConfiguration *configuration;
	@private
    UIWindow *window;
	SpeakViewController *viewControllerSpeak;

}

@property (nonatomic, retain) GlobalConfiguration *configuration;


@end

