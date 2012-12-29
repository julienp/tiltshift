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
#import <QuartzCore/QuartzCore.h>
#import "UIImage_JPResize.h"
#import "UIImageView_JPContentScale.h"
#import "JPTiltShift.h"
#import "PopoverView.h"
#import <SVProgressHUD/SVProgressHUD.h>

@interface JPViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate, PopoverViewDelegate>
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *editButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *shareButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *loadPhotoButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *blurButton;
@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;
@property (nonatomic, strong) PopoverView *popoverView;
@property (nonatomic, strong) UIView *divider;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIImage *originalImage;
@property (nonatomic, assign) CGFloat center;
@property (nonatomic, assign) CGFloat blur;
@property (nonatomic, assign, getter = isDragging) BOOL dragging;
@property (nonatomic, strong) NSMutableArray *imageSources;
@property (nonatomic, assign) BOOL toolbarHidden;
@property (nonatomic, assign) BOOL firstLoad;
@property (nonatomic, strong) UIPopoverController *popover;
@property (nonatomic, strong) UIPopoverController *sharePopover;
@property (nonatomic, strong) UIActionSheet *actionSheet;
@end

@implementation JPViewController

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackTranslucent];
        self.wantsFullScreenLayout = YES;
    }
    self.toolbarHidden = NO;
    self.firstLoad = YES;

    self.center = 0.5;
    self.blur = 10;

    self.imageView.userInteractionEnabled = YES;
    self.imageView.image = [UIImage imageNamed:@"placeholder.png"];
    self.imageView.contentMode = UIViewContentModeCenter;
}

- (void)viewDidLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    self.toolbarHidden = NO;
    [self updateDividers];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.image == nil && self.firstLoad) {
        [self loadImage:nil];
        self.firstLoad = NO;
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showInfo"]) {
        [self hidePopovers];
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    float duration = animated ? 0.25 : 0;
    if (editing) {
        if (self.divider == nil) {
            [self setupDividers];
        }
        [self.editButton setTintColor:[UIColor colorWithHue:0.391 saturation:0.578 brightness:0.984 alpha:1.000]];
        [UIView animateWithDuration:duration animations:^{
            self.divider.alpha = 1.0;
        } completion:^(BOOL finished) {
            self.divider.userInteractionEnabled = YES;
        }];
    } else {
        [self.editButton setTintColor:[UIColor whiteColor]];
        [UIView animateWithDuration:duration animations:^{
            self.divider.alpha = 0.0;
        } completion:^(BOOL finished) {
            self.divider.userInteractionEnabled = NO;
        }];
    }
}

- (void)setImage:(UIImage *)image
{
    if (_image != image) {
        _image = image;
        if (_image) {
            self.blurButton.enabled = YES;
            self.editButton.enabled = YES;
            self.shareButton.enabled = YES;
        } else {
            self.blurButton.enabled = NO;
            self.editButton.enabled = NO;
            self.shareButton.enabled = NO;
        }
    }
}

#pragma mark - Dividers

- (void)setupDividers
{
    CGFloat width = self.imageView.bounds.size.width;
    self.divider = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 44)];
    self.divider.backgroundColor = [UIColor clearColor];
    self.divider.alpha = 0.0;
    CGFloat maxLength = MAX(CGRectGetMaxX(self.view.window.bounds), CGRectGetMaxY(self.view.window.bounds));
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 20, maxLength, 4)];
    line.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.5];
    CGFloat ipad_gap = 0.0; //up/down arrows are slightly inset on ipad so they dont overlap the black border in landscape
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        ipad_gap = 12.0;
    }
    UIImage *up = [UIImage imageNamed:@"up.png"];
    UIImageView *upView = [[UIImageView alloc] initWithImage:up];
    upView.frame = CGRectMake(5 + ipad_gap, 8, 10, 10);
    [self.divider addSubview:upView];
    UIImage *down = [UIImage imageNamed:@"down.png"];
    UIImageView *downView = [[UIImageView alloc] initWithImage:down];
    downView.frame = CGRectMake(5 + ipad_gap, 26, 10, 10);
    [self.divider addSubview:downView];

    [self.divider addSubview:line];
    UIPanGestureRecognizer *recognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(drag:)];
    [self.divider addGestureRecognizer:recognizer];
    self.divider.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.01];
    [self.imageView addSubview:self.divider];
    [self updateDividers];
}

- (void)updateDividers
{
    CGFloat height = self.image.size.height * self.imageView.jp_contentScale;
    CGFloat offset = (self.imageView.bounds.size.height - height) / 2;
    CGRect frame = self.divider.frame;
    frame.origin.y = offset + height * self.center - 22;
    frame.size.width = self.imageView.frame.size.width;
    self.divider.frame = frame;
}

#pragma mark - IBAction

- (IBAction)modify:(id)sender
{
    [self setEditing:!self.editing animated:YES];
}

- (IBAction)loadImage:(id)sender
{
    [self hidePopovers];
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
        self.actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:nil
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:nil];
        for (NSString *title in buttonTitles) {
            [self.actionSheet addButtonWithTitle:title];
        }
        [self.actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel")];
        self.actionSheet.cancelButtonIndex = self.imageSources.count;
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
            [self.actionSheet showInView:self.view];
        } else {
            [self.actionSheet showFromBarButtonItem:self.loadPhotoButton animated:YES];
        }
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                            message:NSLocalizedString(@"There are no sources available to select a photo", @"There are no sources available to select a photo")
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:nil];
        [alertView show];
    }
}


