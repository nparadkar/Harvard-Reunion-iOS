#import "KGOFoursquareEngine.h"
#import "JSON.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "Foundation+KGOAdditions.h"
#import "KGOSocialMediaController.h"
#import "KGOTheme.h"

// NSUserDefaults
NSString * const FoursquareUsernameKey = @"FoursquareUsername";
NSString * const FoursquareUserIDKey = @"FoursquareUserID";

static NSString * const FoursquareBaseURL = @"https://api.foursquare.com/v2";

@implementation KGOFoursquareRequest

@synthesize delegate, resourceName, resourceID, command, params, postParams, isPostRequest;

- (NSString *)fullURLString
{
    NSMutableArray *pathComponents = [NSMutableArray arrayWithObjects:FoursquareBaseURL, self.resourceName, nil];
    if (self.resourceID) {
        [pathComponents addObject:self.resourceID];
    }
    if (self.command) {
        [pathComponents addObject:self.command];
    }
    
    NSString *baseURL = [pathComponents componentsJoinedByString:@"/"];
    NSString *query = [NSURL queryStringWithParameters:self.params];
    
    return [NSString stringWithFormat:@"%@?%@", baseURL, query];
}

- (void)connect
{
    [self requestFromURL:[self fullURLString]];
}

- (void)requestFromURL:(NSString *)urlString
{
    if (_connection) {
        return;
    }
    
    DLog(@"foursquare: requesting from %@", urlString);
    
    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]
                                                                 cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                             timeoutInterval:30] autorelease];
    
    if (self.isPostRequest) {
        [request setHTTPMethod:@"POST"];
        self.isPostRequest = NO;
    }
    
    if (self.postParams) {
        NSError *error = nil;
        [request setHTTPBody:[NSPropertyListSerialization dataWithPropertyList:_postParams
                                                                        format:NSPropertyListBinaryFormat_v1_0
                                                                       options:0
                                                                         error:&error]];
        [self.postParams release];
        self.postParams = nil;

         if (error) {
            NSLog(@"problem setting http post body: %@", [error description]);
            return;
        }
    }
    
    [KGO_SHARED_APP_DELEGATE() showNetworkActivityIndicator];
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if (!_data) {
        _data = [[NSMutableData alloc] init];
    }
    [_data setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_data appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [_data release];
    _data = nil;
    [_connection release];
    _connection = nil;

    [KGO_SHARED_APP_DELEGATE() hideNetworkActivityIndicator];
    [self.delegate foursquareRequest:self didFailWithError:error];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    SBJsonParser *parser = [[[SBJsonParser alloc] init] autorelease];
    id result = [parser objectWithData:_data];
    
    if ([result isKindOfClass:[NSDictionary class]]) {
        DLog(@"%@", [result description]);
        NSDictionary *meta = [result objectForKey:@"meta"];
        id errorType = [meta objectForKey:@"errorType"];
        id errorInfo = [result objectForKey:@"error"];
        if (errorInfo || errorType) {
            NSError *error = [NSError errorWithDomain:@"com.modolabs.foursquareEngine" code:1 userInfo:result];
            [self.delegate foursquareRequest:self didFailWithError:error];
            
        } else {
            NSDictionary *response = [result dictionaryForKey:@"response"];
            NSArray *notifications = [result arrayForKey:@"notifications"];
            if (response) {
                [self.delegate foursquareRequest:self didSucceedWithResponse:response andNotifications: notifications];
            } else {
                [self.delegate foursquareRequest:self didSucceedWithResponse:result andNotifications: nil];
            }
        }
        
    } else {
        NSLog(@"received result that was not a dictionary: %@", [result description]);
    }
    
    [_connection release];
    _connection = nil;
    [_data release];
    _data = nil;

    [KGO_SHARED_APP_DELEGATE() hideNetworkActivityIndicator];
}

- (void)dealloc
{
    if (_connection) {
        [_connection cancel];
    }
    self.postParams = nil;
    [_data release];
    
    [super dealloc];
}

@end




@interface KGOFoursquareCheckinPair : NSObject {
}

@property (nonatomic, retain) NSDictionary *userData;
@property (nonatomic, assign) id<KGOFoursquareCheckinDelegate> delegate;
@property (nonatomic, assign) KGOFoursquareRequest *request;

@end


