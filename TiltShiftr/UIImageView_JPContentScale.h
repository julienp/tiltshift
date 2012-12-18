//
//  UIImageView_JPContentScale.h
//  TiltShiftr
//
//  Created by Julien Poissonnier on 12/18/12.
//  Copyright (c) 2012 Julien Poissonnier. All rights reserved.
//

//http://stackoverflow.com/questions/6726423/how-can-i-get-the-scale-factor-of-a-uiimageview-whos-mode-is-aspectfit/6732045#6732045

#import <UIKit/UIKit.h>

@interface UIImageView (UIImageView_ContentScale)

- (CGFloat)jp_contentScale;

@end
