//
//  ViewController.m
//  2020Music
//
//  Created by Lan Xuping on 2020/2/7.
//  Copyright © 2020 Lan Xuping. All rights reserved.
//

#import "ViewController.h"
#import <AFNetworking/AFNetworking.h>
#import "NSString+Md5.h"
#import "AVSeparation.h"
#import <WebKit/WebKit.h>
#import <FSAudioStream.h>
#import <AVKit/AVKit.h>
#import "YoutubeExtractor.h"
#import "PSYouTubeExtractor.h"
#import <youtube_ios_player_helper/youtube-ios-player-helper-umbrella.h>
#import "YoutubeDownloadUrl.h"


static NSString *patYtPlayer = @"<\\s*script\\s*>((.+?)jsbin\\\\/(player(_ias)?-(.+?).js)(.+?))</\\s*script\\s*>";
static NSString *patDecryptionJsFile = @"jsbin\\\\/(player(_ias)?-(.+?).js)";
static NSString *patCipher = @"\"cipher\"\\s*:\\s*\"(.+?)\"";


@interface ViewController () <WKNavigationDelegate, YTPlayerViewDelegate, YoutubeDownloadUrlDelegate>
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) FSAudioStream *audioStream;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) NSString *downloadM4A;
@property (weak, nonatomic) IBOutlet UILabel *playerStateLable;
@property (nonatomic, strong) NSString *musicName;
@property (nonatomic ,strong) YoutubeDownloadUrl *down;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //arxdY8in7fY
    //nbqMIBYJlvk
    self.down = [[YoutubeDownloadUrl alloc] init];
    [self.down  getStreamUrlsWithVideoID:@"LHCob76kigA"];
    self.down.delegate = self;
}

- (void)youtubePlayerHelperView {
    YTPlayerView *v = [[YTPlayerView alloc] initWithFrame:CGRectMake(20, 60, 300, 150)];
    NSDictionary *playerVars = @{
        @"playsinline" : @1,
        @"origin": @"https://www.youtube.com"
    };
    [v loadWithVideoId:@"nbqMIBYJlvk" playerVars:playerVars];
    [self.view addSubview:v];
}
- (void)signTest {
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithURL:[NSURL URLWithString:@"https://youtube.com/watch?v=nbqMIBYJlvk"] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSString *videoQuery = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        NSString *streamMap = nil;
        streamMap = [self matchFirstLinkWithStr:videoQuery withMatchStr:patYtPlayer];
        streamMap = [streamMap stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
        NSString *currentJsFileName = nil;
        currentJsFileName = [self matchFirstLinkWithStr:streamMap withMatchStr:patDecryptionJsFile];
        currentJsFileName = [currentJsFileName stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
        NSLog(@"1");
    }] resume];
}
- (void)downloadUrlWithMP4UrlsDictionary:(NSDictionary *)mp4Urls videoID:(NSString *)videoID{
    if (!mp4Urls) {
        return;
    }
    NSLog(@"download videoID : %@",videoID);
    NSString *mp4 = mp4Urls[@"140"];
    [self downloadWithVideoUrl:mp4];
}

- (IBAction)loadwebview:(id)sender {
    NSString *v1 = @"https://www.youtube.com/embed/vSBcrmx4aFw";//4min
//    NSString *v2 = @"https://www.youtube.com/embed/arxdY8in7fY";//8min
    [self loadYoutubeWebviewWirhUrl:v1];
}
- (IBAction)getDownloadVideoUrlAndSeparationMp3:(id)sender {
    NSString *JsStr = @"(document.getElementsByTagName(\"video\")[0]).src";
    NSString *videoUrl = [self syncExecFetchBodyScriptWithScript:JsStr];
    NSLog(@"videoUrl : [%@]",videoUrl);
    [self downloadWithVideoUrl:videoUrl];
}
- (IBAction)downloadTestMp4:(id)sender {
    [self downloadWithVideoUrl:@"http://vfx.mtime.cn/Video/2019/03/19/mp4/190319104618910544.mp4"];
}
- (IBAction)separationMp3:(id)sender {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"testvideo" ofType:@"mp4"];
    NSURL *sourceMovieURL = [NSURL fileURLWithPath:path];
    [self separationMp3WithFilePath:sourceMovieURL];
}
- (IBAction)createAvplayer:(id)sender {
    [self avplayerPlayMusicLocal:_downloadM4A ? YES : NO];
}
- (IBAction)pasueAVPlayer:(id)sender {
    if (self.player.rate == 1.0) {
        [self.player pause];
        self.playerStateLable.text = [NSString stringWithFormat:@"暂停 %@",self.musicName];
    } else {
        [self.player play];
        self.playerStateLable.text = [NSString stringWithFormat:@"playing %@",self.musicName];
    }
}

