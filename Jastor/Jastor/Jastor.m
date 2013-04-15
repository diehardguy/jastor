#import "Jastor.h"
#import "JastorRuntimeHelper.h"
#import "JSONKit.h"
#import "ISO8601DateFormatter.h"

@interface Jastor (private)
-(void)populateWithDictionary:(NSDictionary*)dictionary;
- (NSDate *)convertWCFStringToDate:(NSString*)wcfDate;
- (NSString *)convertDateToWCFString:(NSDate*)wcfDate;
@end

@implementation Jastor

@synthesize objectId;
static NSString *idPropertyName = @"id";
static NSString *idPropertyNameOnObject = @"objectId";

Class nsDictionaryClass;
Class nsArrayClass;

+ (id)objectFromDictionary:(NSDictionary*)dictionary {
    id item = [[[self alloc] initWithDictionary:dictionary] autorelease];
    return item;
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
	if (!nsDictionaryClass) nsDictionaryClass = [NSDictionary class];
	if (!nsArrayClass) nsArrayClass = [NSArray class];
    
	if ((self = [super init])) {
        [self populateWithDictionary:dictionary];
	}
	return self;
}

-(void)setValuesForKeysWithDictionary:(NSDictionary *)keyedValues {
    [self populateWithDictionary:keyedValues];
}

- (void)dealloc {
	self.objectId = nil;
	
    //	for (NSString *key in [JastorRuntimeHelper propertyNames:[self class]]) {
    //		//[self setValue:nil forKey:key];
    //	}
	
	[super dealloc];
}

- (void)encodeWithCoder:(NSCoder*)encoder {
	[encoder encodeObject:self.objectId forKey:idPropertyNameOnObject];
	for (NSString *key in [JastorRuntimeHelper propertyNames:[self class]]) {
		[encoder encodeObject:[self valueForKey:key] forKey:key];
	}
}

- (id)initWithCoder:(NSCoder *)decoder {
	if ((self = [super init])) {
		[self setValue:[decoder decodeObjectForKey:idPropertyNameOnObject] forKey:idPropertyNameOnObject];
		
		for (NSString *key in [JastorRuntimeHelper propertyNames:[self class]]) {
            if ([JastorRuntimeHelper isPropertyReadOnly:[self class] propertyName:key]) {
                continue;
            }
			id value = [decoder decodeObjectForKey:key];
			if (value != [NSNull null] && value != nil) {
				[self setValue:value forKey:key];
			}
		}
	}
	return self;
}

- (NSMutableDictionary *)toDictionary {
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    if (self.objectId) {
        [dic setObject:self.objectId forKey:idPropertyName];
    }
	for (NSString *key in [JastorRuntimeHelper propertyNames:[self class]]) {
        if ([key length] > 6) {
            if ([[key substringToIndex:6] isEqualToString:@"_spotr"] || [key isEqualToString:@"delegate"] ) {
                break;
            }
        }
        id value = [self valueForKey:key];
        if (value && [value isKindOfClass:[Jastor class]]) {
            [dic setObject:[value toDictionary] forKey:key];
        } else if (value && [value isKindOfClass:[NSArray class]] && ((NSArray*)value).count > 0) {
            id internalValue = [value objectAtIndex:0];
            if (internalValue && [internalValue isKindOfClass:[Jastor class]]) {
                NSMutableArray *internalItems = [NSMutableArray array];
                for (id item in value) {
                    [internalItems addObject:[item toDictionary]];
                }
                [dic setObject:internalItems forKey:key];
            } else {
                [dic setObject:[self convertValueToOdataValue:value andClass:[JastorRuntimeHelper propertyClassNameForPropertyName:key ofClass:[self class]]] forKey:key];
            }
        } else if (value != nil) {
            [dic setObject:[self convertValueToOdataValue:value andClass:[JastorRuntimeHelper propertyClassNameForPropertyName:key ofClass:[self class]]] forKey:key];
            
        }
	}
    return dic;
}

- (NSString *)description {
    NSMutableDictionary *dic = [self toDictionary];
	
	return [NSString stringWithFormat:@"#<%@: id = %@ %@>", [self class], self.objectId, [dic description]];
}

- (BOOL)isEqual:(id)object {
	if (object == nil || ![object isKindOfClass:[Jastor class]]) return NO;
	
	Jastor *model = (Jastor *)object;
	
	return [self.objectId isEqualToString:model.objectId];
}

