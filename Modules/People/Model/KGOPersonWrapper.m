#import "KGOPersonWrapper.h"
#import "Foundation+KGOAdditions.h"
#import "KGOPerson.h"
#import "CoreDataManager.h"
#import "PersonContact.h"
#import "PersonOrganization.h"
#import "PersonAddress.h"
#import "AddressBookUtils.h"

NSString * const KGOPersonContactTypeEmail = @"email";
NSString * const KGOPersonContactTypePhone = @"phone";
NSString * const KGOPersonContactTypeIM = @"im";
NSString * const KGOPersonContactTypeURL = @"url";
NSString * const KGOPersonContactTypeAddress = @"address";

@interface KGOPersonWrapper (Private)

+ (BOOL)isValidAddressDict:(id)aDict;
+ (BOOL)isValidOrganizationDict:(id)aDict;
+ (BOOL)isValidContactDict:(id)aDict;

+ (NSDate *)recentlyViewedThreshold;

- (NSArray *)getMultiValueRecordProperty:(ABPropertyID)property;
- (id)getRecordProperty:(ABPropertyID)property expectedClass:(Class)expectedClass;
- (BOOL)setRecordValue:(id)value forProperty:(ABPropertyID)property expectedClass:(Class)expectedClass;
- (ABPropertyType)abPropertyTypeForClass:(Class)class;
- (Class)classForABPropertyType:(ABPropertyType)type;
- (BOOL)setMultiValue:(NSArray *)values forProperty:(ABPropertyID)property expectedClass:(Class)expectedClass;
- (BOOL)setABAddresses:(NSArray *)addressDict;

@end


@implementation KGOPersonWrapper

@synthesize identifier = _identifier,
name = _name,
firstName = _firstName,
lastName = _lastName,
birthday = _birthday,
photo = _photo,
photoURL = _photoURL,
organizations = _organizations,
addresses = _addresses,
phones = _phones,
emails = _emails,
screennames = _screennames,
webpages = _webpages;

- (void)dealloc {

    [_identifier release];
    [_name release];
    
    [_firstName release];
    [_lastName release];
    [_birthday release];
    [_organizations release];
    [_addresses release];
    [_photo release];
    [_photoURL release];
    [_phones release];
    [_emails release];
    [_screennames release];
    [_webpages release];
    
    [_kgoPerson release];
    
    if (_ab != NULL) {
        CFRelease(_ab);
    }
    if (_abRecord != NULL) {
        CFRelease(_abRecord);
    }
    
    [super dealloc];
}

#pragma mark KGOSearchResult

- (NSString *)title {
    return self.name;
}

- (NSString *)subtitle {
    NSString *subtitle = nil;
    if (self.organizations.count) {
        NSDictionary *labelValue = [self.organizations objectAtIndex:0];
        NSDictionary *orgDict = [labelValue dictionaryForKey:@"value"];
        if (orgDict) {
            subtitle = [orgDict stringForKey:@"jobTitle" nilIfEmpty:YES];
            if (!subtitle)
                subtitle = [orgDict stringForKey:@"organization" nilIfEmpty:YES];
        }
    }
    return subtitle;
}

- (BOOL)isBookmarked {
    return NO;
}

- (void)addBookmark {
    // do nothing
}

- (void)removeBookmark {
    // do nothing
}

#pragma mark -
#pragma mark Dictionary representation

