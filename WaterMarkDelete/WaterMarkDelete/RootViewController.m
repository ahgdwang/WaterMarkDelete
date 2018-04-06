//
//  RootViewController.m
//  WaterMarkDelete
//
//  Created by WangYiming on 2018/4/6.
//  Copyright © 2018年 WangYiming. All rights reserved.
//

#import "RootViewController.h"

@interface RootViewController ()

@end

@implementation RootViewController

#pragma life circle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    CGRect screen = [[UIScreen mainScreen] bounds];
    CGFloat button_width = 100;
    CGFloat button_height = 100;
    CGFloat button_top_view = 260;
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGColorRef colorRef = CGColorCreate(colorspace, (CGFloat[]){0,0,0,1});
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = @"去除水印";
    
    
    UIButton *videoDelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    videoDelButton.frame = CGRectMake(0.5*(screen.size.width - button_width) - 100, button_top_view, button_width, button_height);
    videoDelButton.titleLabel.font = [UIFont systemFontOfSize:20];
    [videoDelButton.titleLabel sizeToFit];
    [videoDelButton setTitle:@"视频去除" forState:UIControlStateNormal];
    [videoDelButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    videoDelButton.layer.borderColor = colorRef;
    [videoDelButton.layer setBorderWidth:2.0];
    [videoDelButton.layer setCornerRadius:12.0];
    [videoDelButton.layer setMasksToBounds:YES];
    [videoDelButton addTarget:self action:@selector(onClickVideoButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:videoDelButton];
    
    UIButton *imageDelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    imageDelButton.frame = CGRectMake(videoDelButton.frame.origin.x + 200, button_top_view, button_width, button_height);
    imageDelButton.titleLabel.font = [UIFont systemFontOfSize:20];
    [imageDelButton.titleLabel sizeToFit];
    [imageDelButton setTitle:@"图片去除" forState:UIControlStateNormal];
    [imageDelButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [imageDelButton.layer setBorderColor:colorRef];
    [imageDelButton.layer setBorderWidth:2.0];
    [imageDelButton.layer setCornerRadius:12.0];
    [imageDelButton.layer setMasksToBounds:YES];
    [imageDelButton addTarget:self action:@selector(onClickImageButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:imageDelButton];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma action
- (void)onClickVideoButton{
    
}

- (void)onClickImageButton{
    
}
@end
