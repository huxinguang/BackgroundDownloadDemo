//
//  TableViewCell.h
//  BackgroundDownloadDemo
//
//  Created by huxinguang on 2016/12/30.
//  Copyright © 2016年 hkhust. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
@property (weak, nonatomic) IBOutlet UIButton *downloadBtn;
@property (weak, nonatomic) IBOutlet UIButton *cancelBtn;

@end
