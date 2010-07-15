//
//  GlobalConfiguration.h
//  iSpeak
//
//  Created by Junqiang You on 5/6/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum{
	FREE_APP=1,
	PAID_APP=2
} APP_RELEASE_TYPE;
@interface GlobalConfiguration : NSObject {
	int dirtyLevel;
	int shoutQuota;
	APP_RELEASE_TYPE appPrivilege;
	NSString *myCity;
	NSString *myCountry;
	NSString *osVersion;
	NSString *deviceId;
}
@property(nonatomic, retain) NSString *osVersion;
@property(nonatomic, retain) NSString *deviceId;
@property APP_RELEASE_TYPE appPrivilege;
@property int dirtyLevel;
@property int shoutQuota;
@property(nonatomic, retain) NSString *myCity;
@property(nonatomic, retain) NSString *myCountry;
-(void)saveToFile;
-(BOOL)isOS3OrLater;
-(NSString*)decodeDeviceSpecificString:(NSString*)encodedString;
-(NSString*)encodeDeviceSpecificString:(NSString*)inputString;
@end
