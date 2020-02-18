//
//  YoutubeDownloadUrl.m
//  2020Music
//
//  Created by Lan Xuping on 2020/2/12.
//  Copyright © 2020 Lan Xuping. All rights reserved.
//

#import "YoutubeDownloadUrl.h"

static NSString *patTitle = @"\"title\"\\s*:\\s*\"(.*?)\"";
static NSString *patAuthor = @"\"author\"\\s*:\\s*\"(.+?)\"";
static NSString *patChannelId = @"\"channelId\"\\s*:\\s*\"(.+?)\"";
static NSString *patLength = @"\"lengthSeconds\"\\s*:\\s*\"(\\d+?)\"";
static NSString *patViewCount = @"\"viewCount\"\\s*:\\s*\"(\\d+?)\"";
static NSString *patShortDescript = @"\"shortDescription\"\\s*:\\s*\"(.+?)\"";
static NSString *patStatusOk = @"status=ok(&|,|\\z)";

static NSString *patHlsvp = @"hlsvp=(.+?)(&|\\z)";
static NSString *patHlsItag = @"/itag/(\\d+?)/";

static NSString *patItag = @"itag=([0-9]+?)(&|\\z)";
static NSString *patEncSig = @"s=(.{10,}?)(\\\\\\\\u0026|\\z)";
static NSString *patUrl = @"\"url\"\\s*:\\s*\"(.+?)\"";
static NSString *patCipher = @"\"cipher\"\\s*:\\s*\"(.+?)\"";
static NSString *patCipherUrl = @"url=(.+?)(\\\\\\\\u0026|\\z)";
static NSString *patYtPlayer = @"<\\s*script\\s*>((.+?)jsbin\\\\/(player(_ias)?-(.+?).js)(.+?))</\\s*script\\s*>";

static NSString *patVariableFunction = @"([{; =])([a-zA-Z$][a-zA-Z0-9$]{0,2})\\.([a-zA-Z$][a-zA-Z0-9$]{0,2})\\(";
static NSString *patFunction = @"([{; =])([a-zA-Z$_][a-zA-Z0-9$]{0,2})\\(";

static NSString *patDecryptionJsFile = @"jsbin\\\\/(player(_ias)?-(.+?).js)";
static NSString *patSignatureDecFunction = @"\\b([\\w$]{2})\\s*=\\s*function\\((\\w+)\\)\\{\\s*\\2=\\s*\\2\\.split\\(\"\"\\)\\s*;";


static BOOL useHttp = false;
static NSString *decipherJsFileName = nil;

@interface VideoMeta : NSObject
@property (nonatomic, strong)NSString *title;
@property (nonatomic, strong)NSString *author;
@property (nonatomic, strong)NSString *channelId;
@property (nonatomic, strong)NSString *shortDescript;
@property (nonatomic, strong)NSString *viewCount;
@property (nonatomic, strong)NSString *length;
@property (nonatomic, assign)BOOL isLiveStream;
@end
@implementation VideoMeta
@end

@implementation YoutubeDownloadUrl
static VideoMeta *videoMeta;

- (void)getStreamUrlsWithVideoID:(NSString *)videoID {
    self.videoID = videoID;
    NSString *ytInfoUrl = useHttp ? @"http://" : @"https://";
    NSString *eurl = [[@"https://youtube.googleapis.com/v/" stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLUserAllowedCharacterSet]] stringByAppendingString:videoID];
    NSString *youtubeUrl = [NSString stringWithFormat:@"www.youtube.com/get_video_info?video_id=%@&eurl=%@",videoID,eurl];
    ytInfoUrl = [ytInfoUrl stringByAppendingString:youtubeUrl];
    NSLog(@"info url : %@",ytInfoUrl);
    
    __block NSString *streamMap = nil;
    [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:ytInfoUrl] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSString *videoQuery = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        streamMap = [videoQuery stringByRemovingPercentEncoding];
        streamMap = [streamMap stringByReplacingOccurrencesOfString:@"\\u0026" withString:@"&"];
        [self parseVideoMeta:streamMap];
        if (videoMeta.isLiveStream) {
            
        }
        BOOL sigEnc = true;
        BOOL statusFail = false;
        if (![self matchFirstLinkWithStr:streamMap withMatchStr:patCipher]) {
            sigEnc = false;
            if (![self matchFirstLinkWithStr:streamMap withMatchStr:patStatusOk]) {
                statusFail = true;
            }
        }
        if (sigEnc || statusFail) {
            [self watchVideoID:videoID sigEnc:sigEnc];
        } else {
            NSMutableDictionary *mp4URLs = [NSMutableDictionary dictionary];
            NSArray *cephers = [self _matchLinkWithStr:streamMap withMatchStr:patUrl];
            for (int i = 0; i < cephers.count; i ++) {
                NSString *url = [self matchFirstLinkWithStr:cephers[i] withMatchStr:patUrl group:1];
                NSString *itag = [self matchFirstLinkWithStr:url withMatchStr:patItag group:1];
                if (!itag) {
                    continue;
                }
                [mp4URLs setValue:url forKey:itag];
            }
            if ([self.delegate respondsToSelector:@selector(downloadUrlWithMP4UrlsDictionary:videoID:)]) {
                [self.delegate downloadUrlWithMP4UrlsDictionary:mp4URLs videoID:_videoID];
            }
        }
