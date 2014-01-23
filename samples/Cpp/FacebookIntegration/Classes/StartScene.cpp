#include "StartScene.h"
#include "AppMacros.h"

#include "FacebookController-Interface.h"

class MyFacebookControllerHandler : public FacebookControllerHandler
{
    StartScene* m_scene;
    
public:
    MyFacebookControllerHandler(StartScene* _scene) : m_scene(_scene) {}
    virtual ~MyFacebookControllerHandler(){}
    
    virtual void OnLogin(bool result)
    {
        m_scene->SetLoginButtonEnable(!result);
        if (!result)
        {
            m_scene->SetText("Facebook Integration Demo");  
            m_scene->SetProfilePicture("");
        }
    }
    
    virtual void OnGetUserInfoError()
    {
    }
    
    virtual void OnGetUserInfoCompleted(std::string name, unsigned long long facebookId)
    {
        m_scene->SetText(std::string("Facebook Integration Demo, welcome ") + name);  
    }
    
    virtual void OnProfilePictureReady(std::string profileImagePath)
    {
        m_scene->SetProfilePicture(profileImagePath);
    }
    
    virtual void OnGetPublishPermissions(bool enable)
    {
        if (enable)
        {
            if (m_scene->m_wasPost)
            {
                m_scene->OnFacebookPost(0);
                m_scene->m_wasPost = false;
            }
            
            if (m_scene->m_wasRequest)
            {
                m_scene->OnFacebookRequest(0);
                m_scene->m_wasRequest = false;
            }
        }
    }
};

static MyFacebookControllerHandler* facebookHandler = 0;

StartScene::~StartScene()
{
    if (facebookHandler != 0)
    {
        delete facebookHandler;
        facebookHandler = 0;
    }
}

CCScene* StartScene::scene()
{
    CCScene *scene = CCScene::create();
    StartScene *layer = StartScene::create();
    scene->addChild(layer);

    return scene;
}

bool StartScene::init()
{
    if ( !CCLayer::init() )
    {
        return false;
    }
    
    CCSize visibleSize = CCDirector::sharedDirector()->getVisibleSize();
    CCPoint origin = CCDirector::sharedDirector()->getVisibleOrigin();

    m_facebookLoginButton = CCMenuItemImage::create("FbNormal.png",
                                                    "FbSelected.png",
                                                    this,
                                                    menu_selector(StartScene::OnFacebookLogin));
	m_facebookLoginButton->setPosition(ccp(origin.x + visibleSize.width - m_facebookLoginButton->getContentSize().width/2,
                                         origin.y + 3 * m_facebookLoginButton->getContentSize().height/2 + 10));
    
    m_facebookRequestButton = CCMenuItemImage::create("FbReqNormal.png",
                                                      "FbReqSelected.png",
                                                      this,
                                                      menu_selector(StartScene::OnFacebookRequest));
	m_facebookRequestButton->setPosition(ccp(origin.x +
                                             visibleSize.width - m_facebookRequestButton->getContentSize().width/2,
                                             origin.y + m_facebookRequestButton->getContentSize().height/2));
    
    m_facebookPostButton = CCMenuItemImage::create("FbPostNormal.png",
                                                   "FbPostSelected.png",
                                                   this,
                                                   menu_selector(StartScene::OnFacebookPost));
	m_facebookPostButton->setPosition(ccp(origin.x + m_facebookPostButton->getContentSize().width/2,
                                           origin.y + 3 * m_facebookPostButton->getContentSize().height/2 + 10));
    
    m_facebookLogoutButton = CCMenuItemImage::create("FbLogoutNormal.png",
                                                     "FbLogoutSelected.png",
                                                     this,
                                                     menu_selector(StartScene::OnFacebookLogout));
	m_facebookLogoutButton->setPosition(ccp(origin.x + m_facebookLogoutButton->getContentSize().width/2,
                                             origin.y + m_facebookLogoutButton->getContentSize().height/2));

    CCMenu* menu_right = CCMenu::create(m_facebookLoginButton, m_facebookRequestButton, NULL);
    menu_right->setPosition(CCPoint(-10, 10));
    this->addChild(menu_right, 1);
    
    CCMenu* menu_left = CCMenu::create(m_facebookPostButton, m_facebookLogoutButton, NULL);
    menu_left->setPosition(CCPoint(10, 10));
    this->addChild(menu_left, 1);

    CCLabelTTF* text_label = CCLabelTTF::create("Facebook Integration Demo", "Arial", TITLE_FONT_SIZE);
    text_label->setPosition(ccp(origin.x + visibleSize.width/2,
                            origin.y + visibleSize.height - text_label->getContentSize().height));
    this->addChild(text_label, 1);
    m_textSprite = text_label;

    CCSprite* logo_sprite = CCSprite::create("Logo_Alawar_600x600-white.png");
    logo_sprite->setPosition(ccp(visibleSize.width/2 + origin.x, visibleSize.height/2 + origin.y));
    logo_sprite->setScale(0.5f);
    this->addChild(logo_sprite, 0);
    
    m_quadSprite = CCSprite::create("Quad.png");
    m_quadSprite->setPosition(ccp(visibleSize.width/2 + origin.x, visibleSize.height/2 + origin.y));
    this->addChild(m_quadSprite, 0);
    m_curPosition = m_quadSprite->getPosition();
    m_curDirection = CCPoint(1.0f, 0.0f);
    
    SetLoginButtonEnable(true);
    m_wasPost = false;
    m_wasRequest = false;
    
    this->scheduleUpdate();
    
    // set handler
    facebookHandler = new MyFacebookControllerHandler(this);
    FacebookControllerInterface::SetHandler(facebookHandler);
    
    // check if the user logged in previous session
    FacebookControllerInterface::CheckIfLoggedIn();
    
    return true;
}

