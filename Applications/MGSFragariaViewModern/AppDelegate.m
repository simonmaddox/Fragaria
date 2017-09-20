//
//  AppDelegate.h
//  MGSFragariaView Demo
//
//  Created by Jim Derry on 2015/03/15.
//
//  A playground and demonstration for MGSFragariaView and the new-style
//  preferences panels.
//
//

#import "AppDelegate.h"
#import <Fragaria/Fragaria.h>
#import "MGSSampleBreakpointDelegate.h"
#import "MASPreferencesWindowController.h"


#pragma mark - PRIVATE INTERFACE


@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;

@property (weak) IBOutlet MGSFragariaView *viewTop;

@property (weak) IBOutlet MGSFragariaView *viewBottom;

@property (nonatomic, strong) NSWindowController *preferencesWindowController;
@property (nonatomic, strong) NSWindowController *preferencesHybridTopWindowController;
@property (nonatomic, strong) NSWindowController *viewTopSettingsWindowController;
@property (nonatomic, strong) NSWindowController *viewBottomSettingsWindowController;

@property (strong) NSArray *breakpoints;

@end


#pragma mark - IMPLEMENTATION


@implementation AppDelegate {
	MGSSampleBreakpointDelegate *breakpointDelegate;
}

@synthesize preferencesWindowController = _preferencesWindowController;


#pragma mark - Initialization and Setup


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	applicationDidFinishLaunching:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	#pragma unused(aNotification)

    /* Get a sample file to pre-populate the views. */
    NSString *file = [[NSBundle mainBundle] pathForResource:@"README" ofType:@"html"];
    NSString *fileContent;
    NSError *error;
    if (file)
    {
        fileContent = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:&error];
    }
    if (!file || error)
    {
        fileContent = @"<p>There was a nice file to load for you, but some reason I couldn't open it.</p>";
    }

    /* Setup our Preferences and Groups in a separate method: */
    [self makePreferencesAndGroups];

    /* Sample Syntax Error Definitions */
    self.viewTop.syntaxErrors = [self makeSyntaxErrors];

    /* Make the upper view interesting. */
    self.viewTop.textView.string = fileContent;
    self.viewTop.syntaxDefinitionName = @"HTML";

    /* Make the lower view interesting. */
    [self.viewBottom replaceTextStorage:self.viewTop.textView.textStorage];
    self.viewBottom.syntaxDefinitionName = @"HTML";
	
	/* Use an external breakpoint delegate for the bottom view. */
	breakpointDelegate = [[MGSSampleBreakpointDelegate alloc] init];
	self.viewTop.breakpointDelegate = breakpointDelegate;
    
    /* If you want to use the same breakpoint delegate for both views,
     * you'll have to keep them in sync yourself! */
}


#pragma mark - Property Accessors

