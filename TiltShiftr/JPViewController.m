//
//  JPViewController.m
//  TiltShift
//
//  Created by Julien Poissonnier on 12/17/12.
//  Copyright (c) 2012 Julien Poissonnier. All rights reserved.
//

#import "JPViewController.h"
#import <CoreImage/CoreImage.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/ImageIO.h>
#import "UIImage_JPResize.h"
#import "JPTiltShift.h"
#import "PopoverView.h"

@interface JPViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
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
    self.center = 0.5;
    self.blur = 15;
    self.originalImage = [UIImage imageNamed:@"example2.jpg"];
    self.image = [UIImage imageWithImage:self.originalImage scaledToSizeWithSameAspectRatio:CGSizeMake(640, 853)]; //TODO: size
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.image = self.image;
    self.imageView.userInteractionEnabled = YES;
}

- (void)viewWillLayoutSubviews
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self liveUpdate];
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
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    } else {
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    [self presentViewController:picker animated:YES completion:nil];
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

- (IBAction)blur:(id)sender event:(UIEvent *)event
{
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint point = [touch locationInView:self.view];
//    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 50)];
//    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
//    label.text = @"Blur Radius ";
//    [container addSubview:label];
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
//    [container addSubview:slider];
//    slider.translatesAutoresizingMaskIntoConstraints = NO;
//    label.translatesAutoresizingMaskIntoConstraints = NO;
//    NSDictionary *bindings = NSDictionaryOfVariableBindings(slider, label);
//    [container addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[label]-|" options:0 metrics:nil views:bindings]];
//    [container addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[slider]-|" options:0 metrics:nil views:bindings]];
//    [container addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[label]-[slider]-|" options:0 metrics:nil views:bindings]];
    [slider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
    slider.maximumValue = 30;
    slider.minimumValue = 1;
    slider.value = self.blur;
    slider.continuous = NO;
//    [PopoverView showPopoverAtPoint:point inView:self.view withContentView:container delegate:nil];
    [PopoverView showPopoverAtPoint:point inView:self.view withTitle:@"Blur Radius" withContentView:slider delegate:nil];
}

- (IBAction)sliderChanged:(UISlider *)slider
{
    self.blur = slider.value;
    [self liveUpdate];
}

- (IBAction)tiltShift:(id)sender
{
    [self liveUpdate];
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

- (CGImageRef)processImage:(CGImageRef)cgimage
{
    CGFloat top = 1 - MAX(self.center - 0.25, 0.0); //Quartz origin is bottom left
    CGFloat bottom = 1 - MIN(self.center + 0.25, 1.0);
    CGFloat center = 1 - self.center;
    CIImage *image = [CIImage imageWithCGImage:cgimage];
    CGFloat blurScale = self.image.size.width / self.originalImage.size.width;

    JPTiltShift *filter = [[JPTiltShift alloc] init];
    [filter setDefaults];
    filter.inputImage = image;
    filter.inputRadius = self.blur * blurScale;
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

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self dismissViewControllerAnimated:YES completion:nil];
    self.originalImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    self.image = [UIImage imageWithImage:self.originalImage scaledToSizeWithSameAspectRatio:self.imageView.bounds.size];
    [self liveUpdate];
}

@end