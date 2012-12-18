//
//  JPViewController.m
//  TiltShift
//
//  Created by Julien Poissonnier on 12/17/12.
//  Copyright (c) 2012 Julien Poissonnier. All rights reserved.
//

#import "JPViewController.h"
#import <CoreImage/CoreImage.h>
#import "UIImage_JPResize.h"
#import "JPTiltShift.h"

@interface JPViewController ()
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *editButton;
@property (nonatomic, strong) UIView *divider;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIImage *originalImage;
@property (nonatomic, assign) CGFloat center;
@property (nonatomic, assign) CGFloat blur;
@property (nonatomic, assign, getter = isDragging) BOOL dragging;
@end

@implementation JPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    CGFloat scale = 1; //blur radius needs to be proportional to image size, what ratio to chose?
    self.center = 0.5;
    self.blur = 5 * scale; //what's the correct ratio for scale/imagesize
//    self.image = [UIImage imageNamed:@"example.jpg"];
    UIImage *image = [UIImage imageNamed:@"example2.jpg"];
    self.image = [UIImage imageWithImage:image scaledToSizeWithSameAspectRatio:CGSizeMake(640 * scale, 853 * scale)];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.image = self.image;
    self.imageView.userInteractionEnabled = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    CGFloat width = self.imageView.bounds.size.width;
    CGFloat height = self.imageView.bounds.size.height;
    self.divider = [[UIView alloc] initWithFrame:CGRectMake(0, height * 0.5 - 2, width, 44)];
    self.divider.backgroundColor = [UIColor clearColor];
    self.divider.alpha = 0.0;
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 18, width, 8)];
    line.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.5];
    [self.divider addSubview:line];
    UIPanGestureRecognizer *recognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(drag:)];
    [self.divider addGestureRecognizer:recognizer];
    [self.imageView addSubview:self.divider];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    float duration = animated ? 0.25 : 0;
    if (editing) {
        [UIView animateWithDuration:duration animations:^{
            [self.editButton setStyle:UIBarButtonItemStyleDone];
            self.editButton.title = @"Done";
            self.divider.alpha = 1.0;
        } completion:^(BOOL finished) {
            self.divider.userInteractionEnabled = YES;
        }];
    } else {
        [UIView animateWithDuration:duration animations:^{
            [self.editButton setStyle:UIBarButtonItemStyleBordered];
            self.editButton.title = @"Edit";
            self.divider.alpha = 0.0;
        } completion:^(BOOL finished) {
            self.divider.userInteractionEnabled = NO;
        }];
    }
}

- (IBAction)modify:(id)sender
{
    [self setEditing:!self.editing animated:YES];
}

- (IBAction)loadImage:(id)sender
{

}

- (IBAction)share:(id)sender
{
    //apply filter to original and share that
    //need to change blur radius?
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
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        self.dragging = YES;
        [self liveUpdate];
    }
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        self.dragging = NO;
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(liveUpdate) object:nil];
        [self liveUpdate];
    }
}

- (void)liveUpdate
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        CGImageRef image = [self processImage:self.image.CGImage];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imageView.image = [UIImage imageWithCGImage:image];
            CGImageRelease(image);
            if (self.isDragging) {
                [self performSelector:@selector(liveUpdate) withObject:nil afterDelay:0.2];
            }
        });
    });
}

- (IBAction)blur:(id)sender
{
    //set blur radius, update similar to liveUpdate
    //show slider in https://github.com/werner77/WEPopover ?
}


- (IBAction)tiltShift:(id)sender
{
    [self liveUpdate];
}

- (CGImageRef)processImage:(CGImageRef)cgimage
{
    CGFloat top = 1 - MAX(self.center - 0.25, 0.0); //Quartz origin is bottom left
    CGFloat bottom = 1 - MIN(self.center + 0.25, 1.0);
    CGFloat center = 1 - self.center;
    CIImage *image = [CIImage imageWithCGImage:cgimage];

    JPTiltShift *filter = [[JPTiltShift alloc] init];
    [filter setDefaults];
    filter.inputImage = image;
    filter.inputRadius = 10;
    filter.inputTop = top;
    filter.inputCenter = center;
    filter.inputBottom = bottom;

    static CIContext *context;
    if (context == nil) {
        context = [CIContext contextWithOptions:nil];
    }
    CIImage *result = filter.outputImage;
    CGImageRef cgImage = [context createCGImage:result fromRect:[result extent]];
    return cgImage;
}


@end
