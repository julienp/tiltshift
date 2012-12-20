//
//  UIImage_JPResize.m
//  TiltShift
//
//  Created by Julien Poissonnier on 12/17/12.
//  Copyright (c) 2012 Julien Poissonnier. All rights reserved.
//

#import "UIImage_JPResize.h"

@implementation UIImage (JPResize)

+ (UIImage *)imageWithImage:(UIImage *)sourceImage scaledToWidth:(CGFloat)width
{
    float oldWidth = sourceImage.size.width;
    float scaleFactor = width / oldWidth;

    float newHeight = sourceImage.size.height * scaleFactor;
    float newWidth = oldWidth * scaleFactor;

    UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
    [sourceImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
