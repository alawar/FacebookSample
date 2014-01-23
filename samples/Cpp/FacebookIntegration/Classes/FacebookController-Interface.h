//
//  FacebookController-Interface.h
//  FacebookIntegration
//
//  Created by Roman Kuznetsov on 29/11/13.
//
//

#pragma once
#include <string>

class FacebookControllerHandler;

class FacebookControllerInterface
{
public:
    static void CheckIfLoggedIn();
    static void LoginFacebook();
    static bool IsLoggedIn();
    static void LogoutFacebook();
    
    static void RequestPublishPermissions();
    static bool HasPublishPermissions();
    static void RequestFriend();
    static void PostStory();
    
    static std::string GetName();
    
    static void SetHandler(FacebookControllerHandler* handler);
};

class FacebookControllerHandler
{
public:
    virtual ~FacebookControllerHandler(){}
    
    virtual void OnLogin(bool result){}
    virtual void OnGetUserInfoError(){}
    virtual void OnGetUserInfoCompleted(std::string name, unsigned long long facebookId){}
    virtual void OnProfilePictureReady(std::string profileImagePath){}
    virtual void OnGetPublishPermissions(bool enable){}
};
