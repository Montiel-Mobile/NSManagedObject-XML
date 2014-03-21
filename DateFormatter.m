//
//  Created by John Montiel on 5/16/12.
//  Copyright (c) 2012 Em Sevn, LLC. All rights reserved.

#import "DateFormatter.h"


static DateFormatter *sharedInstance = nil;

@interface DateFormatter () 
{

}
@property (readwrite, nonatomic) NSDateFormatter *dateFormatter;
@end

@implementation DateFormatter
@synthesize dateFormatter;



#pragma mark -
#pragma mark Singleton Methods

- (id)init
{
	self = [super init];
	if (self != nil) 
    {
        dateFormatter = [[NSDateFormatter alloc] init];
	}
	return self;
}

+ (void)initialize
{
    if (sharedInstance == nil)
        sharedInstance = [[self alloc] init];
}

+ (DateFormatter *)sharedHelper;
{
    // Already set by +initialize.
    return sharedInstance;
}

+ (id)allocWithZone:(NSZone*)zone
{
    // Usually already set by +initialize.
    if (sharedInstance) 
    {
        // The caller expects to receive a new object, so implicitly retain it
        // to balance out the eventual release message.
        return sharedInstance;
    }
    else 
    {
        // When not already set, +initialize is our caller.
        // It's creating the shared instance, let this go through.
        return [super allocWithZone:zone];
    }
}

#pragma mark Custom methods

- (NSDateFormatter *)dateFormatter;
{
    dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    dateFormatter.timeStyle = NSDateFormatterNoStyle;
    return dateFormatter;
}

@end
