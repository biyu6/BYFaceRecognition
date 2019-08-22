//
//  BYTools.h
//  BYFaceRecognition
//
//  Created by 胡忠诚 on 2019/8/22.
//  Copyright © 2019 ether. All rights reserved.
//我的工具类

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BYTools : NSObject
/**检测相机权限：准许返回YES;否则返回NO*/
+ (BOOL)isCapturePermissionGranted;
//CMSampleBufferRef转为图片
+ (UIImage *)sampleBufferToImage:(CMSampleBufferRef)sampleBuffer;
//获取摄像头感知的环境光亮度（测试：人脸是2.6左右、对着光是3.4左右，完全黑暗是-1左右）
+ (float )getAmbientBrightnessValue:(CMSampleBufferRef)sampleBuffer;


@end

NS_ASSUME_NONNULL_END