- (id)initWithDictionary:(NSDictionary *)dictionary {
    if (!dictionary) {
        [self release];
        return nil;
    }
    
    self = [super init];
    if (self) {
        self.name = [dictionary stringForKey:@"name" nilIfEmpty:YES];
        self.firstName = [dictionary stringForKey:@"firstName" nilIfEmpty:YES];
        self.lastName = [dictionary stringForKey:@"lastName" nilIfEmpty:YES];
        self.birthday = [dictionary dateForKey:@"birthday" format:@"yyyyMMdd"];
        self.photoURL = [dictionary stringForKey:@"photoURL" nilIfEmpty:YES];

        NSMutableArray *array = [NSMutableArray array];
        for (id aDict in [dictionary arrayForKey:@"organizations"]) {
            NSDictionary *orgDict = [aDict dictionaryForKey:@"value"];
            if ([KGOPersonWrapper isValidOrganizationDict:orgDict])
                [array addObject:aDict];
        }
        if (array.count)
            self.organizations = array;

        _phones = [[NSMutableArray alloc] init];
        _emails = [[NSMutableArray alloc] init];
        _webpages = [[NSMutableArray alloc] init];
        _screennames = [[NSMutableArray alloc] init];
        _addresses = [[NSMutableArray alloc] init];
        
        for (NSDictionary *aDict in [dictionary arrayForKey:@"contacts"]) {
            if ([KGOPersonWrapper isValidContactDict:aDict]) {
                NSString *type = [aDict stringForKey:@"type" nilIfEmpty:YES];
                if ([type isEqualToString:KGOPersonContactTypePhone]) {
                    [_phones addObject:aDict];
                } else if ([type isEqualToString:KGOPersonContactTypeEmail]) {
                    [_emails addObject:aDict];
                } else if ([type isEqualToString:KGOPersonContactTypeURL]) {
                    [_webpages addObject:aDict];
                } else if ([type isEqualToString:KGOPersonContactTypeIM]) {
                    [_screennames addObject:aDict];
                } else if ([type isEqualToString:KGOPersonContactTypeAddress]) {
                    [_addresses addObject:aDict];
                }
            }
        }
    }
    return self;
}

+ (NSString *)displayAddressForDict:(NSDictionary *)addressDict {
    NSString *address = [addressDict stringForKey:@"display" nilIfEmpty:YES];
    if (!address) {
        NSMutableArray *addressArray = [NSMutableArray array];
        
        NSMutableArray *lineArray = [NSMutableArray array];
        for (NSString *key in [NSArray arrayWithObjects:@"street", @"street2", nil]) {
            NSString *tempVal = [addressDict stringForKey:key nilIfEmpty:YES];
            if (tempVal)
                [lineArray addObject:tempVal];
        }
        if (lineArray.count)
            [addressArray addObject:[lineArray componentsJoinedByString:@"\n"]];
        
        lineArray = [NSMutableArray array];
        for (NSString *key in [NSArray arrayWithObjects:@"city", @"state", @"country", nil]) {
            NSString *tempVal = [addressDict stringForKey:key nilIfEmpty:YES];
            if (tempVal)
                [lineArray addObject:tempVal];
        }
        if (lineArray.count)
            [addressArray addObject:[lineArray componentsJoinedByString:@", "]];
        
        NSString *zip = [addressDict stringForKey:@"zip" nilIfEmpty:YES];
        if (zip)
            [addressArray addObject:zip];
        
        address = [addressArray componentsJoinedByString:@"\n"];
    }
    
    return address;
}

+ (BOOL)isValidAddressDict:(id)aDict {
    return [aDict isKindOfClass:[NSDictionary class]]
        && ([aDict stringForKey:@"display" nilIfEmpty:NO] || [aDict stringForKey:@"street" nilIfEmpty:NO]
            || [aDict stringForKey:@"city" nilIfEmpty:NO] || [aDict stringForKey:@"state" nilIfEmpty:NO]
            || [aDict stringForKey:@"zip" nilIfEmpty:NO] || [aDict stringForKey:@"country" nilIfEmpty:NO]);
}

+ (BOOL)isValidOrganizationDict:(id)aDict {
    return [aDict isKindOfClass:[NSDictionary class]]
        && ([aDict stringForKey:@"department" nilIfEmpty:NO] || [aDict stringForKey:@"organization" nilIfEmpty:NO]
            || [aDict stringForKey:@"jobTitle" nilIfEmpty:NO]);
}