#pragma mark - download
- (void)downloadWithVideoUrl:(NSString *)videourl {
    if (!videourl) {
        NSLog(@"videourl is nil");
        return;
    }
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    //http://vfx.mtime.cn/Video/2019/03/19/mp4/190319104618910544.mp4
    NSURL *url = [NSURL URLWithString:videourl];
    [[manager downloadTaskWithRequest:[NSURLRequest requestWithURL:url] progress:^(NSProgress * _Nonnull downloadProgress) {
        NSLog(@"%f",1.0*downloadProgress.completedUnitCount/ downloadProgress.totalUnitCount);
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) firstObject];//沙盒
        NSString *fileName = [[videourl md5] stringByAppendingFormat:@".%@",[response.MIMEType componentsSeparatedByString:@"/"].lastObject];//videourlmd5.MIMEType
        NSString *savePath = [documentPath stringByAppendingPathComponent:fileName];//沙盒存放视频的完整路径
        return [NSURL fileURLWithPath:savePath];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        NSLog(@"download file success : [%@]",filePath);
        [self separationMp3WithFilePath:filePath];
    }] resume];
}

#pragma mark - 音视频分离
- (void)separationMp3WithFilePath:(NSURL *)filePath {
    if (!filePath) {
        return;
    }
    NSArray *pathArr = [filePath.absoluteString componentsSeparatedByString:@"."];
    NSString *documentMovPath = [[pathArr.firstObject stringByAppendingFormat:@".m4a"] stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    NSError *error = nil;
    BOOL state = NO;
    state = [[NSFileManager defaultManager] removeItemAtPath:documentMovPath error:&error];
    if (state) {
        NSLog(@"移除本地的 [%@] 文件",documentMovPath.lastPathComponent);
    } else {
        NSLog(@"本地没有 [m4a]");
    }
    
    [AVSeparation VideoManagerGetBackgroundMiusicWithVideoUrl:filePath newFile:documentMovPath completion:^(NSString * _Nonnull data) {
        self.downloadM4A = data;
//使用AVAssetExportSession导出但在导出URL的末尾附加.mov”.
//使AVAssetExportSession成功导出歌曲。最后一步，使用NSFileManager重命名导出的文件，删除末尾的.mov”。
//        NSError * renameError = nil;
//        [[NSFileManager defaultManager] moveItemAtPath:data toPath:documentMp3Path error:&renameError];
//        if (renameError) {
//            NSLog(@"mov转mp3成功 failed   %@",renameError);
//        }else {
//            NSLog(@"mov转mp3成功 success   %@",documentMp3Path);
//        }
    }];
}

#pragma mark - web
- (void)loadYoutubeWebviewWirhUrl:(NSString *)url {
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.mediaTypesRequiringUserActionForPlayback = NO;//把手动播放设置NO ios(8.0, 9.0)
    config.allowsInlineMediaPlayback = YES;//是否允许内联(YES)或使用本机全屏控制器(NO)，默认是NO。
    config.allowsAirPlayForMediaPlayback = YES;//允许播放，ios(8.0, 9.0)
    self.webView = [[WKWebView alloc] initWithFrame:CGRectMake(50, 50, self.view.frame.size.width-100, 280) configuration:config];
    self.webView.navigationDelegate = self;
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?autoplay=1&playsinline=1",url]]]];
    [self.view addSubview:self.webView];
}
- (NSString *)syncExecFetchBodyScriptWithScript:(NSString *)script { //同步获取html，解决异步webview释放导致获取失败的问题。将defaultRunloop启动，不会阻塞主线程
    __block BOOL finished = NO;
    __block NSString *content = nil;
    [self.webView evaluateJavaScript:script completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        content = result;
        finished = YES;
    }];
    while (!finished) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    return content;
}
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSLog(@"-webview加载url-%@",navigationAction.request.URL.absoluteString);
    decisionHandler(WKNavigationActionPolicyAllow);
}
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSLog(@"WKWebView 加载成功");
}
- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"%@",error);
}
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"%@",error);
}

