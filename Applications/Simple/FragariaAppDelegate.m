//
//  FragariaAppDelegate.m
//  Fragaria
//
//  Created by Jonathan on 30/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "FragariaAppDelegate.h"
#import <Fragaria/Fragaria.h>
#import "MGSSimpleBreakpointDelegate.h"


@implementation FragariaAppDelegate {
    IBOutlet MGSFragariaView *fragaria;
    MGSSimpleBreakpointDelegate *breakptDelegate;
}

@synthesize window;


#pragma mark - NSApplicationDelegate

/*
 * - applicationDidFinishLaunching:
 */
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	// define initial object configuration
	//
	// see Fragaria.h for details
	//
    fragaria.textViewDelegate = self;
	
    // set the syntax colouring delegate
    fragaria.syntaxColouringDelegate = self;

	// set our syntax definition
	[self setSyntaxDefinition:@"Objective-C"];

	// get initial text - in this case a test file from the bundle
	NSString *path = [[NSBundle mainBundle] pathForResource:@"example" ofType:@"txt"];
	NSString *fileText = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
	
	// set text
    fragaria.string = fileText;

    // define a syntax error
    SMLSyntaxError *syntaxError = [SMLSyntaxError new];
    syntaxError.errorDescription = @"Syntax errors can be defined.";
    syntaxError.line = 1;
    syntaxError.character = 1;
    syntaxError.length = 10;
    fragaria.syntaxErrors = @[syntaxError];

    // specify a breakpoint delegate
    breakptDelegate = [[MGSSimpleBreakpointDelegate alloc] init];
    fragaria.breakpointDelegate = breakptDelegate;
}


/*
 * - applicationShouldTerminateAfterLastWindowClosed:
 */
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	 #pragma unused(theApplication)
	 
	 return YES;
}


#pragma mark - Actions


/*
 * - reloadString:
 */
- (IBAction)reloadString:(id)sender
{
    [fragaria setString:[fragaria string]];
}


#pragma mark - Pasteboard handling

/*
 * - copyToPasteBoard:
 */
- (IBAction)copyToPasteBoard:(id)sender
{
	NSAttributedString *attString = fragaria.textView.attributedString;
    NSData *data = [attString RTFFromRange:NSMakeRange(0, [attString length])
                        documentAttributes:@{NSDocumentTypeDocumentAttribute: NSRTFTextDocumentType}];
	NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
	[pasteboard clearContents];
	[pasteboard setData:data forType:NSRTFPboardType];
}


#pragma mark - Property Accessors

/*
 * @property syntaxDefinition
 */
- (void)setSyntaxDefinition:(NSString *)name
{
    fragaria.syntaxDefinitionName = name;
}

- (NSString *)syntaxDefinition
{
	return fragaria.syntaxDefinitionName;
}


#pragma mark - NSTextDelegate

/*
 * - textDidChange:
 */
- (void)textDidChange:(NSNotification *)notification
{
	#pragma unused(notification)

	[window setDocumentEdited:YES];
}


/*
 * - textDidBeginEditing:
 */
- (void)textDidBeginEditing:(NSNotification *)aNotification
{
	NSLog(@"notification : %@", [aNotification name]);
}


/*
 * - textDidEndEditing:
 */
- (void)textDidEndEditing:(NSNotification *)aNotification
{
	NSLog(@"notification : %@", [aNotification name]);
}


/*
 * - textShouldBeginEditing:
 */
- (BOOL)textShouldBeginEditing:(NSText *)aTextObject
{
    #pragma unused(aTextObject)
	
	return YES;
}


/*
 * - textShouldEndEditing:
 */
- (BOOL)textShouldEndEditing:(NSText *)aTextObject
{
    #pragma unused(aTextObject)
	
	return YES;
}