+ (BOOL)isValidContactDict:(id)aDict {
    return [aDict isKindOfClass:[NSDictionary class]] && [aDict stringForKey:@"label" nilIfEmpty:NO] && [aDict objectForKey:@"value"];
}

#pragma mark -
#pragma mark Core Data representation

- (id)initWithKGOPerson:(KGOPerson *)person {
    self = [super init];
    if (self) {
        self.KGOPerson = person;
    }
    return self;
}

- (void)markAsRecentlyViewed {
    [self convertToKGOPerson];
    _kgoPerson.viewed = [NSDate date];
    [self saveToCoreData];
}

- (void)saveToCoreData {
    [self convertToKGOPerson]; // make sure we have a reference to the NSManagedObject
    
    [[CoreDataManager sharedManager] saveData];
}

- (KGOPerson *)KGOPerson {
    return _kgoPerson;
}

- (void)setKGOPerson:(KGOPerson *)person {
    if (_kgoPerson != person) {
        [_kgoPerson release];
        _kgoPerson = [person retain];
    }
    self.name = _kgoPerson.name;
    self.firstName = _kgoPerson.firstName;
    self.lastName = _kgoPerson.lastName;
    self.birthday = _kgoPerson.birthday;
    self.photo = _kgoPerson.photo;
    
    NSMutableArray *array = [NSMutableArray array];
    for (PersonOrganization *organization in _kgoPerson.organizations) {
        [array addObject:[organization dictionary]];
    }
    self.organizations = [NSArray arrayWithArray:array];
    
    array = [NSMutableArray array];
    for (PersonAddress *address in _kgoPerson.addresses) {
        [array addObject:[address dictionary]];
    }
    self.addresses = [NSArray arrayWithArray:array];
    
    _phones = [[NSMutableArray alloc] init];
    _emails = [[NSMutableArray alloc] init];
    _webpages = [[NSMutableArray alloc] init];
    _screennames = [[NSMutableArray alloc] init];
    
    for (PersonContact *aContact in _kgoPerson.contacts) {
        if ([aContact.type isEqualToString:KGOPersonContactTypePhone]) {
            [_phones addObject:[aContact dictionary]];
        } else if ([aContact.type isEqualToString:KGOPersonContactTypeEmail]) {
            [_emails addObject:[aContact dictionary]];
        } else if ([aContact.type isEqualToString:KGOPersonContactTypeURL]) {
            [_webpages addObject:[aContact dictionary]];
        } else if ([aContact.type isEqualToString:KGOPersonContactTypeIM]) {
            [_screennames addObject:[aContact dictionary]];
        }
    }
}

