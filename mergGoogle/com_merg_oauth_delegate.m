//
//  com_merg_oauth_delegate.m
//  mergGoogle
//
//  Created by Monte Goulding on 27/07/2015.
//
//

#import "com_merg_oauth_delegate.h"

@implementation com_merg_oauth_delegate

@synthesize auth;
@synthesize error;

- (id)initWithWait: (LCWaitRef)p_wait
{
    // Make sure the superclass is initialized.
    self = [super init];
    if (self == nil)
        return nil;
    
    _wait = p_wait;
    LCWaitRetain(_wait);
    
    auth = nil;
    error = nil;
    
    // Return ourselves - if we forget this, bad things happen!
    return self;
}

- (void)dealloc
{
    // Release our wait object.
    LCWaitRelease(_wait);
    
    if (auth)
        [auth release];
    
    if (error)
        [error release];
    
    // Make surethe superclass deallocs itself.
    [super dealloc];
}

- (void) runWithScope: (NSString *) scope clientID: (NSString *) clientID secret: (NSString *) secret keychainItemName: (NSString *) keychainItemName
{
#if TARGET_OS_IPHONE
    GTMOAuth2ViewControllerTouch *viewController;
    viewController = [[[GTMOAuth2ViewControllerTouch alloc] initWithScope:scope
                                                                 clientID:clientID
                                                             clientSecret:secret
                                                         keychainItemName:keychainItemName
                                                                 delegate:self
                                                         finishedSelector:@selector(viewController:finishedWithAuth:error:)] autorelease];
    
    
    LCInterfacePresentModalViewController(viewController, true);
    
    LCWaitRun(_wait);
    
    LCInterfaceDismissModalViewController(viewController, true);
#else
    GTMOAuth2WindowController *windowController;
    windowController = [[[GTMOAuth2WindowController alloc] initWithScope:scope clientID:clientID clientSecret:secret keychainItemName:keychainItemName resourceBundle:[NSBundle bundleForClass:[com_merg_oauth_delegate class]]] autorelease];
    
    LCObjectRef tStack;
    LCContextDefaultStack(&tStack);
    int tWindowID;
    LCObjectGet(tStack, kLCValueOptionAsInteger, "windowid", nil, &tWindowID);
    
    NSWindow *t_nswindow;
    
    t_nswindow = nil;
    
    t_nswindow = [NSApp windowWithWindowNumber:tWindowID];
    
    [windowController signInSheetModalForWindow:t_nswindow delegate:self finishedSelector:@selector(windowController:finishedWithAuth:error:)];
    
    LCWaitRun(_wait);
    
#endif
}




#if TARGET_OS_IPHONE
- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)p_auth
                 error:(NSError *)p_error
#else
- (void)windowController:(GTMOAuth2WindowController *)windowController
        finishedWithAuth:(GTMOAuth2Authentication *)p_auth
                   error:(NSError *)p_error

#endif
{
    
    if (p_error != nil) {
        error = p_error;
        [error retain];
    } else {
        // Sign-in succeeded
        auth = p_auth;
        [auth retain];
    }
    
    LCWaitBreak(_wait);
}

@end
