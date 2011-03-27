#import "VideosModule.h"
#import "FacebookVideosViewController.h"
#import "FacebookVideoDetailViewController.h"
#import "KGOSocialMediaController.h"
#import "KGOHomeScreenWidget.h"
#import "KGOTheme.h"
#import "FacebookVideo.h"

@implementation VideosModule

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        vc = [[[FacebookVideosViewController alloc] initWithNibName:@"FacebookMediaViewController" bundle:nil] autorelease];
    } else if ([pageName isEqualToString:LocalPathPageNameDetail]) {
        FacebookVideo *video = [params objectForKey:@"video"];
        if (video) {
            vc = [[[FacebookVideoDetailViewController alloc] initWithNibName:@"FacebookMediaDetailViewController" bundle:nil] autorelease];
            [(FacebookVideoDetailViewController *)vc setVideo:video];
            NSArray *videos = [params objectForKey:@"videos"];
            if (videos) {
                [(FacebookVideoDetailViewController *)vc setPosts:videos];
            }
        }
    }
    return vc;
}

- (void)launch {
    [super launch];
    [[KGOSocialMediaController sharedController] startupFacebook];
}

- (void)terminate {
    [super terminate];
    [[KGOSocialMediaController sharedController] shutdownFacebook];
}

#pragma mark Social media controller

- (NSSet *)socialMediaTypes {
    return [NSSet setWithObject:KGOSocialMediaTypeFacebook];
}

- (NSDictionary *)userInfoForSocialMediaType:(NSString *)mediaType {
    if ([mediaType isEqualToString:KGOSocialMediaTypeFacebook]) {
        return [NSDictionary dictionaryWithObject:[NSArray arrayWithObjects:
                                                   @"read_stream",
                                                   @"offline_access",
                                                   @"user_groups",
                                                   @"user_videos",
                                                   @"publish_stream",
                                                   nil]
                                           forKey:@"permissions"];
    }
    return nil;
}

@end