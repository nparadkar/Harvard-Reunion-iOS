//
//  ConnectViewController.h
//

#import <UIKit/UIKit.h>
#import "BumpAPI.h"
#import "CustomBumpUI.h"
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@interface ConnectViewController : UIViewController <BumpAPIDelegate, 
UITextFieldDelegate, ABPeoplePickerNavigationControllerDelegate,
UIAlertViewDelegate, BumpAPICustomUI> {
    CustomBumpUI *customConnectUI;
    BOOL shouldPromptAboutAddingRecordAtNextChance;
    BOOL addressBookPickerShowing;
}

@property (nonatomic, retain) CustomBumpUI *customBumpUI;
@property (nonatomic, retain) NSDictionary *incomingABRecordDict;
//@property (nonatomic, retain) UIActivityIndicatorView *spinner;
@property (nonatomic, retain) UILabel *statusLabel;
@property (nonatomic, retain) UILabel *messageLabel;

@end