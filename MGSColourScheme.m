//
//  MGSColourScheme.m
//  Fragaria
//
//  Created by Jim Derry on 3/16/15.
//
//

#import "MGSColourScheme.h"
#import "MGSFragariaView+Definitions.h"
#import "MGSColourToPlainTextTransformer.h"
#import "NSColor+TransformedCompare.h"


@interface MGSColourScheme ()

@property (nonatomic, assign, readwrite) NSDictionary *dictionaryRepresentation;
@property (nonatomic, assign, readwrite) NSDictionary *propertyListRepresentation;

+ (NSSet *) propertiesAll;
+ (NSSet *) propertiesOfTypeBool;
+ (NSSet *) propertiesOfTypeColor;
+ (NSSet *) propertiesOfTypeString;

@end


@implementation MGSColourScheme


#pragma mark - Initializers


/*
 * - initWithDictionary:
 */
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
{
    self = [super init];
    
    NSMutableDictionary *tmp = [[[self class] defaultValues] mutableCopy];
    NSDictionary *safe = [dictionary dictionaryWithValuesForKeys:[tmp allKeys]];
    [tmp addEntriesFromDictionary:safe];
    self.dictionaryRepresentation = tmp;

    return self;
}


/*
 * - initWithFile:
 */
- (instancetype)initWithFile:(NSString *)file
{
    if ((self = [self init]))
    {
        [self propertiesLoadFromFile:file];
    }

    return self;
}


/*
 * - init
 */
- (instancetype)init
{
	return [self initWithDictionary:@{}];
}


#pragma mark - General Properties


/*
 * @property dictionaryRepresentation
 * Publicly this is readonly, but we'll use the setter of this "representation"
 * internally in order to set the values from a dictionary.
 */
- (void)setDictionaryRepresentation:(NSDictionary *)dictionaryRepresentation
{
    [self setValuesForKeysWithDictionary:dictionaryRepresentation];
}

- (NSDictionary *)dictionaryRepresentation
{
    return [self dictionaryWithValuesForKeys:[[[self class] propertiesAll] allObjects]];
}


/*
 * @property propertyListRepresentation
 * Publicly this is readonly, but we'll use the setter of this "representation"
 * internally in order to set the values from a property list.
 */
- (void)setPropertyListRepresentation:(NSDictionary *)propertyListRepresentation
{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
	NSValueTransformer *xformer = [NSValueTransformer valueTransformerForName:@"MGSColourToPlainTextTransformer"];

    for (NSString *key in [propertyListRepresentation allKeys])
    {
        if ([[[self class] propertiesOfTypeString] containsObject:key])
        {
			NSString *object = [propertyListRepresentation objectForKey:key];
            [dictionary setObject:object forKey:key];
        }
        if ([[[self class] propertiesOfTypeColor] containsObject:key])
        {
			NSColor *object = [xformer reverseTransformedValue:[propertyListRepresentation objectForKey:key]];
            [dictionary setObject:object forKey:key];
        }
        if ([[[self class] propertiesOfTypeBool] containsObject:key])
        {
			NSNumber *object = [propertyListRepresentation objectForKey:key];
            [dictionary setObject:object forKey:key];
        }
    }
    
    self.dictionaryRepresentation = dictionary;
}

- (NSDictionary *)propertyListRepresentation
{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
	NSValueTransformer *xformer = [NSValueTransformer valueTransformerForName:@"MGSColourToPlainTextTransformer"];

    for (NSString *key in [self.dictionaryRepresentation allKeys])
    {
        if ([[[self class] propertiesOfTypeString] containsObject:key])
        {
            [dictionary setObject:[self.dictionaryRepresentation objectForKey:key] forKey:key];
        }
        if ([[[self class] propertiesOfTypeColor] containsObject:key])
        {
			[dictionary setObject:[xformer transformedValue:[self.dictionaryRepresentation objectForKey:key]] forKey:key];
        }
        if ([[[self class] propertiesOfTypeBool] containsObject:key])
        {
            [dictionary setObject:[self.dictionaryRepresentation objectForKey:key] forKey:key];
        }
    }
    
    return dictionary;
}


