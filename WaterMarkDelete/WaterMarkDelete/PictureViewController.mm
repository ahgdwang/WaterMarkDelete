//
//  PictureViewController.m
//  WaterMarkDelete
//
//  Created by WangYiming on 2018/4/6.
//  Copyright © 2018年 WangYiming. All rights reserved.
//
#import "PictureViewController.h"
#import "UIImage+OpenCV.h"
@interface PictureViewController ()
@property(strong,nonatomic) UIImageView *imageView;
@property(assign,nonatomic) CGPoint startPoint;
@property(strong,nonatomic) ClipView *clipView;
@property(assign,nonatomic) CGFloat factor_scale;
@property(assign,nonatomic) CGPoint offsetImageToImageView;
@end

@implementation PictureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    CGRect screen = [[UIScreen mainScreen]bounds];
    CGFloat imageLayerwidth = screen.size.width;
    CGFloat imageLayerTopView = 65;
    
    self.navigationItem.title = @"图片去水印";
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onSave:)];
    self.navigationItem.rightBarButtonItem = saveButton;
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, imageLayerTopView, imageLayerwidth, screen.size.height - imageLayerTopView)];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.imageView];
    self.imageView.image = self.image;
    

}
- (void)viewWillAppear:(BOOL)animated{
    self.clipView = [[ClipView alloc] init];
    [self.imageView addSubview:self.clipView];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [self.imageView addGestureRecognizer:pan];
    self.imageView.userInteractionEnabled = YES;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma action
- (void)onSave:(id)sender{
    UIImageWriteToSavedPhotosAlbum(self.imageFinished, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    
    if (error == nil) {
        NSString *message = @"保存成功";
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示信息" message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:ok];
        [self presentViewController:alert animated:YES completion:nil];
    }else{
        NSString *message = @"保存失败";
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示信息" message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:ok];
        [self presentViewController:alert animated:YES completion:nil];
    }
    
}

#pragma defineBySelf
- (CGPoint)pickerPointJudge:(UIImageView*)imageView pointInView:(CGPoint)point{
    CGPoint tempPoint = CGPointMake(0, 0);
    CGFloat factor_frame = imageView.frame.size.width/imageView.frame.size.height;
    CGFloat factor_image = self.image.size.width/self.image.size.height;
    if (factor_frame < factor_image) {  //固定宽缩放
        self.factor_scale = imageView.frame.size.width/self.image.size.width;
        tempPoint.x = point.x;
        CGPoint offset = CGPointMake(0, 0.5*(imageView.frame.size.height - self.image.size.height * self.factor_scale));
        self.offsetImageToImageView = offset;
        if (point.y < 0.5*(imageView.frame.size.height - self.image.size.height * self.factor_scale)) {
            tempPoint.y = 0.5*(imageView.frame.size.height - self.image.size.height * self.factor_scale);
        }else if (point.y > 0.5*(imageView.frame.size.height + self.image.size.height * self.factor_scale)){
            tempPoint.y = 0.5*(imageView.frame.size.height + self.image.size.height * self.factor_scale);
        }
        else{
            tempPoint.y = point.y;
        }
    }else{
        self.factor_scale = imageView.frame.size.height/self.image.size.height;
        tempPoint.y = point.y;
        CGPoint offset = CGPointMake(0.5*(imageView.frame.size.width - self.image.size.width * self.factor_scale),0);
        self.offsetImageToImageView = offset;
        if (point.x < 0.5*(imageView.frame.size.width - self.image.size.width * self.factor_scale)) {
            tempPoint.x = 0.5*(imageView.frame.size.width - self.image.size.width * self.factor_scale);
        }else if (point.x > 0.5*(imageView.frame.size.width + self.image.size.width * self.factor_scale)){
            tempPoint.x = 0.5*(imageView.frame.size.width + self.image.size.width * self.factor_scale);
        }else{
            tempPoint.x = point.x;
        }
    }
    return tempPoint;
}
- (UIImage *)cropImage:(UIImage*)image toRect:(CGRect)rect {
    CGFloat (^rad)(CGFloat) = ^CGFloat(CGFloat deg) {
        return deg / 180.0f * (CGFloat) M_PI;
    };
    // determine the orientation of the image and apply a transformation to the crop rectangle to shift it to the correct position
    CGAffineTransform rectTransform;
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(90)), 0, -image.size.height);
            break;
        case UIImageOrientationRight:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(-90)), -image.size.width, 0);
            break;
        case UIImageOrientationDown:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(-180)), -image.size.width, -image.size.height);
            break;
        default:
            rectTransform = CGAffineTransformIdentity;
    };
    
    // adjust the transformation scale based on the image scale
    rectTransform = CGAffineTransformScale(rectTransform, image.scale, image.scale);
    
    // apply the transformation to the rect to create a new, shifted rect
    CGRect transformedCropSquare = CGRectApplyAffineTransform(rect, rectTransform);
    // use the rect to crop the image
    CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, transformedCropSquare);
    // create a new UIImage and set the scale and orientation appropriately
    UIImage *result = [UIImage imageWithCGImage:imageRef scale:image.scale orientation:image.imageOrientation];
    // memory cleanup
    CGImageRelease(imageRef);
    
    return result;
}
-(void)pan:(UIPanGestureRecognizer*)panner{
    CGPoint endPoint = CGPointZero;
    if (panner.state == UIGestureRecognizerStateBegan) {
        self.startPoint = [self pickerPointJudge:self.imageView pointInView:[panner locationInView:self.imageView]];
    }
    else if (panner.state == UIGestureRecognizerStateChanged){
        endPoint = [self pickerPointJudge:self.imageView pointInView:[panner locationInView:self.imageView]];
        CGFloat clipWidth = endPoint.x - self.startPoint.x;
        CGFloat clipHeight = endPoint.y - self.startPoint.y;
        
        self.clipView.frame = CGRectMake(self.startPoint.x, self.startPoint.y, clipWidth, clipHeight);
        
    }
    else if (panner.state == UIGestureRecognizerStateEnded){
        CGRect rectInImage = CGRectMake((self.clipView.frame.origin.x - self.offsetImageToImageView.x)/ self.factor_scale, (self.clipView.frame.origin.y - self.offsetImageToImageView.y) / self.factor_scale, self.clipView.frame.size.width/ self.factor_scale, self.clipView.frame.size.height/ self.factor_scale);
        //UIImage *imageCut = [self cropImage:self.image toRect:rectInImage];
        self.imageFinished = [self.image WaterMarkDelete:rectInImage];
        
        [self.imageView setImage:self.imageFinished];
        [self.clipView removeFromSuperview];
        self.clipView = nil;
        [self viewWillAppear:YES];
    }
}
@end
