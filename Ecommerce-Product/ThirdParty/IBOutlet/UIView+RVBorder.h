//
//  UIView+RVBorder.h
//  rVidi
//
//  Created by Sajith C on 01/09/15.
//  Copyright (c) 2015 Qwinix. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (RVBorder)
@property (nonatomic) IBInspectable UIColor *borderColor;
@property (nonatomic) IBInspectable CGFloat borderWidth;
@property (nonatomic) IBInspectable CGFloat cornerRadius;
@property (nonatomic) IBInspectable UIColor *shadowColor;
@end
