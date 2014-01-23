//
//  FacebookController.h
//  FacebookIntegration
//
//  Created by Roman Kuznetsov on 29/11/13.
//
//

#import <Foundation/Foundation.h>
#import "FacebookController-Interface.h"

@interface FacebookController : NSObject

+ (void) checkIfLoggedIn;
+ (void) loginFacebook;
+ (bool) isLoggedIn;
+ (void) logoutFacebook;

+ (void) requestPublishPermissions;
+ (bool) hasPublishPermissions;
+ (void) requestFriend;
+ (void) postStory;

+ (void) getUserInfo;

+ (NSString*) getAppID;
+ (NSArray*) getBasicPermissions;
+ (NSString*) getName;

+ (NSString*) getProfilePicture: (NSString*) filename;
+ (void) onProfilePictureReady: (NSString*) filename;

@end
