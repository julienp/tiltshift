//
//  JPViewController.m
//  TiltShift
//
//  Created by Julien Poissonnier on 12/17/12.
//  Copyright (c) 2012 Julien Poissonnier. All rights reserved.
//

#import "JPViewController.h"
#import <CoreImage/CoreImage.h>

@interface JPViewController ()
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) UIView *divider;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign) CGFloat center;
@end

@implementation JPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.center = 0.5;
    self.image = [UIImage imageNamed:@"example.jpg"];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.image = self.image;
    self.imageView.userInteractionEnabled = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    CGFloat width = self.imageView.bounds.size.width;
    CGFloat height = self.imageView.bounds.size.height;
    self.divider = [[UIView alloc] initWithFrame:CGRectMake(0, height * 0.5 - 2, width, 4)];
    self.divider.backgroundColor = [UIColor grayColor];
    self.divider.userInteractionEnabled = YES;
    UIPanGestureRecognizer *recognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(drag:)];
    [self.divider addGestureRecognizer:recognizer];
    [self.imageView addSubview:self.divider];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)drag:(UIPanGestureRecognizer *)gestureRecognizer
{
    CGPoint translation = [gestureRecognizer translationInView:self.imageView];
    [gestureRecognizer setTranslation:CGPointMake(0, 0) inView:self.imageView];
    CGRect frame = self.divider.frame;
    CGFloat y = frame.origin.y + translation.y;
    y = MAX(y, 0.0);
    y = MIN(y, self.imageView.bounds.size.height);
    frame.origin.y = y;
    self.divider.frame = frame;
    self.center = y / self.imageView.bounds.size.height;
}

- (IBAction)tiltShift:(id)sender
{

    CGFloat top = 1 - MAX(self.center - 0.25, 0.0);
    CGFloat bottom = 1 - MIN(self.center + 0.25, 1.0);
    CGFloat center = 1 - self.center;
    CGFloat height = self.image.size.height;
    CGRect cropRect = (CGRect){.origin = {0, 0}, .size = self.image.size};
    CIImage *image = [CIImage imageWithCGImage:self.image.CGImage];

    //blur
    CIFilter *blur = [CIFilter filterWithName:@"CIGaussianBlur"
                                  keysAndValues:@"inputImage", image,
                        @"inputRadius", @(10), nil];
    blur = [CIFilter filterWithName:@"CICrop"
                             keysAndValues:@"inputImage", blur.outputImage,
                   @"inputRectangle", [CIVector vectorWithCGRect:cropRect], nil];
    //gradient mask
    CIFilter *topGradient = [CIFilter filterWithName:@"CILinearGradient"
                                       keysAndValues:@"inputPoint0", [CIVector vectorWithX:0 Y:(top * height)],
                             @"inputColor0", [CIColor colorWithRed:0 green:1 blue:0 alpha:1],
                             @"inputPoint1", [CIVector vectorWithX:0 Y:(center * height)],
                             @"inputColor1", [CIColor colorWithRed:0 green:1 blue:0 alpha:0], nil];
    CIFilter *bottomGradient = [CIFilter filterWithName:@"CILinearGradient"
                                       keysAndValues:@"inputPoint0", [CIVector vectorWithX:0 Y:(bottom * height)],
                             @"inputColor0", [CIColor colorWithRed:0 green:1 blue:0 alpha:1],
                             @"inputPoint1", [CIVector vectorWithX:0 Y:(center * height)],
                             @"inputColor1", [CIColor colorWithRed:0 green:1 blue:0 alpha:0], nil];
    topGradient = [CIFilter filterWithName:@"CICrop"
                                   keysAndValues:@"inputImage", topGradient.outputImage,
                   @"inputRectangle", [CIVector vectorWithCGRect:cropRect], nil];
    bottomGradient = [CIFilter filterWithName:@"CICrop"
                                   keysAndValues:@"inputImage", bottomGradient.outputImage,
                         @"inputRectangle", [CIVector vectorWithCGRect:cropRect], nil];
    CIFilter *gradients = [CIFilter filterWithName:@"CIAdditionCompositing"
                                     keysAndValues:@"inputImage", topGradient.outputImage,
                           @"inputBackgroundImage", bottomGradient.outputImage, nil];

    //blend
    CIFilter *tiltShift = [CIFilter filterWithName:@"CIBlendWithMask"
                                     keysAndValues:@"inputImage", blur.outputImage,
                           @"inputBackgroundImage", image,
                           @"inputMaskImage", gradients.outputImage, nil];

    static CIContext *context;
    if (context == nil) {
        context = [CIContext contextWithOptions:nil];
    }
    CIImage *result = tiltShift.outputImage;
    CGImageRef cgImage = [context createCGImage:result fromRect:[result extent]];
    self.imageView.image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
}


@end
