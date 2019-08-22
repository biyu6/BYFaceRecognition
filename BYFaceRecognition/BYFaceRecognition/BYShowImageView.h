//
//  BYShowImageView.h
//  BYFaceRecognition
//
//  Created by 胡忠诚 on 2019/8/22.
//  Copyright © 2019 ether. All rights reserved.
//图片显示View

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BYShowImageView : UIView
/**识别结果图片*/
@property (nonatomic,strong) UIImage *resultImg;
/**点击了界面上的按钮*/
@property(nonatomic, copy)void (^clickShowImageViewBtn)(NSInteger tag,UIImage *resultImg);


@end

NS_ASSUME_NONNULL_END
