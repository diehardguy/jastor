@interface JastorRuntimeHelper : NSObject {
	
}
+ (BOOL)isPropertyReadOnly:(Class)klass propertyName:(NSString*)propertyName;
+ (Class)propertyClassForPropertyName:(NSString *)propertyName ofClass:(Class)klass;
+ (NSString*)propertyClassNameForPropertyName:(NSString *)propertyName ofClass:(Class)klass;
+ (NSArray *)propertyNames:(Class)klass;

@end
