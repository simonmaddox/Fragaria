//
//  MGSColorSchemeOption.m
//  Fragaria
//
//  Created by Daniele Cattaneo on 20/10/17.
//

#import "MGSColourSchemeOption.h"


@implementation MGSColourSchemeOption


- (instancetype)initWithDictionary:(NSDictionary *)d
{
    self = [super initWithDictionary:d];
    _loadedFromBundle = NO;
    return self;
}


@end
