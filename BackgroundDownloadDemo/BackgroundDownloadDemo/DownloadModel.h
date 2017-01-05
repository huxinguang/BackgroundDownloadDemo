//
//  DownloadModel.h
//  BackgroundDownloadDemo
//
//  Created by huxinguang on 2016/12/30.
//  Copyright © 2016年 hkhust. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DownloadModel : NSObject
@property (nonatomic, copy)NSString *url;
@property (nonatomic, strong)NSMutableArray *tasksArr;
@property (nonatomic, strong)NSURLSessionDownloadTask *task;
@property (nonatomic, strong)NSData *resumeData;

@end
