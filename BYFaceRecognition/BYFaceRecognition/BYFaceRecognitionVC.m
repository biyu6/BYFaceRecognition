//
//  BYFaceRecognitionVC.m
//  BYFaceRecognition
//
//  Created by 胡忠诚 on 2019/8/22.
//  Copyright © 2019 ether. All rights reserved.
//人脸识别VC

#import "BYFaceRecognitionVC.h"
#import "BYFaceRecognitionView.h"//人脸识别view
#import "BYTools.h"//我的工具类

@interface BYFaceRecognitionVC ()
/**人脸识别view*/
@property (nonatomic,strong) BYFaceRecognitionView *scanView;

@end
@implementation BYFaceRecognitionVC
#pragma mark- init初始化
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self addSubViewClick];
}
- (void)setupUI{
    self.view.backgroundColor = [UIColor whiteColor];
    /**人脸识别view
     人脸入库 warehousing ：获取脸部照片后显示获取的照片，可以重拍 或 上传照片；
     人脸比对 comparison  ：获取照片后直接调用后台接口进行比对
     */
    _scanView =[[BYFaceRecognitionView alloc]initWithFrame:self.view.bounds paramsData:@{@"type":@"warehousing"}];
    [self.view addSubview:_scanView];
}
- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    [_scanView stopCaptureSession];
}

#pragma mark- 用户交互
- (void)addSubViewClick{
    __weak __typeof(&*self) weakSelf = self;
    _scanView.noCameraAuthorTips = ^() {//没有相机权限的提示
        [weakSelf tipCameraAuthor];
    };
    _scanView.requestServerResultImage = ^(NSString * _Nonnull typeStr, UIImage * _Nonnull resultImg) {//请求网络的交互:人脸上传、人脸比对
        if ([typeStr isEqualToString:@"warehousing"]) {
            [weakSelf requestFaceWarehousingWithUploadImage:resultImg];
        }else if ([typeStr isEqualToString:@"comparison"]){
            [weakSelf requestFaceComparison:resultImg];
        }
    };
}
- (void)tipCameraAuthor{//提示相机授权
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:@"没有相机权限" message: nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSURL * url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:(UIAlertActionStyleCancel) handler:^(UIAlertAction * _Nonnull action) {
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark- 网络请求
- (void)requestFaceWarehousingWithUploadImage:(UIImage *)img{//点击了上传图片按钮
    NSLog(@"去调用--->人脸入库接口");
}
- (void)requestFaceComparison:(UIImage *)img{//请求人脸比对接口
    NSLog(@"去调用--->人脸比对接口");
}


@end