- (KGOPerson *)convertToKGOPerson {
    if (!_kgoPerson) {
        _kgoPerson = [[KGOPerson personWithIdentifier:_identifier] retain];
    }
    _kgoPerson.name = self.name;
    _kgoPerson.firstName = self.firstName;
    _kgoPerson.lastName = self.lastName;
    _kgoPerson.birthday = self.birthday;
    _kgoPerson.photo = self.photo;
    
    _kgoPerson.organizations = nil;
    for (NSDictionary *aDict in _organizations) {
        //NSString *label = [aDict stringForKey:@"label" nilIfEmpty:YES]; // we are currently ignoring this in core data
        NSDictionary *orgDict = [aDict dictionaryForKey:@"value"];
        if ([KGOPersonWrapper isValidOrganizationDict:orgDict]) {
            PersonOrganization *anOrganization = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:PersonOrganizationEntityName];
            anOrganization.person = _kgoPerson;
            anOrganization.organization = [orgDict stringForKey:@"organization" nilIfEmpty:YES];
            anOrganization.jobTitle = [orgDict stringForKey:@"jobTitle" nilIfEmpty:YES];
            anOrganization.department = [orgDict stringForKey:@"department" nilIfEmpty:YES];
        }
    }

    _kgoPerson.addresses = nil;
    for (NSDictionary *aDict in _addresses) {
        NSString *label = [aDict stringForKey:@"label" nilIfEmpty:YES];
        NSDictionary *addressDict = [aDict dictionaryForKey:@"value"];
        if ([KGOPersonWrapper isValidAddressDict:addressDict]) {
            PersonAddress *anAddress = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:PersonAddressEntityName];
            anAddress.person = _kgoPerson;
            anAddress.label = label;
            anAddress.city = [addressDict stringForKey:@"city" nilIfEmpty:YES];
            anAddress.country = [addressDict stringForKey:@"country" nilIfEmpty:YES];
            anAddress.display = [addressDict stringForKey:@"display" nilIfEmpty:YES];
            anAddress.state = [addressDict stringForKey:@"state" nilIfEmpty:YES];
            anAddress.street = [addressDict stringForKey:@"street" nilIfEmpty:YES];
            anAddress.street2 = [addressDict stringForKey:@"street2" nilIfEmpty:YES];
            anAddress.zip = [addressDict stringForKey:@"zip" nilIfEmpty:YES];
        }
    }
    
    NSMutableSet *allContacts = [NSMutableSet set];
    
    for (NSDictionary *aDict in _phones) {
        [allContacts addObject:[PersonContact personContactWithDictionary:aDict type:KGOPersonContactTypePhone]];
    }
    for (NSDictionary *aDict in _emails) {
        [allContacts addObject:[PersonContact personContactWithDictionary:aDict type:KGOPersonContactTypeEmail]];
    }
    for (NSDictionary *aDict in _webpages) {
        [allContacts addObject:[PersonContact personContactWithDictionary:aDict type:KGOPersonContactTypeURL]];
    }
    for (NSDictionary *aDict in _screennames) {
        [allContacts addObject:[PersonContact personContactWithDictionary:aDict type:KGOPersonContactTypeIM]];
    }
    
    _kgoPerson.contacts = allContacts;
    
    return _kgoPerson;
}

#pragma mark Core Data class methods

+ (KGOPersonWrapper *)personWithUID:(NSString *)uid
{
	KGOPersonWrapper *person = [[CoreDataManager sharedManager] getObjectForEntity:KGOPersonEntityName attribute:@"uid" value:uid];
	return person;
}

+ (NSDate *)recentlyViewedThreshold {
    // TODO: configure this timeout
    return [NSDate dateWithTimeIntervalSinceNow:-1500000];
}

+ (void)clearRecentlyViewed {
    NSDate *timeout = [KGOPersonWrapper recentlyViewedThreshold];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"viewed > %@", timeout];
    NSArray *results = [[CoreDataManager sharedManager] objectsForEntity:KGOPersonEntityName matchingPredicate:pred];
    for (KGOPerson *person in results) {
        [[CoreDataManager sharedManager] deleteObject:person];
    }
    [[CoreDataManager sharedManager] saveData];
}

+ (void)clearOldResults {
    // if the person's result was viewed over X days ago, remove it
    // TODO: configure these timeouts
    NSDate *timeout = [KGOPersonWrapper recentlyViewedThreshold];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"viewed < %@", timeout];
    
    NSArray *results = [[CoreDataManager sharedManager] objectsForEntity:KGOPersonEntityName matchingPredicate:pred];
    if (results.count) {
        for (KGOPerson *person in results) {
            [[CoreDataManager sharedManager] deleteObject:person];
        }
        [[CoreDataManager sharedManager] saveData];
    }
}

+ (NSArray *)fetchRecentlyViewed {
    NSMutableArray *recents = [NSMutableArray array];
    NSDate *timeout = [KGOPersonWrapper recentlyViewedThreshold];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"viewed > %@", timeout];
    NSArray *sort = [NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"viewed" ascending:NO] autorelease]];
    NSArray *storedPeople = [[CoreDataManager sharedManager] objectsForEntity:KGOPersonEntityName matchingPredicate:pred sortDescriptors:sort];
    for (KGOPerson *person in storedPeople) {
        KGOPersonWrapper *personWrapper = [[[KGOPersonWrapper alloc] initWithKGOPerson:person] autorelease];
        [recents addObject:personWrapper];
    }
    return recents;
}