void StartScene::SetText(const std::string& text)
{
    m_textSprite->setString(text.c_str());
}

void StartScene::SetLoginButtonEnable(bool enable)
{
    m_facebookLoginButton->setEnabled(enable);
    
    m_facebookPostButton->setEnabled(!enable);
    m_facebookRequestButton->setEnabled(!enable);
    m_facebookLogoutButton->setEnabled(!enable);
}

void StartScene::SetProfilePicture(const std::string& path)
{
    CCSize sz = m_quadSprite->getContentSize();
    this->removeChild(m_quadSprite);
    
    m_quadSprite = CCSprite::create(path.empty() ? "Quad.png" : path.c_str());
    this->addChild(m_quadSprite, 0);
    
    CCSize sz2 = m_quadSprite->getContentSize();
    m_quadSprite->setScaleX(sz.width / sz2.width);
    m_quadSprite->setScaleY(sz.height / sz2.height);
}

void StartScene::OnFacebookLogin(CCObject* pSender)
{
    FacebookControllerInterface::LoginFacebook();
}

void StartScene::OnFacebookLogout(CCObject* pSender)
{
    FacebookControllerInterface::LogoutFacebook();
}

void StartScene::OnFacebookPost(CCObject* pSender)
{
    if (!FacebookControllerInterface::HasPublishPermissions())
    {
        m_wasPost = true;
        FacebookControllerInterface::RequestPublishPermissions();
    }
    else
    {
        FacebookControllerInterface::PostStory();
    }
}

void StartScene::OnFacebookRequest(CCObject* pSender)
{
    if (!FacebookControllerInterface::HasPublishPermissions())
    {
        m_wasRequest = true;
        FacebookControllerInterface::RequestPublishPermissions();
    }
    else
    {
        FacebookControllerInterface::RequestFriend();
    }
}

void StartScene::update(float dt)
{
    CCSize visibleSize = CCDirector::sharedDirector()->getVisibleSize();
    CCPoint origin = CCDirector::sharedDirector()->getVisibleOrigin();
    CCSize quadSize = m_quadSprite->getContentSize();
    float radius = quadSize.width * 0.5f;
    
    m_curPosition = m_curPosition + (m_curDirection * dt * 200.0f);
    CCPoint pos = m_curPosition + (m_curDirection * radius);
    if (pos.x <= origin.x || pos.x >= origin.x + visibleSize.width ||
        pos.y <= origin.y || pos.y >= origin.y + visibleSize.height)
    {
        CCPoint randomDir = CCPoint(rand() % 2, rand() % 2);
        randomDir = randomDir.normalize();
        
        if (pos.x <= origin.x || pos.x >= origin.x + visibleSize.width)
        {
            randomDir.x = -m_curDirection.x;
        }
        if (pos.y <= origin.y || pos.y >= origin.y + visibleSize.height)
        {
            randomDir.y = -m_curDirection.y;
        }
        
        m_curDirection = randomDir.normalize();
    }
    
    if (m_curPosition.x <= origin.x) m_curPosition.x = origin.x;
    if (m_curPosition.x >= origin.x + visibleSize.width) m_curPosition.x = origin.x + visibleSize.width;
    if (m_curPosition.y <= origin.y) m_curPosition.y = origin.y;
    if (m_curPosition.y >= origin.y + visibleSize.height) m_curPosition.y = origin.y + visibleSize.height;
    
    m_quadSprite->setPosition(m_curPosition);
}
