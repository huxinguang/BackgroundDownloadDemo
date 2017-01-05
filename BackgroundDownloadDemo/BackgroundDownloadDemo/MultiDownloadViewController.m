//
//  MultiDownloadViewController.m
//  BackgroundDownloadDemo
//
//  Created by huxinguang on 2017/1/3.
//  Copyright © 2017年 hkhust. All rights reserved.
//

#import "MultiDownloadViewController.h"
#import "TableViewCell.h"
#import "DownloadModel.h"
#import "NSURLSession+CorrectedResumeData.h"
#import "AppDelegate.h"
typedef void(^CompletionHandlerType)();
#define IS_IOS10ORLATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10)

// 缓存主目录
#define HSCachesDirectory [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"HSCache"]

#define KScreenWidth [[UIScreen mainScreen]bounds].size.width
#define KScreenHeight [[UIScreen mainScreen]bounds].size.height

@interface MultiDownloadViewController ()<UITableViewDelegate,UITableViewDataSource,NSURLSessionDownloadDelegate,HandleEventsForBackgroundDelegate>

@property (nonatomic ,strong)UITableView *downloadTableView;
@property (nonatomic ,strong)NSMutableArray *dataArr;
@property (strong, nonatomic)NSURLSession *backgroundSession;
@property (strong, nonatomic) NSMutableDictionary *completionHandlerDictionary;
@property (strong, nonatomic) UILocalNotification *localNotification;
@property (strong, nonatomic) NSMutableArray *downloadTaskArray;
//@property (strong, nonatomic) NSURLSessionDownloadTask *downloadTask;


@end

@implementation MultiDownloadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    AppDelegate *ad = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    ad.HEFBdelegate = self;
    
    self.downloadTaskArray = [[NSMutableArray alloc]init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDownloadProgress:) name:kDownloadProgressNotification object:nil];
    
    [self createCacheDirectory];
    
    
    self.backgroundSession = [self backgroundURLSession];
    
    self.dataArr = [[NSMutableArray alloc]init];
    for (int i = 0; i < 9; i++) {
        DownloadModel *dm = [[DownloadModel alloc]init];
        dm.url = [NSString stringWithFormat:@"http://120.25.226.186:32812/resources/videos/minion_0%d.mp4",i+1];
        dm.tasksArr = [[NSMutableArray alloc]init];
        [self.dataArr addObject:dm];
    }
    self.downloadTableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.downloadTableView.delegate = self;
    self.downloadTableView.dataSource = self;
    [self.view addSubview:self.downloadTableView];
    
}


- (void)createCacheDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:HSCachesDirectory]) {
        [fileManager createDirectoryAtPath:HSCachesDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    NSLog(@"%@",HSCachesDirectory);
}


- (NSURLSession *)backgroundURLSession {
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *identifier = @"com.yourcompany.appId.BackgroundSession";
        NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
        sessionConfig.sessionSendsLaunchEvents = YES;
        sessionConfig.discretionary = YES;//允许系统为background tasks进行性能优化。这意味着只有当设备有足够电量时，设备才通过 Wifi 进行数据传输。如果电量低，或者只仅有一个蜂窝连接，传输任务是不会运行的。后台传输总是在 discretionary模式下运行
        session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                delegate:self
                                           delegateQueue:[NSOperationQueue mainQueue]];
    });
    
    return session;
}


