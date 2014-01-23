#pragma once

#include "cocos2d.h"

USING_NS_CC;

class MyFacebookControllerHandler;

class StartScene : public cocos2d::CCLayer
{
    friend class MyFacebookControllerHandler;
    
    CCSprite* m_quadSprite;
    CCPoint m_curPosition;
    CCPoint m_curDirection;
    CCLabelTTF* m_textSprite;
    CCMenuItemImage* m_facebookLoginButton;
    CCMenuItemImage* m_facebookLogoutButton;
    CCMenuItemImage* m_facebookPostButton;
    CCMenuItemImage* m_facebookRequestButton;
    bool m_wasPost;
    bool m_wasRequest;

public:
    virtual ~StartScene();
    virtual bool init();
    static cocos2d::CCScene* scene();
    
    virtual void update(float dt);
    
    void SetText(const std::string& text);
    void SetLoginButtonEnable(bool enable);
    void SetProfilePicture(const std::string& path);
    
    void OnFacebookLogin(CCObject* pSender);
    void OnFacebookLogout(CCObject* pSender);
    void OnFacebookPost(CCObject* pSender);
    void OnFacebookRequest(CCObject* pSender);
    
    CREATE_FUNC(StartScene);
};