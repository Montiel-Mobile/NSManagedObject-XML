//
//  Created by John Montiel on 5/16/12.
//  Copyright (c) 2012 Em Sevn, LLC. All rights reserved.

#import <Foundation/Foundation.h>

@interface DateFormatter : NSObject 

+ (DateFormatter *)sharedHelper;
- (NSDateFormatter *)dateFormatter;

@end
