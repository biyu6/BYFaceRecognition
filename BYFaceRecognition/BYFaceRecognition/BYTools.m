//
//  BYTools.m
//  BYFaceRecognition
//
//  Created by 胡忠诚 on 2019/8/22.
//  Copyright © 2019 ether. All rights reserved.
//我的工具类

#import "BYTools.h"

@implementation BYTools
//检测相机权限：准许返回YES;否则返回NO
+ (BOOL)isCapturePermissionGranted{
    if([AVCaptureDevice respondsToSelector:@selector(authorizationStatusForMediaType:)]){
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if(authStatus ==AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied){
            return NO;
        }else if(authStatus==AVAuthorizationStatusNotDetermined){
            dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            __block BOOL isGranted=YES;
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                isGranted=granted;
                dispatch_semaphore_signal(sema);
            }];
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
            return isGranted;
        }else{
            return YES;
        }
    }else{
        return YES;
    }
}

//CMSampleBufferRef转为图片
+ (UIImage *)sampleBufferToImage:(CMSampleBufferRef)sampleBuffer{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIContext *temporaryContext = [CIContext contextWithOptions:nil];
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:imageBuffer];//[CIImage imageWithCGImage:images.CGImage];
    CGRect imgFrame = CGRectMake(0, 0, CVPixelBufferGetWidth(imageBuffer), CVPixelBufferGetHeight(imageBuffer));
    CGImageRef videoImage = [temporaryContext createCGImage:ciImage fromRect:imgFrame];
    UIImage *result = [[UIImage alloc] initWithCGImage:videoImage scale:1.0 orientation:UIImageOrientationLeftMirrored];
    CGImageRelease(videoImage);
    return result;
}

//获取摄像头感知的环境光亮度（测试：人脸是2.6左右、对着光是3.4左右，完全黑暗是-1左右）
+ (float )getAmbientBrightnessValue:(CMSampleBufferRef)sampleBuffer{
    CFDictionaryRef metadataDict = CMCopyDictionaryOfAttachments(NULL,sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    NSDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:(__bridge NSDictionary*)metadataDict];
    CFRelease(metadataDict);
    NSDictionary *exifMetadata = [[metadata objectForKey:(NSString *)kCGImagePropertyExifDictionary] mutableCopy];
    float brightnessValue = [[exifMetadata objectForKey:(NSString *)kCGImagePropertyExifBrightnessValue] floatValue];
    NSLog(@"环境光亮度：%f",brightnessValue);
    return brightnessValue;
}


@end
