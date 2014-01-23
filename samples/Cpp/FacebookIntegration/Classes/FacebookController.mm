//
//  FacebookController.m
//  FacebookIntegration
//
//  Created by Roman Kuznetsov on 29/11/13.
//
//

#import "FacebookController.h"
#import "FacebookSDK/FacebookSDK.h"

typedef void (^OpenGraphObjectCreationHandler)(NSString* objectId);

@interface FacebookController()

+ (void) createSession;
+ (NSDictionary*) parseURLParams:(NSString *)query;
+ (void) createOpenGraphObjectWithType:(NSString *) type
                                 title:(NSString *) title
                                 url:(NSString *) url
                                 image:(NSString *) image
                                 handler: (OpenGraphObjectCreationHandler) handler;

@end


@implementation FacebookController

// -----------------------------------------------------------------------------
// C++
// -----------------------------------------------------------------------------

FacebookControllerHandler* g_handler = 0;

void FacebookControllerInterface::LoginFacebook()
{
    [FacebookController loginFacebook];
}

bool FacebookControllerInterface::IsLoggedIn()
{
    return [FacebookController isLoggedIn];
}

void FacebookControllerInterface::LogoutFacebook()
{
    [FacebookController logoutFacebook];
}

void FacebookControllerInterface::CheckIfLoggedIn()
{
    [FacebookController checkIfLoggedIn];
}

void FacebookControllerInterface::RequestFriend()
{
    [FacebookController requestFriend];
}

void FacebookControllerInterface::RequestPublishPermissions()
{
    [FacebookController requestPublishPermissions];
}

bool FacebookControllerInterface::HasPublishPermissions()
{
    return [FacebookController hasPublishPermissions];
}

void FacebookControllerInterface::PostStory()
{
    [FacebookController postStory];
}

void FacebookControllerInterface::SetHandler(FacebookControllerHandler* handler)
{
    g_handler = handler;
}

std::string FacebookControllerInterface::GetName()
{
    return std::string([userName UTF8String]);
}

// -----------------------------------------------------------------------------
// Objective C
// -----------------------------------------------------------------------------

static bool isLoggedIn = false;
static bool hasPublishPermissions = false;
static NSString* userName = nil;
static unsigned long long facebookId = 0;
static FBFrictionlessRecipientCache* friendsCache = nil;

+ (void) createSession
{
    FBSession* session = [[FBSession alloc] initWithAppID:[FacebookController getAppID]
                                            permissions:[FacebookController getBasicPermissions]
                                            urlSchemeSuffix:nil
                                            tokenCacheStrategy:nil];
    [FBSession setActiveSession: session];
}

+ (void) loginFacebook
{
    if(![FacebookController getAppID])
    {
        isLoggedIn = false;
        if (g_handler) { g_handler->OnLogin(isLoggedIn); }
        return;
    }
    
    if ([FacebookController isLoggedIn])
    {
        return;
    }
    
    if (![FBSession activeSession])
    {
        [FacebookController createSession];
    }

    // Open FB session
    [FBSession openActiveSessionWithReadPermissions:[FacebookController getBasicPermissions]
               allowLoginUI:true
               completionHandler:^(FBSession *session, FBSessionState status, NSError *error)
    {
        if (status == FBSessionStateClosedLoginFailed ||
            status == FBSessionStateClosed ||
            status == FBSessionStateCreatedOpening)
        {
            [[FBSession activeSession] closeAndClearTokenInformation];
            [FBSession setActiveSession:nil];
            hasPublishPermissions = false;
            isLoggedIn = false;
        }
        else
        {
            isLoggedIn = true;
            
            NSLog([NSString stringWithFormat: @"Access Token: %@", [FBSession activeSession].accessTokenData.accessToken]);
            
            hasPublishPermissions = [[FBSession activeSession].permissions containsObject:@"publish_actions"] &&
                                    [[FBSession activeSession].permissions containsObject:@"publish_stream"];
            [FacebookController getUserInfo];
        }
        if (g_handler) { g_handler->OnLogin(isLoggedIn); }
    }];
}

