//
//  YoutubeExtractor.h
//  2020Music
//
//  Created by Lan Xuping on 2020/2/10.
//  Copyright © 2020 Lan Xuping. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YoutubeStreamingDataModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface YoutubeExtractor : NSObject
+ (YoutubeExtractor *)sharedInstance;
- (void)extractVideoForIdentifier:(NSString *)videoIdentifier completion:(void (^)(YoutubeStreamingDataModel *model, NSError *error))completion;
@end

NS_ASSUME_NONNULL_END
