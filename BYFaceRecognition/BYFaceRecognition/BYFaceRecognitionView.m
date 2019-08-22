//
//  BYFaceRecognitionView.m
//  BYFaceRecognition
//
//  Created by 胡忠诚 on 2019/8/22.
//  Copyright © 2019 ether. All rights reserved.
//人脸识别view

#import "BYFaceRecognitionView.h"
#import <AVFoundation/AVFoundation.h>
#import "BYTools.h"//我的工具类
#import "BYShowImageView.h"//图片显示View

@interface BYFaceRecognitionView()<AVCaptureVideoDataOutputSampleBufferDelegate>
/**传过来的参数*/
@property (nonatomic,strong)NSDictionary *paramsDictData;
/**识别类型： 人脸入库 warehousing 、 人脸比对 comparison */
@property (nonatomic,copy)NSString *typeStr;
/**脸部捕捉提示label*/
@property (nonatomic,strong) UILabel *tipMsgLabel;
/**脸部捕捉框*/
@property (nonatomic, strong) UIView *faceBoxView;
/**识别结果展示图片View*/
@property (nonatomic,strong) BYShowImageView *showImgaeView;
/**人脸识别相关*/
@property (nonatomic, strong)AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong)AVCaptureSession *captureSession;
@property (nonatomic, strong)AVCaptureDevice *captureDevice;
/**全局的layer（不含小窗口）*/
@property (nonatomic,strong)CALayer* coverLayer;
/**小窗口的layer*/
@property (nonatomic, strong)CAShapeLayer* cropLayer;
/**捕捉脸部的小窗口的坐标*/
@property (nonatomic,assign)CGRect cropRect;
/**是否正在聚焦中*/
@property (nonatomic, assign)BOOL hasSetFocus;
/**是否开始识别*/
@property (nonatomic, assign)BOOL isStart;
/**成功的次数（连续成功10次才调用）*/
@property (nonatomic, assign) NSInteger successCount;