@implementation KGOFoursquareCheckinPair

@synthesize delegate, request, userData;

- (void)dealloc
{
    self.userData = nil;
    self.delegate = nil;
    self.request = nil;
    [super dealloc];
}

@end



@implementation KGOFoursquareEngine

NSString * const FoursquareOAuthTokenKey = @"4squareToken";
NSString * const FoursquareOAuthExpirationDate = @"4squareExpiration";

@synthesize authCode, redirectURI, clientID, clientSecret;

- (KGOFoursquareRequest *)checkinRequestWithDelegate:(id<KGOFoursquareRequestDelegate>)delegate
                                               venue:(NSString *)venue
                                      broadcastLevel:(NSUInteger)level
                                             message:(NSString *)message
{
    KGOFoursquareRequest *request = [self requestWithDelegate:delegate];
    
    request.resourceName = @"checkins";
    request.command = @"add";
    
    NSMutableDictionary *mutableParams = [[request.params mutableCopy] autorelease];
    
    [mutableParams setObject:venue forKey:@"venueId"];
    
    NSMutableArray *values = [NSMutableArray array];
    if (level == FoursquareBroadcastLevelPrivate) {
        [values addObject:@"private"];
    } else {
        if (level & FoursquareBroadcastLevelPublic) {
            [values addObject:@"public"];
        }
        if (level & FoursquareBroadcastLevelTwitter) {
            [values addObject:@"twitter"];
        }
        if (level & FoursquareBroadcastLevelFacebook) {
            [values addObject:@"facebook"];
        }
    }
    [mutableParams setObject:[values componentsJoinedByString:@","] forKey:@"broadcast"];
    
    if (message) {
        [mutableParams setObject:message forKey:@"shout"];
    }
    
    request.isPostRequest = YES;
    request.params = [[mutableParams copy] autorelease];
    
    return request;
}

- (KGOFoursquareRequest *)queryUserWithDelegate:(id<KGOFoursquareRequestDelegate>)delegate
{
    KGOFoursquareRequest *request = [self requestWithDelegate:delegate];
    request.resourceName = @"users";
    request.resourceID = @"self";
    
    return request;
}

- (KGOFoursquareRequest *)queryCheckinsRequestWithDelegate:(id<KGOFoursquareRequestDelegate>)delegate
{
    KGOFoursquareRequest *request = [self requestWithDelegate:delegate];
    request.resourceName = @"users";
    request.resourceID = @"self";
    request.command = @"checkins";
    
    return request;
}

- (KGOFoursquareRequest *)herenowRequestWithDelegate:(id<KGOFoursquareRequestDelegate>)delegate
                                               venue:(NSString *)venue
{
    KGOFoursquareRequest *request = [self requestWithDelegate:delegate];
    
    request.resourceName = @"venues";
    request.resourceID = venue;
    //request.command = @"herenow";
    
    return request;
}

- (KGOFoursquareRequest *)requestWithDelegate:(id<KGOFoursquareRequestDelegate>)delegate
{
    KGOFoursquareRequest *request = [[[KGOFoursquareRequest alloc] init] autorelease];
    request.delegate = delegate;
    if (_oauthToken) {
        request.params = [NSDictionary dictionaryWithObject:_oauthToken forKey:@"oauth_token"];
    }
    return request;
}

- (void)checkinVenue:(NSString *)venue delegate:(id<KGOFoursquareCheckinDelegate>)delegate message:(NSString *)message
{
    KGOFoursquareRequest *request = [self checkinRequestWithDelegate:self
                                                               venue:venue
                                                      broadcastLevel:FoursquareBroadcastLevelPublic
                                                             message:message];
    
    KGOFoursquareCheckinPair *pair = [[[KGOFoursquareCheckinPair alloc] init] autorelease];
    pair.delegate = delegate;
    pair.request = request;

    if (!_checkinQueue) {
        _checkinQueue = [[NSMutableArray alloc] init];
    }
    
    [_checkinQueue addObject:pair];
    
    [request connect];
}

- (void)checkUserStatusForVenue:(NSString *)venue delegate:(id<KGOFoursquareCheckinDelegate>)delegate
{
    KGOFoursquareRequest *request = [self herenowRequestWithDelegate:self venue:venue];
    KGOFoursquareCheckinPair *pair = [[[KGOFoursquareCheckinPair alloc] init] autorelease];
    pair.delegate = delegate;
    pair.request = request;
    
    if (!_checkinQueue) {
        _checkinQueue = [[NSMutableArray alloc] init];
    }
    
    [_checkinQueue addObject:pair];
    
    [request connect];
}

