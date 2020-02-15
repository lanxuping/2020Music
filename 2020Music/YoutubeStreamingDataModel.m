//
//  YoutubeStreamingDataModel.m
//  2020Music
//
//  Created by Lan Xuping on 2020/2/10.
//  Copyright © 2020 Lan Xuping. All rights reserved.
//

#import "YoutubeStreamingDataModel.h"
#import <YYModel/YYModel.h>

@implementation YoutubeStreamingVideoInfoModel


@end

@implementation YoutubeStreamingDataModel

+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{@"formats":[YoutubeStreamingVideoInfoModel class], @"adaptiveFormats":[YoutubeStreamingVideoInfoModel class]};
}

@end
