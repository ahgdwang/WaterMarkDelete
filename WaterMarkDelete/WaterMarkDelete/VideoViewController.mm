//
//  VideoViewController.m
//  WaterMarkDelete
//
//  Created by WangYiming on 2018/4/10.
//  Copyright © 2018年 WangYiming. All rights reserved.
//

#import "VideoViewController.h"
#import "ClipView.h"
#import "FramesShowViewController.h"
#import "UIImage+OpenCV.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "HJImagesToVideo.h"
#import <Photos/Photos.h>
@interface VideoViewController ()
{
    AVPlayer *player;
    int second; // 获取视频总时长,单位秒
    CGRect rectInImage;
    BOOL rectDraw;
}
@property(strong,nonatomic) ClipView *clipView;
@property(strong,nonatomic) UIView *videoView;
@property(strong,nonatomic) AVPlayerViewController *playerVC;
@property(assign,nonatomic) CGPoint startPoint;
@property(assign,nonatomic) CGFloat factor_scale;
@property(assign,nonatomic) CGPoint offsetImageToImageView;
@property(strong,nonatomic) UIImage *image;
@property(strong,nonatomic) AVAssetTrack *srcAudioTrack;
@property(strong,nonatomic) NSURL *picsTovideoPath;
@property(strong,nonatomic) NSMutableArray *imageArray;
@property(strong,nonatomic) AVAsset *movieAsset;

@property(strong,nonatomic) UIProgressView *progressView;

@end

@implementation VideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    CGFloat bottomheight = 80.0f;
    self.view.backgroundColor = [UIColor whiteColor];
    CGRect screen = [[UIScreen mainScreen]bounds];
    self.videoView = [[UIView alloc] initWithFrame:CGRectMake(0, self.navigationController.navigationBar.frame.size.height, screen.size.width, screen.size.height - self.navigationController.navigationBar.frame.size.height - bottomheight)];
    self.videoView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.videoView];
    self.navigationItem.title = @"视频水印去除";
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onClickSave:)];
    saveButton.title = @"执行";
    self.navigationItem.rightBarButtonItem = saveButton;
    UIView *progressBottomView = [[UIView alloc] initWithFrame:CGRectMake(0, screen.size.height - bottomheight, screen.size.width, bottomheight)];
    
    self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(20, 0, screen.size.width - 40, bottomheight)];
    //设置进度条位置（水平居中）
    self.progressView.layer.position = CGPointMake(screen.size.width/2,bottomheight/2);
    //通过变形改变进度条高度（ 横向宽度不变，纵向高度变成默认的5倍）
    self.progressView.transform = CGAffineTransformMakeScale(1.0, 10.0);
    [progressBottomView addSubview:self.progressView];
    [self.view addSubview:progressBottomView];
    
    //载入播放器
    player = [AVPlayer playerWithURL:self.videoUrl];
    self.playerVC = [[AVPlayerViewController alloc]init];
    self.playerVC.player = player;
    self.playerVC.view.frame = CGRectMake(0, 0, self.videoView.frame.size.width, self.videoView.frame.size.height);
    player.externalPlaybackVideoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.videoView addSubview:self.playerVC.view];
    self.playerVC.showsPlaybackControls = NO;
    
    FramesShowViewController *framesShowCon = [[FramesShowViewController alloc] init];
    framesShowCon.videoUrl = self.videoUrl;
    //[self presentViewController:framesShowCon animated:YES completion:nil];
    self.movieAsset = [AVAsset assetWithURL:self.videoUrl]; // fileUrl:文件路径
    second = (int)self.movieAsset.duration.value / self.movieAsset.duration.timescale; // 获取视频总时长,单位秒

    //取第1帧
    self.image = [self getVideoPreViewImage];
