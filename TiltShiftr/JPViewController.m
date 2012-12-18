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

@interface JPViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate, PopoverViewDelegate>
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *editButton;
@property (nonatomic, strong) PopoverView *popoverView;
@property (nonatomic, strong) UIView *divider;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIImage *originalImage;
@property (nonatomic, assign) CGFloat center;
@property (nonatomic, assign) CGFloat blur;
@property (nonatomic, assign, getter = isDragging) BOOL dragging;
@property (nonatomic, strong) NSMutableArray *imageSources;
@end

@implementation JPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.center = 0.5;
    self.blur = 10;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.userInteractionEnabled = YES;
}

- (void)setupDividers
{
    CGFloat width = self.imageView.bounds.size.width;
    CGFloat height = self.imageView.bounds.size.height;
    self.divider = [[UIView alloc] initWithFrame:CGRectMake(0, height * self.center - 22, width, 44)];
    self.divider.backgroundColor = [UIColor clearColor];
    self.divider.alpha = 0.0;
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 18, 1000, 8)]; //long line is long
    line.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.5];
    [self.divider addSubview:line];
    UIPanGestureRecognizer *recognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(drag:)];
    [self.divider addGestureRecognizer:recognizer];
    [self.imageView addSubview:self.divider];
}

- (void)viewDidLayoutSubviews
{
    [super viewWillLayoutSubviews];
    CGFloat height = self.imageView.bounds.size.height;
    CGRect frame = self.divider.frame;
    frame.origin.y = height * self.center - 22;
    frame.size.width = self.imageView.frame.size.width;
    self.divider.frame = frame;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.image == nil) {
        [self loadImage:nil];
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.popoverView dismiss];
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
        if (self.divider == nil) {
            [self setupDividers];
        }
        [UIView animateWithDuration:duration animations:^{
            self.divider.alpha = 1.0;
        } completion:^(BOOL finished) {
            self.divider.userInteractionEnabled = YES;
        }];
    } else {
        [UIView animateWithDuration:duration animations:^{
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
    self.imageSources = [[NSMutableArray alloc] init];
    NSMutableArray *buttonTitles = [[NSMutableArray alloc] init];

    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [self.imageSources addObject:[NSNumber numberWithInteger:UIImagePickerControllerSourceTypeCamera]];
        [buttonTitles addObject:NSLocalizedString(@"Take Photo", @"Take Photo")];
    }
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        [self.imageSources addObject:[NSNumber numberWithInteger:UIImagePickerControllerSourceTypePhotoLibrary]];
        [buttonTitles addObject:NSLocalizedString(@"Choose Existing", @"Choose Existing")];
    } else if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]) {
        [self.imageSources addObject:[NSNumber numberWithInteger:UIImagePickerControllerSourceTypeSavedPhotosAlbum]];
        [buttonTitles addObject:NSLocalizedString(@"Choose Existing", @"Choose Existing")];
    }

    if (self.imageSources.count == 1) {
        [self showPickerWithSourceType:0];
    } else if (self.imageSources.count > 1) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:nil
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:nil];
        for (NSString *title in buttonTitles) {
            [actionSheet addButtonWithTitle:title];
        }
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel")];
        actionSheet.cancelButtonIndex = self.imageSources.count;
        [actionSheet showInView:[[UIApplication sharedApplication] keyWindow]];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                            message:NSLocalizedString(@"There are no sources available to select a photo", @"There are no sources available to select a photo")
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:nil];
        [alertView show];
    }
}
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex < self.imageSources.count) {
        [self showPickerWithSourceType:[self.imageSources[buttonIndex] integerValue]];
    }
}

- (void)showPickerWithSourceType:(UIImagePickerControllerSourceType)sourceType
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = sourceType;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (IBAction)share:(id)sender
{
    CGImageRef image = [self processImage:self.originalImage.CGImage];
    UIImage *sharedImage = [UIImage imageWithCGImage:image];
    CGImageRelease(image);
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[ sharedImage ] applicationActivities:nil];
    [self presentViewController:activityViewController animated:YES completion:NULL];
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
    CGPoint point = [touch locationInView:self.view]; //TODO: should be at top center of barbuttonitem
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, 200, 50)];
    [slider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
    slider.backgroundColor = [UIColor clearColor];
    slider.maximumValue = 30;
    slider.minimumValue = 1;
    slider.value = self.blur;
    slider.continuous = NO;
    self.popoverView = [PopoverView showPopoverAtPoint:point inView:self.view withTitle:@"Blur Radius" withContentView:slider delegate:self];
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
    CGFloat blurScale = CGImageGetWidth(cgimage) / self.originalImage.size.width;

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
    CGFloat scale = self.view.window.bounds.size.width * 2;
    if (self.originalImage.size.width > self.originalImage.size.height) {
        scale = self.view.window.bounds.size.height * 2;
    }
    self.image = [UIImage imageWithImage:self.originalImage scaledToWidth:self.imageView.bounds.size.width];
    [self liveUpdate];
}

#pragma mark - PopoverViewDelegate

- (void)popoverViewDidDismiss:(PopoverView *)popoverView
{
    self.popoverView = nil;
}

@end