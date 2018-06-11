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
#import "MGSColourSchemeController.h"


NSString * const MGSColourSchemeErrorDomain = @"MGSColourSchemeErrorDomain";


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


- (instancetype)initWithFragaria:(MGSFragariaView *)fragaria displayName:(NSString *)name
{
    NSArray *keys = [[self class] propertiesOfScheme];
    NSDictionary *dict = [fragaria dictionaryWithValuesForKeys:keys];
    self = [self initWithDictionary:dict];
    _displayName = name;
    return self;
}


/*
 * - initWithFile:
 */
- (instancetype)initWithSchemeFileURL:(NSURL *)file error:(NSError **)err
{
    self = [self init];
    
    if (![self loadFromSchemeFileURL:file error:err])
        return nil;

    return self;
}


- (instancetype)initWithColourScheme:(MGSColourScheme *)scheme
{
    return [self initWithDictionary:[scheme dictionaryRepresentation]];
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


- (BOOL)isEqual:(id)other
{
    if ([super isEqual:other])
        return YES;
    if ([other isKindOfClass:[self class]] && [self class] != [other class])
        return [other isEqual:self];
    if (![self isKindOfClass:[other class]])
        return NO;
    return [self isEqualToScheme:other];
}


/*
 * - propertiesLoadFromFile:
 */
- (BOOL)loadFromSchemeFileURL:(NSURL *)file error:(NSError **)err
{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    NSValueTransformer *xformer = [NSValueTransformer valueTransformerForName:@"MGSColourToPlainTextTransformer"];
    
    NSSet *stringKeys = [[self class] propertiesOfTypeString];
    NSSet *colorKeys = [[self class] propertiesOfTypeColor];
    NSSet *boolKeys = [[self class] propertiesOfTypeBool];
    
    NSInputStream *fp = [NSInputStream inputStreamWithURL:file];
    [fp open];
    if (!fp) {
        if (err)
            *err = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:nil];
        return NO;
    }
    
    id fileContents = [NSPropertyListSerialization propertyListWithStream:fp options:NSPropertyListImmutable format:nil error:err];
    if (!fileContents)
        goto plistError;
    [fp close];
    
    if (![fileContents isKindOfClass:[NSDictionary class]])
        goto wrongFormat;

    for (NSString *key in fileContents) {
        id object;
        
        if ([stringKeys containsObject:key]) {
            object = [fileContents objectForKey:key];
            if (![object isKindOfClass:[NSString class]])
                goto wrongFormat;
            
        } else if ([colorKeys containsObject:key]) {
            NSString *data = [fileContents objectForKey:key];
            if (![data isKindOfClass:[NSString class]])
                goto wrongFormat;
            object = [xformer reverseTransformedValue:[fileContents objectForKey:key]];
            if (![object isKindOfClass:[NSColor class]])
                goto wrongFormat;
            
        } else if ([boolKeys containsObject:key]) {
            object = [fileContents objectForKey:key];
            if (![object isKindOfClass:[NSNumber class]])
                goto wrongFormat;
            
        } else {
            NSLog(@"unrecognized key %@ in colour scheme file %@", key, file);
            continue;
        }
        
        [dictionary setObject:object forKey:key];
    }
    
    [self setPropertiesFromDictionary:dictionary];
    return YES;
    
plistError:
    if (err) {
        if ([[*err domain] isEqual:NSCocoaErrorDomain]) {
            if ([*err code] != NSPropertyListReadStreamError)
                *err = [NSError errorWithDomain:MGSColourSchemeErrorDomain code:MGSColourSchemeWrongFileFormat userInfo:@{NSUnderlyingErrorKey: *err}];
            else if ([[*err userInfo] objectForKey:NSUnderlyingErrorKey])
                *err = [[*err userInfo] objectForKey:NSUnderlyingErrorKey];
        }
    }
    return NO;
    
wrongFormat:
    if (err)
        *err = [NSError errorWithDomain:MGSColourSchemeErrorDomain code:MGSColourSchemeWrongFileFormat userInfo:@{}];
    return NO;
}


/*
 * - propertiesSaveToFile:
 */
- (BOOL)writeToSchemeFileURL:(NSURL *)file error:(NSError **)err
{
	NSDictionary *props = [self propertyListRepresentation];
    
    NSOutputStream *fp = [NSOutputStream outputStreamWithURL:file append:NO];
    if (!fp) {
        if (err)
            *err = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:nil];
    }
    
    [fp open];
    BOOL res = [NSPropertyListSerialization writePropertyList:props toStream:fp format:NSPropertyListXMLFormat_v1_0 options:0 error:err];
    [fp close];
    
    return res;
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"<(%@ *)%p displayName=\"%@\">",
        NSStringFromClass([self class]),
        self,
        self.displayName];
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


+ (NSArray <MGSColourScheme *> *)builtinColourSchemes
{
    NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
    NSArray <NSURL *> *paths = [myBundle URLsForResourcesWithExtension:KMGSColourSchemeExt subdirectory:KMGSColourSchemesFolder];
    
    NSMutableArray <MGSColourScheme *> *res = [NSMutableArray array];
    for (NSURL *path in paths) {
        MGSColourScheme *sch = [[MGSColourScheme alloc] initWithSchemeFileURL:path error:nil];
        if (!sch) {
            NSLog(@"loading of scheme %@ failed", path);
            continue;
        }
        [res addObject:sch];
    }
    
    return res;
}


@end