#pragma mark - avplayer
- (void)avplayerPlayMusicLocal:(BOOL)local {
    self.player = [[AVPlayer alloc]init];
    //后台播放
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:YES error:nil];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    //888f31ee856d3a8f01673ea347b715a5.m4a
    //薛之谦-陪你去流浪.mp3
    //888f31ee856d3a8f01673ea347b715a5.mov
    NSString *urlStr = @"http://music.163.com/song/media/outer/url?id=407679949.mp3";
    self.musicName = @"网络音乐 张信哲";
    NSURL *url = [NSURL URLWithString:urlStr];
    if (local) {
        if (_downloadM4A) {
            url = [NSURL fileURLWithPath:_downloadM4A];
        } else {
            urlStr = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) firstObject];
            url = [NSURL fileURLWithPath:[urlStr stringByAppendingPathComponent:@"888f31ee856d3a8f01673ea347b715a5.mov"]];
        }
        self.musicName = [url.absoluteString componentsSeparatedByString:@"/Documents"].lastObject;
    }
    AVPlayerItem* playerItem = [AVPlayerItem playerItemWithURL:url];
    [self.player replaceCurrentItemWithPlayerItem:playerItem];
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];// 监听status属性
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    AVPlayerItem *item = object;
    //判断监听对象的状态
    if ([keyPath isEqualToString:@"status"]) {
        if (item.status == AVPlayerItemStatusReadyToPlay) {//准备好的
            NSLog(@"AVPlayerItemStatusReadyToPlay , begin Play music");
            self.playerStateLable.text = [NSString stringWithFormat:@"playing %@",self.musicName];
            [self.player play];
        } else if(item.status ==AVPlayerItemStatusUnknown){//未知的状态
            NSLog(@"AVPlayerItemStatusUnknown");
        }else if(item.status ==AVPlayerItemStatusFailed){//有错误的
            NSLog(@"AVPlayerItemStatusFailed");
        }
    }
}

#pragma mark - freestream music （暂未知为啥播放不了转的mp3和ma4文件）
- (void)freestreamPlayMusic {
    _audioStream = [[FSAudioStream alloc] init];
        // 播放失败的回调
        _audioStream.onFailure = ^(FSAudioStreamError error,NSString *description){
            NSLog(@"播放过程中发生错误，错误信息：%@",description);
        };
        // 播放完成的回调
        _audioStream.onCompletion=^(){
            NSLog(@"播放完成!");
        };
        // 设置音量
        [_audioStream setVolume:0.5];
        // 使用音频链接URL播放音频
    //    NSString *urlStr = @"http://music.163.com/song/media/outer/url?id=407679949.mp3";
    //    NSURL *url = [NSURL URLWithString:urlStr];
        NSString *urlStr = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) firstObject];
        NSURL *url = [NSURL fileURLWithPath:[urlStr stringByAppendingPathComponent:@"888f31ee856d3a8f01673ea347b715a5.m4a"]];
        [_audioStream playFromURL:url];
}

#pragma mark - 正则
- (NSMutableArray *)_matchLinkWithStr:(NSString *)str withMatchStr:(NSString *)matchRegex {
    if (!matchRegex || str) {
        return nil;
    }
    NSError *error = NULL;
    NSRegularExpression *reg = [NSRegularExpression regularExpressionWithPattern:matchRegex options:NSRegularExpressionCaseInsensitive error:&error];
    if (!reg) {
        return nil;
    }
    NSArray *match = [reg matchesInString:str
                                  options:NSMatchingReportCompletion
                                  range:NSMakeRange(0, [str length])];
    
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

- (NSString *)matchFirstLinkWithStr:(NSString *)str withMatchStr:(NSString *)matchRegex {
    if (!matchRegex || !str) {
        return nil;
    }
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:matchRegex options:NSRegularExpressionAnchorsMatchLines error:&error];
    NSTextCheckingResult *firstMatch = [regex firstMatchInString:str options:0 range:NSMakeRange(0, [str length])];
    if (firstMatch) {
        NSRange resultRange = [firstMatch rangeAtIndex:0];
        //从urlString中截取数据
        NSString *result = [str substringWithRange:resultRange];
        return result;
    }
    return nil;
}

#pragma mark - base64
-(NSString *)base64EncodeString:(NSString *)string{
    //1、先转换成二进制数据
    NSData *data =[string dataUsingEncoding:NSUTF8StringEncoding];
    //2、对二进制数据进行base64编码，完成后返回字符串
    return [data base64EncodedStringWithOptions:0];
}

-(NSString *)base64DecodeString:(NSString *)string{
    //注意：该字符串是base64编码后的字符串
    //1、转换为二进制数据（完成了解码的过程）
    NSData *data=[[NSData alloc]initWithBase64EncodedString:string options:0];
    //2、把二进制数据转换成字符串
    return [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
}

@end
