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
    
    NSDictionary *defaults = [[self class] defaultValues];
    NSMutableDictionary *tmp = [defaults mutableCopy];
    [tmp addEntriesFromDictionary:dictionary];
    NSDictionary *safe = [tmp dictionaryWithValuesForKeys:[defaults allKeys]];
    [self setPropertiesFromDictionary:safe];

    return self;
}


/*
 * - initWithFile:
 */
- (instancetype)initWithSchemeFileURL:(NSURL *)file
{
    if ((self = [self init]))
    {
        [self loadFromSchemeFileURL:file];
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


- (void)setPropertiesFromDictionary:(NSDictionary *)dictionaryRepresentation
{
    [self setValuesForKeysWithDictionary:dictionaryRepresentation];
}


- (NSDictionary *)dictionaryRepresentation
{
    return [self dictionaryWithValuesForKeys:[[[self class] propertiesAll] allObjects]];
}


- (NSDictionary *)propertyListRepresentation
{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
	NSValueTransformer *xformer = [NSValueTransformer valueTransformerForName:@"MGSColourToPlainTextTransformer"];

    for (NSString *key in [self.dictionaryRepresentation allKeys])
    {
        if ([[[self class] propertiesOfTypeString] containsObject:key])
        {
            [dictionary setObject:[self valueForKey:key] forKey:key];
        }
        if ([[[self class] propertiesOfTypeColor] containsObject:key])
        {
			[dictionary setObject:[xformer transformedValue:[self valueForKey:key]] forKey:key];
        }
        if ([[[self class] propertiesOfTypeBool] containsObject:key])
        {
            [dictionary setObject:[self valueForKey:key] forKey:key];
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
- (void)loadFromSchemeFileURL:(NSURL *)file
{
    NSDictionary *fileContents = [NSDictionary dictionaryWithContentsOfURL:file];
	if (!fileContents) {
        NSLog(@"Error reading file %@", file);
        return;
    }

    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    NSValueTransformer *xformer = [NSValueTransformer valueTransformerForName:@"MGSColourToPlainTextTransformer"];

    for (NSString *key in [fileContents allKeys])
    {
        if ([[[self class] propertiesOfTypeString] containsObject:key])
        {
            NSString *object = [fileContents objectForKey:key];
            [dictionary setObject:object forKey:key];
        }
        if ([[[self class] propertiesOfTypeColor] containsObject:key])
        {
            NSColor *object = [xformer reverseTransformedValue:[fileContents objectForKey:key]];
            [dictionary setObject:object forKey:key];
        }
        if ([[[self class] propertiesOfTypeBool] containsObject:key])
        {
            NSNumber *object = [fileContents objectForKey:key];
            [dictionary setObject:object forKey:key];
        }
    }
    
    [self setPropertiesFromDictionary:dictionary];
}


/*
 * - propertiesSaveToFile:
 */
- (BOOL)writeToSchemeFileURL:(NSURL *)file
{
	NSDictionary *props = [self propertyListRepresentation];
	return [props writeToURL:file atomically:YES];
}


#pragma mark - Category and Private


/*
 * - defaultValues
 */
+ (NSDictionary *)defaultValues
{
    NSMutableDictionary *res = [NSMutableDictionary dictionary];

    [res setObject:NSLocalizedStringFromTableInBundle(
            @"Custom Settings", nil, [NSBundle bundleForClass:[self class]],
            @"Name for Custom Settings scheme.")
        forKey:@"displayName"];
    
    // Use the built-in defaults instead of reinventing wheels.
    NSDictionary *defaults = [MGSFragariaView defaultsDictionary];
    
    NSMutableSet *mykeys = [[self propertiesAll] mutableCopy];
    [mykeys removeObject:@"displayName"];
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
