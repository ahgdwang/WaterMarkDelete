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
    
//    UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
//    ipc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;//sourcetype有三种分别是camera，photoLibrary和photoAlbum
//    NSArray *availableMedia = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];//Camera所支持的Media格式都有哪些,共有两个分别是@"public.image",@"public.movie"
//    ipc.mediaTypes = [NSArray arrayWithObject:availableMedia[1]];//设置媒体类型为public.movie
//    [self presentViewController:ipc animated:YES completion:nil];
//    ipc.delegate = self;//设置委托
}

- (void)onClickImageButton{
    UIAlertController *actionSheet = [[UIAlertController alloc] init];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"取消操作");
        [self showToast:@"操作已取消"];
    }];
    
    UIAlertAction *takePhoto = [UIAlertAction actionWithTitle:@"拍照" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"拍照");
        [self takePhoto];
    }];
    
    UIAlertAction *fromPictures = [UIAlertAction actionWithTitle:@"从相册中选择" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"从相册中选择图像");
        [self fromPictures];
    }];
    [actionSheet addAction:cancel];
    [actionSheet addAction:takePhoto];
    [actionSheet addAction:fromPictures];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}
#pragma imagePickerDelegate
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    PictureViewController *pictureViewController = [[PictureViewController alloc] init];
    pictureViewController.image = image;
    [self.navigationController pushViewController:pictureViewController animated:YES];
    
}
#pragma defineBySelf
-(void)showToast:(NSString *)str{
    MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:self.view];
    HUD.label.text = str;
    HUD.mode = MBProgressHUDModeText;
    [HUD setOffset:CGPointMake(0.0f, 300.0f)];
    HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
    HUD.bezelView.color = [[UIColor whiteColor] colorWithAlphaComponent:0.2];
    [self.view addSubview:HUD];
    [HUD showAnimated:YES];
    dispatch_async(dispatch_get_global_queue(NSQualityOfServiceUserInteractive, 0), ^{
        sleep(1);
        dispatch_async(dispatch_get_main_queue(), ^{
            [HUD hideAnimated:YES];

        });
    });
    HUD = nil;
}
-(void)takePhoto{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePickerController.allowsEditing = NO;
    imagePickerController.delegate = self;

    [self presentViewController:imagePickerController animated:YES completion:nil];
}
-(void)fromPictures{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickerController.allowsEditing = NO;
    imagePickerController.delegate = self;
    
    [self presentViewController:imagePickerController animated:YES completion:nil];
}
@end