- (IBAction)share:(id)sender
{
    [self hidePopovers];

    [SVProgressHUD showWithStatus:NSLocalizedString(@"Processing", @"Processing") maskType:SVProgressHUDMaskTypeClear];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CGImageRef image = [self processImage:self.originalImage.CGImage];
        UIImage *sharedImage = [UIImage imageWithCGImage:image scale:1.0 orientation:self.originalImage.imageOrientation];
        CGImageRelease(image);
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[ sharedImage ] applicationActivities:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
                [self presentViewController:activityViewController animated:YES completion:NULL];
            } else {
                self.sharePopover = [[UIPopoverController alloc] initWithContentViewController:activityViewController];
                [self.sharePopover presentPopoverFromBarButtonItem:self.shareButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            }
        });
    });
}

- (IBAction)drag:(UIPanGestureRecognizer *)gestureRecognizer
{
    CGPoint translation = [gestureRecognizer translationInView:self.imageView];
    [gestureRecognizer setTranslation:CGPointMake(0, 0) inView:self.imageView];
    CGRect frame = self.divider.frame;
    CGFloat imageHeight = self.image.size.height * self.imageView.jp_contentScale;
    CGFloat imageOffset = (self.imageView.bounds.size.height - imageHeight) / 2; //image is centered in imageview
    CGFloat y = frame.origin.y + translation.y;
    CGFloat statusbar = 20; //not sure why this is necessary
    CGFloat min_gap = 10;
    y = MAX(y, imageOffset - statusbar + min_gap + 1); //magic numbers so the top/bottom of arrow hit edge of image. Would be nicer if the up/down.png didn't have deadspace at top/bottom
    y = MIN(y, self.imageView.bounds.size.height - imageOffset - statusbar - min_gap - 5);
    frame.origin.y = y;
    self.divider.frame = frame;

    self.center = (y - imageOffset + statusbar) / imageHeight;
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
    [self hidePopovers];

    //Hacky way to get the location of the barbutton
    UITouch *touch = [[event allTouches] anyObject];
    UIView *view = touch.view;
    CGRect frame = [view convertRect:view.bounds toView:self.view];
    CGPoint point = CGPointMake(CGRectGetMidX(frame), CGRectGetMinY(frame) + 5);

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

- (IBAction)toggleToolbar:(id)sender
{
    if (self.image == nil) {
        [self loadImage:nil];
        return;
    }

    if (self.toolbarHidden) {
        CATransition *transition = [CATransition animation];
        transition.duration = 0.25;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
        transition.type = kCATransitionPush;
        transition.subtype = kCATransitionFromTop;
        [self.toolbar.layer addAnimation:transition forKey:nil];
        self.toolbar.frame = CGRectOffset(self.toolbar.frame, 0, - self.toolbar.frame.size.height);
        self.toolbarHidden = NO;
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
        }
    } else {
        CATransition *transition = [CATransition animation];
        transition.duration = 0.25;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        transition.type = kCATransitionPush;
        transition.subtype = kCATransitionFromBottom;
        [self.toolbar.layer addAnimation:transition forKey:nil];
        self.toolbar.frame = CGRectOffset(self.toolbar.frame, 0, self.toolbar.frame.size.height);
        self.toolbarHidden = YES;
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
        }
    }
}

#pragma mark - Helpers

- (void)hidePopovers
{
    [self.popoverView dismiss];
    [self.sharePopover dismissPopoverAnimated:YES];
    [self.popover dismissPopoverAnimated:YES];
    [self.actionSheet dismissWithClickedButtonIndex:-1 animated:YES];
}

- (void)showPickerWithSourceType:(UIImagePickerControllerSourceType)sourceType
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = sourceType;
    picker.delegate = self;
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        [self presentViewController:picker animated:YES completion:nil];
    } else {
        if (sourceType == UIImagePickerControllerSourceTypeCamera) {
            [self presentViewController:picker animated:YES completion:nil];
        } else {
            self.popover = [[UIPopoverController alloc] initWithContentViewController:picker];
            [self.popover presentPopoverFromBarButtonItem:self.loadPhotoButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
    }
}

#pragma mark - Update Image

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

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex < self.imageSources.count) {
        [self showPickerWithSourceType:[self.imageSources[buttonIndex] integerValue]];
    }
    self.actionSheet = nil;
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.popover dismissPopoverAnimated:YES];
    self.popover = nil;

    self.originalImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    CGFloat scale = self.view.window.bounds.size.width * 2;
    if (self.originalImage.size.width > self.originalImage.size.height) {
        scale = self.view.window.bounds.size.height * 2;
    }
    self.image = [UIImage imageWithImage:self.originalImage scaledToWidth:scale];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.image = self.image;
    self.center = 0.5;
    self.blur = 10;
    [self updateDividers];
    [self liveUpdate];
}

#pragma mark - PopoverViewDelegate

- (void)popoverViewDidDismiss:(PopoverView *)popoverView
{
    self.popoverView = nil;
}

@end