//
//  MGSUserDefaultsUtilities.h
//  Fragaria
//
//  Created by Jim Derry on 3/4/15.
//
//

#import <Cocoa/Cocoa.h>


NSColor *MGSTestRandomColor(void);


/**
 *  This class implements some utilities required by MGSUserDefaults tests.
 **/
@interface MGSUserDefaultsUtilities : NSObject

/**
 *  Returns a dictionary of all visible properties of an object, including
 *  those from all its superclasses. Courtesy of Duncan Babbage.
 *  @param object The object for which you want to retrieve property
 *  information.
 **/
+ (NSDictionary *)propertiesOfObject:(id)object;


/**
 *  Returns a dictionary of all visible properties of a class, including
 *  those from all its superclasses. Courtesy of Duncan Babbage.
 *  @param class The class for which you want to retrieve property information.
 **/
+ (NSDictionary *)propertiesOfClass:(Class)class;


/**
 *  Returns a dictionary of all visible properties that are specific to
 *  a subclass. Properties for its superclasses are not included.
 *  Courtesy of Duncan Babbage.
 *  @param class The class for which you want to retrieve property information.
 **/
+ (NSDictionary *)propertiesOfSubclass:(Class)class;

@end
