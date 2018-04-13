//
//  FramesShowViewController.m
//  WaterMarkDelete
//
//  Created by WangYiming on 2018/4/10.
//  Copyright © 2018年 WangYiming. All rights reserved.
//

#import "FramesShowViewController.h"

@interface FramesShowViewController ()
@property(strong,nonatomic) UIImageView *imageView;
@end

@implementation FramesShowViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.imageView = [[UIImageView alloc] initWithFrame:[[UIScreen mainScreen]bounds]];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.imageView];
    
    AVAsset *movieAsset = [AVAsset assetWithURL:self.videoUrl]; // fileUrl:文件路径
    int second = (int)movieAsset.duration.value / movieAsset.duration.timescale; // 获取视频总时长,单位秒
    for (float i = 0.0; i < second;) {
        self.imageView.image = [self getVideoPreViewImageByTime:1];
        i += 0.1;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIImage *)getVideoPreViewImageByTime:(float)t

{
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:self.videoUrl options:nil];
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    gen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(t, 1); //0.0  600
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *img = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    
    return img;
}

@end