- (void)textViewDidChangeSelection:(NSNotification *)notification
{
    NSUInteger i, r, c;
    
    i = fragaria.textView.selectedRange.location;
    [fragaria getRow:&r column:&c forCharacterIndex:i];
    self.row = [NSString stringWithFormat:@"%lu", (unsigned long)r+1];
    self.column = [NSString stringWithFormat:@"%lu", (unsigned long)c+1];
}


#pragma mark - MGSFragariaTextViewDelegate

/*
 * - mgsTextDidPaste:
 */
- (void)mgsTextDidPaste:(NSNotification *)aNotification
{
    // When this notification is received the paste will have been accepted.
    // Use this method to query the pasteboard for additional pasteboard content
    // that may be relevant to the application: eg: a plist that may contain custom data.
    NSLog(@"notification : %@", [aNotification name]);
}


#pragma mark - SMLSyntaxColouringDelegate

/*
 * For more information on custom colouring see SMLSyntaxColouringDelegate.h
 */


/*
 * - fragariaDocument:shouldColourWithBlock:string:range:info
 */
- (BOOL)fragariaDocument:(MGSFragariaView *)fragaria shouldColourWithBlock:(BOOL (^)(NSDictionary<NSString *, id> *, NSRange))colourWithBlock string:(NSString *)string range:(NSRange)range info:(NSDictionary <NSString *, id> *)info
{
    // query info
    BOOL willColour = [[info objectForKey:SMLSyntaxWillColour] boolValue];
    NSDictionary *syntaxInfo = [info objectForKey:SMLSyntaxInfo];

    // provide compiler comfort
    (void)syntaxInfo, (void)willColour;
    
    NSLog(@"Should colour document.");
    
    // we can call colourWithBlock to perform initial colouring
    
    // YES: Fragaria should colour document
    // NO: Fragaria should not colour document
    return YES;
}


/*
 * - fragariaDocument:shouldColourGroupWithBlock:string:range:info
 */
- (BOOL)fragariaDocument:(MGSFragariaView *)fragaria shouldColourGroupWithBlock:(BOOL (^)(NSDictionary<NSString *, id> *, NSRange))colourWithBlock string:(NSString *)string range:(NSRange)range info:(NSDictionary<NSString *, id> *)info
{
    BOOL fragariaShouldColour = YES;
    
    // query info
    NSString *group = [info objectForKey:SMLSyntaxGroup];
    NSInteger groupID = [[info objectForKey:SMLSyntaxGroupID] integerValue];
    BOOL willColour = [[info objectForKey:SMLSyntaxWillColour] boolValue];
    
    // for key values see SMLSyntaxDefinition.h
    NSDictionary *syntaxInfo = [info objectForKey:SMLSyntaxInfo];

    // provide compiler comfort
    (void)syntaxInfo;

    // follow the default behaviour. if we don't then colouring occurs even when we turn
    // syntax colouring off in the preferences. this is fine in practice but confusing in a demo app.
    fragariaShouldColour = willColour;
    
    // this amount of logging makes the app sluggish
    NSLog(@"%@ group : %@ id : %li caller will colour : %@", NSStringFromSelector(_cmd), group, groupID, (willColour ? @"YES" : @"NO"));
    
    // group
    switch (groupID) {
        case kSMLSyntaxGroupNumber:
            // we can call colourWithBlock to perform initial group colouration
#if 0
                // colour the whole string with the number group colour
                colourWithBlock(attributes, range);
                
                fragariaShouldColour = NO;
#endif
            break;
            
        case kSMLSyntaxGroupCommand:
            break;
            
        case kSMLSyntaxGroupInstruction:
            break;
            
        case kSMLSyntaxGroupKeyword:
            break;
            
        case kSMLSyntaxGroupAutoComplete:
            break;
            
        case kSMLSyntaxGroupVariable:
            break;
            
        case kSMLSyntaxGroupFirstString:
            break;
            
        case kSMLSyntaxGroupSecondString:
            break;
            
        case kSMLSyntaxGroupAttribute:
            break;

        case kSMLSyntaxGroupSingleLineComment:
            break;
            
        case kSMLSyntaxGroupMultiLineComment:
            
            // we can prevent colouring of this group by returning NO
            if (NO) {
                fragariaShouldColour = NO;
            }
            
            break;
            
        case kSMLSyntaxGroupSecondStringPass2:
            break;
    }

    
    // YES: Fragaria should colour group
    // NO: Fragaria should not colour group
    return fragariaShouldColour;
}


