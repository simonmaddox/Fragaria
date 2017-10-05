//
//  MyDocument.m
//  Fragaria Document
//
//  Created by Jonathan on 24/07/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MyDocument.h"
#import <Fragaria/Fragaria.h>

@implementation MyDocument{
    __weak IBOutlet MGSFragariaView *fragaria;
}


/*
 * - init
 */
- (id)init
{
    if ((self = [super init]))
    {
        _contents = [[NSTextStorage alloc] initWithString:@"// We don't need the future"];
    }
    return self;
}


#pragma mark - Nib loading

/*
 * - windowNibName
 */
- (NSString *)windowNibName
{
    return @"MyDocument";
}


/*
 * - windowControllerDidLoadNib:
 */
- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
	
    fragaria.textViewDelegate = self;
	
	// set our syntax definition
	[self setSyntaxDefinition:@"Objective-C"];
	
	// define initial document configuration
	//
	// see Fragaria.h for details
	//
    if (YES) {
        fragaria.syntaxColoured = YES;
        fragaria.showsLineNumbers = YES;
    }

    // set text
    [fragaria replaceTextStorage:_contents];

    [[MGSUserDefaultsController sharedController] addFragariaToManagedSet:fragaria];
	
    // Set the undo manager. This is fundamental and allows NSDocument to perform its magic.
    [self setUndoManager:[fragaria.textView undoManager]];
}


- (void)close
{
    [[MGSUserDefaultsController sharedController] removeFragariaFromManagedSet:fragaria];
    [super close];
}


#pragma mark - NSDocument data

/*
 * - dataOfType:error:
 */
- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    return [[self.contents string] dataUsingEncoding:NSUTF8StringEncoding];
}


/*
 * - readFromData:ofType:error:
 */
- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    NSTextStorage *ts;
    
    ts = [[NSTextStorage alloc] initWithData:data options:@{NSDocumentTypeDocumentOption:NSPlainTextDocumentType, NSCharacterEncodingDocumentOption:@(NSUTF8StringEncoding)} documentAttributes:nil error:outError];
    
    if (ts) {
        self.contents = ts;
        return YES;
    }
    return NO;
}


#pragma mark - Property Accessors

/*
 * - setSyntaxDefinition:
 */
- (void)setSyntaxDefinition:(NSString *)name
{
    fragaria.syntaxDefinitionName = name;
}


/*
 * - syntaxDefinition
 */
- (NSString *)syntaxDefinition
{
    return fragaria.syntaxDefinitionName;
}


@end
