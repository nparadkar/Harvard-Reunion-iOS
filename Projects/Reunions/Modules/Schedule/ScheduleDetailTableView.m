#import "ScheduleDetailTableView.h"
#import "KGOSocialMediaController+Foursquare.h"
#import "KGOFoursquareEngine.h"
#import "UIKit+KGOAdditions.h"
#import "ScheduleEventWrapper.h"
#import "ThemeConstants.h"
#import "Foundation+KGOAdditions.h"

@implementation ScheduleDetailTableView

- (void)foursquareButtonPressed:(id)sender
{
    [[KGOSocialMediaController sharedController] startupFoursquare];
    [[KGOSocialMediaController sharedController] loginFoursquare];
}

- (void)facebookButtonPressed:(id)sender
{
}

- (NSArray *)sectionForAttendeeInfo
{
    NSMutableArray *attendeeInfo = [NSMutableArray array];

    ScheduleEventWrapper *eventWrapper = (ScheduleEventWrapper *)_event;
    if ([eventWrapper registrationFee]) {
        if ([eventWrapper isRegistered]) {
            UIImage *image = [UIImage imageWithPathName:@"modules/schedule/badge-confirmed"];
            [attendeeInfo addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                     image, @"image",
                                     @"Registration Confirmed", @"title",
                                     nil]];
            
        } else {
            UIImage *image = [UIImage imageWithPathName:@"modules/schedule/badge-register"];
            NSString *title = [NSString stringWithFormat:@"Registration Required (%@)", [eventWrapper registrationFee]];
            NSString *subtitle = [NSString stringWithFormat:@"Register online at %@", [eventWrapper registrationURL]];
            [attendeeInfo addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                     image, @"image",
                                     title, @"title",
                                     subtitle, @"subtitle",
                                     nil]];
        }
    }
    
    if (_event.attendees) {
        [attendeeInfo addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSString stringWithFormat:@"%d others attending", _event.attendees.count], @"title",
                                 KGOAccessoryTypeChevron, @"accessory",
                                 nil]];
    }
    
    return attendeeInfo;
}

- (void)headerViewFrameDidChange:(KGODetailPageHeaderView *)headerView
{
    CGRect frame = _facebookButton.frame;
    frame.origin.x = 10;
    frame.origin.y = _headerView.frame.size.height;
    _facebookButton.frame = frame;
    
    frame.origin.x += _facebookButton.frame.size.width + 10;
    _foursquareButton.frame = frame;
    
    frame = _headerView.frame;
    frame.size.height += _foursquareButton.frame.size.height + 20;
    
    if (frame.size.height != self.tableHeaderView.frame.size.height) {
        self.tableHeaderView.frame = frame;
        self.tableHeaderView = self.tableHeaderView;
    }
}

// TODO: use proper images for both 4square and fb
- (UIView *)viewForTableHeader
{
    UIView *headerView = [super viewForTableHeader];
    
    if (!_facebookButton) {
        _facebookButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        UIImage *image = [UIImage imageWithPathName:@"modules/facebook/button-facebook.png"];
        _facebookButton.frame = CGRectMake(0, 0, image.size.width, image.size.height);
        [_facebookButton setImage:image forState:UIControlStateNormal];
        [_facebookButton addTarget:self action:@selector(facebookButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    if (!_foursquareButton) {
        _foursquareButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        UIImage *image = [UIImage imageWithPathName:@"modules/foursquare/foursquare.jpg"];
        [_foursquareButton setImage:image forState:UIControlStateNormal];
        [_foursquareButton addTarget:self action:@selector(foursquareButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    CGRect frame = headerView.frame;
    frame.size.height += _foursquareButton.frame.size.height;
    UIView *containerView = [[[UIView alloc] initWithFrame:frame] autorelease];
    
    [containerView addSubview:headerView];
    [containerView addSubview:_foursquareButton];
    [containerView addSubview:_facebookButton];
    
    return containerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id cellData = [[_sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    if ([cellData isKindOfClass:[NSDictionary class]]) {    
        NSString *accessory = [cellData objectForKey:@"accessory"];
        NSURL *url = nil;
        if ([accessory isEqualToString:TableViewCellAccessoryMap]) {
            NSString *placemarkID = [_event placemarkID];
            NSString *placemarkString = placemarkID ? [NSString stringWithFormat:@"&identifier=%@", placemarkID] : @"";
            NSString *queryString = [NSString stringWithFormat:@"title=%@&lat=%.4f&lon=%.4f&type=building%@",
                                     _event.title,
                                     _event.coordinate.latitude, _event.coordinate.longitude, placemarkString];
            
            url = [NSURL internalURLWithModuleTag:MapTag path:LocalPathPageNameSearch query:queryString];
            if (url && [[UIApplication sharedApplication] canOpenURL:url]) {
                [[UIApplication sharedApplication] openURL:url];
                return;
            }
        }
    }
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (void)dealloc
{
    [_facebookButton release];
    [_foursquareButton release];
    [super dealloc];
}

@end