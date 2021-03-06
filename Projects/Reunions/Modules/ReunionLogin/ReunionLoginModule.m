
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import "ReunionLoginModule.h"
#import "KGOHomeScreenWidget.h"
#import "KGOHomeScreenViewController.h"
#import "KGOTheme.h"
#import "UIKit+KGOAdditions.h"
#import "ReunionHomeModule.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "Foundation+KGOAdditions.h"
#import <QuartzCore/QuartzCore.h>

#define IPAD_CURRENTUSER_FONT 20

@implementation ReunionLoginModule

- (UIView *)currentUserWidget
{
    NSDictionary *userDict = [[[KGORequestManager sharedManager] sessionInfo] dictionaryForKey:@"user"];
    self.username = [userDict stringForKey:@"name" nilIfEmpty:YES];

    KGOAppDelegate *appDelegate = KGO_SHARED_APP_DELEGATE();
    ReunionHomeModule *homeModule = (ReunionHomeModule *)[appDelegate moduleForTag:@"home"];
    self.userDescription = [homeModule reunionName];

    KGONavigationStyle navStyle = [appDelegate navigationStyle];
    CGRect frame = CGRectZero;
    if (navStyle == KGONavigationStylePortlet) {
        KGOHomeScreenViewController *homeVC = (KGOHomeScreenViewController *)[appDelegate homescreen];
        frame = [homeVC springboardFrame];
        UIImage *image = [UIImage imageWithPathName:@"modules/home/ribbon"];
        frame = CGRectMake(10, 10, frame.size.width - image.size.width - 30, 90);
    } else {
        frame = CGRectZero;
    }
    KGOHomeScreenWidget *widget = [[[KGOHomeScreenWidget alloc] initWithFrame:frame] autorelease];

    NSString *title;
    NSString *subtitle = nil;
    if (navStyle == KGONavigationStyleTabletSidebar) {
        if (self.username) {
            title = [NSString stringWithFormat:@"%@ : %@", self.userDescription, self.username];

        } else {
            title = self.userDescription;
        }
        
    } else {
        title = self.username;
        subtitle = self.userDescription;
        if (!title) {
            title = self.userDescription;
            subtitle = nil;
        }
    }
    
    UILabel *titleLabel = nil;
    UILabel *subtitleLabel = nil;
    
    if (navStyle == KGONavigationStylePortlet) {
        CGFloat y = 14; // iphone only
    
        if (subtitle) {
            subtitle = [NSString stringWithFormat:@"%@ Reunion", subtitle, nil];
            
            UIFont *font = [UIFont boldSystemFontOfSize:16];
            subtitleLabel = [UILabel multilineLabelWithText:subtitle font:font width:widget.frame.size.width];
            subtitleLabel.text = subtitle;
            CGRect frame = subtitleLabel.frame;
            frame.origin.x = 3;
            frame.origin.y = y;
            subtitleLabel.frame = frame;
            subtitleLabel.textColor = [UIColor colorWithHexString:@"D3DBE0"];
        
            y += subtitleLabel.frame.size.height + 8;
            
            [widget addSubview:subtitleLabel];
        }
        
        if (title) {
            UIFont *font = [UIFont fontWithName:@"Georgia" size:26];
            titleLabel = [UILabel multilineLabelWithText:title font:font width:widget.frame.size.width];
            CGRect frame = titleLabel.frame;
            frame.origin.x = 3;
            frame.origin.y = y;
            titleLabel.frame = frame;
            titleLabel.text = title;
            titleLabel.font = font;
            titleLabel.backgroundColor = [UIColor clearColor];
            titleLabel.textColor = [UIColor whiteColor];
            titleLabel.layer.shadowColor = [[UIColor blackColor] CGColor];
            titleLabel.layer.shadowOffset = CGSizeMake(0, 1);
            titleLabel.layer.shadowOpacity = 0.75;
            titleLabel.layer.shadowRadius = 1;
            
            y += titleLabel.frame.size.height + 10;
            
            [widget addSubview:titleLabel];
        }
        
    } else {
        if (title) {
            UIFont *font = [UIFont boldSystemFontOfSize:IPAD_CURRENTUSER_FONT];
            CGSize size = [title sizeWithFont:font];
            CGRect frame = CGRectMake(0, 0, size.width, size.height);
            titleLabel = [[[UILabel alloc] initWithFrame:frame] autorelease];
            titleLabel.text = title;
            titleLabel.backgroundColor = [UIColor clearColor];
            titleLabel.font = font;
            titleLabel.textColor = [UIColor whiteColor];
            
            [widget addSubview:titleLabel];
        }
        
        if (subtitle) {
            subtitle = [NSString stringWithFormat:@"%@ : ", subtitle];
            UIFont *font = [UIFont boldSystemFontOfSize:IPAD_CURRENTUSER_FONT];
            CGSize size = [subtitle sizeWithFont:font];
            CGRect frame = CGRectMake(0, 0, size.width, size.height);
            subtitleLabel = [[[UILabel alloc] initWithFrame:frame] autorelease];
            subtitleLabel.text = subtitle;
            
            subtitleLabel.font = font;
            subtitleLabel.backgroundColor = [UIColor clearColor];
            subtitleLabel.textColor = [UIColor whiteColor];
            subtitleLabel.layer.shadowColor = [[UIColor blackColor] CGColor];
            subtitleLabel.layer.shadowOffset = CGSizeMake(0, 1);
            subtitleLabel.layer.shadowOpacity = 0.75;
            subtitleLabel.layer.shadowRadius = 1;

            [widget addSubview:subtitleLabel];
        }
    }
    
    if (navStyle == KGONavigationStyleTabletSidebar) {
        CGRect outerFrame = [(KGOHomeScreenViewController *)[appDelegate homescreen] springboardFrame];
        
        frame = widget.frame;
        CGFloat titleWidth = (titleLabel != nil) ? titleLabel.frame.size.width : 0;
        CGFloat titleHeight = (titleLabel != nil) ? titleLabel.frame.size.height : 0;
        
        frame.size.width = titleWidth;
        frame.size.height = titleHeight;
        frame.origin.y = 10;
        frame.origin.x = floorf((outerFrame.size.width - frame.size.width) / 2);
        
        widget.frame = frame;
        widget.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        widget.overlaps = YES;
    }
    
    widget.behavesAsIcon = NO;
    
    return widget;
}

