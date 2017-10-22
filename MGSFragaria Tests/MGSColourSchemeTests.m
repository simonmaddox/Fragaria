//
//  MGSColourSchemeTests.m
//  Fragaria
//
//  Created by Jim Derry on 3/16/15.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "MGSColourScheme.h"
#import "NSColor+TransformedCompare.h"
#import "MGSFragariaView.h"
#import "MGSUserDefaultsUtilities.h"


/**
 *  Basic tests for MGSColourScheme.
 **/
@interface MGSColourSchemeTests : XCTestCase

@end


@implementation MGSColourSchemeTests


/*
 * - setUp
 */
- (void)setUp
{
    [super setUp];
}


/*
 * - tearDown
 */
- (void)tearDown
{
    [super tearDown];
}


/*
 * - test_properties_to_file_and_back
 *   Make sure we can write a valid plist.
 */
- (void)test_propertiesToFile
{
    NSURL *tmpdir = [NSURL fileURLWithPath:NSTemporaryDirectory()];
    NSURL *outputPath;
	NSString *expects1 = @"Monty Python";
    NSColor *expects2 = [NSColor purpleColor];

    outputPath = [tmpdir URLByAppendingPathComponent:@"test_propertiesToFile.plist"];
	MGSColourScheme *scheme = [[MGSColourScheme alloc] init];
	scheme.displayName = expects1;
    scheme.colourForComments = expects2;
	
	XCTAssert([scheme writeToSchemeFileURL:outputPath error:nil]);
	
	scheme = [[MGSColourScheme alloc] init];

	XCTAssert([scheme loadFromSchemeFileURL:outputPath error:nil]);
 
    [[NSFileManager defaultManager] removeItemAtURL:outputPath error:nil];
	
	XCTAssert([scheme.displayName isEqualToString:expects1]);
    XCTAssert([scheme.colourForComments mgs_isEqualToColor:expects2 transformedThrough:@"MGSColourToPlainTextTransformer"]);
}


- (void)test_corruptFiles
{
    NSBundle *mybundle = [NSBundle bundleForClass:[self class]];
    NSArray <NSURL *> *testCases = @[
        [mybundle URLForResource:@"ColorScheme_WrongRootObject" withExtension:@"plist"],
        [mybundle URLForResource:@"ColorScheme_NotAPlist" withExtension:@"rtf"],
        [mybundle URLForResource:@"ColorScheme_WrongType1" withExtension:@"plist"],
        [mybundle URLForResource:@"ColorScheme_WrongType2" withExtension:@"plist"],
        [mybundle URLForResource:@"ColorScheme_WrongType3" withExtension:@"plist"]
    ];
    
    for (NSURL *url in testCases) {
        NSError *err;
        MGSColourScheme *test = [[MGSColourScheme alloc] initWithSchemeFileURL:url error:&err];
        XCTAssert(err && !test, @"invalid color scheme %@ did not fail to parse", url);
        NSLog(@"invalid file: %@; error: %@", url, err);
    }
}


/*
 * - test_initWithDictionary_simple
 */
- (void)test_initWithDictionary_simple
{
    NSString *expects = @"Autumn Noontime Moonlight";

    NSDictionary *testDict = @{ @"displayName" : expects };

    MGSColourScheme *testInstance = [[MGSColourScheme alloc] initWithDictionary:testDict];

    NSString *result = testInstance.displayName;

    XCTAssert([result isEqualToString:expects]);
}


- (void)test_initWithFragaria
{
    MGSFragariaView *fragaria = [[MGSFragariaView alloc] init];
    NSDictionary *keys = @{
        NSStringFromSelector(@selector(coloursComments)): @(NO),
        NSStringFromSelector(@selector(colourForComments)): MGSTestRandomColor()
    };
    [fragaria setValuesForKeysWithDictionary:keys];
    
    MGSColourScheme *s1 = [[MGSColourScheme alloc] initWithFragaria:fragaria displayName:@"test"];
    
    for (NSString *key in keys) {
        id val = [s1 valueForKey:key];
        XCTAssert([val isEqual:[keys objectForKey:key]]);
    }
}


/*
 * - test_isEqualToScheme
 */
- (void)test_isEqualToScheme
{
    NSColor *expects1 = [NSColor purpleColor];

    MGSColourScheme *scheme1 = [[MGSColourScheme alloc] init];
    MGSColourScheme *scheme2 = [[MGSColourScheme alloc] init];

    // Assert that they are equal.
    XCTAssert([scheme1 isEqualToScheme:scheme2]);

    scheme1.colourForNumbers = expects1;

    // Changing a color is detectable as a difference.
    XCTAssert(![scheme1 isEqualToScheme:scheme2]);

    scheme2.colourForNumbers = expects1;

    // Now equal again.
    XCTAssert([scheme1 isEqualToScheme:scheme2]);

    // Reset
    scheme1 = [[MGSColourScheme alloc] init];
    scheme2 = [[MGSColourScheme alloc] init];

    scheme1.coloursStrings = !scheme1.coloursStrings;

    // Should be not the same.
    XCTAssert(![scheme1 isEqualToScheme:scheme2]);

    scheme2.coloursStrings = !scheme2.coloursStrings;

    // Should be the same.
    XCTAssert([scheme1 isEqualToScheme:scheme2]);
}

/*
 * - test_isEqualToScheme_file
 *   Make sure isEqualToScheme works.
 */
- (void)test_isEqualToScheme_file
{
    NSURL *tmpdir = [NSURL fileURLWithPath:NSTemporaryDirectory()];
    NSURL *outputPath;
	NSString *expects1 = @"Pecans and Cashews";
	NSColor *expects2 = [NSColor purpleColor];
	
    outputPath = [tmpdir URLByAppendingPathComponent:@"test_isEqualToScheme_file.plist"];
    
	MGSColourScheme *scheme = [[MGSColourScheme alloc] init];
	scheme.displayName = expects1;
	scheme.colourForKeywords = expects2;
	
    NSError *err;
	[scheme writeToSchemeFileURL:outputPath error:&err];
    NSLog(@"%@", err);
	
	scheme = [[MGSColourScheme alloc] init];
    err = nil;
	[scheme loadFromSchemeFileURL:outputPath error:&err];
    NSLog(@"%@", err);
	
	MGSColourScheme *scheme2 = [[MGSColourScheme alloc] initWithSchemeFileURL:outputPath error:nil];
 
    [[NSFileManager defaultManager] removeItemAtURL:outputPath error:nil];
	
	XCTAssert([scheme isEqualToScheme:scheme2]);
}

/*
 * - test_make_classic_fragaria_theme
 *   This test always passes, but makes a virgin Classic Fragaria.plist.
 */
- (void)test_make_classic_fragaria_theme
{
    NSURL *tmpdir = [NSURL fileURLWithPath:NSTemporaryDirectory()];
    NSURL *outputPath;
	
    outputPath = [tmpdir URLByAppendingPathComponent:@"Classic Fragaria.plist"];
    
	MGSColourScheme *scheme = [[MGSColourScheme alloc] init];
	scheme.displayName = @"Classic Fragaria";

	[scheme writeToSchemeFileURL:outputPath error:nil];
	
	XCTAssert(YES);
}


@end
