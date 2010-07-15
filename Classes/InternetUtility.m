//
//  InternetUtility.m
//  iSpeak
//
//  Created by Junqiang You on 5/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "InternetUtility.h"


@implementation InternetUtility

-(NSString*)sendGetMethod:(NSString*)urlString error:(NSError *)error{
	NSString *urlEncodedString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:[NSURL URLWithString:urlEncodedString]];
	
	// send it
	NSURLResponse *response;
	NSData *serverReply = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	[request release];
	if(error){
		return nil;
	}else{
		//NSString *replyString = [[NSString alloc] initWithBytes:[serverReply bytes] length:[serverReply length] encoding: NSUTF8StringEncoding];
		NSString *replyString = [[NSString alloc] initWithData:serverReply encoding:NSUTF8StringEncoding];
		return replyString;
	}
}
@end
