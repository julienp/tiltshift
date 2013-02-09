//
//  UIImage_JPRotate.m
//  TiltShift
//
//  Created by Julien Poissonnier on 2/9/13.
//  Copyright (c) 2013 Julien Poissonnier. All rights reserved.
//

#import "UIImage_JPRotate.h"

@implementation UIImage (JPRotate)

// from http://stackoverflow.com/a/10548409/289843
- (UIImage *)rotateToOrientation:(UIImageOrientation)orientation
{
    UIGraphicsBeginImageContext(self.size);

    CGContextRef context = UIGraphicsGetCurrentContext();

    if (orientation == UIImageOrientationRight) {
        CGContextRotateCTM(context, 90 / 180 * M_PI);
    } else if (orientation == UIImageOrientationLeft) {
        CGContextRotateCTM(context, -90 / 180 * M_PI);
    } else if (orientation == UIImageOrientationDown) {
        // Nothing
    } else if (orientation == UIImageOrientationUp) {
        CGContextRotateCTM(context, 90 / 180 * M_PI);
    }

    [self drawAtPoint:CGPointMake(0, 0)];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
