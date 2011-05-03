#import "ReunionMapModule.h"
#import "KGOPlacemark.h"
#import "ReunionMapDetailViewController.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "MapHomeViewController.h"
#import "KGOSidebarFrameViewController.h"
#import "ScheduleDataManager.h"

NSString * const EventMapCategoryName = @"event"; // this is what the mobile web gives us
NSString * const ScheduleTag = @"schedule";

@implementation ReunionMapModule

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    
    if ([pageName isEqualToString:LocalPathPageNameDetail]) {
        ReunionMapDetailViewController *detailVC = [[[ReunionMapDetailViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
        
        KGOPlacemark *detailItem = [params objectForKey:@"detailItem"];
        if (detailItem) {
            NSArray *annotations = [NSArray arrayWithObject:detailItem];
            NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:annotations, @"annotations", nil];
            
            UIViewController *topVC = [KGO_SHARED_APP_DELEGATE() visibleViewController];
            if (topVC.modalViewController) {
                [topVC dismissModalViewControllerAnimated:YES];
            }
            
            KGONavigationStyle navStyle = [KGO_SHARED_APP_DELEGATE() navigationStyle];
            if (navStyle == KGONavigationStyleTabletSidebar) {
                KGOSidebarFrameViewController *homescreen = (KGOSidebarFrameViewController *)[KGO_SHARED_APP_DELEGATE() homescreen];
                topVC = homescreen.visibleViewController;
                if (topVC.modalViewController) {
                    [topVC dismissModalViewControllerAnimated:YES];
                }
            }
            
            if ([topVC isKindOfClass:[MapHomeViewController class]]) {
                [(MapHomeViewController *)topVC setAnnotations:annotations];
                
            } else {
                return [self modulePage:LocalPathPageNameHome params:params];
            }
            
            if ([topVC isKindOfClass:[MapHomeViewController class]]) {
                [(MapHomeViewController *)topVC setAnnotations:annotations];
                return nil;
                
            } else {
                return [self modulePage:LocalPathPageNameHome params:params];
            }
        }
        
        KGOPlacemark *place = [params objectForKey:@"place"];
        if (place) {
            detailVC.annotation = place;
            //detailVC.placemark = place;
        }
        id<KGODetailPagerController> controller = [params objectForKey:@"pagerController"];
        if (controller) {
            KGODetailPager *pager = [[[KGODetailPager alloc] initWithPagerController:controller delegate:detailVC] autorelease];
            detailVC.pager = pager;
        }
        
        return detailVC;
    }
    else if([pageName isEqualToString:LocalPathPageNameHome]) {
        // schedule needs to be loaded in case user taps on
        // annotation that corresponds to an event
        if(!scheduleManager) {
            scheduleManager = [ScheduleDataManager new];
            scheduleManager.moduleTag = ScheduleTag;
        }
        if (![scheduleManager allEvents]) {
            [scheduleManager requestAllEvents];
        }
    }
    
    return [super modulePage:pageName params:params];
}

- (void)dealloc {
    [scheduleManager release];
}
@end