//    //获取音频音轨
//    AVAsset *srcAsset  = [AVAsset assetWithURL:self.videoUrl];
//    NSArray *trackArray = [srcAsset tracksWithMediaType:AVMediaTypeAudio];
//    self.srcAudioTrack = [trackArray  objectAtIndex:0];
    //self.imageArray = [[NSMutableArray alloc] init];
    //self.imageArray = nil;
}
- (void)viewWillAppear:(BOOL)animated{
    self.clipView = [[ClipView alloc] init];
    [self.videoView addSubview:self.clipView];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [self.videoView addGestureRecognizer:pan];
    self.videoView.userInteractionEnabled = YES;
    [self.navigationItem.rightBarButtonItem setEnabled:YES];
    [player play];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark --onClickSave
-(void)onClickSave:(id)sender{
    if (rectDraw) {
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
        CGRect waterMarkRect = rectInImage;
        [self.progressView setProgress:0.2];
        //处理每一帧
        [self splitVideo:self.videoUrl fps:30 splitCompleteBlock:^(BOOL success, NSMutableArray *splitimgs) {
            if (success && splitimgs.count != 0) {
                NSLog(@"----->> success");
                NSLog(@"---> splitimgs个数:%lu",(unsigned long)splitimgs.count);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.progressView setProgress:0.35];
                    NSMutableArray *imageArrayFinished = [[NSMutableArray alloc] init];
                    for (int i=0; i<[splitimgs count];) {
                        UIImage *imageOir = [splitimgs objectAtIndex:i];
                        UIImage *imageFinished = [imageOir WaterMarkDelete:waterMarkRect];
                        [self.progressView setProgress:0.5];
                        [imageArrayFinished addObject:imageFinished];
                        imageFinished = nil;
                        i = i + 1;
                    }
                    //合成视频
                    [self fromPicsToVideo:imageArrayFinished];
                });
            }
        }];
    }
}

