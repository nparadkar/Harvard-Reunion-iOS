#import "KGOPostalAddress.h"

@class KGOPerson;

@interface PersonAddress : KGOPostalAddress
{
}

@property (nonatomic, retain) KGOPerson * person;

- (NSDictionary *)dictionary;

@end



