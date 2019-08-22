//
//  BYHomeVC.m
//  BYFaceRecognition
//
//  Created by 胡忠诚 on 2019/8/22.
//  Copyright © 2019 ether. All rights reserved.
//首页VC

#import "BYHomeVC.h"
#import "BYFaceRecognitionVC.h"//人脸识别VC

@interface BYHomeVC ()

@end
@implementation BYHomeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}
- (void)setupUI{
    self.view.backgroundColor = [UIColor whiteColor];
    UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(100, 150, 120, 50)];
    btn.backgroundColor = [UIColor blueColor];
    [btn setTitle:@"人脸检测" forState:UIControlStateNormal];
    btn.titleLabel.textColor = [UIColor whiteColor];
    [btn addTarget:self action:@selector(btnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}
- (void)btnClick{
    BYFaceRecognitionVC *vc = [[BYFaceRecognitionVC alloc]init];
    [self presentViewController:vc animated:YES completion:nil];
}


@end
