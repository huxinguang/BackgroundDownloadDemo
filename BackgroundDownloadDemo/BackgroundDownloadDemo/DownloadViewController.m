//
//  DownloadViewController.m
//  BackgroundDownloadDemo
//
//  Created by huxinguang on 2016/12/30.
//  Copyright © 2016年 hkhust. All rights reserved.
//

#import "DownloadViewController.h"
#import "TableViewCell.h"
#import "DownloadModel.h"

// 缓存主目录
#define HSCachesDirectory [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"HSCache"]

#define KScreenWidth [[UIScreen mainScreen]bounds].size.width
#define KScreenHeight [[UIScreen mainScreen]bounds].size.height

@interface DownloadViewController ()<UITableViewDelegate,UITableViewDataSource,NSURLSessionDownloadDelegate>

@property (nonatomic ,strong)UITableView *downloadTableView;
@property (nonatomic ,strong)NSMutableArray *dataArr;
@property (strong, nonatomic)NSURLSession *backgroundSession;
@property (nonatomic ,strong)NSMutableDictionary *taskDic;
@property (nonatomic ,strong)NSMutableDictionary *urlDic;


@end

@implementation DownloadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self createCacheDirectory];
    
    
    self.taskDic = [[NSMutableDictionary alloc]init];
    self.urlDic = [[NSMutableDictionary alloc]init];
    self.backgroundSession = [self backgroundURLSession];
    
    self.dataArr = [[NSMutableArray alloc]init];
    for (int i = 0; i < 10; i++) {
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
    [cell.downloadBtn addTarget:self action:@selector(downloadBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{

    return 70;
}


- (void)downloadBtnClick:(UIButton *)btn{
    
    DownloadModel *dm = self.dataArr[btn.tag];
    if ([btn.titleLabel.text isEqualToString:@"下载"]) {
        //下载
        if (dm.tasksArr.count == 0) {
            NSURL *downloadURL = [NSURL URLWithString:dm.url];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:downloadURL];
            // 设置请求头信息
            long long totalLength = [self getFilesize:dm.url];
//            [self reserveSpaceForFileWithUrl:dm.url totalLength:totalLength];
            
            // 每片文件的下载量
            long long size = 0;
            if (totalLength % 3 == 0) {
                size = totalLength / 3;
            } else {
                size = totalLength / 3 + 1;
            }

            for (int i = 0; i < 3; i++) {
                NSString *value = [NSString stringWithFormat:@"bytes=%lld-%lld", i*size, (i+1)*size-1];
                [request setValue:value forHTTPHeaderField:@"Range"];
                NSURLSessionDownloadTask *task = [self.backgroundSession downloadTaskWithRequest:request];
                [self.urlDic setObject:dm.url forKey:[NSString stringWithFormat:@"%ld",task.taskIdentifier]];
                NSLog(@"taskIdentifier = %ld",task.taskIdentifier);
                [task resume];
            }
        }
        
        [btn setTitle:@"暂停" forState:UIControlStateNormal];
        
        
    }else{
        //暂停
        [btn setTitle:@"下载" forState:UIControlStateNormal];
        
    }
    TableViewCell *cell = [self.downloadTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:btn.tag inSection:0]];
    
    
    
}

// 创建一个跟服务器文件等大小的临时文件
- (void)reserveSpaceForFileWithUrl:(NSString *)url totalLength:(long long)length{
    NSString *suffix = [url lastPathComponent];
    // 文件保存到什么地方
    NSString *filepath = [HSCachesDirectory stringByAppendingPathComponent:suffix];
    // 创建一个跟服务器文件等大小的临时文件
    [[NSFileManager defaultManager] createFileAtPath:filepath contents:nil attributes:nil];
    // 让self.destPath文件的长度是self.totalLengt
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:filepath];
    [handle truncateFileAtOffset:length];
}

- (long long)getFilesize:(NSString *)url
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = @"HEAD";
    NSURLResponse *response = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
    long long totalLength = response.expectedContentLength;
    return totalLength;
}

//- (long long)getCurrentLength:


#pragma mark - NSURLSessionDownloadDelegate
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    
    NSLog(@"downloadTask:%lu didFinishDownloadingToURL:%@", (unsigned long)downloadTask.taskIdentifier, location);
    NSString *locationString = [location path];
//    NSString *finalLocation = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"%lufile",(unsigned long)downloadTask.taskIdentifier]];
    NSString *url = [self.urlDic objectForKey:[NSString stringWithFormat:@"%ld",downloadTask.taskIdentifier]];
//    NSString *finalLocation = [HSCachesDirectory stringByAppendingPathComponent:[url lastPathComponent]];
    NSString *finalLocation = [HSCachesDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld.mp4",downloadTask.taskIdentifier]];
    NSError *error;
    [[NSFileManager defaultManager] moveItemAtPath:locationString toPath:finalLocation error:&error];
    
    // 用 NSFileManager 将文件复制到应用的存储中
    // ...
    
    // 通知 UI 刷新
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
    
    [self.taskDic setObject:[NSNumber numberWithLongLong:totalBytesWritten] forKey:[NSString stringWithFormat:@"downloadTask%ld",downloadTask.taskIdentifier]];
    
    NSLog(@"downloadTask:%lu percent:%.2f%%",(unsigned long)downloadTask.taskIdentifier,(CGFloat)totalBytesWritten / totalBytesExpectedToWrite * 100);
//    NSString *strProgress = [NSString stringWithFormat:@"%.2f",(CGFloat)totalBytesWritten / totalBytesExpectedToWrite];
//    [self postDownlaodProgressNotification:strProgress];
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
//    NSLog(@"Background URL session %@ finished events.\n", session);
//    
//    if (session.configuration.identifier) {
//        // 调用在 -application:handleEventsForBackgroundURLSession: 中保存的 handler
//        [self callCompletionHandlerForSession:session.configuration.identifier];
//    }
}

/*
 * 该方法下载成功和失败都会回调，只是失败的是error是有值的，
 * 在下载失败时，error的userinfo属性可以通过NSURLSessionDownloadTaskResumeData
 * 这个key来取到resumeData(和上面的resumeData是一样的)，再通过resumeData恢复下载
 */
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    
//    if (error) {
//        // check if resume data are available
//        if ([error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData]) {
//            NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
//            //通过之前保存的resumeData，获取断点的NSURLSessionTask，调用resume恢复下载
//            self.resumeData = resumeData;
//        }
//    } else {
//        [self sendLocalNotification];
//        [self postDownlaodProgressNotification:@"1"];
//    }
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