+ (bool) isLoggedIn
{
    return isLoggedIn;
}

+ (void) logoutFacebook
{
    [[FBSession activeSession] closeAndClearTokenInformation];
    [FBSession setActiveSession:nil];
    isLoggedIn = false;
    hasPublishPermissions = false;
    if (g_handler) { g_handler->OnLogin(isLoggedIn); }
}

+ (void) requestPublishPermissions
{
    if (hasPublishPermissions) return;
    
    NSArray *permissions = [[NSArray alloc] initWithObjects:
                            @"publish_actions", @"publish_stream", nil];
    
    [[FBSession activeSession] requestNewPublishPermissions:permissions
                               defaultAudience:FBSessionDefaultAudienceFriends
                               completionHandler:^(FBSession *session, NSError *error)
    {
        hasPublishPermissions = [[FBSession activeSession].permissions containsObject:@"publish_actions"] &&
                                [[FBSession activeSession].permissions containsObject:@"publish_stream"];
        if (g_handler) { g_handler->OnGetPublishPermissions(hasPublishPermissions); }
    }];
}

+ (bool) hasPublishPermissions
{
    return hasPublishPermissions;
}

+ (NSDictionary*)parseURLParams:(NSString *)query
{
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[[NSMutableDictionary alloc] init]
                                   autorelease];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val = [[kv objectAtIndex:1]
                         stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [params setObject:val forKey:[kv objectAtIndex:0]];
    }
    return params;
}

+ (void) requestFriend
{
    // more details here
    // https://developers.facebook.com/docs/ios/send-requests-using-ios-sdk/
    
    if (!friendsCache)
    {
        friendsCache = [[FBFrictionlessRecipientCache alloc] init];
    }
    
    [friendsCache prefetchAndCacheForSession:nil];
    
    [FBWebDialogs presentRequestsDialogModallyWithSession:nil
                  message:@"Help me, friend!"
                  title:@"Help me!"
                  parameters:nil
                  handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error)
    {
        if (error)
        {
            NSLog(@"Error sending request");
        }
        else
        {
            if (result == FBWebDialogResultDialogNotCompleted)
            {
                NSLog(@"User canceled request");
            }
            else
            {
                NSDictionary *urlParams = [FacebookController parseURLParams:[resultURL query]];
                if (![urlParams valueForKey:@"request"])
                {
                    NSLog(@"User canceled request");
                }
                else
                {
                    NSLog([NSString stringWithFormat: @"Request Sent: %@", [urlParams valueForKey:@"request"]]);
                }
            }
        }
    }
    friendCache:friendsCache];
}

+ (void) createOpenGraphObjectWithType:(NSString *) type
                                 title:(NSString *) title
                                   url:(NSString *) url
                                 image:(NSString *) image
                                 handler: (OpenGraphObjectCreationHandler) handler
{
    NSMutableDictionary<FBOpenGraphObject> *object =
    [FBGraphObject openGraphObjectForPostWithType:type
                                            title:title
                                            image:image
                                              url:url
                                      description:@""];
    object[@"create_object"] = @"true";
    object[@"fbsdk:create_object"] = @"true";
    
    [FBRequestConnection startForPostOpenGraphObject:object
                                   completionHandler:^(FBRequestConnection *connection, id result, NSError *error)
     {
         if (!error && result != nil)
         {
             NSLog([NSString stringWithFormat:@"Posting object '%@' (id=%@) is created!",
                    title, [result objectForKey:@"id"]]);
             
             handler([result objectForKey:@"id"]);
         }
         else
         {
             NSLog([NSString stringWithFormat:@"Posting object creation error: %@", error]);
         }
     }];
}

