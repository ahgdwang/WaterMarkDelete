//
//  PictureViewController.h
//  WaterMarkDelete
//
//  Created by WangYiming on 2018/4/6.
//  Copyright © 2018年 WangYiming. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <GPUImage/GPUImage.h>
#import "ClipView.h"
#import <Photos/Photos.h>
@interface PictureViewController : UIViewController
@property(strong,nonatomic) UIImage *image;
@property(strong,nonatomic) UIImage *imageFinished;
@end
