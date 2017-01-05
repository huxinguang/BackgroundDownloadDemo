//
//  DownloadManager.h
//  BackgroundDownloadDemo
//
//  Created by huxinguang on 2017/1/4.
//  Copyright © 2017年 hkhust. All rights reserved.
//

#import <Foundation/Foundation.h>

// 缓存主目录
#define HSCachesDirectory [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"HSCache"]

#define IS_IOS10ORLATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10)

@interface DownloadManager : NSObject

@end