+ (void) postStory
{
    NSString* badge_title = @"Blue Badge";
    NSString* badge_url = @"http://demo.tom3.html5.services.alawar.com/images/tester/blue_badge.htm";
    NSString* badge_image = @"http://demo.tom3.html5.services.alawar.com/images/tester/blue_badge.png";
    int rnd = arc4random() % 2;
    if (rnd == 0)
    {
        badge_title = @"Red Badge";
        badge_url = @"http://demo.tom3.html5.services.alawar.com/images/tester/red_badge.htm";
        badge_image = @"http://demo.tom3.html5.services.alawar.com/images/tester/red_badge.png";
    }
    
    [FacebookController createOpenGraphObjectWithType:@"aw_test:badge"
                                                title:badge_title
                                                url:badge_url
                                                image:badge_image
                                                handler:^(NSString *objectId)
    {
        // action
        NSMutableDictionary<FBGraphObject> *action = [FBGraphObject graphObject];
        action[@"badge"] = objectId;
        action[@"fb:explicitly_shared"] = @"1";
        
        [FBRequestConnection startForPostWithGraphPath:@"me/aw_test:find"
                                           graphObject:action
                                     completionHandler:^(FBRequestConnection *connection,
                                                         id result,
                                                         NSError *error)
         {
             if (!error && result != nil)
             {
                 NSLog([NSString stringWithFormat:@"Posted (id=%@)!", [result objectForKey:@"id"]]);
             }
             else
             {
                 NSLog([NSString stringWithFormat:@"Posting error: %@", error]);
             }
         }];
    }];
}

+ (NSString*) getAppID
{
    NSString* appID = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"FacebookAppID"];
    if([appID isKindOfClass:[NSNull class]]) return nil;
    return appID;
}

+ (NSArray*) getBasicPermissions
{
    NSArray* permissions = [[NSArray alloc] initWithObjects:
                            @"user_birthday",
                            nil];
    return permissions;
}

+ (NSString*) getName
{
    if (![FacebookController isLoggedIn]) return nil;
    if (![FBSession activeSession]) return nil;
    return userName;
}

+ (void) checkIfLoggedIn
{
    if([FacebookController getAppID])
    {
        [FacebookController createSession];
        
        // autologin
        FBSessionState state = [[FBSession activeSession] state];
        if (state == FBSessionStateCreatedTokenLoaded)
        {
            [FacebookController loginFacebook];
        }
    }
}

+ (void) getUserInfo
{
    [[FBRequest requestForMe] startWithCompletionHandler: ^(FBRequestConnection *connection,
                                                            NSDictionary<FBGraphUser> *result,
                                                            NSError *error)
     {
         if (!error && result)
         {
             userName = [[NSString alloc] initWithString:result.first_name];
             facebookId = [result.id longLongValue];
             
             // load and save profile picture in separate thread
             dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
             {
                 NSString* profilePicture = [FacebookController getProfilePicture: @"profile.png"];
                 [self performSelectorOnMainThread: @selector(onProfilePictureReady:)
                                        withObject: profilePicture waitUntilDone:NO];
             });
             
             std::string str = std::string([userName UTF8String]);
             if (g_handler) { g_handler->OnGetUserInfoCompleted(str, facebookId); }
         }
         else
         {
             if (g_handler) { g_handler->OnGetUserInfoError(); }
         }
     }];
}

+ (NSString*) getProfilePicture: (NSString*) filename
{
    if (userName == nil) return nil;
    NSString* url = [NSString stringWithFormat:@"http://graph.facebook.com/%llu/picture?width=100&height=100", facebookId];
    UIImage* profileImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:url]]];
    
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent: filename];
    
    // save image
    [UIImagePNGRepresentation(profileImage) writeToFile:filePath atomically:YES];
    
    return filePath;
}

+ (void) onProfilePictureReady: (NSString*) filename;
{
    std::string prof_str = std::string([filename UTF8String]);
    if (g_handler) { g_handler->OnProfilePictureReady(prof_str); }
}

@end
