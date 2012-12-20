//
//  UIImageView_JPContentScale.m
//  TiltShiftr
//
//  Created by Julien Poissonnier on 12/18/12.
//  Copyright (c) 2012 Julien Poissonnier. All rights reserved.
//

#import "UIImageView_JPContentScale.h"

@implementation UIImageView (UIImageView_ContentScale)

- (CGFloat)jp_contentScale;
{
    CGFloat widthScale = self.bounds.size.width / self.image.size.width;
    CGFloat heightScale = self.bounds.size.height / self.image.size.height;

    if (self.contentMode == UIViewContentModeScaleToFill) {
        return (widthScale==heightScale) ? widthScale : NAN;
    }
    if (self.contentMode == UIViewContentModeScaleAspectFit) {
        return MIN(widthScale, heightScale);
    }
    if (self.contentMode == UIViewContentModeScaleAspectFill) {
        return MAX(widthScale, heightScale);
    }
    return 1.0;

}

@end