//        NSArray *a = [self _matchLinkWithStr:streamMap withMatchStr:@"mimeType\":\"\""];
//        NSLog(@"%@",a);
    }] resume];
}

- (void)watchVideoID:(NSString *)videoID sigEnc:(BOOL)sigEnc {
    NSURL *getUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://youtube.com/watch?v=%@",videoID]];
    [[[NSURLSession sharedSession] dataTaskWithURL:getUrl completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSString *videoQuery = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSString *streamMap = nil;
        if ([self matchLinkWithStr:videoQuery withMatchStr:patYtPlayer]) {
            streamMap = [videoQuery stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
        }
        NSString *curJsFileName = nil;
        NSMutableDictionary *encSignatures = [NSMutableDictionary dictionary];
        curJsFileName = [self matchFirstLinkWithStr:streamMap withMatchStr:patDecryptionJsFile group:1];
        curJsFileName = [curJsFileName stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
        decipherJsFileName = curJsFileName;
        NSString *sig = nil;
        NSString *url = nil;
        
        NSArray *cephers = [self _matchLinkWithStr:streamMap withMatchStr:patCipher];
        NSMutableDictionary *mp4URLs = [NSMutableDictionary dictionary];
        for (int i = 0; i < cephers.count; i ++) {
            if (sigEnc) {
                url = [[self matchFirstLinkWithStr:cephers[i] withMatchStr:patCipherUrl group:1] stringByRemovingPercentEncoding];
                url = [url stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                sig = [[self matchFirstLinkWithStr:cephers[i] withMatchStr:patEncSig group:1] stringByRemovingPercentEncoding];
            } else {
                url = [self matchFirstLinkWithStr:cephers[i] withMatchStr:patUrl group:1];
            }
            NSString *itag = [self matchFirstLinkWithStr:url withMatchStr:patItag group:1];
            if (sig) {
                [encSignatures setValue:sig forKey:itag];
                [mp4URLs setValue:url forKey:itag];
            }
        }
        
        [self decipherSignatureWithEncSignatures:encSignatures mp4URLs:mp4URLs];
    }] resume];
}

- (void)decipherSignatureWithEncSignatures:(NSDictionary *)encSignatures mp4URLs:(NSDictionary *)mp4URLs{
    NSString *decipherFunctUrl = [@"https://s.ytimg.com/yts/jsbin/" stringByAppendingString:decipherJsFileName];
    
    [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:decipherFunctUrl] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSString *javascriptFile = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSString *decipherFunctionName = [self matchFirstLinkWithStr:javascriptFile withMatchStr:patSignatureDecFunction group:1];
        NSString *patMainVariable = [NSString stringWithFormat:@"(var |\\s|,|;)%@(=function\\((.{1,3})\\)\\{)",[decipherFunctionName stringByReplacingOccurrencesOfString:@"$" withString:@"\\$"]];
        
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:patMainVariable options:NSRegularExpressionCaseInsensitive error:&error];
        NSTextCheckingResult *firstMatch = [regex firstMatchInString:javascriptFile options:0 range:NSMakeRange(0, [javascriptFile length])];
        NSString *mainDecipherFunct = nil;
        if (firstMatch) {
            mainDecipherFunct = [NSString stringWithFormat:@"var %@%@",decipherFunctionName,[javascriptFile substringWithRange:[firstMatch rangeAtIndex:2]]];
        } else {
            NSString *patMainFunction = [NSString stringWithFormat:@"function %@(\\((.{1,3})\\)\\{)",[decipherFunctionName stringByReplacingOccurrencesOfString:@"$" withString:@"\\$"]];
            NSRegularExpression *patMainFunctionRegex = [NSRegularExpression regularExpressionWithPattern:patMainFunction options:NSRegularExpressionCaseInsensitive error:&error];
            NSTextCheckingResult *firstMatch = [patMainFunctionRegex firstMatchInString:javascriptFile options:0 range:NSMakeRange(0, [javascriptFile length])];
            if (firstMatch) {
                mainDecipherFunct = [NSString stringWithFormat:@"function %@%@",decipherFunctionName,[javascriptFile substringWithRange:[firstMatch rangeAtIndex:2]]];
            }
        }
        NSRange range= [firstMatch range];
        long startIndex = range.location + range.length;
        for (long braces = 1, i = startIndex; i < javascriptFile.length; i++) {
            if (braces == 0 && startIndex + 5 < i) {
                mainDecipherFunct = [mainDecipherFunct stringByAppendingFormat:@"%@;",[javascriptFile substringWithRange:NSMakeRange(startIndex, i - startIndex)]];
                break;
            }
            char c = [javascriptFile characterAtIndex:i];
            if (c == '{') {
                braces++;
            } else if (c == '}') {
                braces--;
            }
        }
        NSString *decipherFunctions = [mainDecipherFunct stringByReplacingOccurrencesOfString:@"\"" withString:@"'"];
        
        NSRegularExpression *patVariableFunctionRegx = [NSRegularExpression regularExpressionWithPattern:patVariableFunction options:NSRegularExpressionCaseInsensitive error:&error];
        NSTextCheckingResult *match = [patVariableFunctionRegx firstMatchInString:mainDecipherFunct options:0 range:NSMakeRange(0, [mainDecipherFunct length])];
        if (match) {
            NSString *variableDef = [NSString stringWithFormat:@"var %@={",[mainDecipherFunct substringWithRange:[match rangeAtIndex:2]]];
            if (![decipherFunctions containsString:variableDef]) {
                startIndex = [javascriptFile rangeOfString:variableDef].location + variableDef.length;
                for (long braces = 1, i = startIndex; i < javascriptFile.length; i++) {
                    if (braces == 0) {
                        decipherFunctions = [decipherFunctions stringByAppendingFormat:@"%@%@;",variableDef,[javascriptFile substringWithRange:NSMakeRange(startIndex, i - startIndex)]];
                        break;
                    }
                    char c = [javascriptFile characterAtIndex:i];
                    if (c == '{')
                        braces++;
                    else if (c == '}')
                        braces--;
                }
            }
        }
        // Search for functions
        NSRegularExpression *patFunctionRegx = [NSRegularExpression regularExpressionWithPattern:patFunction options:NSRegularExpressionCaseInsensitive error:&error];
        NSTextCheckingResult *patFunctionMatch = [patFunctionRegx firstMatchInString:mainDecipherFunct options:0 range:NSMakeRange(0, [mainDecipherFunct length])];
        if (patFunctionMatch) {
            NSString *functionDef = [NSString stringWithFormat:@"function %@(",[mainDecipherFunct substringWithRange:[patFunctionMatch rangeAtIndex:2]]];
            if (![decipherFunctions containsString:functionDef]) {
                startIndex = [javascriptFile rangeOfString:functionDef].location + functionDef.length;
                for (long braces = 0, i = startIndex; i < javascriptFile.length; i++) {
                    if (braces == 0 && startIndex + 5 < i) {
                        decipherFunctions = [decipherFunctions stringByAppendingFormat:@"%@%@;",functionDef,[javascriptFile substringWithRange:NSMakeRange(startIndex, i - startIndex)]];
                        break;
                    }
                    char c = [javascriptFile characterAtIndex:i];
                    if (c == '{')
                        braces++;
                    else if (c == '}')
                        braces--;
                }
            }
        }
        [self decipherViaWebViewDecipherFunctions:decipherFunctions decipherFunctionName:decipherFunctionName encSignatures:encSignatures mp4URLs:mp4URLs];
    }] resume];
}

