//
//  ConnectViewController.m
//  Universitas
//
//  Created by Jim Kang on 3/22/11.
//  Copyright 2011 Modo Labs. All rights reserved.
//

#import "ConnectViewController.h"
#import "BumpAPI.h"

typedef enum
{
    kBumpTextFieldTag = 0x324,
    kBumpSendButtonTag,
    kBumpIncomingLabel
}
ConnectViewControllerTags;



#pragma mark Private methods

@interface ConnectViewController (Private)

- (void)setUpBump;

#pragma mark Address book
- (void)showPicker;

@end

@implementation ConnectViewController (Private)

- (void)setUpBump
{
    BumpAPI *bumpObject = [BumpAPI sharedInstance];        
//    [self.customBumpUI setParentView:self.view];
//    [self.customBumpUI setBumpAPIObject:[BumpAPI sharedInstance]];
    [[BumpAPI sharedInstance] configUIDelegate:self.customBumpUI];
    
    // Start Bump.
    [bumpObject configAPIKey:@"57571df95089489d906d0d396ace290d"];
    [bumpObject configDelegate:self];
    [bumpObject configParentView:self.view];
    [bumpObject configActionMessage:
     @"Bump with another app user to get started."];
    [bumpObject requestSession];
}

#pragma mark Address book
- (void)showPicker {
    ABPeoplePickerNavigationController *picker =
    [[ABPeoplePickerNavigationController alloc] init];
    picker.peoplePickerDelegate = self;
    
    [self presentModalViewController:picker animated:YES];
    [picker release];
}

@end


@implementation ConnectViewController

@synthesize customBumpUI;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)init
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.customBumpUI = [[[CustomBumpUI alloc] init] autorelease];
    }
    return self;
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
    [super loadView];
    //self.view.backgroundColor = [UIColor greenColor];
    
    UITextField *bumpField = 
    [[UITextField alloc] initWithFrame:CGRectMake(20, 20, 280, 40)];
    bumpField.tag = kBumpTextFieldTag;
    bumpField.placeholder = @"Text you want to send via Bump.";
    bumpField.borderStyle = UITextBorderStyleBezel;
    bumpField.backgroundColor = [UIColor whiteColor];
    bumpField.delegate = self;
    [self.view addSubview:bumpField];
    [bumpField release];
    
    UIButton *sendButton = 
    [UIButton buttonWithType:UIButtonTypeRoundedRect];
    sendButton.tag = kBumpSendButtonTag;
    [sendButton setTitle:@"Send via Bump" forState:UIControlStateNormal];
    sendButton.frame = CGRectMake(20, 80, 280, 40);
    [sendButton addTarget:self action:@selector(buttonTapped:) 
         forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:sendButton];
    
    UILabel *incomingLabel = [[UILabel alloc] initWithFrame:
                              CGRectMake(20, 140, 280, 80)];
    incomingLabel.tag = kBumpIncomingLabel;
    [self.view addSubview:incomingLabel];
    [incomingLabel release];
        
    [self setUpBump];
}

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    // Stop bump.
    [[BumpAPI sharedInstance] endSession];
    [customBumpUI release];
    
    [super dealloc];
}

#pragma mark BumpAPIDelegate methods

- (void)bumpDataReceived:(NSData *)chunk {
	// The chunk sent from the other user is string data.
	NSString *chunkString = 
    [[NSString alloc] initWithData:chunk encoding:NSUTF8StringEncoding];
    
    // Update label with incoming text.
    UILabel *incomingLabel = 
    (UILabel *)[self.view viewWithTag:kBumpIncomingLabel];
    incomingLabel.text = chunkString;
    
    [chunkString release];
}

- (void)bumpSessionStartedWith:(Bumper*)otherBumper{
    NSLog(@"Bump session started.");
    [self showPicker];
}

- (void)bumpSessionEnded:(BumpSessionEndReason)reason {
	NSString *alertText;
	switch (reason) {
		case END_OTHER_USER_QUIT:
			alertText = @"Other user has quit the session.";
			break;
		case END_LOST_NET:
			alertText = @"Connection to Bump server was lost.";
			break;
		case END_OTHER_USER_LOST:
			alertText = @"Connection to other user was lost.";
			break;
		case END_USER_QUIT:
			alertText = @"You have been disconnected.";
			break;
		default:
			alertText = @"You have been disconnected.";
			break;
	}
	
	if(reason != END_USER_QUIT){ 
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Disconnected" message:alertText delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
}

- (void)bumpSessionFailedToStart:(BumpSessionStartFailedReason)reason {
	
	NSString *alertText;
	switch (reason) {
		case FAIL_NETWORK_UNAVAILABLE:
			alertText = @"Please check your network settings and try again.";
			break;
		case FAIL_INVALID_AUTHORIZATION:
			//the user should never see this, since we'll pass in the correct API auth strings.
			//just for debug.
			alertText = @"Failed to connect to the Bump service. Auth error.";
			break;
		default:
			alertText = @"Failed to connect to the Bump service.";
			break;
	}
	
	if(reason != FAIL_USER_CANCELED){
		//if the user canceled they know it and they don't need a popup.
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection Failed" message:alertText delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
}

#pragma mark UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark UI Actions
- (IBAction)buttonTapped:(id)sender
{
    UITextField *textField = 
    (UITextField *)[self.view viewWithTag:kBumpTextFieldTag];
    [[BumpAPI sharedInstance] sendData:
     [textField.text dataUsingEncoding:NSUTF8StringEncoding]];
}

#pragma mark ABPeoplePickerNavigationControllerDelegate
- (void)peoplePickerNavigationControllerDidCancel:
(ABPeoplePickerNavigationController *)peoplePicker {
    [self dismissModalViewControllerAnimated:YES];
}

- (BOOL)peoplePickerNavigationController:
(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person {
    
    NSString* name = (NSString *)ABRecordCopyValue(person,
                                                   kABPersonFirstNameProperty);
    NSString *firstName = name;
    [name release];
    
    name = (NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
    NSString *lastName = name;
    [name release];
        
    [self dismissModalViewControllerAnimated:YES];
    
    [[BumpAPI sharedInstance] sendData:
     [[NSString stringWithFormat:@"%@ %@", firstName, lastName] 
      dataUsingEncoding:NSUTF8StringEncoding]];    
    
    return NO;
}

- (BOOL)peoplePickerNavigationController:
(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
                                property:(ABPropertyID)property
                              identifier:(ABMultiValueIdentifier)identifier{
    return NO;
}

@end
