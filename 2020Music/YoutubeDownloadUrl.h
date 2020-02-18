//
//  YoutubeDownloadUrl.h
//  2020Music
//
//  Created by Lan Xuping on 2020/2/12.
//  Copyright © 2020 Lan Xuping. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <JavaScriptCore/JavaScriptCore.h>


@protocol YoutubeDownloadUrlDelegate <NSObject>

- (void)downloadUrlWithMP4UrlsDictionary:(NSDictionary *)mp4Urls videoID:(NSString *)videoID;

@end

@interface YoutubeDownloadUrl : NSObject <UIWebViewDelegate>
- (void)getStreamUrlsWithVideoID:(NSString *)videoID;

@property (nonatomic, weak) id <YoutubeDownloadUrlDelegate> delegate;
@property (nonatomic, strong) NSString *videoID;
@end