- (void)decipherViaWebViewDecipherFunctions:(NSString *)decipherFunctions decipherFunctionName:(NSString *)decipherFunctionName encSignatures:(NSDictionary *)encSignatures mp4URLs:(NSDictionary *)mp4URLs{
    NSString *stb = [decipherFunctions stringByAppendingString:@" function decipher(){return "];
    NSArray *keys = [encSignatures allKeys];
    for (int i = 0; i < keys.count; i ++) {//')+"\n"+
        if (i < keys.count -1) {
            stb = [stb stringByAppendingString:[NSString stringWithFormat:@"%@('%@')+\"\\n\"+",decipherFunctionName,[encSignatures objectForKey:keys[i]]]];
        } else {
            stb = [stb stringByAppendingString:[NSString stringWithFormat:@"%@('%@')",decipherFunctionName,[encSignatures objectForKey:keys[i]]]];
        }
    }
    stb = [stb stringByAppendingString:@"};decipher();"];
    JSContext *context = [[JSContext alloc] init];
    [context evaluateScript:stb];
    JSValue *adjs = context[@"decipher"];
    JSValue *resValue = [adjs callWithArguments:nil];
    NSString *result = [resValue toString];
    NSMutableDictionary *decipheredSignature = [NSMutableDictionary dictionary];
    NSArray *arr = [result componentsSeparatedByString:@"\n"];
    for (int i = 0; i < keys.count; i ++) {
        NSString *url = [[mp4URLs objectForKey:keys[i]] stringByAppendingString:[NSString stringWithFormat:@"&sig=%@",arr[i]]];
        [decipheredSignature setValue:url forKey:keys[i]];
    }
    if ([self.delegate respondsToSelector:@selector(downloadUrlWithMP4UrlsDictionary:videoID:)]) {
        [self.delegate downloadUrlWithMP4UrlsDictionary:decipheredSignature videoID:_videoID];
    }
}