/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	@availableSyntaxDefinitions
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSArray *)availableSyntaxDefinitions
{
	return [[MGSSyntaxController sharedInstance] syntaxDefinitionNames];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	@preferencesWindowController
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSWindowController *)preferencesWindowController
{
    /* We only have a few global properties defined in the global group, and
       so most things will be disabled when the controller's window is shown. */

    if (!_preferencesWindowController)
    {
        _preferencesWindowController = [self createWindowControllerForGroup:nil title:@"Preferences"];
    }

    return _preferencesWindowController;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	@preferencesHybridTopWindowController
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSWindowController *)preferencesHybridTopWindowController
{
    /* We're configuring the windowController with hybridUserDefaultsController,
       so we can't use our convenience method createWindowControllerForGroup. */

    if (!_preferencesHybridTopWindowController)
    {
        MGSPrefsEditorPropertiesViewController *editorSettingsController = [[MGSPrefsEditorPropertiesViewController alloc] init];
        MGSPrefsColourPropertiesViewController *colorSettingsController = [[MGSPrefsColourPropertiesViewController alloc] init];

        editorSettingsController.userDefaultsController = [MGSHybridUserDefaultsController sharedControllerForGroupID:@"topWindowGroup"];
        colorSettingsController.userDefaultsController = [MGSHybridUserDefaultsController sharedControllerForGroupID:@"topWindowGroup"];

		/* We will hide panels that have nothing enabled, and allow global
		   properties to be stylized in the Preferences. */
        editorSettingsController.hidesUselessPanels = YES;
		editorSettingsController.stylizeGlobalProperties = YES;
		
        colorSettingsController.hidesUselessPanels = YES;
		colorSettingsController.stylizeGlobalProperties = YES;

        NSArray *controllers = @[editorSettingsController, colorSettingsController];

        NSString *title = NSLocalizedString(@"Hybrid Global/TopView Settings", @"Title for the hybrid preferences.");
        
        _preferencesHybridTopWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:controllers title:title];
    }

    return _preferencesHybridTopWindowController;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	@viewTopSettingsWindowController
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSWindowController *)viewTopSettingsWindowController
{
    /* Global properties will be disabled when this controller's window is
       shown. Changes to this group are persistent, and so changes made in
       this window are persistent. */

    if (!_viewTopSettingsWindowController)
    {
        _viewTopSettingsWindowController = [self createWindowControllerForGroup:@"topWindowGroup" title:@"Top Panel View Settings"];
    }

    return _viewTopSettingsWindowController;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	@viewBottomSettingsWindowController
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSWindowController *)viewBottomSettingsWindowController
{
    /* Global properties will be disabled when this controller's window is
     shown. Changes to this group are not persistent, and so changes made in
     this window will reset to user defaults next time you run the app. */

    if (!_viewBottomSettingsWindowController)
    {
        _viewBottomSettingsWindowController = [self createWindowControllerForGroup:@"bottomWindowGroup" title:@"Bottom Panel View Settings"];
    }

    return _viewBottomSettingsWindowController;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	createWindowControllerForGroup:title:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSWindowController *)createWindowControllerForGroup:(NSString *)group title:(NSString *)title
{
    /* `MGSPrefsEditorPropertiesViewController` and
       `MGSPrefsColourPropertiesViewController` already support the methods
       required by MASPreferences */

    MGSPrefsEditorPropertiesViewController *editorSettingsController = [[MGSPrefsEditorPropertiesViewController alloc] init];
    MGSPrefsColourPropertiesViewController *colorSettingsController = [[MGSPrefsColourPropertiesViewController alloc] init];

    /* We have to tell the controllers who the associated defaults controllers
       is so that they will know which properties they are allowed to control,
       and so that the defaults controllers can propagate the properties to
       every other instance in the group.
     
       In this example we're simply setting it for each view controller
       individually. In the real world I'd probably add a property to
       the window controller and set it only once, there. */

    editorSettingsController.userDefaultsController = [MGSUserDefaultsController sharedControllerForGroupID:group];
    colorSettingsController.userDefaultsController = [MGSUserDefaultsController sharedControllerForGroupID:group];
	
	/* We'll tell the panels to hide property groups that have no enabled items.
	   Items are only enabled if the propertiesController is managing them. */
	editorSettingsController.hidesUselessPanels = YES;
	colorSettingsController.hidesUselessPanels = YES;

    NSArray *controllers = @[editorSettingsController, colorSettingsController];

    title = NSLocalizedString(title, @"Common title for Preferences window");

    return [[MASPreferencesWindowController alloc] initWithViewControllers:controllers title:title];
}


#pragma mark - Delegate methods

/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	textDidChange:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)textDidChange:(NSNotification *)notification
{
	#pragma unused(notification)
	NSLog(@"%@", @"textDidChange: notification.");
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	concludeDragOperation:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	#pragma unused(sender)
	NSLog(@"%@", @"concludeDragOperation: delegate method.");
}


#pragma mark - UI Handling