#pragma mark -
#pragma mark Address Book representation

- (id)initWithABRecord:(ABRecordRef)record {
    
    if (ABRecordGetRecordType(record) != kABPersonType) {
        NSLog(@"attempted to initialize KGOPerson with a non-person Address Book record");
        [self release];
        return nil;
    }
    
    self = [super init];
    if (self) {
        _ab = ABAddressBookCreate();
        _abRecord = CFRetain(record);

        self.firstName = [self getRecordProperty:kABPersonFirstNameProperty expectedClass:[NSString class]];
        self.lastName = [self getRecordProperty:kABPersonLastNameProperty expectedClass:[NSString class]];
        self.name = [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName];
        self.birthday = [self getRecordProperty:kABPersonDepartmentProperty expectedClass:[NSDate class]];
        
        if (ABPersonHasImageData(_abRecord)) {
            // if on iOS 4.1 and later, we can use
            // ABPersonCopyImageDataWithFormat(_abRecord, kABPersonImageFormatThumbnail)
            CFDataRef imageData = ABPersonCopyImageData(_abRecord);
            _photo = [(NSData *)imageData copy];
            CFRelease(imageData);
        }
        
        
        
        self.phones = [self getRecordProperty:kABPersonPhoneProperty expectedClass:[NSArray class]];
        self.emails = [self getRecordProperty:kABPersonEmailProperty expectedClass:[NSArray class]];
        self.screennames = [self getRecordProperty:kABPersonInstantMessageProperty expectedClass:[NSArray class]];
        self.webpages = [self getRecordProperty:kABPersonURLProperty expectedClass:[NSArray class]];
    }
    return self;
}

- (ABRecordRef)ABPerson {
    return _abRecord;
}

- (ABRecordRef)convertToABPerson {
    if (!_ab) {
        _ab = ABAddressBookCreate();
    }
    if (!_abRecord) {
        _abRecord = ABPersonCreate();
    }
    if (_firstName)    [self setRecordValue:_firstName forProperty:kABPersonFirstNameProperty expectedClass:[NSString class]];
    if (_lastName)     [self setRecordValue:_lastName forProperty:kABPersonLastNameProperty expectedClass:[NSString class]];
    if (_birthday)     [self setRecordValue:_birthday forProperty:kABPersonOrganizationProperty expectedClass:[NSDate class]];

    if (_photo) {
        CFErrorRef error = NULL;
        if (!ABPersonSetImageData(_abRecord, (CFDataRef)_photo, &error)) {
            NSLog(@"could not set image data");
        }
    }


    if (self.organizations.count) {
        NSDictionary *labelValue = [self.organizations objectAtIndex:0];
        NSDictionary *orgDict = [labelValue objectForKey:@"value"];
        if (orgDict) {
            NSString *jobTitle = [orgDict stringForKey:@"jobTitle" nilIfEmpty:YES];
            if (jobTitle) {
                [self setRecordValue:jobTitle forProperty:kABPersonJobTitleProperty expectedClass:[NSString class]];
            }
            NSString *organization = [orgDict stringForKey:@"organization" nilIfEmpty:YES];
            if (organization) {
                [self setRecordValue:organization forProperty:kABPersonOrganizationProperty expectedClass:[NSString class]];
            }
            NSString *department = [orgDict stringForKey:@"department" nilIfEmpty:YES];
            if (department) {
                [self setRecordValue:department forProperty:kABPersonDepartmentProperty expectedClass:[NSString class]];
            }
        }
    }
    
    if (_phones)       [self setMultiValue:_phones forProperty:kABPersonPhoneProperty expectedClass:[NSString class]];
    if (_emails)       [self setMultiValue:_emails forProperty:kABPersonEmailProperty expectedClass:[NSString class]];
    if (_screennames)  [self setMultiValue:_screennames forProperty:kABPersonInstantMessageProperty expectedClass:[NSString class]];
    if (_webpages)     [self setMultiValue:_webpages forProperty:kABPersonURLProperty expectedClass:[NSString class]];

    if (_addresses)    [self setABAddresses:_addresses];

    return _abRecord;
}