#pragma mark --panGesture
-(void)pan:(UIPanGestureRecognizer*)panner{
    CGPoint endPoint = CGPointZero;
    if (panner.state == UIGestureRecognizerStateBegan) {
        self.startPoint = [self pickerPointJudge:self.videoView pointInView:[panner locationInView:self.videoView]];
    }
    else if (panner.state == UIGestureRecognizerStateChanged){
        endPoint = [self pickerPointJudge:self.videoView pointInView:[panner locationInView:self.videoView]];;
        
        CGFloat clipWidth = endPoint.x - self.startPoint.x;
        CGFloat clipHeight = endPoint.y - self.startPoint.y;
        
        self.clipView.frame = CGRectMake(self.startPoint.x, self.startPoint.y, clipWidth, clipHeight);
    }
    else if (panner.state == UIGestureRecognizerStateEnded){
        rectInImage = CGRectMake((self.clipView.frame.origin.x - self.offsetImageToImageView.x)/ self.factor_scale, (self.clipView.frame.origin.y - self.offsetImageToImageView.y) / self.factor_scale, self.clipView.frame.size.width/ self.factor_scale, self.clipView.frame.size.height/ self.factor_scale);
            rectDraw = YES;
//        CGRect waterMarkRect = rectInImage;
//        //处理每一帧
//        [self splitVideo:self.videoUrl fps:30 splitCompleteBlock:^(BOOL success, NSMutableArray *splitimgs) {
//            if (success && splitimgs.count != 0) {
//                NSLog(@"----->> success");
//                NSLog(@"---> splitimgs个数:%lu",(unsigned long)splitimgs.count);
//                dispatch_async(dispatch_get_main_queue(), ^{
//                NSMutableArray *imageArrayFinished = [[NSMutableArray alloc] init];
//                for (int i=0; i<[splitimgs count];) {
//                    UIImage *imageOir = [splitimgs objectAtIndex:i];
//                    UIImage *imageFinished = [imageOir WaterMarkDelete:waterMarkRect];
//                    [imageArrayFinished addObject:imageFinished];
//                    imageFinished = nil;
//                    i = i + 1;
//                }
//                    //合成视频
//                    [self fromPicsToVideo:imageArrayFinished];
//                    
//                    [self.clipView removeFromSuperview];
//                    self.clipView = nil;
//                    [self viewWillAppear:YES];
//                });
//            }
//        }];
        
        
        
        
        
        
        //[self frameProsess:rectInImage];
        //[self savepics];
        //[self fromPicsToVideo:self.imageArray];
        
        //[self addAudioToVideo:self.srcAudioTrack videoURL:self.picsTovideoPath];
        
//        [self.clipView removeFromSuperview];
//        self.clipView = nil;
//        [self viewWillAppear:YES];
    }
}
#pragma mark --Imagealgorithm
-(void) frameProsess:(CGRect) waterMaskRect{
    //处理每一帧
    [self splitVideo:self.videoUrl fps:30 splitCompleteBlock:^(BOOL success, NSMutableArray *splitimgs) {
        if (success && splitimgs.count != 0) {
            NSLog(@"----->> success");
            NSLog(@"---> splitimgs个数:%lu",(unsigned long)splitimgs.count);
            NSMutableArray *imageArrayFinished = [[NSMutableArray alloc] init];
            for (int i=0; i<[splitimgs count];) {
                UIImage *imageFinished = [[splitimgs objectAtIndex:i] WaterMarkDelete:waterMaskRect];
                [imageArrayFinished addObject:imageFinished];
            }
            //合成视频
            [self fromPicsToVideo:imageArrayFinished];
        }
    }];
}
- (void)splitVideo:(NSURL *)fileUrl fps:(float)fps splitCompleteBlock:(void(^)(BOOL success, NSMutableArray *splitimgs))splitCompleteBlock  {
    if (!fileUrl) {
        return;
    }
    NSMutableArray *splitImages = [NSMutableArray array];
    NSDictionary *optDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *avasset = [[AVURLAsset alloc] initWithURL:fileUrl options:optDict];
    
    CMTime cmtime = avasset.duration; //视频时间信息结构体
    Float64 durationSeconds = CMTimeGetSeconds(cmtime); //视频总秒数
    NSMutableArray *times = [NSMutableArray array];
    Float64 totalFrames = durationSeconds * fps; //获得视频总帧数
    CMTime timeFrame;
    for (int i = 1; i <= totalFrames; i++) {
        timeFrame = CMTimeMake(i, fps); //第i帧 帧率
        NSValue *timeValue = [NSValue valueWithCMTime:timeFrame];
        [times addObject:timeValue];
    }
    AVAssetImageGenerator *imgGenerator = [[AVAssetImageGenerator alloc] initWithAsset:avasset]; //防止时间出现偏差
    imgGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    imgGenerator.requestedTimeToleranceAfter = kCMTimeZero;
    NSInteger timesCount = [times count];  // 获取每一帧的图片
    [imgGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime, CGImageRef _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
        NSLog(@"current-----: %lld", requestedTime.value);
        NSLog(@"timeScale----: %d",requestedTime.timescale); // 帧率
        BOOL    isSuccess = NO;
        switch (result) {
            case AVAssetImageGeneratorCancelled:
                NSLog(@"Cancelled");
                break;
            case AVAssetImageGeneratorFailed:
                NSLog(@"Failed");
                break;
            case AVAssetImageGeneratorSucceeded: {
                UIImage *frameImg = [UIImage imageWithCGImage:image];
                UIImage *frameFit = [self reSizeImage:frameImg toSize:CGSizeMake((int)frameImg.size.width - (int)frameImg.size.width%16, (int)frameImg.size.height - (int)frameImg.size.height%16)];
                [splitImages addObject:frameFit];
                if (requestedTime.value == timesCount)  {
                    isSuccess = YES;
                    NSLog(@"completed");
                }
            }
                break;
        }
        if (splitCompleteBlock) {
            splitCompleteBlock(isSuccess,splitImages);
        }
    }];
}
- (UIImage*) getVideoPreViewImage
{
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:self.videoUrl options:nil];
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    gen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(0.0, 600);
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *img = [[UIImage alloc] initWithCGImage:image];
    UIImage *imgFit = [self reSizeImage:img toSize:CGSizeMake((int)img.size.width - (int)img.size.width%16, (int)img.size.height - (int)img.size.height%16)];
    CGImageRelease(image);
    return imgFit;
}
- (CGPoint)pickerPointJudge:(UIView*)imageView pointInView:(CGPoint)point{
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
        if (point.y > self.videoView.bounds.origin.y + self.videoView.frame.size.height) {
            point.y = self.videoView.bounds.origin.y + self.videoView.frame.size.height;
        }
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
-(void)fromPicsToVideo:(NSMutableArray *)imageArray{
    //设置mov路径
    NSArray *paths =NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES);
    NSString *moviePath =[[paths objectAtIndex:0]stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4",@"temp"]];
    self.picsTovideoPath = [NSURL fileURLWithPath:moviePath];
    NSFileManager* fileManager=[NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:moviePath]) {
        NSLog(@" have");
        BOOL blDele= [fileManager removeItemAtPath:moviePath error:nil];
        if (blDele) {
            NSLog(@"dele success");
        }else {
            NSLog(@"dele fail");
        }
    }
    //定义视频的大小
    CGSize size =CGSizeMake(self.image.size.width,self.image.size.height);
    NSError *error =nil;
    // 转成UTF-8编码
    unlink([moviePath UTF8String]);
    NSLog(@"path->%@",moviePath);
    //     iphone提供了AVFoundation库来方便的操作多媒体设备，AVAssetWriter这个类可以方便的将图像和音频写成一个完整的视频文件
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:moviePath] fileType:AVFileTypeQuickTimeMovie error:&error];
    NSParameterAssert(videoWriter);
    if(error)
        NSLog(@"error =%@", [error localizedDescription]);
    //mov的格式设置 编码格式 宽度 高度
    NSDictionary *videoSettings =[NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecTypeH264,AVVideoCodecKey,
                                  [NSNumber numberWithInt:size.width],AVVideoWidthKey,
                                  [NSNumber numberWithInt:size.height],AVVideoHeightKey,nil];
    
    AVAssetWriterInput *writerInput =[AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
    NSDictionary*sourcePixelBufferAttributesDictionary =[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32ARGB],kCVPixelBufferPixelFormatTypeKey,nil];
    //    AVAssetWriterInputPixelBufferAdaptor提供CVPixelBufferPool实例,
    //    可以使用分配像素缓冲区写入输出文件。使用提供的像素为缓冲池分配通常
    //    是更有效的比添加像素缓冲区分配使用一个单独的池
    AVAssetWriterInputPixelBufferAdaptor *adaptor =[AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    
    NSParameterAssert(writerInput);
    NSParameterAssert([videoWriter canAddInput:writerInput]);
    
    if ([videoWriter canAddInput:writerInput])
    {
        NSLog(@"videoWriter canAddInput:writerInput");
    }
    else
    {
        NSLog(@"videoWriter cannotAddInput:writerInput");
    }
    
    [videoWriter addInput:writerInput];
    
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    //合成多张图片为一个视频文件
    int total_frame = second * 30;
    int frames = (int)self.movieAsset.duration.value;
    int step = frames/total_frame;
    dispatch_queue_t dispatchQueue =dispatch_queue_create("mediaInputQueue",NULL);
    int __block frame =0;
    [writerInput requestMediaDataWhenReadyOnQueue:dispatchQueue usingBlock:^{
        
        while([writerInput isReadyForMoreMediaData])
        {
            if(++frame >=[imageArray count] * step)
            {
                [writerInput markAsFinished];
                [videoWriter finishWritingWithCompletionHandler:^(){
                    NSLog (@"finished writing");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.progressView setProgress:0.75];
                        [self addAudioToVideo:self.srcAudioTrack videoURL:self.picsTovideoPath];
                    });
                }];
                break;
            }
            CVPixelBufferRef buffer =NULL;
            int idx =frame / step;
            NSLog(@"idx==%d",idx);
            buffer = (CVPixelBufferRef)[self pixelBufferFromCGImage:[[imageArray objectAtIndex:idx] CGImage] size:size];
            
            if (buffer)
            {
                if(![adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeMake(frame,600)])//设置每秒钟播放图片的个数
                {
                    NSLog(@"FAIL");
                }
                else
                {
                    NSLog(@"OK");
                }
                
                CFRelease(buffer);
            }
        }
    }];
}
- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image size:(CGSize)size
{
    NSDictionary *options =[NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithBool:YES],kCVPixelBufferCGImageCompatibilityKey,
                            [NSNumber numberWithBool:YES],kCVPixelBufferCGBitmapContextCompatibilityKey,nil];
    CVPixelBufferRef pxbuffer =NULL;
    CVReturn status =CVPixelBufferCreate(kCFAllocatorDefault,size.width,size.height,kCVPixelFormatType_32ARGB,(__bridge CFDictionaryRef) options,&pxbuffer);
    
    NSParameterAssert(status ==kCVReturnSuccess && pxbuffer !=NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer,0);
    
    void *pxdata =CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata !=NULL);
    CGColorSpaceRef rgbColorSpace=CGColorSpaceCreateDeviceRGB();
    //    当你调用这个函数的时候，Quartz创建一个位图绘制环境，也就是位图上下文。当你向上下文中绘制信息时，Quartz把你要绘制的信息作为位图数据绘制到指定的内存块。一个新的位图上下文的像素格式由三个参数决定：每个组件的位数，颜色空间，alpha选项
    CGContextRef context =CGBitmapContextCreate(pxdata,size.width,size.height,8,4*size.width,rgbColorSpace,kCGImageAlphaPremultipliedFirst);
    NSParameterAssert(context);
    
    //使用CGContextDrawImage绘制图片  这里设置不正确的话 会导致视频颠倒
    //    当通过CGContextDrawImage绘制图片到一个context中时，如果传入的是UIImage的CGImageRef，因为UIKit和CG坐标系y轴相反，所以图片绘制将会上下颠倒
    CGContextDrawImage(context,CGRectMake(0,0,CGImageGetWidth(image),CGImageGetHeight(image)), image);
    // 释放色彩空间
    CGColorSpaceRelease(rgbColorSpace);
    // 释放context
    CGContextRelease(context);
    // 解锁pixel buffer
    CVPixelBufferUnlockBaseAddress(pxbuffer,0);
    
    return pxbuffer;
}

