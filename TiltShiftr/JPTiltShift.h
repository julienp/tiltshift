//
//  JPTiltShift.h
//  TiltShiftr
//
//  Created by Julien Poissonnier on 12/18/12.
//  Copyright (c) 2012 Julien Poissonnier. All rights reserved.
//

#import <CoreImage/CoreImage.h>

@interface JPTiltShift : CIFilter

@property (retain, nonatomic) CIImage *inputImage;
@property (assign, nonatomic) CGFloat inputRadius;
@property (assign, nonatomic) CGFloat inputTop;
@property (assign, nonatomic) CGFloat inputCenter;
@property (assign, nonatomic) CGFloat inputBottom;

@end