- (KGOHomeScreenWidget *)ribbonWidget
{
    KGOAppDelegate *appDelegate = KGO_SHARED_APP_DELEGATE();
    
    ReunionHomeModule *homeModule = (ReunionHomeModule *)[appDelegate moduleForTag:@"home"];
    
    KGONavigationStyle navStyle = [appDelegate navigationStyle];
    UIImage *image = [UIImage imageWithPathName:@"modules/home/ribbon"];
    UIImageView *imageView = [[[UIImageView alloc] initWithImage:image] autorelease];
    
    // reunion number
    NSString *text = [homeModule reunionNumber];
    UIFont *font = [UIFont fontWithName:@"Georgia" size:38];
    CGSize size = CGSizeZero;
    if (text) {
        size = [text sizeWithFont:font];
    }

    CGFloat y = 4;
    if (navStyle == KGONavigationStyleTabletSidebar) {
        y += 10;
    }
    
    UILabel *yearLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, y, size.width, size.height)] autorelease];
    yearLabel.text = text;
    yearLabel.font = font;
    
    // reunion number superscript
    text = @"th";
    font = [UIFont fontWithName:@"Georgia" size:18];
    size = [text sizeWithFont:font];
    UILabel *yearSupLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, y + 5, size.width, size.height)] autorelease];
    yearSupLabel.text = text;
    yearSupLabel.font = font;
    
    y += yearLabel.frame.size.height;
    
    // position above two elements
    CGFloat x = floor((imageView.frame.size.width - yearLabel.frame.size.width - yearSupLabel.frame.size.width) / 2);
    CGRect yearFrame = yearLabel.frame;
    yearFrame.origin.x = x;
    yearLabel.frame = yearFrame;
    yearFrame = yearSupLabel.frame;
    yearFrame.origin.x = x + yearLabel.frame.size.width;
    yearSupLabel.frame = yearFrame;
    
    // "reunion"
    font = [UIFont fontWithName:@"Georgia" size:16];
    UILabel *reunionLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, y, image.size.width, font.lineHeight)] autorelease];
    reunionLabel.text = @"Reunion";
    reunionLabel.font = font;
    reunionLabel.textAlignment = UITextAlignmentCenter;
    y += reunionLabel.frame.size.height;
    
    // reunion date
    font = [UIFont fontWithName:@"Georgia" size:13];
    UILabel *dateLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, y, image.size.width, font.lineHeight)] autorelease];
    dateLabel.text = [homeModule reunionDateString];
    dateLabel.font = font;
    dateLabel.textAlignment = UITextAlignmentCenter;
    
    CGRect frame = imageView.frame;
    CGRect springboardFrame = [(KGOHomeScreenViewController *)[appDelegate homescreen] springboardFrame];
    if (navStyle == KGONavigationStylePortlet) {
        frame.origin.x = springboardFrame.size.width - frame.size.width - 2;
    } else {
        frame.origin.x = 16;
    }
    KGOHomeScreenWidget *widget = [[[KGOHomeScreenWidget alloc] initWithFrame:frame] autorelease];
    
    for (UILabel *label in [NSArray arrayWithObjects:yearLabel, yearSupLabel, reunionLabel, dateLabel, nil]) {
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor whiteColor];
        label.layer.shadowColor = [[UIColor blackColor] CGColor];
        label.layer.shadowOffset = CGSizeMake(0, 1);
        label.layer.shadowOpacity = 0.67;
        label.layer.shadowRadius = 1;
    }
    
    [widget addSubview:imageView];
    [widget addSubview:yearLabel];
    [widget addSubview:yearSupLabel];
    [widget addSubview:reunionLabel];
    [widget addSubview:dateLabel];
    
    widget.behavesAsIcon = NO;
    
    if (navStyle == KGONavigationStylePortlet) {
        widget.overlaps = YES;
    } else {
        widget.gravity = KGOLayoutGravityTopLeft;
    }
    
    return widget;
}

- (NSArray *)widgetViews {
    
    NSMutableArray *widgets = [NSMutableArray array];
    UIView *currentUserWidget = [self currentUserWidget];
    if (currentUserWidget) {
        [widgets addObject:currentUserWidget];
    }
    UIView *ribbonWidget = [self ribbonWidget];
    if (ribbonWidget) {
        [widgets addObject:ribbonWidget];
    }
    return widgets;
}

- (BOOL)webViewController:(KGOWebViewController *)webVC shouldOpenSystemBrowserForURL:(NSURL *)url
{
    return [[url absoluteString] rangeOfString:[[KGORequestManager sharedManager] host]].location == NSNotFound;
}


@end
