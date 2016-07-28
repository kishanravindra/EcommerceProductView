//
//  UIView+RVBorder.m
//  rVidi
//
//  Created by Sajith C on 01/09/15.
//  Copyright (c) 2015 Qwinix. All rights reserved.
//

#import "UIView+RVBorder.h"

@implementation UIView (RVBorder)
@dynamic borderColor,borderWidth,cornerRadius, shadowColor;

-(void)setBorderColor:(UIColor *)borderColor{
    [self.layer setBorderColor:borderColor.CGColor];
}

-(void)setBorderWidth:(CGFloat)borderWidth{
    [self.layer setBorderWidth:borderWidth];
}

-(void)setCornerRadius:(CGFloat)cornerRadius{
    [self.layer setCornerRadius:cornerRadius];
}

-(void)setShadowColor:(UIColor *)borderColor{
    [self.layer setShadowColor:borderColor.CGColor];
}
@end