@end
@implementation BYFaceRecognitionView
#pragma mark- init初始化
- (id)initWithFrame:(CGRect)frame paramsData:(NSDictionary *)paramsDictData{
    self = [super initWithFrame:frame];
    if (self) {
        self.hasSetFocus = NO;//是否在聚焦中
        self.cropRect = CGRectMake((frame.size.width - 250)/2.0, 200, 250, 300);//设置捕捉脸部的小窗口的坐标
        self.paramsDictData = paramsDictData;//解析传过来的参数
        [self addRecognition];//添加识别
        [self setupResultImageView];//添加识别结果展示图片View
    }
    return self;
}
- (void)layoutSubviews{
    [self.previewLayer setFrame:self.bounds];
    [self.coverLayer setFrame:self.bounds];//添加全局的遮罩（扣掉小窗口）
    self.coverLayer.mask = self.cropLayer;//全局的遮罩（扣掉小窗口）
}
- (void)initOtherLayers{ //初始化全局的遮罩（抠掉小窗口）
    self.coverLayer = [CALayer layer];
    self.coverLayer.backgroundColor = [[[UIColor blackColor] colorWithAlphaComponent:0.4] CGColor];
    [self.layer addSublayer:self.coverLayer];
    if(!CGRectEqualToRect(CGRectZero, self.cropRect)){ //抠掉小窗口的路径
        self.cropLayer = [[CAShapeLayer alloc] init];
        CGMutablePathRef path = CGPathCreateMutable();// 可变路径 用于添加下一个点
        CGPathAddEllipseInRect(path, nil, self.cropRect);//内切椭圆 （需 cropRect 宽高不一样（150，200））
        CGPathAddRect(path, nil, self.bounds);//绘制一个全局的大矩形
        [self.cropLayer setFillRule:kCAFillRuleEvenOdd];
        [self.cropLayer setPath:path];
        [self.cropLayer setFillColor:[[UIColor redColor] CGColor]];
    }
    //实时调用展示的图片 （左边中间的那个）
    self.previewLayer.contentsGravity = kCAGravityResizeAspect;
}
- (void)setCropRect:(CGRect)cropRect{//设置捕捉脸部的小窗口的坐标
    _cropRect = cropRect;
    if(!CGRectEqualToRect(CGRectZero, self.cropRect)){ //小窗口的路径范围
        self.cropLayer = [[CAShapeLayer alloc] init];
        CGMutablePathRef path = CGPathCreateMutable();// 可变路径 用于添加下一个点
        CGPathAddEllipseInRect(path, nil, self.cropRect);//内切椭圆 （需 cropRect 宽高不一样（150，200））
        CGPathAddRect(path, nil, self.bounds);//绘制一个全局的大矩形
        [self.cropLayer setFillRule:kCAFillRuleEvenOdd];
        [self.cropLayer setPath:path];
        [self.cropLayer setFillColor:[[UIColor whiteColor] CGColor]];
        [self.cropLayer setNeedsDisplay];
    }
}
- (void)setupResultImageView{//添加一个view 用于在人脸入库时的显示
    if ([_typeStr isEqualToString:@"warehousing"]) {//人脸入库
        //图片显示View
        [self addSubview:self.showImgaeView];
        _showImgaeView.hidden = YES;
        __weak __typeof(&*self) weakSelf = self;
        _showImgaeView.clickShowImageViewBtn = ^(NSInteger tag, UIImage * _Nonnull resultImg) {
            if (tag == 1) {//重拍
                [weakSelf distinguishAgain];
            }else if (tag == 2) {//上传图片
                NSLog(@"调用人脸上传接口");
                if (weakSelf.requestServerResultImage) {
                    weakSelf.requestServerResultImage(@"warehousing",resultImg);
                }
            }
        };
    }
}
- (UILabel *)tipMsgLabel{//脸部捕捉提示label
    if (!_tipMsgLabel) {
        _tipMsgLabel = [[UILabel alloc]initWithFrame:CGRectMake(50, 100,[UIScreen mainScreen].bounds.size.width -100 , 30)];
        _tipMsgLabel.textColor = [UIColor redColor];
        _tipMsgLabel.font = [UIFont systemFontOfSize:20];
        _tipMsgLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _tipMsgLabel;
}
- (BYShowImageView *)showImgaeView{//图片显示View
    if(!_showImgaeView){
        _showImgaeView = [[BYShowImageView alloc]initWithFrame:[UIScreen mainScreen].bounds];
    }
    return _showImgaeView;
}
- (UIView *)faceBoxView{//脸部捕捉框
    if (!_faceBoxView) {
        CGRect frame = _cropRect;
        _faceBoxView = [[UIView alloc] initWithFrame:frame];
        _faceBoxView.backgroundColor = [UIColor clearColor];
    }
    return _faceBoxView;
}

#pragma mark- 数据处理
- (void)setParamsDictData:(NSDictionary *)paramsDictData{//处理外界传递过来的参数
    _paramsDictData = paramsDictData;
    _typeStr = [paramsDictData objectForKey:@"type"];//识别类型： 人脸入库 warehousing 、 人脸比对 comparison
}

#pragma mark- 用户交互
- (void)changeTipTextWithCaptureFaceStatus:(NSInteger)captureFaceStatus{//提示拦截
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString * title = @""; /* 请靠近一点 请远离一点 没找到检测的方法*/
        switch (captureFaceStatus) {
            case 101:
                title = @"请将人脸移动到识别区域";//请正对相机,保证光线充足
                break;
            case 102:
                title = @"请保证只有一张人脸";
                break;
            case 103:
                title = @"正在验证,请稍后";
                break;
            case 104:
                title = @"没有相机权限";
                break;
            case 105:
                title = @"请勿移动";
                break;
            case 106:
                title = @"请保持正脸";
                break;
            case 107:
                title = @"光线不足";
                break;
            default:
                break;
        }
        self.tipMsgLabel.text = title;//脸部捕捉提示label 赋值
        if (captureFaceStatus == 104) {//没有相机权限--跳到控制器去提示设置
            if(self.noCameraAuthorTips){
                self.noCameraAuthorTips();
            }
        }
    });
}
- (void)handleResultImage:(UIImage *)resultImg{//识别出图片
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.typeStr isEqualToString:@"warehousing"]) {//人脸入库--展示结果图片
            self.showImgaeView.resultImg = resultImg;
            self.showImgaeView.hidden = NO;
        }else if ([self.typeStr isEqualToString:@"comparison"]){//人脸比对--调用比对接口
            NSLog(@"调用比对接口");
            if (self.requestServerResultImage) {
                self.requestServerResultImage(@"comparison",resultImg);
            }
        }
    });
}
- (void)distinguishAgain{//点击了重拍按钮
    self.showImgaeView.hidden = YES;
    _successCount = 0;
    self.isStart = true;
}

