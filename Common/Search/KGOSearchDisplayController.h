#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "KGOSearchDelegate.h"
#import "KGOTableViewController.h"
#import "KGODetailPager.h"

@class KGOSearchDisplayController;
@protocol KGOSearchResult;


@protocol KGOSearchDisplayDelegate <NSObject>

- (BOOL)searchControllerShouldShowSuggestions:(KGOSearchDisplayController *)controller; // whether or not to show recent searches
- (NSArray *)searchControllerValidModules:(KGOSearchDisplayController *)controller; // modules to pass the search term to

- (NSString *)searchControllerModuleTag:(KGOSearchDisplayController *)controller; // module tag to associate with saved search term
- (void)searchController:(KGOSearchDisplayController *)controller didSelectResult:(id<KGOSearchResult>)aResult;

@optional

- (void)searchController:(KGOSearchDisplayController *)controller didShowSearchResultsTableView:(UITableView *)tableView;
- (void)searchController:(KGOSearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView;
- (void)searchControllerDidShowSearchResultsMapView:(KGOSearchDisplayController *)controller;
- (void)searchControllerWillHideSearchResultsMapView:(KGOSearchDisplayController *)controller;

@end


@class KGOTableController;

@interface KGOSearchDisplayController : NSObject <UISearchBarDelegate, KGOTableViewDataSource, KGOSearchDelegate, MKMapViewDelegate, KGODetailPagerController> {
    
    id<KGOSearchDisplayDelegate> _delegate;
    NSArray *_searchResults;
    BOOL _didExecuteSearch;

    UISearchBar *_searchBar;
    BOOL _active;
    UIViewController *_searchContentsController;
    KGOTableController *_searchTableController;
    UIControl *_searchOverlay;
    MKMapView *_searchResultsMapView;
    BOOL _showingMapView;
}

@property (nonatomic, readonly) id<KGOSearchDisplayDelegate> delegate;
@property (nonatomic, retain) NSArray *searchResults;

@property (nonatomic, readonly) UISearchBar *searchBar;
@property (nonatomic, getter=isActive) BOOL active;
@property (nonatomic, readonly) UIViewController *searchContentsController;
@property (nonatomic, readonly) KGOTableController *searchTableController;

@property (nonatomic, readonly) MKMapView *searchResultsMapView;

- (id)initWithSearchBar:(UISearchBar *)searchBar delegate:(id<KGOSearchDisplayDelegate>)delegate contentsController:(UIViewController *)viewController;
- (void)setActive:(BOOL)visible animated:(BOOL)animated;
- (void)executeSearch:(NSString *)text params:(NSDictionary *)params;

- (void)focusSearchBarAnimated:(BOOL)animated;
- (void)unfocusSearchBarAnimated:(BOOL)animated;

- (void)showSearchOverlayAnimated:(BOOL)animated;
- (void)hideSearchOverlayAnimated:(BOOL)animated;

- (void)showSearchResultsTableView;
- (void)hideSearchResultsTableView;

- (void)reloadSearchResultsTableView;

- (void)showSearchResultsMapView;
- (void)hideSearchResultsMapView;

- (BOOL)canShowMapView;

@end