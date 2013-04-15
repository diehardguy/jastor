//
//  Jastor.h
//  Jastor
//
//  Created by Elad Ossadon on 12/14/11.
//  http://devign.me | http://elad.ossadon.com | http://twitter.com/elado
//

@interface Jastor : NSObject <NSCoding>

@property (nonatomic, copy) NSString *objectId;
@property (nonatomic, assign) Boolean isDirty;
@property (nonatomic, assign) Boolean isNew;
@property (nonatomic, assign) Boolean isRefreshing;

+ (id)objectFromDictionary:(NSDictionary*)dictionary;

- (id)initWithDictionary:(NSDictionary *)dictionary;

- (NSMutableDictionary *)toDictionary;

@end