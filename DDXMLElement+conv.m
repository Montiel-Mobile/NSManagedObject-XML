//
//  DDXMLElement+conv.m
//  CPSStabilization
//
//  Created by John Montiel on 5/21/12.
//  Copyright (c) 2012 Em Sevn, LLC. All rights reserved.
//

#import "DDXMLElement+conv.h"

@implementation DDXMLElement (conv)

- (NSString *)valueForTag:(NSString *)inTag;
{
    return [[[self elementsForName:inTag] lastObject] stringValue];
}


@end