- (void)authorize
{
    NSAssert(self.clientID != nil, @"foursquare client ID not set, check Config.plist");
    
    NSString *internalScheme = [KGO_SHARED_APP_DELEGATE() defaultURLScheme];
    
    if (internalScheme) {
        self.redirectURI = [NSString stringWithFormat:@"%@://foursquare/authorize", internalScheme];
        NSString *urlString = [NSString stringWithFormat:@"https://foursquare.com/oauth2/authenticate"
                               "?client_id=%@"
                               "&response_type=code"
                               "&redirect_uri=%@"
                               "&display=touch",
                               self.clientID,
                               self.redirectURI];
        
        [_webVC release];
        _webVC = [[KGOWebViewController alloc] init];
        _webVC.requestURL = [NSURL URLWithString:urlString];
        _webVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        _webVC.delegate = self;
        
        UIViewController *visibleVC = [KGO_SHARED_APP_DELEGATE() visibleViewController];
        if (visibleVC.modalViewController) {
            visibleVC = visibleVC.modalViewController;
            if ([visibleVC isKindOfClass:[UINavigationController class]]) {
                visibleVC = [(UINavigationController *)visibleVC topViewController];
            }
        }
        [[NSNotificationCenter defaultCenter] addObserver:visibleVC
                                                 selector:@selector(dismissModalViewControllerAnimated:)
                                                     name:FoursquareDidLoginNotification
                                                   object:nil];
        [visibleVC presentModalViewController:_webVC animated:YES];
        [_webVC performSelector:@selector(fadeInDismissControls) withObject:nil afterDelay:10];
    }
}

- (void)requestOAuthToken
{
    NSAssert(self.clientSecret != nil, @"foursquare client not set, check Config.plist");
    
    NSString *urlString = [NSString stringWithFormat:@"https://foursquare.com/oauth2/access_token"
                           "?client_id=%@"
                           "&client_secret=%@"
                           "&grant_type=authorization_code"
                           "&redirect_uri=%@"
                           "&code=%@",
                           self.clientID,
                           self.clientSecret,
                           self.redirectURI,
                           self.authCode];
    
    _oauthRequest = [[self requestWithDelegate:self] retain];;
    [_oauthRequest requestFromURL:urlString];
}

- (void)logout
{
    [_oauthToken release];
    _oauthToken = nil;
    
    NSMutableArray *badCookies = [NSMutableArray array];
    for (NSHTTPCookie *aCookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]) {
        if ([[aCookie domain] rangeOfString:@"foursquare"].location != NSNotFound) {
            [badCookies addObject:aCookie];
        }
    }
    
    for (NSHTTPCookie *aCookie in badCookies) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:aCookie];
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:FoursquareOAuthTokenKey];
    [defaults removeObjectForKey:FoursquareUserIDKey];
    [defaults removeObjectForKey:FoursquareUsernameKey];
    [defaults synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FoursquareDidLogoutNotification object:nil];
}

- (BOOL)isLoggedIn
{
    if (!_oauthToken) {
        NSString *token = [[NSUserDefaults standardUserDefaults] stringForKey:FoursquareOAuthTokenKey];
        NSDate *date = [[NSUserDefaults standardUserDefaults] objectForKey:FoursquareOAuthExpirationDate];
        if (token && (!date || [date compare:[NSDate date]] != NSOrderedAscending)) {
            _oauthToken = [token retain];
        }
    }
    
    return _oauthToken != nil;
}


