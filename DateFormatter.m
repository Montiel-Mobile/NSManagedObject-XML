//
//

#import "DateFormatter.h"


static DateFormatter *sharedInstance = nil;

@interface DateFormatter () 
{
    NSDateFormatter *globalDateFormatter;
}
@end

@implementation DateFormatter



#pragma mark -
#pragma mark Singleton Methods

- (void)dealloc
{
    [globalDateFormatter release];
	[super dealloc];
}
- (id)init
{
	self = [super init];
	if (self != nil) 
    {
        globalDateFormatter = [[NSDateFormatter alloc] init];
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
        return [sharedInstance retain];
    }
    else 
    {
        // When not already set, +initialize is our caller.
        // It's creating the shared instance, let this go through.
        return [super allocWithZone:zone];
    }
}

- (id)retain
{
	// Singletons don't get retained
	return self;
}

- (oneway void)release
{
	// Singletons don't get released
}

#pragma mark Custom methods

- (NSDateFormatter *)dateFormatter;
{
    globalDateFormatter.dateStyle = NSDateFormatterMediumStyle;
    globalDateFormatter.timeStyle = NSDateFormatterNoStyle;
    return globalDateFormatter;
}

@end