#pragma mark - UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return self.dataArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellId= @"CellID";
    TableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[[NSBundle mainBundle]loadNibNamed:@"TableViewCell" owner:self options:nil]lastObject];
    }
    cell.downloadBtn.tag = indexPath.row;
    cell.cancelBtn.tag = indexPath.row;
    [cell.downloadBtn addTarget:self action:@selector(downloadBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [cell.cancelBtn addTarget:self action:@selector(cancelBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    DownloadModel *dm = self.dataArr[indexPath.row];
    CGFloat receivedBytes = [self getTaskDownloadProgress:dm.url];
    
//    NSMutableURLRequest *mURLRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:dm.url]];
//    [mURLRequest setHTTPMethod:@"HEAD"];
//    [[NSURLSession sharedSession] dataTaskWithRequest:mURLRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//        NSDictionary *dict = [(NSHTTPURLResponse *)response allHeaderFields];
//        long long totalBytes = [[dict objectForKey:@"Content-Length"] longLongValue];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            cell.progressView.progress = (float)receivedBytes/totalBytes;
//        });
//    }];


    return cell;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return 70;
}

- (void)downloadBtnClick:(UIButton *)btn{
    
    DownloadModel *dm = self.dataArr[btn.tag];
    if ([btn.titleLabel.text isEqualToString:@"开始"]) {
        //下载
        NSString *plistPath = [HSCachesDirectory stringByAppendingPathComponent:@"resumeData.plist"];
        NSMutableDictionary *plistDic = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
        
        NSURLSessionDownloadTask *downloadTask = nil;
        
        if (plistDic && [plistDic objectForKey:dm.url]) {
            NSData *resumeData = [plistDic objectForKey:dm.url];
            downloadTask = [self.backgroundSession downloadTaskWithResumeData:resumeData];
//            for (NSURLSessionDownloadTask *task in self.downloadTaskArray) {
//                if (task.currentRequest.) {
//                    <#statements#>
//                }
//            }
            
            [self.downloadTaskArray addObject:downloadTask];
//            self.downloadTask = [self.backgroundSession downloadTaskWithResumeData:resumeData];
        }else{
            NSURL *downloadURL = [NSURL URLWithString:dm.url];
            NSURLRequest *request = [NSURLRequest requestWithURL:downloadURL];
            downloadTask = [self.backgroundSession downloadTaskWithRequest:request];
            [self.downloadTaskArray addObject:downloadTask];
            NSLog(@"taskIdentifier = %ld",dm.task.taskIdentifier);
        }
        
        [downloadTask resume];
        [btn setTitle:@"暂停" forState:UIControlStateNormal];
        
    }else{
        //暂停
        
        for (NSURLSessionDownloadTask *task in self.downloadTaskArray) {
            if ([task.currentRequest.URL.absoluteString isEqualToString:dm.url]) {
                [task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                }];
            }
        }
        
        [btn setTitle:@"开始" forState:UIControlStateNormal];
    }
    
}

- (void)cancelBtnClick:(UIButton *)btn{

    
}




- (float)getTaskDownloadProgress:(NSString *)url{
    NSString *plistPath = [HSCachesDirectory stringByAppendingPathComponent:@"resumeData.plist"];
    NSMutableDictionary *plistDic = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    NSData *resumeData = [plistDic objectForKey:url];
    if (resumeData) {
        NSError *error = nil;
        NSPropertyListFormat format;
        NSDictionary *resumeDic = (NSDictionary *)[NSPropertyListSerialization propertyListWithData:resumeData options:NSPropertyListImmutable format:&format error:&error];
        
        if(!resumeDic){
            NSLog(@"Error: %@",[error localizedDescription]);
        }else{
            NSLog(@"%@",resumeDic);
        }
        
        long long bytesReceived = [[resumeDic objectForKey:@"NSURLSessionResumeBytesReceived"] longLongValue];
        NSLog(@"bytesReceived = %lld",bytesReceived);
        
        return bytesReceived;
        
    }else{
        return 0;
    }
    
}





#pragma mark - NSURLSessionDownloadDelegate
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    
    NSLog(@"downloadTask:%lu didFinishDownloadingToURL:%@", (unsigned long)downloadTask.taskIdentifier, location);
    NSString *locationString = [location path];
    
    NSString *urlStr = downloadTask.currentRequest.URL.absoluteString;
    NSString *destinationPath = [HSCachesDirectory stringByAppendingPathComponent:[urlStr lastPathComponent]];
    NSError *error;
    [[NSFileManager defaultManager] moveItemAtPath:locationString toPath:destinationPath error:&error];
    
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes {
    
    NSLog(@"fileOffset:%lld expectedTotalBytes:%lld",fileOffset,expectedTotalBytes);
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
    NSString *plistPath = [HSCachesDirectory stringByAppendingPathComponent:@"resumeData.plist"];
    NSMutableDictionary *plistDic = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    
    
    NSLog(@"downloadTask:%lu percent:%.2f%%",(unsigned long)downloadTask.taskIdentifier,(CGFloat)totalBytesWritten / totalBytesExpectedToWrite * 100);
    NSString *strProgress = [NSString stringWithFormat:@"%.2f%%",(CGFloat)totalBytesWritten / totalBytesExpectedToWrite*100];
    for (DownloadModel *item in self.dataArr) {
        if ([item.url isEqualToString:downloadTask.currentRequest.URL.absoluteString]) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.dataArr indexOfObject:item] inSection:0];
            TableViewCell *cell = [self.downloadTableView cellForRowAtIndexPath:indexPath];
            cell.progressLabel.text = strProgress;
            [cell.progressView setProgress:(CGFloat)totalBytesWritten/totalBytesExpectedToWrite animated:YES];
        }
    }
    
    
    
