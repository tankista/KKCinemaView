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

@implementation KKCinemaView
{
    UIEdgeInsets    _edgeInsets;    //this insets drawing rect from view's edges
    
    UIPanGestureRecognizer* _panGesture;
    NSMutableArray*         _rowOriginsY;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    _edgeInsets = UIEdgeInsetsMake(30, 20, 30, 20);
    
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognized:)];
    _panGesture.maximumNumberOfTouches = 1;
    [self addGestureRecognizer:_panGesture];
}

- (void)panGestureRecognized:(UIPanGestureRecognizer*)recongizer
{
    CGPoint panPoint = [recongizer locationInView:self];
    
    if ([recongizer state] == UIGestureRecognizerStateBegan) {
        NSLog(@"Began");
        NSLog(@"%@", _rowOriginsY);
        
        //find row
        CGRect drawingRect = UIEdgeInsetsInsetRect(self.frame, _edgeInsets);
        CGFloat distanceY = panPoint.y - drawingRect.origin.y;
        
        __block NSUInteger rowIndex = NSUIntegerMax;
        [_rowOriginsY enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSNumber* distanceNumber, NSUInteger idx, BOOL *stop) {
            
            if ([distanceNumber floatValue] <= distanceY) {
                rowIndex = idx;
                *stop = YES;
            }
        }];
        
        if (rowIndex < NSUIntegerMax) {
            NSLog(@"found row: %i", rowIndex);
        }
    }
    
    if ([recongizer state] == UIGestureRecognizerStateChanged) {
        NSLog(@"%@", NSStringFromCGPoint(panPoint));
    }
    
    if ([recongizer state] == UIGestureRecognizerStateRecognized || [recongizer state] == UIGestureRecognizerStateCancelled) {
        NSLog(@"Ended");
    }
}

- (void)reloadData
{
    //TODO: do initial math
    
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect drawingRect = UIEdgeInsetsInsetRect(rect, _edgeInsets);
    
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
    _rowOriginsY = [[NSMutableArray alloc] initWithCapacity:numberOfRows];
    
    
    for (int row = 0; row < numberOfRows; row++) {
    
        CGFloat previousColOriginX = drawingRect.origin.x;
        
        //Calculate row spacing. If not first or last row, ask for interrow spacing
        CGFloat rowOriginY = previousRowOriginY;
        CGFloat rowSpacing = DEFAULT_ROW_SPACING;
        if (row > 0 && row < numberOfRows) {
            if ([_dataSource respondsToSelector:@selector(cinemaView:interRowSpacingForRow:)]) {
                rowSpacing = [_dataSource cinemaView:self interRowSpacingForRow:row];
            }
            rowOriginY += rowSpacing;
        }
        rowOriginY += seatSize.height;
        previousRowOriginY = rowOriginY;
        [_rowOriginsY addObject:@(previousRowOriginY)];
        
        //calculate seat position
        CGRect seatRect = CGRectZero;
        seatRect.origin.y = rowOriginY;
        seatRect.size = seatSize;

        for (int col = 0; col < numberOfCols; col++) {
            
            CGFloat colOriginX = previousColOriginX;
            if (col > 0) {
                colOriginX += colSpacing;
            }
            previousColOriginX = colOriginX;
            
            seatRect.origin.x = colOriginX + col * seatSize.width;
            
            KKSeatLocation location;
            location.row = row;
            location.col = col;
            
            KKSeatType seatType = [_dataSource cinemaView:self seatTypeForLocation:location];
            
            drawSeat(context, seatRect, location, seatType);
        }
    }
}

void drawSeat(CGContextRef context, CGRect rect, KKSeatLocation location, KKSeatType type)
{
    CGContextSaveGState(context);
    CGContextSetFillColorWithColor(context, colorRefForSeatType(type));
    CGContextFillRect(context, rect);
    CGContextRestoreGState(context);
}

CGColorRef colorRefForSeatType(KKSeatType type)
{
    if (type == KKSeatTypeNone) {
        static dispatch_once_t onceToken;
        static CGColorRef color;
        dispatch_once(&onceToken, ^{
            color = [UIColor whiteColor].CGColor;
        });
        return color;
    }
    else if (type == KKSeatTypeFree) {
        static dispatch_once_t onceToken;
        static CGColorRef color;
        dispatch_once(&onceToken, ^{
            color = [UIColor blueColor].CGColor;
        });
        return color;
    }
    else if (type == KKSeatTypeReserved) {
        static dispatch_once_t onceToken;
        static CGColorRef color;
        dispatch_once(&onceToken, ^{
            color = [UIColor redColor].CGColor;
        });
        return color;
    }
    else if (type == KKSeatTypeSelected) {
        static dispatch_once_t onceToken;
        static CGColorRef color;
        dispatch_once(&onceToken, ^{
            color = [UIColor greenColor].CGColor;
        });
        return color;
    }
    return NULL;
}

@end