- (void)foursquareRequest:(KGOFoursquareRequest *)request didSucceedWithResponse:(NSDictionary *)response andNotifications:(NSArray *)notifications
{
    if (request == _oauthRequest) {
        [_oauthRequest release];
        _oauthRequest = nil;
        
        [_oauthToken release];
        _oauthToken = [[response stringForKey:@"access_token" nilIfEmpty:YES] retain];
        
        if (_oauthToken) {
            
            // TODO: foursquare currently doesn't expire access tokens,
            // but there is a "possibility in the future"
            // we need to verify the following code won't break anything if executed.
            id expires = [response objectForKey:@"expires"];
            if ([expires isKindOfClass:[NSString class]] || [expires isKindOfClass:[NSNumber class]]) {
                double expireTime = [expires doubleValue];
                NSDate *expireDate = [NSDate dateWithTimeIntervalSince1970:expireTime];
                [[NSUserDefaults standardUserDefaults] setObject:expireDate forKey:FoursquareOAuthExpirationDate];
            }
            
            [[NSUserDefaults standardUserDefaults] setObject:_oauthToken forKey:FoursquareOAuthTokenKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:FoursquareDidLoginNotification object:self];
            
            [self requestUserDetails];
            
            DLog(@"received oauth token %@", _oauthToken);
        }

    } else if (request == _currentUserRequest) {
        _currentUserRequest = nil;
        
        NSDictionary *userDict = [response dictionaryForKey:@"user"];
        
        NSString *userID = [userDict stringForKey:@"id" nilIfEmpty:YES];
        NSString *firstName = [userDict stringForKey:@"firstName" nilIfEmpty:YES];
        NSString *lastName = [userDict stringForKey:@"lastName" nilIfEmpty:YES];

        NSString *username = nil;
        if (firstName) {
            if (lastName) {
                username = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
            } else {
                username = firstName;
            }
        } else if (lastName) {
            username = lastName;
        }

        BOOL didSave = NO;
        
        if (username) {
            [[NSUserDefaults standardUserDefaults] setObject:username forKey:FoursquareUsernameKey];
            didSave = YES;
        }
        
        if (userID) {
            [[NSUserDefaults standardUserDefaults] setObject:userID forKey:FoursquareUserIDKey];
            didSave = YES;
        }
        
        if (didSave) {
            [[NSUserDefaults standardUserDefaults] synchronize];
            // this triggers the settings to reload
            // TODO: use a less destructive notification.  using this for now
            // since foursquare works fine without us knowing the user's name
            [[NSNotificationCenter defaultCenter] postNotificationName:KGOUserPreferencesDidChangeNotification object:nil];
        }
        
    } else {
        
        KGOFoursquareCheckinPair *currentPair = nil;
        for (KGOFoursquareCheckinPair *aPair in _checkinQueue) {
            if (aPair.request == request) {
                currentPair = aPair;
                break;
            }
        }

        if (currentPair) {
            if ([request.resourceName isEqualToString:@"venues"]) {
                NSDictionary *venueDict = [response dictionaryForKey:@"venue"];
                
                DLog(@"%@", venueDict);

                BOOL foundSelf = NO;
                // only attempt to search for self below if beenHere count is > 0
                NSDictionary *beenHereDict = [venueDict dictionaryForKey:@"beenHere"];
                id count = [beenHereDict objectForKey:@"count"];
                if ([count isKindOfClass:[NSNumber class]] || [count isKindOfClass:[NSString class]]) {
                    if ([count integerValue]) {
                        foundSelf = YES;
                    }
                }

                NSDictionary *hereNowDict = [venueDict dictionaryForKey:@"hereNow"];
                NSInteger total = [hereNowDict integerForKey:@"count"];
                NSArray *groups = [hereNowDict arrayForKey:@"groups"];
                
                if (foundSelf && groups.count) {
                    foundSelf = NO;
                    NSDictionary *firstGroup = [groups dictionaryAtIndex:0];
                    NSArray *items = [firstGroup arrayForKey:@"items"];
                    for (NSDictionary *itemInfo in items) {
                        NSDictionary *userInfo = [itemInfo dictionaryForKey:@"user"];
                        if ([[userInfo stringForKey:@"relationship" nilIfEmpty:YES] isEqualToString:@"self"]) {
                            foundSelf = YES;
                            
                            // Remove the user from the list
                            // We handle the user separately
                            NSMutableArray *tempGroups = [NSMutableArray arrayWithArray:groups];
                            NSMutableDictionary *tempFirstGroup = [NSMutableDictionary dictionaryWithDictionary:firstGroup];
                            NSMutableArray *tempItems = [NSMutableArray arrayWithArray:items];

                            // Create new group containing only the user
                            NSArray *selfItems = [NSArray arrayWithObject:itemInfo];
                            NSDictionary *selfGroup = [NSDictionary dictionaryWithObjectsAndKeys: 
                                                       [NSNumber numberWithInt:1], @"count",
                                                       selfItems, @"items",
                                                       @"You are here!", @"name",
                                                       @"self", @"type",
                                                       nil];
                            
                            // Remove the user from the friends group
                            [tempItems removeObject:itemInfo];
                            NSInteger count = [tempFirstGroup integerForKey:@"count"];
                            [tempFirstGroup setObject:[NSNumber numberWithInt:(count-1)] forKey:@"count"];

                            [tempFirstGroup setObject:[NSArray arrayWithArray:tempItems] forKey:@"items"];
                            [tempGroups replaceObjectAtIndex:0 withObject:[NSDictionary dictionaryWithDictionary:tempFirstGroup]];
                            
                            // Insert the new self group
                            [tempGroups insertObject:selfGroup atIndex:0];
                            
                            groups = [NSArray arrayWithArray:tempGroups];
                            DLog(@"%@", groups);

                            break;
                        }
                    }
                }
                
               
                if (foundSelf) {
                    if ([currentPair.delegate respondsToSelector:@selector(venueCheckinStatusReceived:forVenue:)]) {
                        [currentPair.delegate venueCheckinStatusReceived:foundSelf forVenue:request.resourceID];
                    }
                    
                    if ([currentPair.delegate respondsToSelector:@selector(didReceiveCheckins:total:forVenue:)]) {
                        [currentPair.delegate didReceiveCheckins:groups total:total forVenue:request.resourceID];
                    }
                } else {
                    // sometimes the hereNow API is out of date.  Also look at the user's checkins:
                    
                    KGOFoursquareRequest *checkinsRequest = [self queryCheckinsRequestWithDelegate:self];
                    KGOFoursquareCheckinPair *pair = [[[KGOFoursquareCheckinPair alloc] init] autorelease];
                    pair.delegate = currentPair.delegate;
                    pair.request = checkinsRequest;
                    pair.userData = [NSDictionary dictionaryWithObjectsAndKeys:
                                     request.resourceID, @"venue", 
                                     groups, @"groups", 
                                     [NSNumber numberWithInt: total], @"total", 
                                     nil];
                    
                    if (!_checkinQueue) {
                        _checkinQueue = [[NSMutableArray alloc] init];
                    }
                    
                    [_checkinQueue addObject:pair];
                    
                    [checkinsRequest connect];
                }
                    
                
            } else if ([request.resourceName isEqualToString:@"users"] && [request.command isEqualToString:@"checkins"]) {
                BOOL foundSelf = NO;
                
                NSArray *groups = [currentPair.userData objectForKey:@"groups"];
                NSInteger total = [currentPair.userData integerForKey:@"total"];
                
                NSDictionary *checkinDict = [response dictionaryForKey:@"checkins"];
                NSArray *items = [checkinDict arrayForKey:@"items"];
                NSString *targetVenue = [currentPair.userData objectForKey:@"venue"];

                if (!targetVenue) return;
                DLog(@"%@", currentPair.userData);
                
                NSMutableDictionary *newestCheckin = nil;
                NSString *newestCheckinVenue = nil;
                int newestCheckinAge = 60*60*3; // Anything after 3 hours ago is invalid
                
                // Only the very newest checkin at a venue is valid
                for (NSDictionary *itemDict in items) {
                    double creationTime = (double)[itemDict integerForKey:@"createdAt"];
                    NSDate *creationDate = [NSDate dateWithTimeIntervalSince1970:creationTime];
                    int checkinAge = -(int)[creationDate timeIntervalSinceNow];
                    
                    if (checkinAge < newestCheckinAge) {
                        NSDictionary *venue = [itemDict dictionaryForKey:@"venue"];
                        newestCheckin = [NSMutableDictionary dictionaryWithDictionary:itemDict];
                        newestCheckinVenue = [venue stringForKey:@"id" nilIfEmpty:YES];
                        newestCheckinAge = checkinAge;
                    }
                }
                
                if (newestCheckinVenue && targetVenue && [newestCheckinVenue isEqualToString:targetVenue]) {
                    foundSelf = YES;
                    total++;
                    
                    KGOFoursquareRequest *usersRequest = [self queryUserWithDelegate:self];
                    KGOFoursquareCheckinPair *pair = [[[KGOFoursquareCheckinPair alloc] init] autorelease];
                    pair.delegate = currentPair.delegate;
                    pair.request = usersRequest;
                    pair.userData = [NSDictionary dictionaryWithObjectsAndKeys:
                                     targetVenue, @"venue", 
                                     groups, @"groups", 
                                     [NSNumber numberWithInt: total], @"total", 
                                     newestCheckin, @"selfCheckin", 
                                     nil];
                    
                    if (!_checkinQueue) {
                        _checkinQueue = [[NSMutableArray alloc] init];
                    }
                    
                    [_checkinQueue addObject:pair];
                    
                    [usersRequest connect];
                    
                } else {
                    if ([currentPair.delegate respondsToSelector:@selector(venueCheckinStatusReceived:forVenue:)]) {
                        [currentPair.delegate venueCheckinStatusReceived:foundSelf forVenue:targetVenue];
                    }
                    
                    if ([currentPair.delegate respondsToSelector:@selector(didReceiveCheckins:total:forVenue:)]) {
                        [currentPair.delegate didReceiveCheckins:groups total:total forVenue:targetVenue];
                    }

                }
                
            } else if ([request.resourceName isEqualToString:@"users"] && [request.resourceID isEqualToString:@"self"]) {
                NSString *targetVenue = [currentPair.userData objectForKey:@"venue"];
                NSArray *groups = [currentPair.userData objectForKey:@"groups"];
                NSInteger total = [currentPair.userData integerForKey:@"total"];
                NSMutableDictionary *selfCheckin = [NSMutableDictionary dictionaryWithDictionary:[currentPair.userData dictionaryForKey:@"selfCheckin"]];

                // Add the user bits
                [selfCheckin setObject:[response dictionaryForKey:@"user"] forKey:@"user"];
                
                NSArray *selfItems = [NSArray arrayWithObject:[NSDictionary dictionaryWithDictionary:selfCheckin]];
                NSDictionary *selfGroup = [NSDictionary dictionaryWithObjectsAndKeys: 
                                           [NSNumber numberWithInt:1], @"count",
                                           selfItems, @"items",
                                           @"You are here!", @"name",
                                           @"self", @"type",
                                           nil];
                
                // Insert the new self group
                NSMutableArray *tempGroups = [NSMutableArray arrayWithArray:groups];
                [tempGroups insertObject:selfGroup atIndex:0];
                groups = [NSArray arrayWithArray:tempGroups];
                
                if ([currentPair.delegate respondsToSelector:@selector(venueCheckinStatusReceived:forVenue:)]) {
                    [currentPair.delegate venueCheckinStatusReceived:YES forVenue:targetVenue];
                }
                
                if ([currentPair.delegate respondsToSelector:@selector(didReceiveCheckins:total:forVenue:)]) {
                    [currentPair.delegate didReceiveCheckins:groups total:total forVenue:targetVenue];
                }


            } else if ([request.resourceName isEqualToString:@"checkins"] && [request.command isEqualToString:@"add"]) {
                NSString *message = nil;
                NSInteger points = 0;
                
                if (notifications) {
                    for (NSDictionary *notification in notifications) {
                        NSString *type = [notification objectForKey:@"type"];
                        NSDictionary *item = [notification dictionaryForKey:@"item"];
                        
                        if (item && [type isEqualToString:@"message"]) {
                            message = [item objectForKey:@"message"];
                            
                        } else if (item && [type isEqualToString:@"score"]) {
                            points += [item integerForKey:@"total"];
                        }
                    }
                }
                DLog(@"%d points", points);
                NSDictionary *checkinResponse = [NSDictionary dictionaryWithObjectsAndKeys:
                                                 message, @"message", 
                                                 [NSNumber numberWithInteger:points], @"points", 
                                                 nil];
                
                if ([currentPair.delegate respondsToSelector:@selector(venueCheckinDidSucceed:withResponse:)]) {
                    [currentPair.delegate venueCheckinDidSucceed:request.resourceID withResponse:checkinResponse];
                }
                
            }
            
            [_checkinQueue removeObject:currentPair];
        }

    }
}