-(void)addAudioToVideo:(AVAssetTrack*)srcAudioTrack videoURL:(NSURL*)videoURL{
    // mbp提示框
    //[MBProgressHUD showMessage:@"正在处理中"];
    // 路径
    NSArray *paths =NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES);
    NSString *outPutFilePath =[[paths objectAtIndex:0]stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4",@"merge"]];
    NSFileManager* fileManager=[NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:outPutFilePath]) {
        NSLog(@" have");
        BOOL blDele= [fileManager removeItemAtPath:outPutFilePath error:nil];
        if (blDele) {
            NSLog(@"dele success");
        }else {
            NSLog(@"dele fail");
        }
    }
    // 添加合成路径
    NSURL *outputFileUrl = [NSURL fileURLWithPath:outPutFilePath];
    // 时间起点
    CMTime nextClistartTime = kCMTimeZero;
    // 创建可变的音视频组合
    AVMutableComposition *comosition = [AVMutableComposition composition];
    // 视频采集
    AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:self.picsTovideoPath options:nil];
    // 视频时间范围
    CMTimeRange videoTimeRange = CMTimeRangeMake(kCMTimeZero, videoAsset.duration);
    // 视频通道 枚举 kCMPersistentTrackID_Invalid = 0
    AVMutableCompositionTrack *videoTrack = [comosition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    // 视频采集通道
    AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    //  把采集轨道数据加入到可变轨道之中
    [videoTrack insertTimeRange:videoTimeRange ofTrack:videoAssetTrack atTime:nextClistartTime error:nil];
    
     //声音采集
    // 因为视频短这里就直接用视频长度了,如果自动化需要自己写判断
    CMTimeRange audioTimeRange = videoTimeRange;
    // 音频通道
    AVMutableCompositionTrack *audioTrack = [comosition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    // 加入合成轨道之中
    AVAsset *srcAsset  = [AVAsset assetWithURL:self.videoUrl];
    NSArray *trackArray = [srcAsset tracksWithMediaType:AVMediaTypeAudio];
    [audioTrack insertTimeRange:audioTimeRange ofTrack:[trackArray objectAtIndex:0] atTime:nextClistartTime error:nil];
    
    // 创建一个输出
    AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset:comosition presetName:AVAssetExportPresetMediumQuality];
    // 输出类型
    assetExport.outputFileType = AVFileTypeQuickTimeMovie;
    // 输出地址
    assetExport.outputURL = outputFileUrl;
    // 优化
    assetExport.shouldOptimizeForNetworkUse = YES;
    // 合成完毕
    [assetExport exportAsynchronouslyWithCompletionHandler:^{
        switch ([assetExport status]) {
            case AVAssetExportSessionStatusFailed: {
                NSLog(@"合成失败：%@",[[assetExport error] description]);
            } break;
            case AVAssetExportSessionStatusCancelled: {
            } break;
            case AVAssetExportSessionStatusCompleted: {
                NSLog(@"合成成功");
                [self saveVideo:outputFileUrl];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.progressView setProgress:1.0];
                    [self.clipView removeFromSuperview];
                    self.clipView = nil;
                    [self viewWillAppear:YES];
                });
            } break;
            default: {
                break;
            } break;
        }
