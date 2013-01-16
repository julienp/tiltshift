//
//  JPInfoViewController.m
//  TiltShift
//
//  Created by Julien Poissonnier on 12/28/12.
//  Copyright (c) 2012 Julien Poissonnier. All rights reserved.
//

#import "JPInfoViewController.h"

@interface JPInfoViewController () <UIWebViewDelegate>

@end

@implementation JPInfoViewController

- (void)awakeFromNib
{
    self.modalPresentationStyle = UIModalPresentationFormSheet;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.webView.delegate = self;
    self.webView.scrollView.bounces = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"about" ofType:@"html"]];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (IBAction)done:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)type
{
    // open links in safari
    if (type == UIWebViewNavigationTypeLinkClicked) {
        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }
    return YES;
}

@end
