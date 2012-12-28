//
//  JPInfoNavigationController.m
//  TiltShift
//
//  Created by Julien Poissonnier on 12/28/12.
//  Copyright (c) 2012 Julien Poissonnier. All rights reserved.
//

#import "JPInfoNavigationController.h"

@interface JPInfoNavigationController ()

@end

@implementation JPInfoNavigationController

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
}

@end