/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	openPreferences:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (IBAction)openPreferences:(id)sender
{
    [self.preferencesWindowController showWindow:nil];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	openHybridTopPreferences:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (IBAction)openHybridTopPreferences:(id)sender
{
    [self.preferencesHybridTopWindowController showWindow:nil];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	openTopSettings:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (IBAction)openTopSettings:(id)sender
{
    [self.viewTopSettingsWindowController showWindow:nil];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	openBottomSettings:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (IBAction)openBottomSettings:(id)sender
{
    [self.viewBottomSettingsWindowController showWindow:nil];
}


#pragma mark - Demonstration Setup

/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	makePreferencesAndGroups
        Demonstrate the new settings groups and how they interact
        with user defaults.
    see: MGSFragariaView+Definitions.h
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)makePreferencesAndGroups
{
    /* Legacy Fragaris was controlled via NSUserDefaults, meaning that every
       instance of Fragaria in your application was forced to have the same
       appearance, whether you wanted it to or not. */

    /* The new, preferences system lets you manage all of your user defaults
       yourself, and you can write your own Preferences panels. too. Or you
       could use the optional MGSUSerDefaults controller, which is what is
       demonstrated here. */

    /* It's simple: you tell a "group" which properties to observe, and it
       will ensure that all members of the group (MGSFragariaView instances)
       maintain those property values in common. If you tell the group to be
       persistent, then those properties will be kept in user defaults, too. */

    /* Of course a group can contain only a single MGSFragariaView instance
       if you're only looking for a simple user defaults caching mechanism. */

    /* Even if the group is only managing a few of Fragaria's many properties,
       it will always start with *all* values from user defaults, including
       the "default defaults" registed via NSUserDefaults registerDefaults. */

    /* There's also a global "supergroup" that effects all managed instances
       of MGSFragariaView in your entire application. */


    /* Any time a group is first accessed via its sharedControllerForGroupID,
       [NSUserDefaults standardUserDefaults] registerDefaults:] will be
       perfomed automatically. It's *not* required to do this in
       applicationDidFinishLaunching, but it's good to access these as early
       as possible in your application lifecycle. */

    /* Each view will be in its own group to remain largely independent.
       However we will use the global group to ensure that some properties
       are forced to the same. We're not assigning to the groups yet, only
       referencing them for later (and causing their defaults to load). */
    MGSUserDefaultsController *topGroup = [MGSUserDefaultsController sharedControllerForGroupID:@"topWindowGroup"];
    MGSUserDefaultsController *bottomGroup = [MGSUserDefaultsController sharedControllerForGroupID:@"bottomWindowGroup"];
    MGSUserDefaultsController *globalGroup = [MGSUserDefaultsController sharedController];

    /* This cheat simply provides us a list of all MGSFragaria properties. */
    NSMutableArray *groupProperties = [NSMutableArray arrayWithArray:[[MGSFragariaView defaultsDictionary] allKeys]];

    /* For fun, let's say that the global controller should manage these
       properties, and take away the power to do so from the groups. */
	NSArray *colourProperties = [[MGSFragariaView propertyGroupTheme] allObjects];
	NSMutableArray *globalProperties = [NSMutableArray arrayWithArray:colourProperties];
	[globalProperties addObjectsFromArray:@[
											MGSFragariaDefaultsTextFont,
                                            MGSFragariaDefaultsGutterFont,
											MGSFragariaDefaultsShowsGutter
											]];

    /* And the groups' properties will simply be the remaining properties. */
    [groupProperties removeObjectsInArray:globalProperties];

    //globalGroup.managedProperties = [NSSet setWithArray:globalProperties];
    globalGroup.persistent = YES;

    /* Tell the groups which instances and properties to manage. */

    [topGroup addFragariaToManagedSet:self.viewTop];
    topGroup.managedProperties = [NSSet setWithArray:groupProperties];
    topGroup.persistent = YES;

    [bottomGroup addFragariaToManagedSet:self.viewBottom];
    bottomGroup.managedProperties = [NSSet setWithArray:groupProperties];

}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	makeSyntaxErrors
        Demonstrate several different means of creating and adding
        syntax errors to Fragaria. Obviously these syntax errors are
        static, and they only make real sense when used with the
        default document that loads at startup. Your implementation
        will be rather less static.
    see SMLSyntaxError.h for property descriptions.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSArray *)makeSyntaxErrors
{
    /* Errors can be instantiated via a class method from a dictionary: */
    SMLSyntaxError *error1 = [SMLSyntaxError errorWithDictionary:
        @{ @"errorDescription" : @"This is a sample error, and it has the highest warning level.",
           @"line" : @(4),
           @"character" : @(2),
           @"length" : @(4),
           @"hidden" : @(NO),
           @"warningLevel" : @(kMGSErrorCategoryError) }];

    /* They can also be created manually and initialized from a dictionary: */
    SMLSyntaxError *error2 = [[SMLSyntaxError alloc] initWithDictionary:
        @{ @"errorDescription" : @"This is a lower level error on the same line.",
           @"line" : @(4),
           @"character" : @(13),
           @"length" : @(8),
           @"hidden" : @(NO),
           @"warningLevel" : @(kMGSErrorCategoryAccess) }];

    /* You can create syntax errors and address their properties directly: */
    SMLSyntaxError *error3 = [[SMLSyntaxError alloc] init];
    error3.errorDescription = @"This error is hidden and will not appear.";
    error3.line = 7;
    error3.character = 2;
    error3.length = 4;
    error3.hidden = YES;
    error3.warningLevel = kMGSErrorCategoryConfig;

    SMLSyntaxError *error4 = [SMLSyntaxError new];
    error4.errorDescription = @"The red squigglies represent errors, not misspellings.";
    error4.line = 11;
    error4.character = 11;
    error4.length = 21;
    error4.hidden = NO;
    
    /* You can set a contextual menu on a syntax error. */
    NSMenu *cmenu = [[NSMenu alloc] init];
    [[cmenu addItemWithTitle:@"Make a Sound" action:@selector(beep:)
               keyEquivalent:@""] setTarget:self];
    error4.contextualMenu = cmenu;

    return @[error1, error2, error3, error4];
}


- (void)beep:(id)sender
{
    NSBeep();
}


@end
