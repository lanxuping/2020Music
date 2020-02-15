//
//  YoutubeDownloadUrl.h
//  2020Music
//
//  Created by Lan Xuping on 2020/2/12.
//  Copyright © 2020 Lan Xuping. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <JavaScriptCore/JavaScriptCore.h>


NS_ASSUME_NONNULL_BEGIN

@interface YoutubeDownloadUrl : NSObject <UIWebViewDelegate>
- (void)getStreamUrlsWithVideoID:(NSString *)videoID;
@property (nonatomic, strong) UIWebView *web;
@property (nonatomic ,strong) WKWebView *wkweb;
@end

NS_ASSUME_NONNULL_END
