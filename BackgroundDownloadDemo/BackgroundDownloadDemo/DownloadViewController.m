//
//  DownloadViewController.m
//  BackgroundDownloadDemo
//
//  Created by huxinguang on 2016/12/30.
//  Copyright © 2016年 hkhust. All rights reserved.
//

#import "DownloadViewController.h"
#define KScreenWidth [[UIScreen mainScreen]bounds].size.width
#define KScreenHeight [[UIScreen mainScreen]bounds].size.height

@interface DownloadViewController ()

@property (nonatomic ,strong)UITableView *downloadTableView;


@end

@implementation DownloadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.downloadTableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
    
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
