#import <UIKit/UIKit.h>
#import "KGODetailPager.h"
#import "MITThumbnailView.h"
#import "MediaContainerView.h"
#import "FacebookCommentViewController.h"
#import "KGOSocialMediaController+FacebookAPI.h"

#define MAXIMUM_IMAGE_HEIGHT 500

@class FacebookParentPost;

@interface FacebookMediaDetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate,
KGODetailPagerController, KGODetailPagerDelegate, FacebookUploadDelegate> {
    IBOutlet UITableView *_tableView;
    IBOutlet UIButton *_commentButton;
    IBOutlet UIButton *_likeButton;
    IBOutlet UIButton *_bookmarkButton;
    IBOutlet UIView *_buttonsBar;
    
    IBOutlet MediaContainerView *_mediaView;
    IBOutlet UIView *_mediaPreviewView;
    IBOutlet UIView *_mediaImageBackgroundView;
    
    NSArray *_comments;
}

@property(nonatomic, retain) NSArray *posts;
@property(nonatomic, retain) FacebookParentPost *post;
@property(nonatomic, retain) UITableView *tableView;
@property(nonatomic, retain) NSString *moduleTag;
@property(readonly) MediaContainerView *mediaView;



- (IBAction)commentButtonPressed:(id)sender;
- (IBAction)likeButtonPressed:(id)sender;
- (IBAction)bookmarkButtonPressed:(id)sender;
- (IBAction)closeButtonPressed:(id)sender;
- (IBAction)uploadButtonPressed:(id)sender;

- (void)displayPost;
- (NSString *)postTitle;

- (void)getCommentsForPost;
- (void)didReceiveComments:(id)result;

- (void)didLikePost:(id)result;
- (void)didUnlikePost:(id)result;

@end
