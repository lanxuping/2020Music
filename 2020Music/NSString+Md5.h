//
//  NSString+Md5.h
//  2020Music
//
//  Created by Lan Xuping on 2020/2/7.
//  Copyright © 2020 Lan Xuping. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Md5)
- (NSString *)md5;  /**< md5 加密 （小写） */
- (NSString *)MD5;  /**< md5 加密 （大写） */
@end
