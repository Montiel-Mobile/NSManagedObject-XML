//
//  EncryptionHelper.m
//
//  Created by John Montiel on 3/22/12.
//  Copyright (c) 2012 Em Sevn, LLC. All rights reserved.
//

#import "EncryptionHelper.h"
#import "SecKeyWrapper.h"

@interface EncryptionHelper ()
{
    NSData * symmetricKey;
}
@end

@implementation EncryptionHelper
static EncryptionHelper *sharedInstance = nil;

- (id)init
{
	self = [super init];
	if (self != nil) 
    {
#if TARGET_IPHONE_SIMULATOR
        symmetricKey = [[NSData alloc] init];
#else
        SecKeyWrapper *crypto = [SecKeyWrapper sharedWrapper];
        symmetricKey = [[crypto getSymmetricKeyBytes] retain];
        if (!symmetricKey)
        {
            [crypto generateSymmetricKey];
            symmetricKey = [[crypto getSymmetricKeyBytes] retain];
        }
#endif
	}
	return self;
}

- (void)dealloc
{
    [symmetricKey release];
	[super dealloc];
}

+ (void)initialize
{
    if (sharedInstance == nil)
        sharedInstance = [[self alloc] init];
}

+ (id)sharedHelper
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

#pragma mark Encryption methods
- (NSData *)encryptString:(NSString *)plainText;
{
    if (plainText.length > 0)
    {
#if TARGET_IPHONE_SIMULATOR
        return [plainText dataUsingEncoding:NSASCIIStringEncoding];
#else    
        CCOptions pad = kCCOptionPKCS7Padding;
        
        NSString *encrString = plainText;
        
        // Wrapper is crashing when plantext's length is a multiple of 16 bytes, add a space
        NSInteger leftover = plainText.length % 16;
        if (leftover == 0)
            encrString = [plainText stringByAppendingString:@" "];
        
        NSData *plainTextData = [encrString dataUsingEncoding:NSASCIIStringEncoding];
        
        NSData *encryptedData = [[SecKeyWrapper sharedWrapper] doCipher:plainTextData  
                                                                    key:symmetricKey  
                                                                context:kCCEncrypt  
                                                                padding:&pad];  
        
        return encryptedData;  
#endif
    }
    else 
        return nil;
}

- (NSString *)decryptData:(NSData *)encryptedData;
{
    if (encryptedData.length > 0)
    {
#if TARGET_IPHONE_SIMULATOR
        NSString *plainText = [[NSString alloc] initWithData:encryptedData encoding:NSASCIIStringEncoding]; 
        
        return [plainText autorelease];  
#else
        CCOptions pad = kCCOptionPKCS7Padding;
        
        NSData *plainTextData = [[SecKeyWrapper sharedWrapper] doCipher:encryptedData  
                                                                    key:symmetricKey  
                                                                context:kCCDecrypt  
                                                                padding:&pad];  
        
        NSString *plainText = [[NSString alloc] initWithData:plainTextData encoding:NSASCIIStringEncoding]; 
        
        return [plainText autorelease];  
#endif
    }
    else 
        return nil;
}


@end