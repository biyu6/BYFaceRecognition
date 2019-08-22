//
//  BYShowImageView.m
//  BYFaceRecognition
//
//  Created by 胡忠诚 on 2019/8/22.
//  Copyright © 2019 ether. All rights reserved.
//图片显示View

#import "BYShowImageView.h"
#import "BYShowImageView.h"//图片显示View

@interface BYShowImageView()
/**识别结果图片View*/
@property (nonatomic,strong) UIImageView *resultImgView;

@end
@implementation BYShowImageView
#pragma mark- init初始化
- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self initAddSubViews];
    }
    return self;
}
- (void)initAddSubViews{
    self.backgroundColor = [UIColor whiteColor];
    CGFloat screenW = self.bounds.size.width;
    //识别结果图片View
    UIImageView * imageV = [[UIImageView alloc]initWithFrame:CGRectMake((screenW-250)/2.0, 50, 250, 300)];
    imageV.contentMode = UIViewContentModeScaleAspectFit;
    imageV.layer.borderColor = [UIColor blueColor].CGColor;
    imageV.layer.borderWidth = 2.0;
    [self addSubview:imageV];
    self.resultImgView = imageV;
    
    //重拍按钮
    UIButton *backBtn = [[UIButton alloc]initWithFrame:CGRectMake(10, 350 + 30, (screenW-30)/2.0, 30)];
    backBtn.backgroundColor = [UIColor redColor];
    [backBtn setTitle:@"重拍" forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(backBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:backBtn];
    
    //上传按钮
    UIButton *uploadBtn = [[UIButton alloc]initWithFrame:CGRectMake((screenW-30)/2.0 + 20, 350 + 30, (screenW-30)/2.0, 30)];
    uploadBtn.backgroundColor = [UIColor redColor];
    [uploadBtn setTitle:@"上传" forState:UIControlStateNormal];
    [uploadBtn addTarget:self action:@selector(uploadBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:uploadBtn];
}

#pragma mark- 数据处理
- (void)setResultImg:(UIImage *)resultImg{
    _resultImg = resultImg;
    self.resultImgView.image = _resultImg;
}

#pragma mark- 用户交互
- (void)backBtnClick{//点击了图片返回
    if(self.clickShowImageViewBtn){
        self.clickShowImageViewBtn(1,self.resultImg);
    }
}
- (void)uploadBtnClick{//点击了上传图片
    if(self.clickShowImageViewBtn){
        self.clickShowImageViewBtn(2,self.resultImg);
    }
}


@end