//        });
    }];
}
-(void)saveVideo:(NSURL*)videoURL{
    
    //UISaveVideoAtPathToSavedPhotosAlbum([videoURL absoluteString], self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:videoURL];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            NSLog(@"保存成功");
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"视频保存成功" preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSFileManager* fileManager=[NSFileManager defaultManager];
                BOOL blDele= [fileManager removeItemAtURL:videoURL error:nil];
                if (blDele) {
                    NSLog(@"dele1 success");
                }else {
                    NSLog(@"dele1 fail");
                }
                blDele = [fileManager removeItemAtURL:self.picsTovideoPath error:nil];
                if (blDele) {
                    NSLog(@"dele2 success");
                }else {
                    NSLog(@"dele2 fail");
                }
            }]];
            [self presentViewController:alert animated:true completion:nil];
        }
        
        if (error) {
            NSLog(@"%@",error);
            NSLog(@"%@",error.description);
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"视频保存失败" preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                
            }]];
            [self presentViewController:alert animated:true completion:nil];
        }
    }];
//    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//    [library writeVideoAtPathToSavedPhotosAlbum:videoURL completionBlock:^(NSURL *assetURL, NSError *error) {
//                    if (error) {
//
//                        NSLog(@"Save video fail:%@",error);
//
//                    } else {
//
//                        NSLog(@"Save video succeed.");
//
//                    }
//
//                }];
}
// 视频保存回调
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo: (void *)contextInfo
{
    
    if (error == nil) {
        
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"视频保存成功" preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }]];
        [self presentViewController:alert animated:true completion:nil];
        
    }else{
        NSLog(@"%@",error.description);
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"视频保存失败" preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }]];
        [self presentViewController:alert animated:true completion:nil];
    }
}
- (UIImage *)reSizeImage:(UIImage *)image toSize:(CGSize)reSize

{
    UIGraphicsBeginImageContext(CGSizeMake(reSize.width, reSize.height));
    [image drawInRect:CGRectMake(0, 0, reSize.width, reSize.height)];
    UIImage *reSizeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return reSizeImage;
    
}
//保存图片
-(void)savepics{
    NSArray *paths =NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES);
    for (int i = 0; i < self.imageArray.count; i++)
    {
        UIImage * imgsave = self.imageArray[i];
        NSString *Pathimg =[[paths objectAtIndex:0]stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.png",i]];
        [UIImagePNGRepresentation(imgsave) writeToFile:Pathimg atomically:YES];
    }
}
@end
