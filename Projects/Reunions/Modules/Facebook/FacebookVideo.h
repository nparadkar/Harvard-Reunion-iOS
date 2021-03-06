
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import "FacebookParentPost.h"
#import "FacebookThumbnail.h"

@interface FacebookVideo : FacebookParentPost <FacebookThumbSource> {
@private
}
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSString * summary;
@property (nonatomic, retain) NSString * thumbSrc;
@property (nonatomic, retain) NSData * thumbData;
@property (nonatomic, retain) NSString * link;
@property (nonatomic, retain) NSString * src;

+ (FacebookVideo *)videoWithDictionary:(NSDictionary *)dictionary;
+ (FacebookVideo *)videoWithID:(NSString *)identifier;

// Right now, it will return either "YouTube" or "Vimeo".
- (NSString *)videoSourceName;

@end