#pragma mark- 识别相关
- (AVCaptureSession *)captureSession{//初始化链接对象
    if (!_captureSession) {
        _captureSession = [[AVCaptureSession alloc] init];
        [_captureSession setSessionPreset:AVCaptureSessionPresetHigh];//高质量采集率，AVCaptureSessionPresetMedium
    }
    return _captureSession;
}
- (void)addRecognition{//添加识别
    if (![BYTools isCapturePermissionGranted]) {//没有相机权限
        [self changeTipTextWithCaptureFaceStatus:104];
        return;
    }
    _successCount = 0;//初始化成功捕获的次数
    self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    NSArray<AVCaptureDevice *> *devices = [AVCaptureDevice devices];
    for (AVCaptureDevice *device in devices) {
        if ([device hasMediaType:AVMediaTypeVideo]) {
            if (device.position == AVCaptureDevicePositionFront) {// AVCaptureDevicePositionBack 启动前后摄像头的切换
                self.captureDevice = device;
                [self beginSession];
            }
        }
    }
    [self addSubview:self.faceBoxView]; //添加脸部捕捉框的父视图
    [self addSubview:self.tipMsgLabel];//添加脸部捕捉提示label
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(captureStartState) userInfo:nil repeats:false];
}
- (void)captureStartState{//是否开始人脸检测
    self.isStart = true;
}
- (void)beginSession{//开始识别
    NSLog(@"开始识别");
    NSError *error;
    //创建输入流
    AVCaptureDeviceInput *deviceInput = [[AVCaptureDeviceInput alloc]initWithDevice:self.captureDevice error:&error];
    //创建输出流
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    output.alwaysDiscardsLateVideoFrames = YES;//旧写法
    dispatch_queue_t cameraQueue = dispatch_queue_create("cameraQueue", DISPATCH_QUEUE_SERIAL);
    [output setSampleBufferDelegate:self queue:cameraQueue];
    //设置像素格式
    output.videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithUnsignedInteger:kCVPixelFormatType_32BGRA],
                            kCVPixelBufferPixelFormatTypeKey,
                            nil];
    //啥玩意？（旧写法）
    AVCaptureStillImageOutput* stillImageOutput = [[AVCaptureStillImageOutput alloc]init];
    NSDictionary* outputSettings = @{AVVideoCodecKey:AVVideoCodecJPEG};
    [stillImageOutput setOutputSettings:outputSettings];
    
    //添加输入输出流，并启动捕获
    if ([self.captureSession canAddInput:deviceInput]){
        [self.captureSession addInput:deviceInput];
        if ([self.captureSession canAddOutput:output]){
            [self.captureSession addOutput:stillImageOutput];
            [self.captureSession addOutput:output];
            //全局的layer
            self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
            self.previewLayer.videoGravity = @"AVLayerVideoGravityResizeAspectFill";//AVLayerVideoGravityResizeAspect;
            self.previewLayer.frame = self.bounds; //挪到了 layoutSubviews
            [self.layer addSublayer:self.previewLayer];
            [self initOtherLayers];//添加大的遮罩（扣掉小窗口）
            //开始捕获 （注意，需要在 initOtherLayers之后启动）
            [self startCaptureSession];
        }else{ NSLog(@"添加输出流错误"); }
    }else{ NSLog(@"添加输入流错误"); }
    if (error) { NSLog(@"设备错误:%@",error.description); }
}
- (void)startCaptureSession{//开始捕获
    if(self.captureSession){
        [self.captureSession startRunning];
    }
}
- (void)stopCaptureSession{//停止捕获
    if(self.captureSession){
        [self.captureSession stopRunning];
    }
}
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{//捕捉影像实时调用
     if (self.isStart) {
         [self settingCaptureVideoFocus];
         UIImage *image = [BYTools sampleBufferToImage:sampleBuffer];//实时获取的全景图
         UIImage *resultImage = [self cropImageInRect:image];//实时获取的捕捉脸部的小窗口里的图
         //判断人脸
         CIImage *ciImage = [[CIImage alloc] initWithImage:resultImage];
         NSDictionary *opts = [NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh forKey:CIDetectorAccuracy];
         CIDetector *faceDetector=[CIDetector detectorOfType:CIDetectorTypeFace context:nil options:opts];
         NSArray *results = [faceDetector featuresInImage:ciImage];
         //若要捕捉脸部表情，打开下方注释
//         NSDictionary *faceOpts=@{CIDetectorEyeBlink:@"true",//为true(bool类型的NSNumber)，识别器将提取眨眼特征。
//                                  CIDetectorSmile:@"true",//为ture(bool类型的NSNumber)，识别器将提取微笑特征。
//                                  };
//         NSArray *results = [faceDetector featuresInImage:ciImage options:faceOpts];
         if (results.count > 1) {//多张脸
             NSLog(@"多张脸---%zd",results.count);
             _successCount = 0;
             [self changeTipTextWithCaptureFaceStatus:102];//请保证只有一张人脸
         }else{
             if (results.count == 0) {//没有检测到脸
                 _successCount = 0;
                 if ([BYTools getAmbientBrightnessValue:sampleBuffer] < 1.0) {//正常采集到人脸是2.6左右、对着光是3.4左右，完全黑暗是-1左右
                      [self changeTipTextWithCaptureFaceStatus:107];//光线不足
                 }else{
                     [self changeTipTextWithCaptureFaceStatus:101];//请将人脸移动到识别区域
                 }
             }
             //脸部捕捉框用的坐标值
             CGFloat scale = self.cropRect.size.width / resultImage.size.width;
             CGFloat topMargin = (self.cropRect.size.height - resultImage.size.height * scale) * 0.5;
             for (CIFaceFeature *faceFeature in results) {
//                 if (faceFeature.hasSmile) {  NSLog(@"有微笑");}else{ NSLog(@"没有微笑"); }
//                 if (faceFeature.leftEyeClosed) {   NSLog(@"左眼闭着");}else{ NSLog(@"左眼睁开"); }
//                 if (faceFeature.rightEyeClosed) {    NSLog(@"右眼闭着");}else{ NSLog(@"右眼睁开"); }
//                 NSLog(@"左眼位置：%@",NSStringFromCGPoint(faceFeature.leftEyePosition));
//                 NSLog(@"右眼位置: %@",NSStringFromCGPoint(faceFeature.rightEyePosition));
//                 NSLog(@"嘴巴位置: %@",NSStringFromCGPoint(faceFeature.mouthPosition));
//                 NSLog(@"脸部区域：%@",NSStringFromCGRect(faceFeature.bounds));
                 if(faceFeature.hasLeftEyePosition && faceFeature.hasRightEyePosition && faceFeature.hasMouthPosition){//左眼右眼嘴
                     _successCount++;
                     [self changeTipTextWithCaptureFaceStatus:105];//请勿移动
                     if (_successCount >= 10) {//连续一张脸检测到10次以上才算成功
                         self.isStart = false;
                         [self changeTipTextWithCaptureFaceStatus:103];
                         [self handleResultImage:resultImage];
                     }
                 }else{
                     _successCount = 0;
                      [self changeTipTextWithCaptureFaceStatus:106];//请保持正脸
                 }
                 //处理脸部捕捉框
                 //脸部框
                 CALayer *faceLayer = [self getRedLayer];
                 faceLayer.frame = CGRectMake(faceFeature.bounds.origin.x * scale,topMargin + resultImage.size.height * scale - faceFeature.bounds.origin.y * scale - faceFeature.bounds.size.height * scale, faceFeature.bounds.size.width * scale, faceFeature.bounds.size.height * scale);
                 //嘴部框
                 CGFloat halfWidth = 5;
                 CALayer *mouthLayer = [self getRedLayer];
                 mouthLayer.frame = CGRectMake(faceFeature.mouthPosition.x * scale - halfWidth, topMargin + (resultImage.size.height - faceFeature.mouthPosition.y) * scale - halfWidth, halfWidth * 2, halfWidth * 2);
                 dispatch_async(dispatch_get_main_queue(), ^{
                     if (self.faceBoxView.layer.sublayers.count > 0) {
                         for (int i = (int)self.faceBoxView.layer.sublayers.count; i > 0; i--) {
                             [self.faceBoxView.layer.sublayers[i-1] removeFromSuperlayer];
                         }
                     }
                     [self.faceBoxView.layer addSublayer:faceLayer];
                     [self.faceBoxView.layer addSublayer:mouthLayer];
                 });
             }
         }
     }
}
- (CALayer *)getRedLayer{//红色的线框
    CALayer *redLayer = [[CALayer alloc] init];
    redLayer.borderWidth = 2;
    redLayer.borderColor = [UIColor redColor].CGColor;
    return redLayer;
}
- (void)settingCaptureVideoFocus{ //捕捉影像时调用
    NSError *error;
    CGPoint foucsPoint = CGPointMake(CGRectGetMidX(self.cropRect), CGRectGetMidY(self.cropRect));
    if([self.captureDevice isFocusPointOfInterestSupported]
       &&[self.captureDevice lockForConfiguration:&error] &&!self.hasSetFocus){
        self.hasSetFocus = YES;
        [self.captureDevice setFocusPointOfInterest:[self convertToPointOfInterestFromViewCoordinates:foucsPoint]];
        [self.captureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];//AVCaptureFocusModeAutoFocus
        [self.captureDevice unlockForConfiguration];
    }
    if (error) {NSLog(@"捕捉影像时调用error:%@",error);}
}

