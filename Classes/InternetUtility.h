//
//  InternetUtility.h
//  iSpeak
//
//  Created by Junqiang You on 5/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface InternetUtility : NSObject {

}
-(NSString*)sendGetMethod:(NSString*)urlString error:(NSError *)error;
@end
