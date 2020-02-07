//
//  NSString+Md5.m
//  2020Music
//
//  Created by Lan Xuping on 2020/2/7.
//  Copyright © 2020 Lan Xuping. All rights reserved.
//

#import "NSString+Md5.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (Md5)

- (NSString *)md5 {
    return [[self MD5] lowercaseString];
}

- (NSString *)MD5 {
    const char *str = self.UTF8String;
    if (str == NULL) {
        str = "";
    }
    
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), result);
    return [[NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
             result[0], result[1], result[2], result[3],result[4], result[5], result[6], result[7],
             result[8],result[9], result[10], result[11],result[12], result[13], result[14], result[15]] uppercaseString];
}

@end