- (void)foursquareRequest:(KGOFoursquareRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"request failed with error: %@", [error description]);

    if (request == _oauthRequest) {
        [_oauthRequest release];
        _oauthRequest = nil;
        
        UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:nil
                                                             message:@"Failed to authenticate with foursquare"
                                                            delegate:self
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil] autorelease];
        [alertView show];
        
    } else if (request == _currentUserRequest) {
        _currentUserRequest = nil;
        
    } else {
        
        KGOFoursquareCheckinPair *currentPair = nil;
        for (KGOFoursquareCheckinPair *aPair in _checkinQueue) {
            if (aPair.request == request) {
                currentPair = aPair;
                break;
            }
        }
        
        if (currentPair) {
            NSString *message = nil;
            
            NSDictionary *errorInfo = [error userInfo];
            if (errorInfo) {
                DLog(@"%@", errorInfo);
                NSString *errorDetail = [[errorInfo objectForKey:@"meta"] objectForKey:@"errorDetail"];
                if (errorDetail) {
                    message = errorDetail;
                }
            }
            
            if ([request.resourceName isEqualToString:@"venues"]) {
                if ([currentPair.delegate respondsToSelector:@selector(venueCheckinStatusFailed:withMessage:)]) {
                    [currentPair.delegate venueCheckinStatusFailed:request.resourceID withMessage:message];
                }
 
            } else if ([request.resourceName isEqualToString:@"users"] && [request.command isEqualToString:@"checkins"]) {
                if ([currentPair.delegate respondsToSelector:@selector(venueCheckinStatusFailed:withMessage:)]) {
                    NSString *venue = [currentPair.userData objectForKey:@"venue"];
                    [currentPair.delegate venueCheckinStatusFailed:venue withMessage:message];
                }
                
            } else if ([request.resourceName isEqualToString:@"users"] && [request.resourceID isEqualToString:@"self"]) {
                if ([currentPair.delegate respondsToSelector:@selector(venueCheckinStatusFailed:withError:)]) {
                    NSString *venue = [currentPair.userData objectForKey:@"venue"];
                    [currentPair.delegate venueCheckinStatusFailed:venue withMessage:message];
                }
                
                
            } else if ([request.resourceName isEqualToString:@"checkins"] && [request.command isEqualToString:@"add"]) {
                if ([currentPair.delegate respondsToSelector:@selector(venueCheckinDidFail:withMessage:)]) {
                    [currentPair.delegate venueCheckinDidFail:request.resourceID withMessage:message];
                }
                
            }
            
            [_checkinQueue removeObject:currentPair];
        }
        
    }
}