- (void)setABPerson:(ABRecordRef)person {
    if (!_ab) {
        _ab = ABAddressBookCreate();
    }
    if (person != _abRecord) {
        CFRelease(_abRecord);
        _abRecord = CFRetain(person);
    }
}

- (void)addMultiValue:(NSDictionary *)valueDict forProperty:(ABPropertyID)property expectedClass:(Class)expectedClass {
    if (!_abRecord)
        return;

    NSString *label = [valueDict objectForKey:@"label"];
    NSString *value = [valueDict objectForKey:@"value"];
    
    // check value against user declared class
    if (![value isKindOfClass:expectedClass])
        return;
    
    // check user declared class against address book class
    ABPropertyType usableType = [self abPropertyTypeForClass:expectedClass];
    ABPropertyType internalType = ABPersonGetTypeOfProperty(property);
    if ((usableType | kABMultiValueMask) != (internalType | kABMultiValueMask))
        return;
    
    ABMutableMultiValueRef multi = ABMultiValueCreateMutable(property);
    CFArrayRef allValues = ABMultiValueCopyArrayOfAllValues(multi);
    if (![(NSArray *)allValues containsObject:value]) {
        ABMultiValueAddValueAndLabel(multi, value, (CFStringRef)label, NULL);
    }
    CFRelease(multi);
    CFRelease(allValues);
}

- (ABPropertyType)abPropertyTypeForClass:(Class)class {
    if (class == [NSString class])
        return kABStringPropertyType;
    if (class == [NSDate class])
        return kABDateTimePropertyType;
    if (class == [NSArray class])
        return kABMultiValueMask;
    // i haven't seen use cases for integer/real/dictionary
    return kABInvalidPropertyType;
}

- (Class)classForABPropertyType:(ABPropertyType)type {
    if ((type | kABMultiValueMask) == (kABStringPropertyType | kABMultiValueMask))
        return [NSString class];
    if ((type | kABMultiValueMask) == (kABDateTimePropertyType | kABMultiValueMask))
        return [NSDate class];
    return [NSNull class]; // something that will fail every check
}

- (BOOL)setABAddresses:(NSArray *)addresses {
    ABMutableMultiValueRef multi = ABMultiValueCreateMutable(kABMultiDictionaryPropertyType);

    static NSDictionary *valueMap = nil;
    if (valueMap == nil) {
        valueMap = [[NSDictionary alloc] initWithObjectsAndKeys:
                    (NSString *)kABPersonAddressStreetKey, @"street",
                    (NSString *)kABPersonAddressCityKey, @"city",
                    (NSString *)kABPersonAddressStateKey, @"state",
                    (NSString *)kABPersonAddressZIPKey, @"zip",
                    (NSString *)kABPersonAddressCountryKey, @"country",
                    nil];
    }
    
    for (NSDictionary *aDict in addresses) {
        NSString *label = [aDict stringForKey:@"label" nilIfEmpty:YES];
        NSDictionary *addressDict = [aDict dictionaryForKey:@"value"];
        if (addressDict) {
            NSMutableDictionary *convertedAddressDict = [NSMutableDictionary dictionary];
            for (NSString *aLabel in [valueMap allKeys]) {
                NSString *value = [addressDict stringForKey:aLabel nilIfEmpty:YES];
                if (value) {
                    [convertedAddressDict setObject:value forKey:[valueMap objectForKey:aLabel]];
                }
            }
            if (convertedAddressDict.count) {
                ABMultiValueAddValueAndLabel(multi, (CFDictionaryRef)convertedAddressDict, (CFStringRef)label, NULL);
            }
        }
    }
            
    CFErrorRef error = NULL;
    BOOL success = ABRecordSetValue(_abRecord, kABPersonAddressProperty, multi, &error);
    CFRelease(multi);
    return success;
}

