//
//  KKCinemaView.m
//  Cinemas
//
//  Created by Peter Stajger on 12/03/14.
//  Copyright (c) 2014 KinemaKity. All rights reserved.
//

#import "KKCinemaView.h"

#define RGBCOLOR(r,g,b) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:1]
#define RGBACOLOR(r,g,b,a) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:(a)]

@implementation KKCinemaView
{
    UIEdgeInsets    _edgeInsets;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    _edgeInsets = UIEdgeInsetsMake(30, 30, 30, 30);
}

- (void)drawRect:(CGRect)rect
{
    CGColorRef redRawColor    = [UIColor redColor].CGColor;
    CGColorRef greenRawColor  = [UIColor greenColor].CGColor;
    CGColorRef blueRawColor   = [UIColor blueColor].CGColor;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect drawingRect = CGRectMake(_edgeInsets.left,
                                    _edgeInsets.top,
                                    CGRectGetWidth(rect) - (_edgeInsets.left + _edgeInsets.right),
                                    CGRectGetHeight(rect) - (_edgeInsets.top + _edgeInsets.bottom));
    
    CGContextClipToRect(context, drawingRect);
    
    
}


@end
