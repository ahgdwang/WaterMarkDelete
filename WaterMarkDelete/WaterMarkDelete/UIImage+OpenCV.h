//
//  UIImage+OpenCV.h
//  WaterMarkDelete
//
//  Created by WangYiming on 2018/4/8.
//  Copyright © 2018年 WangYiming. All rights reserved.
//


#import <opencv2/opencv.hpp>
#import <opencv2/imgproc/imgproc_c.h>
#import <opencv2/highgui/highgui_c.h>
#import <opencv2/photo/photo_c.h>

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
@interface UIImage (UIImage_OpenCV)
-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat;
-(id)WaterMarkDelete:(CGRect) rect;
-(UIImage *)fixOrientation;
@property(nonatomic, readonly) cv::Mat CVMat;
@property(nonatomic, readonly) cv::Mat CVGrayscaleMat;
@end
