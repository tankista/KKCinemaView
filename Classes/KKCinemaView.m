//
//  KKCinemaView.m
//  Cinemas
//
//  Created by Peter Stajger on 12/03/14.
//  Copyright (c) 2014 KinemaKity. All rights reserved.
//

#import "KKCinemaView.h"

#define DEFAULT_COL_SPACING 1
#define DEFAULT_ROW_SPACING 1

typedef struct {
    NSUInteger row;
    NSUInteger col;
} KKSeatLocation;

@implementation KKCinemaView
{
    UIEdgeInsets    _edgeInsets;    //this insets drawing rect from view's edges
    CGFloat         _rowsPadding;   //padding between 2 rows
    
    UIPanGestureRecognizer*      _panGesture;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    _edgeInsets = UIEdgeInsetsMake(30, 30, 30, 30);
    
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognized:)];
    _panGesture.maximumNumberOfTouches = 1;
    [self addGestureRecognizer:_panGesture];
}

- (void)panGestureRecognized:(UIPanGestureRecognizer*)recongizer
{
    CGPoint translatedPoint = [recongizer translationInView:self];
    if ([recongizer state] == UIGestureRecognizerStateChanged) {
        NSLog(@"%@", NSStringFromCGPoint(translatedPoint));
    }
}

- (void)reloadData
{
    //TODO: do initial math
    
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGColorRef redRawColor    = [UIColor redColor].CGColor;
//    CGColorRef greenRawColor  = [UIColor greenColor].CGColor;
//    CGColorRef blueRawColor   = [UIColor blueColor].CGColor;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect drawingRect = CGRectMake(_edgeInsets.left,
                                    _edgeInsets.top,
                                    CGRectGetWidth(rect) - (_edgeInsets.left + _edgeInsets.right),
                                    CGRectGetHeight(rect) - (_edgeInsets.top + _edgeInsets.bottom));
    
    CGContextClipToRect(context, drawingRect);
    
    NSUInteger numberOfRows = [_dataSource numberOfRowsInCinemaView:self];
    NSAssert(numberOfRows > 0, @"You must specify number of rows");
    
    NSUInteger numberOfCols = [_dataSource numberOfColsInCinemaView:self];
    NSAssert(numberOfCols > 0, @"You must specify number of rows");
    
    CGFloat colSpacing = DEFAULT_COL_SPACING;
    if ([_dataSource respondsToSelector:@selector(interColSpacingInCinemaView:)]) {
        colSpacing = [_dataSource interColSpacingInCinemaView:self];
    }
    
    //calcuclate seat size
    CGFloat seatWidth = floorf((CGRectGetWidth(drawingRect) - (numberOfCols-1)*colSpacing)/numberOfCols);
    CGFloat seatHeight = seatWidth;
    CGSize seatSize = CGSizeMake(seatWidth, seatHeight);
    
    CGFloat previousRowOriginY = drawingRect.origin.y;
    
    for (int row = 0; row < numberOfRows; row++) {
    
        CGFloat previousColOriginX = drawingRect.origin.x;
        
        //Calculate row spacing. If not first or last row, ask for interrow spacing
        CGFloat rowOriginY = previousRowOriginY;
        CGFloat rowSpacing = DEFAULT_ROW_SPACING;
        if (row > 0 && row < numberOfRows) {
            if ([_dataSource respondsToSelector:@selector(cinemaView:interRowSpacingForRow:)]) {
                rowSpacing = [_dataSource cinemaView:self interRowSpacingForRow:rowSpacing];
            }
        }
        rowOriginY += rowSpacing;
        previousRowOriginY = rowOriginY;
        
        //calculate seat position
        CGRect seatRect = CGRectZero;
        seatRect.origin.y = rowOriginY + row * seatSize.height;
        seatRect.size = seatSize;
        
        for (int col = 0; col < numberOfCols; col++) {
            
            CGFloat colOriginX = previousColOriginX;
            if (col > 0) {
                colOriginX += colSpacing;
            }
            previousColOriginX = colOriginX;
            
            seatRect.origin.x = colOriginX + col * seatSize.width;
            drawSeat(context, seatRect, redRawColor);
        }
    }
}



void drawSeat(CGContextRef context, CGRect rect, CGColorRef color)
{
    CGContextSaveGState(context);
    CGContextSetFillColorWithColor(context, color);
    CGContextFillRect(context, rect);
    CGContextRestoreGState(context);
}

@end
