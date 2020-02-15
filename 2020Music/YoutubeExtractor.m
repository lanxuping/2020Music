
//
//  YoutubeExtractor.m
//  2020Music
//
//  Created by Lan Xuping on 2020/2/10.
//  Copyright © 2020 Lan Xuping. All rights reserved.
//

#import "YoutubeExtractor.h"
#import <YYModel/YYModel.h>

@implementation YoutubeExtractor

- (NSString *)getParamByKey:(NSString *)key URLString:(NSString *)url {
    NSError *error;
    NSString *regTags = [[NSString alloc] initWithFormat:@"(^|&|\\?)+%@=+([^&]*)(&|$)", key];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regTags options:NSRegularExpressionCaseInsensitive error:&error];
    // 执行匹配的过程
    NSArray *matches = [regex matchesInString:url options:0 range:NSMakeRange(0, [url length])];
    for (NSTextCheckingResult *match in matches) {
        NSString *tagValue = [url substringWithRange:[match rangeAtIndex:2]];
        return tagValue;
    }
    return @"";
}

+ (YoutubeExtractor *)sharedInstance {
    static YoutubeExtractor *_shareInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shareInstance = [YoutubeExtractor new];
    });
    return _shareInstance;
}

- (void)extractVideoForIdentifier:(NSString*)videoIdentifier completion:(void (^)(YoutubeStreamingDataModel *model, NSError *error))completion {
    NSURLSession *session = [NSURLSession sharedSession];
    NSString *s = [self getYoutubeWithVideoId:videoIdentifier];
    [[session dataTaskWithURL:[NSURL URLWithString:s] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSString *videoQuery = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        NSString *videoQueryDecode = [videoQuery stringByRemovingPercentEncoding];
        NSString *res = [self getParamByKey:@"player_response" URLString:videoQueryDecode];
        NSDictionary *dic = [self dictionaryWithJsonString:res];
        NSDictionary *resDic = [dic valueForKey:@"streamingData"];
        YoutubeStreamingDataModel *model = [YoutubeStreamingDataModel yy_modelWithDictionary:resDic];
        completion(model, error);
    }] resume];
}

- (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString {
    if (jsonString == nil) {
        return nil;
    }
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
    if(err) {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
}

- (NSString *)getYoutubeWithVideoId:(NSString *)videoId {
    NSString *eurl = [[@"https://youtube.googleapis.com/v/" stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLUserAllowedCharacterSet]] stringByAppendingString:videoId];
    NSString *youtubeUrl = [NSString stringWithFormat:@"https://www.youtube.com/get_video_info?video_id=%@&eurl=%@",videoId,eurl];
    return youtubeUrl;
}
@end
