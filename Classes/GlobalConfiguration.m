//
//  GlobalConfiguration.m
//  iSpeak
//
//  Created by Junqiang You on 5/6/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "GlobalConfiguration.h"



@implementation GlobalConfiguration
@synthesize dirtyLevel;
@synthesize shoutQuota;
@synthesize appPrivilege;
@synthesize myCity;
@synthesize myCountry;
@synthesize deviceId;
@synthesize osVersion;

int FREE_APP_SHOUT=10;
int PAID_APP_SHOUT=99;
- (id)init{
	if((self=[super init])!=nil){
		
		self.appPrivilege=PAID_APP;
		
		
		
		NSBundle *bundle = [NSBundle mainBundle];
		NSDictionary *dictionary = [bundle infoDictionary];
		if([dictionary objectForKey:@"SignerIdentity"]!=nil){
			//cracked version!
			self.appPrivilege=FREE_APP;
		}
		
		self.dirtyLevel = 0; //default no dirty allowed
		if(self.appPrivilege==FREE_APP){
			self.shoutQuota=FREE_APP_SHOUT;
		}else if(self.appPrivilege==PAID_APP){
			self.shoutQuota =PAID_APP_SHOUT;
		}
		DebugLog(@"setting quota initially %i", self.shoutQuota);
		//check device os version
		self.osVersion = [[UIDevice currentDevice] systemVersion];
		self.deviceId = [[UIDevice currentDevice] uniqueIdentifier];
		DebugLog(@"os %@ device %@", self.osVersion, self.deviceId);
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentDirectory = [paths objectAtIndex:0];
		NSString *settingPath = [documentDirectory stringByAppendingPathComponent:@"iSpeak.setting"];
		NSFileManager *fileManager = [NSFileManager defaultManager];
		if([fileManager fileExistsAtPath:settingPath]){
			NSDictionary *fileAttributes = [fileManager fileAttributesAtPath:settingPath traverseLink:YES];
			if(fileAttributes != nil) {
			
				NSDictionary *dictionary = [[NSDictionary alloc] initWithContentsOfFile:settingPath];
				if([[dictionary allKeys] containsObject:@"dirty-level"]){
					if([@"" compare:[dictionary objectForKey:@"dirty-level"]]!=0){
						self.dirtyLevel= [(NSString*)[dictionary objectForKey:@"dirty-level"] intValue];
					}
				}
				
				if([[dictionary allKeys] containsObject:@"shout-quota"]){
					if([@"" compare:[dictionary objectForKey:@"shout-quota"]]!=0){
					
						NSString *encodedString= [dictionary objectForKey:@"shout-quota"];
						NSString *shoutQuotaString = [self decodeDeviceSpecificString:encodedString];
						if(shoutQuotaString==nil){
							//cracked version????]
							self.shoutQuota=FREE_APP_SHOUT;
						}else{
							self.shoutQuota = [shoutQuotaString intValue];
						}
					}
					DebugLog(@"shout quota from file:%i", self.shoutQuota);
				}else{
					DebugLog(@"no shout quota from file");
				}
			
//				NSDate *fileModDate;
//				if (fileModDate = [fileAttributes objectForKey:NSFileModificationDate]) {
//					DebugLog(@"Modification date: %@\n", fileModDate);
					//is fileModeDate today?
					//if NO, this is the first time it is run today, then, for free version, shot-quota=1
					//for paid-version, saved-quota+1
					//if YES, this is not the first time, use whatever loaded from setting file
//					NSCalendar *calendar = [NSCalendar currentCalendar];
//					unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
//					NSDate *date = [NSDate date];
//					NSDateComponents *comps = [calendar components:unitFlags fromDate:date];
//					NSDate *todayMorning = [calendar dateFromComponents:comps];
//					DebugLog(@"today morning is %@", todayMorning);
//					if([fileModDate compare:todayMorning]==NSOrderedAscending){
//						//firs time today
//						DebugLog(@"this is first time today");
//						if(self.appPrivilege==FREE_APP){
//							self.shoutQuota=1;
//						}else if(self.appPrivilege==PAID_APP){
//							self.shoutQuota = 1 + self.shoutQuota;
//						}
//					}else{
//					}
//					DebugLog(@"finally the quota is %i", self.shoutQuota);
//				}
				if([[dictionary allKeys] containsObject:@"my-country"]){
					if([@"" compare:[dictionary objectForKey:@"my-country"]]!=0){
						self.myCountry= [dictionary objectForKey:@"my-country"];
					}
				}
				if([[dictionary allKeys] containsObject:@"my-city"]){
					if([@"" compare:[dictionary objectForKey:@"my-city"]]!=0){
						self.myCity= [dictionary objectForKey:@"my-city"];
					}
				}
			
				[dictionary release];
			
			}else{
				//invalid file!!!!
				DebugLog(@"file doesn't have attributes!!!");
			}
			
		}else{
			//no setting file
			DebugLog(@"setting file doesn't exist!");
		}
		[self saveToFile];
				
	}
	
	return self;
}

-(void)saveToFile{
	NSMutableArray *keys = [[NSMutableArray alloc] init];
	NSMutableArray *objects = [[NSMutableArray alloc]init];
	
		[keys addObject:@"dirty-level"];
		NSString *s = [[NSString alloc] initWithFormat:@"%i",self.dirtyLevel];
		[objects addObject:s];
		[s release];
	
	[keys addObject:@"shout-quota"];
	NSString *q = [[NSString alloc] initWithFormat:@"%i",self.shoutQuota];
	[objects addObject:[self encodeDeviceSpecificString:q]];
	[q release];
	if(self.myCountry!=nil){
		[keys addObject:@"my-country"];
		[objects addObject:self.myCountry];
	}
	if(self.myCity!=nil){
		[keys addObject:@"my-city"];
		[objects addObject:self.myCity];
	}
	
	NSDictionary *dictionary = [[NSDictionary alloc] initWithObjects:objects forKeys:keys];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentDirectory = [paths objectAtIndex:0];
	[dictionary writeToFile:[documentDirectory stringByAppendingPathComponent:@"iSpeak.setting"] atomically:YES];
	[objects release];
	[keys release];
	[dictionary release];
}

-(BOOL)isOS3OrLater{
	return [self.osVersion hasPrefix:@"3."] || [self.osVersion hasPrefix:@"4."] || [self.osVersion hasPrefix:@"5."];
}

-(NSString*)encodeDeviceSpecificString:(NSString*)inputString{
	NSUInteger deviceNumber = [self.deviceId hash];
	NSString *s = [NSString stringWithFormat:@"%i%@",deviceNumber, inputString];
	DebugLog(@"input:%@ device-UID:%@ device-hash:%i final:%@",inputString, self.deviceId, deviceNumber, s);
	return s;
}


-(NSString*)decodeDeviceSpecificString:(NSString*)encodedString{
	NSUInteger deviceNumber = [self.deviceId hash];
	NSString *d = [[NSString alloc] initWithFormat:@"%i",deviceNumber];
	NSString *result;
	if([encodedString hasPrefix:d]){
		//yes
		result = [encodedString substringFromIndex:[d length]];
	}else{
		result = nil;
	}
	DebugLog(@"encoded:%@ device-UID:%@ device-id:%i decoded:%@",encodedString, self.deviceId, deviceNumber, result);
	[d release];
	return result;
}
- (void)dealloc {

	[osVersion release];
	[deviceId release];		
	[myCity release];
	[myCountry release];
	[super dealloc];
}
@end
