//
//  AppDelegate.h
//  BackgroundDownloadDemo
//
//  Created by HK on 16/9/10.
//  Copyright © 2016年 hkhust. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DownloadManager.h"

#define kDownloadProgressNotification @"downloadProgressNotification"

@protocol HandleEventsForBackgroundDelegate <NSObject>

- (void)handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler;

@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) DownloadManager *downloadManager;

@property (nonatomic,weak)id<HandleEventsForBackgroundDelegate> HEFBdelegate;

- (void)beginDownloadWithUrl:(NSString *)downloadURLString;
- (void)pauseDownload;
- (void)continueDownload;

@end