-(void)populateWithDictionary:(NSDictionary *)dictionary {
    for (NSString *key in [JastorRuntimeHelper propertyNames:[self class]]) {
        id value = [dictionary valueForKey:key];
        if ([value respondsToSelector:@selector(objectForKey:)]) {
            //Need to remove the Results Dictionary Wrapping this Array
            //And change value to array
            if ([value objectForKey:@"results"] != nil) {
                Boolean hasMore = NO;
                NSURL *next = nil;
                if ([value objectForKey:@"__next"] != nil) {
                    hasMore = YES;
                    next = [NSURL URLWithString:[value objectForKey:@"__next"]];
                }
                value = [value objectForKey:@"results"];
            } else if ([value objectForKey:@"__mediaresource"]) {
                value = [value objectForKey:@"__mediaresource"];
            }
        }
        
        if (value == [NSNull null] || value == nil) {
            continue;
        }
        
        if ([JastorRuntimeHelper isPropertyReadOnly:[self class] propertyName:key]) {
            //continue;
        }
        // handle dictionary
        
        if ([value respondsToSelector:@selector(objectForKey:)]) {
            Class klass = [JastorRuntimeHelper propertyClassForPropertyName:key ofClass:[self class]];
            // check if __deferred object, if so then return nil
            if ([value objectForKey:@"__deferred"] == nil) {
                value = [[[klass alloc] initWithDictionary:value] autorelease];
            } else {
                value = nil;
            }
        }
        // handle array
        else if ([value respondsToSelector:@selector(objectAtIndex:)]) {
            Class arrayItemType = [[self class] performSelector:NSSelectorFromString([NSString stringWithFormat:@"%@_class", key])];
            
            //NSMutableArray *childObjects = [NSMutableArray arrayWithCapacity:[(NSArray*)value count]];
            NSMutableArray *childObjects;
            
            if ([self valueForKey:key] != nil && !self.isRefreshing) {
                //OK Must be loading more here! Need to add more to the array
                childObjects = [NSMutableArray arrayWithCapacity:[(NSArray*)value count]+[[self mutableArrayValueForKey:key] count]];
                [childObjects addObjectsFromArray:[self mutableArrayValueForKey:key]];
            } else {
                childObjects = [NSMutableArray arrayWithCapacity:[(NSArray*)value count]];
            }
            
            for (id child in value) {
                if ([child respondsToSelector:@selector(objectForKey:)]) {
                    Jastor *childDTO = [[[arrayItemType alloc] initWithDictionary:child] autorelease];
                    [childObjects addObject:childDTO];
                } else {
                    [childObjects addObject:child];
                }
            }
            
            value = childObjects;
        }
        // handle all others
        [self setValue:[self convertOdataValueToValue:value andClass:[JastorRuntimeHelper propertyClassNameForPropertyName:key ofClass:[self class]]] forKey:key];
        //[self setValue:value forKey:key];
    }
    
    id objectIdValue;
    if ((objectIdValue = [dictionary objectForKey:idPropertyName]) && objectIdValue != [NSNull null]) {
        if (![objectIdValue isKindOfClass:[NSString class]]) {
            objectIdValue = [NSString stringWithFormat:@"%@", objectIdValue];
        }
        [self setValue:objectIdValue forKey:idPropertyNameOnObject];
    }
    
}

-(id)convertValueToOdataValue:(id)value andClass:(NSString*)klassName {
    // Need to translate types
    Class klass = NSClassFromString(klassName);
    if (klass != nil) {
        //We have a type so lets do conversions
        if (klass == [NSDate class]) {
            if ([value class] == [NSNull class]) value = [NSDate date];
            value = [self convertDateToWCFString:value];
        }
    } else {
        // Primitive types.  Only really looking for Booleans and doubles let everything else pass through.
        if ([klassName isEqualToString:@"c"] || [klassName isEqualToString:@"c"]) {
            value = [NSNumber numberWithBool:[value intValue]];
        }
        
        //doubles need to be sent as strings
        if ([klassName isEqualToString:@"d"]) {
            value = [[NSNumber numberWithDouble:[value doubleValue]] stringValue];
        }
    }
    return value;
}

-(id)convertOdataValueToValue:(id)value andClass:(NSString*)klassName {
    // Need to translate types
    Class klass = NSClassFromString(klassName);
    if (klass != nil) {
        //We have a type so lets do conversions
        if (klass == [NSDate class]) {
            value = [self convertWCFStringToDate:value];
        } else if (klass == [NSURL class]) {
            value = [NSURL URLWithString:value];
        }
    } else {
        // Primitive types.  Only really looking for Booleans let everything else pass through.
        if ([klassName isEqualToString:@"C"] || [klassName isEqualToString:@"c"]) {
            //value = [[NSNumber numberWithBool:[value intValue]] boolValue];
        }
    }
    return value;
}

+ (NSDate *)convertWCFStringToDate:(NSString*)wcfDate {
    if ([wcfDate class] != [NSNull class]) {
        ISO8601DateFormatter *formatter = [[[ISO8601DateFormatter alloc] init] autorelease];
        return [formatter dateFromString:wcfDate];
    }
    else {
        return nil;
    }
}

+ (NSString *)convertDateToWCFString:(NSDate*)wcfDate {
    ISO8601DateFormatter *formatter = [[[ISO8601DateFormatter alloc] init] autorelease];
    [formatter setIncludeTime:YES];
    return [formatter stringFromDate:wcfDate];
}
@end
