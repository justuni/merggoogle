//
//  com_merg_oauth_delegate.h
//  mergGoogle
//
//  Created by Monte Goulding on 27/07/2015.
//
//

#import <Foundation/Foundation.h>
#import <LiveCode.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import "GTMOAuth2ViewControllerTouch.h"
#else
#import <GData/GTMOAuth2WindowController.h>
#endif


@interface com_merg_oauth_delegate : NSObject
{
    LCWaitRef _wait;
    
    GTMOAuth2Authentication * auth;
    NSError * error;
}

@property (readonly, nonatomic) GTMOAuth2Authentication * auth;
@property (readonly, nonatomic) NSError * error;

- (id)initWithWait: (LCWaitRef)p_wait;
- (void)dealloc;
- (void)runWithScope: (NSString *) scope clientID: (NSString *) clientID secret: (NSString *) secret keychainItemName: (NSString *) keychainItemName;
#if TARGET_OS_IPHONE
- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)auth
                 error:(NSError *)error;
#else
- (void)windowController:(GTMOAuth2WindowController *)windowController
      finishedWithAuth:(GTMOAuth2Authentication *)auth
                 error:(NSError *)error;

#endif
@end