#pragma mark- 识别用到的工具类
- (UIImage*)cropImageInRect:(UIImage*)image{//获取捕捉脸部的小窗口里的图片
    CGSize size = [image size];
    CGRect cropRect = [self calcRect:size];
    float scale = fminf(1.0f, fmaxf(360 / cropRect.size.width, 360 / cropRect.size.height));
    CGPoint offset = CGPointMake(-cropRect.origin.x, -cropRect.origin.y);
    size_t subsetWidth = cropRect.size.width * scale;
    size_t subsetHeight = cropRect.size.height * scale;
//    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
//    CGContextRef ctx =CGBitmapContextCreate(nil,subsetWidth,subsetHeight,8,0,colorSpace,kCGImageAlphaNone|kCGBitmapByteOrderDefault);
    //上方的设置最终会变成黑白色图片
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(nil,subsetWidth,subsetHeight,8,0,colorSpace,kCGBitmapByteOrder32Little|kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    CGContextSetInterpolationQuality(ctx, kCGInterpolationNone);
    CGContextSetAllowsAntialiasing(ctx, false);
    CGContextTranslateCTM(ctx, 0.0, subsetHeight);
    CGContextScaleCTM(ctx, 1.0, -1.0);
    UIGraphicsPushContext(ctx);
    CGRect rect = CGRectMake(offset.x * scale, offset.y * scale, scale * size.width, scale * size.height);
    [image drawInRect:rect];
    UIGraphicsPopContext();
    CGContextFlush(ctx);
    CGImageRef subsetImageRef = CGBitmapContextCreateImage(ctx);
    UIImage* subsetImage = [UIImage imageWithCGImage:subsetImageRef];
    CGImageRelease(subsetImageRef);
    CGContextRelease(ctx);
    return subsetImage;
}
- (CGRect)calcRect:(CGSize)imageSize{//获取捕捉脸部的小窗口里的图标
    NSString* gravity = self.previewLayer.videoGravity;
    CGRect cropRect = self.cropRect;
    CGSize screenSize = self.previewLayer.bounds.size;
    CGFloat screenRatio = screenSize.height / screenSize.width ;
    CGFloat imageRatio = imageSize.height /imageSize.width;
    CGRect presentImageRect = self.previewLayer.bounds;
    CGFloat scale = 1.0;
    if([AVLayerVideoGravityResizeAspect isEqual: gravity]){
        CGFloat presentImageWidth = imageSize.width;
        CGFloat presentImageHeigth = imageSize.height;
        if(screenRatio > imageRatio){
            presentImageWidth = screenSize.width;
            presentImageHeigth = presentImageWidth * imageRatio;
        }else{
            presentImageHeigth = screenSize.height;
            presentImageWidth = presentImageHeigth / imageRatio;
        }
        presentImageRect.size = CGSizeMake(presentImageWidth, presentImageHeigth);
        presentImageRect.origin = CGPointMake((screenSize.width-presentImageWidth)/2.0, (screenSize.height-presentImageHeigth)/2.0);
    }else if([AVLayerVideoGravityResizeAspectFill isEqual:gravity]){
        CGFloat presentImageWidth = imageSize.width;
        CGFloat presentImageHeigth = imageSize.height;
        if(screenRatio > imageRatio){
            presentImageHeigth = screenSize.height;
            presentImageWidth = presentImageHeigth / imageRatio;
        }else{
            presentImageWidth = screenSize.width;
            presentImageHeigth = presentImageWidth * imageRatio;
        }
        presentImageRect.size = CGSizeMake(presentImageWidth, presentImageHeigth);
        presentImageRect.origin = CGPointMake((screenSize.width-presentImageWidth)/2.0, (screenSize.height-presentImageHeigth)/2.0);
    }else{ NSAssert(0, @"不支持:%@",gravity); }
    scale = CGRectGetWidth(presentImageRect) / imageSize.width;
    CGRect rect = cropRect;
    rect.origin = CGPointMake(CGRectGetMinX(cropRect)-CGRectGetMinX(presentImageRect), CGRectGetMinY(cropRect)-CGRectGetMinY(presentImageRect));
    rect.origin.x /= scale;
    rect.origin.y /= scale;
    rect.size.width /= scale;
    rect.size.height  /= scale;
    return rect;
}
- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates{//捕捉影像时调用-----获取x，y
    CGPoint pointOfInterest = CGPointMake(.5f, .5f);
    CGSize frameSize = self.frame.size;
    AVCaptureVideoPreviewLayer *videoPreviewLayer = self.previewLayer;
    if ([self.previewLayer isMirrored]) {
        viewCoordinates.x = frameSize.width - viewCoordinates.x;
    }
    if ( [[videoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResize] ) {
        pointOfInterest = CGPointMake(viewCoordinates.y / frameSize.height, 1.f - (viewCoordinates.x / frameSize.width));
    } else {
        CGRect cleanAperture;
        for (AVCaptureInputPort *port in [[[[self captureSession] inputs] lastObject] ports]) {
            if ([port mediaType] == AVMediaTypeVideo) {
                cleanAperture = CMVideoFormatDescriptionGetCleanAperture([port formatDescription], YES);
                CGSize apertureSize = cleanAperture.size;
                CGPoint point = viewCoordinates;
                CGFloat apertureRatio = apertureSize.height / apertureSize.width;
                CGFloat viewRatio = frameSize.width / frameSize.height;
                CGFloat xc = .5f;
                CGFloat yc = .5f;
                if ( [[videoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspect] ) {
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = frameSize.height;
                        CGFloat x2 = frameSize.height * apertureRatio;
                        CGFloat x1 = frameSize.width;
                        CGFloat blackBar = (x1 - x2) / 2;
                        if (point.x >= blackBar && point.x <= blackBar + x2) {
                            xc = point.y / y2;
                            yc = 1.f - ((point.x - blackBar) / x2);
                        }
                    } else {
                        CGFloat y2 = frameSize.width / apertureRatio;
                        CGFloat y1 = frameSize.height;
                        CGFloat x2 = frameSize.width;
                        CGFloat blackBar = (y1 - y2) / 2;
                        if (point.y >= blackBar && point.y <= blackBar + y2) {
                            xc = ((point.y - blackBar) / y2);
                            yc = 1.f - (point.x / x2);
                        }
                    }
                } else if ([[videoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = apertureSize.width * (frameSize.width / apertureSize.height);
                        xc = (point.y + ((y2 - frameSize.height) / 2.f)) / y2;
                        yc = (frameSize.width - point.x) / frameSize.width;
                    } else {
                        CGFloat x2 = apertureSize.height * (frameSize.height / apertureSize.width);
                        yc = 1.f - ((point.x + ((x2 - frameSize.width) / 2)) / x2);
                        xc = point.y / frameSize.height;
                    }
                }
                pointOfInterest = CGPointMake(xc, yc);
                break;
            }
        }
    }
    return pointOfInterest;
}


@end
