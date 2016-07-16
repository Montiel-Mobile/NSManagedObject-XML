//
//  EncryptionHelper.h
//
//  Created by John Montiel on 3/22/12.
//  Copyright (c) 2012 Em Sevn, LLC. All rights reserved.
//

@import Foundation;

@interface EncryptionHelper : NSObject

+ (EncryptionHelper*)sharedHelper;
- (NSData *)encryptString:(NSString *)plainText;
- (NSString *)decryptData:(NSData *)encryptedData;

@end