//    [self postDownlaodProgressNotification:strProgress];
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    NSLog(@"Background URL session %@ finished events.\n", session);
    
    if (session.configuration.identifier) {
        // 调用在 -application:handleEventsForBackgroundURLSession: 中保存的 handler
        [self callCompletionHandlerForSession:session.configuration.identifier];
    }
}

/*
 * 该方法下载成功和失败都会回调，只是失败的是error是有值的，
 * 在下载失败时，error的userinfo属性可以通过NSURLSessionDownloadTaskResumeData
 * 这个key来取到resumeData(和上面的resumeData是一样的)，再通过resumeData恢复下载
 */
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    
    NSString *plistPath = [HSCachesDirectory stringByAppendingPathComponent:@"resumeData.plist"];
    NSMutableDictionary *plistDic = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    NSString *urlStr = task.currentRequest.URL.absoluteString;
    NSLog(@"***************%@",urlStr.length>0?urlStr:@"task的url为空");
    NSLog(@"%@",plistPath);
    
    if (error) {
        // check if resume data are available
        if ([error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData]) {
            NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
            
            if ([error.userInfo objectForKey:@"NSURLErrorBackgroundTaskCancelledReasonKey"]) {//重新打开app
                NSLog(@"************* %@ 上次暂停原因:手动杀死app",[error.userInfo objectForKey:@"NSErrorFailingURLKey"] );
            }
            if ([[error.userInfo objectForKey:@"NSLocalizedDescription"] isEqualToString:@"cancelled"]) {//点击“暂停下载”
                NSLog(@"+++++++++++++ %@ 暂停原因:手动暂停下载",[error.userInfo objectForKey:@"NSErrorFailingURLKey"]);
            }
            
            if (plistDic){
                [plistDic setObject:resumeData forKey:urlStr];
                [plistDic writeToFile:plistPath atomically:YES];
            }else{
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                [dict setObject:resumeData forKey:urlStr];
                [dict writeToFile:plistPath atomically:YES];
            }
            
        }
    } else {
        
        if (plistDic && [plistDic objectForKey:urlStr]) {
            [plistDic removeObjectForKey:urlStr];
            [plistDic writeToFile:plistPath atomically:YES];
            
        }
        
        [self sendLocalNotification];
        [self postDownlaodProgressNotification:@"1"];
    }
}

- (void)postDownlaodProgressNotification:(NSString *)strProgress {
    NSDictionary *userInfo = @{@"progress":strProgress};
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kDownloadProgressNotification object:nil userInfo:userInfo];
    });
}

- (void)sendLocalNotification {
    [[UIApplication sharedApplication] scheduleLocalNotification:self.localNotification];
}




#pragma mark - HandleEventsForBackgroundDelegate

- (void)handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler{

    NSURLSession *backgroundSession = [self backgroundURLSession];
    
    NSLog(@"Rejoining session with identifier %@ %@", identifier, backgroundSession);
    
    // 保存 completion handler 以在处理 session 事件后更新 UI
    [self addCompletionHandler:completionHandler forSession:identifier];
}


#pragma mark Save completionHandler
- (void)addCompletionHandler:(CompletionHandlerType)handler forSession:(NSString *)identifier {
    if ([self.completionHandlerDictionary objectForKey:identifier]) {
        NSLog(@"Error: Got multiple handlers for a single session identifier.  This should not happen.\n");
    }
    
    [self.completionHandlerDictionary setObject:handler forKey:identifier];
}

- (void)callCompletionHandlerForSession:(NSString *)identifier {
    CompletionHandlerType handler = [self.completionHandlerDictionary objectForKey:identifier];
    
    if (handler) {
        [self.completionHandlerDictionary removeObjectForKey: identifier];
        NSLog(@"Calling completion handler for session %@", identifier);
        
        handler();
    }
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateDownloadProgress:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    CGFloat fProgress = [userInfo[@"progress"] floatValue];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
