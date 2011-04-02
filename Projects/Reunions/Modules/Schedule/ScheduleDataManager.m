#import "ScheduleDataManager.h"
#import "ScheduleEventWrapper.h"

@implementation ScheduleDataManager

/*

{"id":"http:\/\/uid.trumba.com\/event\/93747775",
    "category":"reunion",
    "location":{
        "title":"Eliot House Courtyard",
        "building":null,
        "latlon":["42.37019","-71.121471"],
        "address":{"street":null,"city":null,"state":null},
        "multiple":false,
        "fbPlaceId":null,
        "fqPlaceId":null},
    "registration":{
        "url":"http:\/\/alumni.harvard.edu\/",
        "fee":"$80",
        "registered":true},
    "attendees":[{
        "prefix":"Ms.",
        "first_name":"Alexis",
        "last_name":"Ellwood",
        "suffix":"",
        "class_year":"2001",
        "display_name":"Alexis Ellwood "}],
    "title":"Welcome Cocktail Reception",
    "description":null,
    "url":null,
    "phone":null,
    "email":null,
    "start":"1306540800",
    "end":"1306558800",
    "allday":false,
    "registered":true}
*/

- (BOOL)requestGroups
{
    BOOL success = NO;
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortOrder" ascending:YES];
    NSArray *oldGroups = [[CoreDataManager sharedManager] objectsForEntity:KGOEntityNameCalendarGroup
                                                         matchingPredicate:nil
                                                           sortDescriptors:[NSArray arrayWithObject:sort]];
    
    if (oldGroups) {
        success = YES;
        [self.delegate groupsDidChange:oldGroups];
    }
    
    // TODO: use a timeout value to decide whether or not to check for update
    if ([[KGORequestManager sharedManager] isReachable]) {
        if(_groupsRequest) {
            return success;
        }
        
        _groupsRequest = [[KGORequestManager sharedManager] requestWithDelegate:self module:self.moduleTag path:@"categories" params:nil];
        _groupsRequest.expectedResponseType = [NSDictionary class];
        [_groupsRequest connect];
    }
    return success;
}

- (BOOL)requestEventsForCalendar:(KGOCalendar *)calendar time:(NSDate *)time
{
    NSString *timeString = [NSString stringWithFormat:@"%.0f", [time timeIntervalSince1970]];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            calendar.identifier, @"category",
                            calendar.type, @"type",
                            timeString, @"time",
                            nil];
    return [self requestEventsForCalendar:calendar params:params];
}


- (BOOL)requestEventsForCalendar:(KGOCalendar *)calendar startDate:(NSDate *)startDate endDate:(NSDate *)endDate
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   calendar.identifier, @"category",
                                   calendar.type, @"type",
                                   nil];
    
    if (startDate) {
        NSString *startString = [NSString stringWithFormat:@"%.0f", [startDate timeIntervalSince1970]];
        [params setObject:startString forKey:@"start"];
    }
    
    if (endDate) {
        NSString *endString = [NSString stringWithFormat:@"%.0f", [endDate timeIntervalSince1970]];
        [params setObject:endString forKey:@"end"];
    }
    
    return [self requestEventsForCalendar:calendar params:params];
}

- (void)request:(KGORequest *)request didReceiveResult:(id)result
{
    if ([request.path isEqualToString:@"events"]) { // events
        
        NSString *calendarID = [request.getParams objectForKey:@"category"];
        KGOCalendar *calendar = [KGOCalendar calendarWithID:calendarID];
        
        // search results boilerplate
        NSInteger total = [result integerForKey:@"total"];
        NSInteger returned = [result integerForKey:@"returned"];
        if (total > returned) {
            // TODO: implement paging
        }
        //NSString *displayField = [result stringForKey:@"displayField" nilIfEmpty:YES];
        
        NSArray *eventDicts = [result arrayForKey:@"results"];
        if (returned > eventDicts.count)
            returned = eventDicts.count;
        
        NSMutableArray *array = [NSMutableArray array];
        for (NSInteger i = 0; i < returned; i++) {
            NSDictionary *aDict = [eventDicts objectAtIndex:i];
            ScheduleEventWrapper *event = [[ScheduleEventWrapper alloc] initWithDictionary:aDict];
            [event addCalendar:calendar];
            [array addObject:event];
        }
        [self.delegate eventsDidChange:array calendar:calendar];
        
    } else {
        [super request:request didReceiveResult:result];
    }
}

@end