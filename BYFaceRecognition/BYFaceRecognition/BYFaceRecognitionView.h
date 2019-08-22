//
//  BYFaceRecognitionView.h
//  BYFaceRecognition
//
//  Created by 胡忠诚 on 2019/8/22.
//  Copyright © 2019 ether. All rights reserved.
//人脸识别view

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BYFaceRecognitionView : UIView
//init初始化
- (id)initWithFrame:(CGRect)frame paramsData:(NSDictionary *)paramsDictData;
//停止捕获
- (void)stopCaptureSession;
/**没有相机权限的提示*/
@property(nonatomic, copy)void(^noCameraAuthorTips)(void);
/**请求网络的交互:人脸上传、人脸比对*/
@property(nonatomic, copy)void(^requestServerResultImage)(NSString *typeStr,UIImage *resultImg);


@end

NS_ASSUME_NONNULL_END
