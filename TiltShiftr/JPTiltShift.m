//
//  JPTiltShift.m
//  TiltShiftr
//
//  Created by Julien Poissonnier on 12/18/12.
//  Copyright (c) 2012 Julien Poissonnier. All rights reserved.
//

#import "JPTiltShift.h"

@implementation JPTiltShift

- (void)setDefaults
{
    [self setValue:@(10) forKey:@"inputRadius"];
    [self setValue:@(0.5) forKey:@"inputCenter"];
    [self setValue:@(0.25) forKey:@"inputBottom"];
    [self setValue:@(0.75) forKey:@"inputTop"];
}

- (CIImage *)outputImage
{
    CGRect cropRect = self.inputImage.extent;
    CGFloat height = cropRect.size.height;

    CIFilter *blur = [CIFilter filterWithName:@"CIGaussianBlur"
                                keysAndValues:@"inputImage", self.inputImage,
                                              @"inputRadius", @(self.inputRadius), nil];
    blur = [CIFilter filterWithName:@"CICrop"
                      keysAndValues:@"inputImage", blur.outputImage,
                                    @"inputRectangle", [CIVector vectorWithCGRect:cropRect], nil];

    CIFilter *topGradient = [CIFilter filterWithName:@"CILinearGradient"
                                       keysAndValues:@"inputPoint0", [CIVector vectorWithX:0 Y:(self.inputTop * height)],
                                                     @"inputColor0", [CIColor colorWithRed:0 green:1 blue:0 alpha:1],
                                                     @"inputPoint1", [CIVector vectorWithX:0 Y:(self.inputCenter * height)],
                                                     @"inputColor1", [CIColor colorWithRed:0 green:1 blue:0 alpha:0], nil];
    CIFilter *bottomGradient = [CIFilter filterWithName:@"CILinearGradient"
                                          keysAndValues:@"inputPoint0", [CIVector vectorWithX:0 Y:(self.inputBottom * height)],
                                                        @"inputColor0", [CIColor colorWithRed:0 green:1 blue:0 alpha:1],
                                                        @"inputPoint1", [CIVector vectorWithX:0 Y:(self.inputCenter * height)],
                                                        @"inputColor1", [CIColor colorWithRed:0 green:1 blue:0 alpha:0], nil];
    topGradient = [CIFilter filterWithName:@"CICrop"
                             keysAndValues:@"inputImage", topGradient.outputImage,
                                           @"inputRectangle", [CIVector vectorWithCGRect:cropRect], nil];
    bottomGradient = [CIFilter filterWithName:@"CICrop"
                                keysAndValues:@"inputImage", bottomGradient.outputImage,
                                              @"inputRectangle", [CIVector vectorWithCGRect:cropRect], nil];
    CIFilter *gradients = [CIFilter filterWithName:@"CIAdditionCompositing"
                                     keysAndValues:@"inputImage", topGradient.outputImage,
                                                   @"inputBackgroundImage", bottomGradient.outputImage, nil];

    CIFilter *tiltShift = [CIFilter filterWithName:@"CIBlendWithMask"
                                     keysAndValues:@"inputImage", blur.outputImage,
                                                   @"inputBackgroundImage", self.inputImage,
                                                   @"inputMaskImage", gradients.outputImage, nil];

    return tiltShift.outputImage;
}

@end