- (BOOL)webViewController:(KGOWebViewController *)webVC shouldOpenSystemBrowserForURL:(NSURL *)url
{
    return [[url absoluteString] rangeOfString:@"login"].location == NSNotFound
        && [[url absoluteString] rangeOfString:@"oauth2"].location == NSNotFound;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [_webVC.parentViewController dismissModalViewControllerAnimated:YES];
}

- (void)webViewControllerFrameLoadInterrupted:(KGOWebViewController *)webVC
{
    [_webVC.parentViewController dismissModalViewControllerAnimated:YES];
    
    [_webVC.parentViewController performSelector:@selector(dismissModalViewControllerAnimated:) withObject:nil afterDelay:1];
}

- (void)disconnectRequestsForDelegate:(id<KGOFoursquareCheckinDelegate>)delegate
{
    NSMutableArray *removed = [NSMutableArray array];
    for (KGOFoursquareCheckinPair *aPair in _checkinQueue) {
        if (aPair.delegate == delegate) {
            aPair.delegate = nil;
            [removed addObject:aPair];
        }
    }
    for (KGOFoursquareCheckinPair *aPair in removed) {
        [_checkinQueue removeObject:aPair];
    }
}

- (void)requestUserDetails
{
    if (_currentUserRequest) {
        return;
    }
    
    _currentUserRequest = [self requestWithDelegate:self];
    _currentUserRequest.resourceName = @"users";
    _currentUserRequest.resourceID = @"self";
    
    [_currentUserRequest connect];
}

- (void)dealloc
{
    if (_oauthRequest) {
        _oauthRequest.delegate = nil;
    }
    
    if (_currentUserRequest) {
        _currentUserRequest.delegate = nil;
    }
    
    [_webVC release];
    self.clientID = nil;
    self.clientSecret = nil;
    self.authCode = nil;
    self.redirectURI = nil;
    
    [_oauthToken release];
    [super dealloc];
}

@end