- (BOOL)setRecordValue:(id)value forProperty:(ABPropertyID)property expectedClass:(Class)expectedClass {
    if (![value isKindOfClass:expectedClass])
        return NO;
    
    if (!_abRecord)
        return NO;
    
    BOOL success = NO;
    CFErrorRef error = NULL;

    ABPropertyType internalType = ABPersonGetTypeOfProperty(property);
    ABPropertyType usableType = [self abPropertyTypeForClass:expectedClass];
    
    if ((internalType & kABMultiValueMask) && (usableType & kABMultiValueMask)) {
        success = [self setMultiValue:value forProperty:property expectedClass:[self classForABPropertyType:internalType]];
        
    } else if (internalType == usableType) {
        success = ABRecordSetValue(_abRecord, property, value, &error);
        if (!success) {
            NSLog(@"error setting value %@", value);
        }
    }
    
    return success;
}

- (BOOL)setMultiValue:(NSArray *)values forProperty:(ABPropertyID)property expectedClass:(Class)expectedClass {
    ABPropertyType internalType = ABPersonGetTypeOfProperty(property);
    ABPropertyType usableType = [self abPropertyTypeForClass:expectedClass];
    if ((usableType | kABMultiValueMask) != (internalType | kABMultiValueMask))
        return NO;
    
    if (!_abRecord)
        return NO;

    BOOL success = NO;
    CFErrorRef error = NULL;

    ABMutableMultiValueRef multi = ABMultiValueCreateMutable(kABMultiStringPropertyType);
    for (NSDictionary *aDict in values) {
        //NSString *label = [aDict objectForKey:@"label"];
        NSString *label = (NSString *)kABOtherLabel;
        id value = [aDict objectForKey:@"value"];
        if ([value isKindOfClass:expectedClass]) {
            ABMultiValueAddValueAndLabel(multi, (CFTypeRef)value, (CFStringRef)label, NULL);
        }
    }
    success = ABRecordSetValue(_abRecord, property, multi, &error);
    if (!success) {
        NSLog(@"error setting values %@", values);
    }
    CFRelease(multi);
    return success;
}

- (id)getRecordProperty:(ABPropertyID)property expectedClass:(Class)expectedClass {
    [self convertToABPerson]; // make sure we have a reference to the address book
    id result = nil;
    CFTypeRef value = ABRecordCopyValue(_abRecord, property);
    ABPropertyType internalType = ABPersonGetTypeOfProperty(property);
    ABPropertyType usableType = [self abPropertyTypeForClass:expectedClass];
    
    if ((internalType & kABMultiValueMask) && (usableType & kABMultiValueMask)) {
        if (expectedClass == [NSArray class])
            result = [self getMultiValueRecordProperty:property];
        
    } else if (internalType == usableType)  {
        result = [[(id)value copy] autorelease];
    }
    CFRelease(value);
    return result;
}

- (NSArray *)getMultiValueRecordProperty:(ABPropertyID)property {
    [self convertToABPerson]; // make sure we have a reference to the address book
    return [AddressBookUtils getMultiValueRecordProperty:property record:_abRecord];
}

- (BOOL)saveToAddressBook {
    BOOL success = YES; // if there are no changes just say we succeeded
    [self convertToABPerson]; // make sure we have a reference to the address book
    
    if (ABAddressBookHasUnsavedChanges(_ab)) {
        CFErrorRef error = NULL;
        success = ABAddressBookSave(_ab, &error);
    }
    return success;
}

@end
