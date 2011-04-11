#import "FacebookParentPost.h"


typedef enum {
     TINY,
     SMALL,
     MEDIUM,
     NORMAL
} FacebookPhotoSize;

@interface FacebookPhoto : FacebookParentPost {
    NSString *_thumbSrc;
    
@private
}
@property (nonatomic, retain) NSString * src;
@property (nonatomic, retain) NSData * data;
@property (nonatomic, retain) NSNumber * width;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * height;
@property (nonatomic, retain) NSData * thumbData;

// non core data
@property (nonatomic, retain) NSString *thumbSrc;

+ (FacebookPhoto *)photoWithID:(NSString *)identifier;
+ (FacebookPhoto *)photoWithDictionary:(NSDictionary *)dictionary size:(FacebookPhotoSize)size;
- (void)updateWithDictionary:(NSDictionary *)dictionary size:(FacebookPhotoSize)size;

@end
