//
//  ViewController.m
//  AVFCamera
//
//  Created by sunmingzhe on 2019/11/19.
//  Copyright © 2019 v_sunmingzhe01. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
@interface ViewController ()
@property (strong, nonatomic) AVCaptureSession *session;
@property (strong, nonatomic) AVCaptureDeviceInput *input;
@property (strong, nonatomic) AVCaptureVideoDataOutput *output;
@property (strong, nonatomic) AVCaptureConnection * conn;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer* videoLayer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self startCamera];
    // Do any additional setup after loading the view.
}

#pragma mark-代理回调
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection{
    
        UIImage *img = [self imageFromSampleBuffer:sampleBuffer];
        
    dispatch_async(dispatch_get_main_queue(), ^{
        //主线程，可用于UI刷新
    });
}
#pragma mark -初始化相机
- (void)startCamera
{
    NSError *error = nil;
    _session = [[AVCaptureSession alloc] init];
    _session.sessionPreset = AVCaptureSessionPreset640x480;
    AVCaptureDevice* device =nil;
    NSArray*cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    //设置前置摄像头
    for(AVCaptureDevice* camera in cameras)
    {
        if(camera.position==AVCaptureDevicePositionFront) {
    device = camera;
        }
    }
    _input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if([self.session canAddInput:self.input]){
        [_session addInput:_input];
    }
    _output = [[AVCaptureVideoDataOutput alloc] init];
    [_session addOutput:_output];
    //添加连接管理
    _conn = [self.output connectionWithMediaType:AVMediaTypeVideo];
    //前置摄像头取照片显示正常，如果存到相册会发生逆时针90度旋转问题，这里将图像旋转90度
    //这个注释掉的话，效果需要保存照片可以看到
    _conn.videoOrientation = AVCaptureVideoOrientationPortrait;
    //前置摄像头镜像显示问题，这几部分可以注释掉看一下区别。
    [_conn setVideoMirrored:YES];
    dispatch_queue_t queue = dispatch_queue_create("myQueue", NULL);
    [_output setSampleBufferDelegate:self queue:queue];
    self.output.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    [_session startRunning];
    self.videoLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.session];
    self.view.layer.masksToBounds=YES;
    self.videoLayer.frame=self.view.bounds;
//    self.videoLayer.videoGravity=AVLayerVideoGravityResizeAspectFill;
    self.videoLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.view.layer addSublayer:self.videoLayer];
}

#pragma mark -从缓存区数据创建一个UIImage对象
-(UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    size_t bytesPerRow  = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    if(!colorSpace){
        NSLog(@"错误");
    }
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    size_t bufferSize = CVPixelBufferGetDataSize(imageBuffer);
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, baseAddress, bufferSize,NULL);
    CGImageRef cgImage = CGImageCreate(width, height, 8, 32, bytesPerRow, colorSpace, kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little, provider, NULL, true, kCGRenderingIntentDefault);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    return image;
}
@end
