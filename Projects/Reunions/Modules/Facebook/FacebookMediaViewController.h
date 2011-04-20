#import <UIKit/UIKit.h>

@interface FacebookMediaViewController : UIViewController 
<UIImagePickerControllerDelegate, UINavigationControllerDelegate,
UIPopoverControllerDelegate> {
    
    IBOutlet UISegmentedControl *_filterControl;
    IBOutlet UIScrollView *_scrollView;
    
    // hidden for logged-in users
    IBOutlet UIView *_loginView;
    IBOutlet UILabel *_loginHintLabel;
    IBOutlet UIButton *_loginButton; // login or open facebook

    NSString *_gid; // facebook group id
    
    BOOL facebookUserLoggedIn;
}

- (IBAction)filterValueChanged:(UISegmentedControl *)sender;
- (IBAction)loginButtonPressed:(UIButton *)sender;
- (IBAction)uploadButtonPressed:(id)sender;

- (void)showLoginViewAnimated:(BOOL)animated;
- (void)hideLoginViewAnimated:(BOOL)animated;

- (void)facebookDidLogout:(NSNotification *)aNotification;
- (void)facebookDidLogin:(NSNotification *)aNotification;

- (void)showUploadPhotoController:(id)sender;

@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) UIPopoverController *photoPickerPopover;

@end