#pragma mark - Instance Methods


/*
 * - isEqualToScheme:
 */
- (BOOL)isEqualToScheme:(MGSColourScheme *)scheme
{
    for (NSString *key in [[self class] propertiesOfScheme])
    {
        if ([[self valueForKey:key] isKindOfClass:[NSColor class]])
        {
            NSColor *color1 = [self valueForKey:key];
            NSColor *color2 = [scheme valueForKey:key];
            BOOL result = [color1 mgs_isEqualToColor:color2 transformedThrough:@"MGSColourToPlainTextTransformer"];
            if (!result)
            {
//                NSLog(@"KEY=%@ and SELF=%@ and EXTERNAL=%@", key, color1, color2);
                return result;
            }
        }
        else
        {
            BOOL result = [[self valueForKey:key] isEqual:[scheme valueForKey:key]];
            if (!result)
            {
//                NSLog(@"KEY=%@ and SELF=%@ and EXTERNAL=%@", key, [self valueForKey:key], [scheme valueForKey:key] );
                return result;
            }
        }
    }

    return YES;
}


/*
 * - propertiesLoadFromFile:
 */
- (void)propertiesLoadFromFile:(NSString *)file
{
	file = [file stringByStandardizingPath];
	NSAssert([[NSFileManager defaultManager] fileExistsAtPath:file], @"File %@ not found!", file);
	
    NSDictionary *fileContents = [NSDictionary dictionaryWithContentsOfFile:file];
	NSAssert(fileContents, @"Error reading file %@", file);

    self.propertyListRepresentation = fileContents;
}


/*
 * - propertiesSaveToFile:
 */
- (BOOL)propertiesSaveToFile:(NSString *)file
{
    file = [file stringByStandardizingPath];
	NSDictionary *props = self.propertyListRepresentation;
	return [props writeToFile:file atomically:YES];
}


#pragma mark - Category and Private


/*
 * - defaultValues
 */
+ (NSDictionary *)defaultValues
{
    NSMutableDictionary *res;

    [res setObject:NSLocalizedStringFromTableInBundle(
            @"Custom Settings", nil, [NSBundle bundleForClass:[self class]],
            @"Name for Custom Settings scheme.")
        forKey:@"displayName"];
    
    // Use the built-in defaults instead of reinventing wheels.
    NSDictionary *defaults = [MGSFragariaView defaultsDictionary];
    
    NSSet *mykeys = [self propertiesAll];
    for (NSString *key in mykeys) {
        id value = [defaults objectForKey:key];
        if ([value isKindOfClass:[NSData class]]) {
            value = [NSUnarchiver unarchiveObjectWithData:value];
        }
        [res setObject:value forKey:key];
    }
    
    return [res copy];
}


/*
 * + propertiesAll
 */
+ (NSSet *)propertiesAll
{
	return [[MGSFragariaView propertyGroupTheme]
			setByAddingObjectsFromSet:[[self class] propertiesOfTypeString]];
}


/*
 * + propertiesOfTypeBool
 */
+ (NSSet*)propertiesOfTypeBool
{
	return [MGSFragariaView propertyGroupSyntaxHighlightingBools];
}


/*
 * + propertiesOfTypeColor
 */
+ (NSSet *)propertiesOfTypeColor
{
	return [[MGSFragariaView propertyGroupEditorColours]
			setByAddingObjectsFromSet:[MGSFragariaView propertyGroupSyntaxHighlightingColours]];
}


/*
 * + propertiesOfTypeString
 */
+ (NSSet *)propertiesOfTypeString
{
	return [NSSet setWithArray:@[@"displayName"]];
}


/*
 * + colourProperties
 */
+ (NSArray *)propertiesOfScheme
{
	return [[MGSFragariaView propertyGroupTheme] allObjects];
}


@end