- (void)parseVideoMeta:(NSString *)getVideoInfo {
    BOOL isLiveStream = false;
    NSString *title = nil;
    NSString *author = nil;
    NSString *channelId = nil;
    NSString *shortDescript = nil;
    NSString *viewCount = 0;
    NSString *length = 0;
    title = [self matchFirstLinkWithStr:getVideoInfo withMatchStr:patTitle];
    if ([self matchFirstLinkWithStr:getVideoInfo withMatchStr:patHlsvp]) {
            isLiveStream = true;
    }
    author = [self matchFirstLinkWithStr:getVideoInfo withMatchStr:patAuthor];
    channelId = [self matchFirstLinkWithStr:getVideoInfo withMatchStr:patChannelId];
    shortDescript = [self matchFirstLinkWithStr:getVideoInfo withMatchStr:patShortDescript];
    length = [self matchFirstLinkWithStr:getVideoInfo withMatchStr:patLength];
    viewCount = [self matchFirstLinkWithStr:getVideoInfo withMatchStr:patViewCount];
    
    videoMeta = [VideoMeta new];
    videoMeta.title = title;
    videoMeta.author = author;
    videoMeta.channelId = channelId;
    videoMeta.shortDescript = shortDescript;
    videoMeta.viewCount = viewCount;
    videoMeta.length = length;
    videoMeta.isLiveStream = isLiveStream;
}

- (void)setDefaultHttpProtocol:(BOOL)protocol {
    useHttp = protocol;
}

- (NSString *)matchFirstLinkWithStr:(NSString *)str withMatchStr:(NSString *)matchRegex group:(NSInteger)group {
    if (!matchRegex || !str) {
        return nil;
    }
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:matchRegex options:NSRegularExpressionCaseInsensitive error:&error];
    NSTextCheckingResult *firstMatch = [regex firstMatchInString:str options:0 range:NSMakeRange(0, [str length])];
    if (firstMatch) {
        NSRange resultRange = [firstMatch rangeAtIndex:group];
        //从urlString中截取数据
        NSString *result = [str substringWithRange:resultRange];
        return result;
    }
    return nil;
}

- (NSString *)matchFirstLinkWithStr:(NSString *)str withMatchStr:(NSString *)matchRegex {
    return [self matchFirstLinkWithStr:str withMatchStr:matchRegex group:0];
}

- (BOOL)matchLinkWithStr:(NSString *)str withMatchStr:(NSString *)matchRegex {
    if (!matchRegex || !str) {
           return nil;
       }
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:matchRegex options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray *arr = [regex matchesInString:str options:0 range:NSMakeRange(0, [str length])];
    return arr.copy ? YES : NO;
}

- (NSMutableArray *)_matchLinkWithStr:(NSString *)str withMatchStr:(NSString *)matchRegex {
    if (!matchRegex || !str) {
        return nil;
    }
    NSError *error = NULL;
    NSRegularExpression *reg = [NSRegularExpression regularExpressionWithPattern:matchRegex options:NSRegularExpressionCaseInsensitive error:&error];
    if (!reg) {
        return nil;
    }
    NSArray *match = [reg matchesInString:str options:NSMatchingReportCompletion range:NSMakeRange(0, [str length])];
    NSMutableArray *rangeArr = [NSMutableArray array];
    // 取得所有的NSRange对象
    if(match.count != 0) {
        for (NSTextCheckingResult *matc in match) {
            NSRange range = [matc range];
            NSValue *value = [NSValue valueWithRange:range];
            [rangeArr addObject:value];
        }
    }
    // 将要匹配的值取出来,存入数组当中
    __block NSMutableArray *mulArr = [NSMutableArray array];
    [rangeArr enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSValue *value = (NSValue *)obj;
        NSRange range = [value rangeValue];
        [mulArr addObject:[str substringWithRange:range]];
    }];
    return mulArr;
}

@end
