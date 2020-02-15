//
//  YoutubeStreamingDataModel.h
//  2020Music
//
//  Created by Lan Xuping on 2020/2/10.
//  Copyright © 2020 Lan Xuping. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YoutubeStreamingVideoInfoModel : NSObject
@property (nonatomic, strong) NSString *mimeType;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, assign) NSInteger itag;
@property (nonatomic, strong) NSString *qualityLabel;
@property (nonatomic, strong) NSString *cipher;
@end

@interface YoutubeStreamingDataModel : NSObject
@property (nonatomic, assign) NSInteger expiresInSeconds;
@property (nonatomic, strong) NSArray <YoutubeStreamingVideoInfoModel *> *formats;
@property (nonatomic, strong) NSArray <YoutubeStreamingVideoInfoModel *> *adaptiveFormats;
@end
