//
//  AVSeparation.h
//  2020Music
//
//  Created by Lan Xuping on 2020/2/7.
//  Copyright © 2020 Lan Xuping. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AVSeparation : UIView
/**
 *  获取视频的缩略图方法
 *  @param filePath 视频的本地路径
 *  @return 视频截图
 */
+ (UIImage *)getScreenShotImageFromVideoPath:(NSString *)filePath;

/**
 *  获取视频中的音频
 *  @param videoUrl 视频的本地路径
 *  @param newFile 导出音频的路径
 *  @completionHandle 音频路径的回调
 */
+ (void)VideoManagerGetBackgroundMiusicWithVideoUrl:(NSURL *)videoUrl newFile:(NSString*)newFile completion:(void(^)(NSString *data))completionHandle;

/*
 *  获取视频播放时长
 *  @param urlString 视频路径
 */
+ (NSInteger)getVideoTimeByUrlString:(NSString*)urlString;
@end