/*
 * - fragariaDocument:didColourGroupWithBlock:string:range:info
 */
- (void)fragariaDocument:(MGSFragariaView *)fragaria didColourGroupWithBlock:(BOOL (^)(NSDictionary<NSString *, id> *, NSRange))colourWithBlock string:(NSString *)string range:(NSRange)range info:(NSDictionary<NSString *, id> *)info
{
    // query info
    NSString *group = [info objectForKey:SMLSyntaxGroup];
    NSInteger groupID = [[info objectForKey:SMLSyntaxGroupID] integerValue];
    BOOL willColour = [[info objectForKey:SMLSyntaxWillColour] boolValue];
    NSDictionary *attributes = [info objectForKey:SMLSyntaxAttributes];
    NSDictionary *syntaxInfo = [info objectForKey:SMLSyntaxInfo];
    
    // compiler comfort
    (void)syntaxInfo;
    
    // this amount of logging makes the app sluggish
    NSLog(@"%@ group : %@ id : %li caller will colour : %@",  NSStringFromSelector(_cmd), group, groupID, (willColour ? @"YES" : @"NO"));
    
    NSString *subString = [string substringWithRange:range];
    NSScanner *rangeScanner = [NSScanner scannerWithString:subString];
    [rangeScanner setScanLocation:0];
    
    // group
    switch (groupID) {
        case kSMLSyntaxGroupNumber:
            break;
            
        case kSMLSyntaxGroupCommand:
            break;
            
        case kSMLSyntaxGroupInstruction:
            break;
            
        case kSMLSyntaxGroupKeyword:
        {
            // we can iterate over the string using an NSScanner to identiy our substrings or use a regex.
            // in this simple case we just colour the occurence of a given string as a false keyword.
            NSString *fauxKeyword = @"kosmic";
            while (YES) {
                
                // look for the keyword
                [rangeScanner scanUpToString:fauxKeyword intoString:nil];
                if ([rangeScanner isAtEnd]) break;
                     
                NSUInteger location = [rangeScanner scanLocation];
                if ([rangeScanner scanString:fauxKeyword intoString:NULL]) {
                    NSRange colourRange = NSMakeRange(range.location + location, [rangeScanner scanLocation] - location);
                    
                    // the block will colour the string
                    colourWithBlock(attributes, colourRange);
                }
            }
        }
            break;
            
        case kSMLSyntaxGroupAutoComplete:
            break;
            
        case kSMLSyntaxGroupVariable:
            break;
            
        case kSMLSyntaxGroupFirstString:
            break;
            
        case kSMLSyntaxGroupSecondString:
            break;
            
        case kSMLSyntaxGroupAttribute:
            break;
            
        case kSMLSyntaxGroupSingleLineComment:
            break;
            
        case kSMLSyntaxGroupMultiLineComment:
            break;
            
        case kSMLSyntaxGroupSecondStringPass2:
            break;
    }
}


/*
 * - fragariaDocument:didColourWithBlock:string:range:info
 */
- (void)fragariaDocument:(MGSFragariaView *)fragaria didColourWithBlock:(BOOL (^)(NSDictionary<NSString *, id> *, NSRange))block string:(NSString *)string range:(NSRange)range info:(NSDictionary<NSString *, id> *)info
{
    NSLog(@"Did colour document.");
    
    // we can call colourWithBlock to perform final colouring
}


@end
