//
//  KKCinemaView.m
//  Cinemas
//
//  Created by Peter Stajger on 12/03/14.
//  Copyright (c) 2014 KinemaKity. All rights reserved.
//

#import "KKCinemaView.h"
#import <objC/runtime.h>

const KKSeatLocation KKSeatLocationInvalid = {NSNotFound, NSNotFound};

bool KKSeatLocationIsInvalid(KKSeatLocation location)
{
    return location.row == NSNotFound || location.col == NSNotFound;
}

bool KKSeatLocationEqualsToLocation(KKSeatLocation location, KKSeatLocation otherLocation)
{
    return location.row == otherLocation.row && location.col == otherLocation.col;
}

NSString* NSStringFromKKSeatLocation(KKSeatLocation location)
{
    if (KKSeatLocationIsInvalid(location)) {
        return @"KKSeatLocationInvalid";
    }
    else {
        return [NSString stringWithFormat:@"{%i, %i}", location.row, location.col];
    }
}

#define DEFAULT_COL_SPACING 1
#define DEFAULT_ROW_SPACING 1

#define MINIMUM_ZOOM_SCALE 1.0
#define MAXIMUM_ZOOM_SCALE 3.0
#define ZOOM_SCALE MAXIMUM_ZOOM_SCALE

@interface KKCinemaView () <UIScrollViewDelegate>

@end

@implementation KKCinemaView
{
    UIView*                 _contentView;
    
    UIEdgeInsets            _edgeInsets;    //this insets drawing rect from view's edges
    CGRect                  _drawingRect;   //Frame, where seat layout is drawn (rect minus _edgeInsets)
    
    NSUInteger              _numberOfRows;
    NSUInteger              _numberOfCols;
    
    UIPanGestureRecognizer* _panGestureRecognizer;
    UITapGestureRecognizer* _tapGestureRecognizer;
    
    NSMutableArray*         _rowOriginsY;
    CGFloat                 _colSpacing;
    
    NSUInteger              _panGestureRowIndex;
    NSUInteger              _panGestureColIndex;
    
    CGSize                  _seatSize;
    CGSize                  _cinemaSize;            //calculated after reloadData
    
    KKSeatLocation          _lastDelegatedLocation; //last location that was sent to a delegate
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.clipsToBounds = YES;
    self.bouncesZoom = YES;
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    self.directionalLockEnabled = YES;
    
    _edgeInsets = UIEdgeInsetsMake(30, 20, 30, 20);

//    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognized:)];
//    _panGestureRecognizer.maximumNumberOfTouches = 1;
//    [self addGestureRecognizer:_panGestureRecognizer];
    
    _panGestureColIndex = NSNotFound;
    _panGestureRowIndex = NSNotFound;
    
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognized:)];
    _tapGestureRecognizer.numberOfTapsRequired = 1;
    [self addGestureRecognizer:_tapGestureRecognizer];
    
    _lastDelegatedLocation = KKSeatLocationInvalid;
    
    self.minimumZoomScale = MINIMUM_ZOOM_SCALE;
    self.maximumZoomScale = MAXIMUM_ZOOM_SCALE;
    
    _contentView = [[UIView alloc] initWithFrame:self.bounds];
    _contentView.backgroundColor = self.backgroundColor;
    _contentView.clipsToBounds = YES;
    [self addSubview:_contentView];
    
    self.delegate = self;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
    [_contentView setBackgroundColor:backgroundColor];
}

- (void)reloadData
{
    _lastDelegatedLocation = KKSeatLocationInvalid;
    [self reloadSeats];
}

- (void)reloadSeats
{
    CGRect rect = self.bounds;
    
    _drawingRect = UIEdgeInsetsInsetRect(rect, _edgeInsets);

    _numberOfRows = [self.dataSource numberOfRowsInCinemaView:self];
    NSAssert(_numberOfRows > 0, @"You must specify number of rows");
    
    _numberOfCols = [self.dataSource numberOfColsInCinemaView:self];
    NSAssert(_numberOfCols > 0, @"You must specify number of rows");
    
    _colSpacing = DEFAULT_COL_SPACING;
    if ([self.dataSource respondsToSelector:@selector(interColSpacingInCinemaView:)]) {
        _colSpacing = [self.dataSource interColSpacingInCinemaView:self];
    }
    
    //calcuclate seat size
    CGFloat seatWidth = floorf((CGRectGetWidth(_drawingRect) - (_numberOfCols-1)*_colSpacing)/_numberOfCols);
    CGFloat seatHeight = seatWidth;
    _seatSize = CGSizeMake(seatWidth, seatHeight);
    
    CGFloat previousRowOriginY = _drawingRect.origin.y;
    _rowOriginsY = [[NSMutableArray alloc] initWithCapacity:_numberOfRows];
    
    
    for (int row = 0; row < _numberOfRows; row++) {
    
        CGFloat previousColOriginX = _drawingRect.origin.x;
        
        //Calculate row spacing. If not first or last row, ask for interrow spacing
        CGFloat rowOriginY = previousRowOriginY;
        CGFloat rowSpacing = DEFAULT_ROW_SPACING;
        if (row > 0 && row < _numberOfRows) {
            if ([self.dataSource respondsToSelector:@selector(cinemaView:interRowSpacingForRow:)]) {
                rowSpacing = [self.dataSource cinemaView:self interRowSpacingForRow:row];
            }
            rowOriginY += rowSpacing;
        }
        rowOriginY += _seatSize.height;
        previousRowOriginY = rowOriginY;
        [_rowOriginsY addObject:@(previousRowOriginY)];
        
        //calculate seat position
        CGRect seatRect = CGRectZero;
        seatRect.origin.y = rowOriginY;
        seatRect.size = _seatSize;

        for (int col = 0; col < _numberOfCols; col++) {
            
            CGFloat colOriginX = previousColOriginX;
            if (col > 0) {
                colOriginX += _colSpacing;
            }
            previousColOriginX = colOriginX;
            
            seatRect.origin.x = colOriginX + col * _seatSize.width;
            
            KKSeatLocation location;
            location.row = row;
            location.col = col;
            
            KKSeatType seatType = [self.dataSource cinemaView:self seatTypeForLocation:location];
            
            UIView *seatView = [[UIView alloc] initWithFrame:seatRect];
            seatView.backgroundColor = colorRefForSeatType(seatType);
            
            [_contentView addSubview:seatView];
        }
    }

    CGFloat lastRowOriginX = [[_rowOriginsY lastObject] floatValue];
    _cinemaSize = CGSizeMake(self.frame.size.width, _edgeInsets.top + _edgeInsets.bottom + lastRowOriginX + _seatSize.height);
    
    [self sizeToFit];
}

- (CGSize)sizeThatFits:(CGSize)size
{
    return _cinemaSize;
}

- (void)sizeToFit
{
    CGRect contentRect = _contentView.frame;
    contentRect.size = _cinemaSize;
    _contentView.frame = contentRect;
}

#pragma mark
#pragma mark Private Methods

- (void)panGestureRecognized:(UIPanGestureRecognizer*)recognizer
{
    CGPoint panPoint = [recognizer locationInView:self];
    
    if ([recognizer state] == UIGestureRecognizerStateBegan) {
        _panGestureRowIndex = [self rowIndexAtPoint:panPoint];
    }
    
    if ([recognizer state] == UIGestureRecognizerStateChanged) {
        _panGestureColIndex = [self colIndexAtPoint:panPoint];
        KKSeatLocation location = {_panGestureRowIndex, _panGestureColIndex};
        [self didSelectSeatAtLocation:location];
    }
    
    if ([recognizer state] == UIGestureRecognizerStateRecognized || [recognizer state] == UIGestureRecognizerStateCancelled) {
        _panGestureColIndex = NSNotFound;
        _panGestureRowIndex = NSNotFound;
    }
}

- (void)tapGestureRecognized:(UITapGestureRecognizer*)recognizer
{
    CGPoint tapPoint = [recognizer locationInView:self];
    
    if ([recognizer state] == UIGestureRecognizerStateRecognized) {
        KKSeatLocation location = [self locationAtPoint:tapPoint];
        
        [self didSelectSeatAtLocation:location];
        
        //zoom to tap location
        if ([self isZoomed] == NO) {
            [self zoomAtPoint:tapPoint scale:ZOOM_SCALE animated:YES];
        }
        else {
            //[self zoomToRect:self.bounds animated:YES];
        }
    }
}

- (void)didSelectSeatAtLocation:(KKSeatLocation)location
{
    /**
        TODO:
        - check if location is out of drawing bounds (within edge insets and last drawed row of seats)
        - dispatch selection/deselection of same seat only once at a time (pan gesture is called after each panning)
        - ask delegate if should be selected
        - call drawing code to draw selected seat
        - call delegate that did select
        - do same but for unselection
     */
    
    //if is invalid
    if (KKSeatLocationIsInvalid(location))
        return;
    
    //if already delegated
//    if (KKSeatLocationEqualsToLocation(location, _lastDelegatedLocation))
//        return;
    
    BOOL shouldSelect = YES;
    if ([self.delegate respondsToSelector:@selector(cinemaView:shouldSelectSeatAtLocation:)]) {
        shouldSelect = [self.delegate cinemaView:self shouldSelectSeatAtLocation:location];
    }
    
    if ([self.delegate respondsToSelector:@selector(cinemaView:didSelectSeatAtLocation:)]) {
        [self.delegate cinemaView:self didSelectSeatAtLocation:location];
    }
    
    NSLog(@"selected: %@", NSStringFromKKSeatLocation(location));
    
    _lastDelegatedLocation = location;
}

UIColor* colorRefForSeatType(KKSeatType type)
{
    if (type == KKSeatTypeNone) {
        static dispatch_once_t onceToken;
        static UIColor* color;
        dispatch_once(&onceToken, ^{
            color = [UIColor whiteColor];
        });
        return color;
    }
    else if (type == KKSeatTypeFree) {
        static dispatch_once_t onceToken;
        static UIColor* color;
        dispatch_once(&onceToken, ^{
            color = [UIColor blueColor];
        });
        return color;
    }
    else if (type == KKSeatTypeReserved) {
        static dispatch_once_t onceToken;
        static UIColor* color;
        dispatch_once(&onceToken, ^{
            color = [UIColor redColor];
        });
        return color;
    }
    else if (type == KKSeatTypeSelected) {
        static dispatch_once_t onceToken;
        static UIColor* color;
        dispatch_once(&onceToken, ^{
            color = [UIColor greenColor];
        });
        return color;
    }
    return NULL;
}

#pragma mark
#pragma mark Location Methods

- (NSUInteger)rowIndexAtPoint:(CGPoint)point
{
    __block NSUInteger rowIndex = NSNotFound;
    [_rowOriginsY enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSNumber* distanceNumber, NSUInteger idx, BOOL *stop) {
        if ([distanceNumber floatValue] * self.zoomScale <= point.y) {
            rowIndex = idx;
            *stop = YES;
        }
    }];
    return rowIndex;
}

- (NSUInteger)colIndexAtPoint:(CGPoint)point
{
    NSUInteger colIndex = NSNotFound;
    for (int col = 0; col < _numberOfCols; col++) {
        CGFloat cumColSpacing = (col > 0 && col < _numberOfCols) ? col * _colSpacing * self.zoomScale : 0;
        CGFloat colOriginX = _edgeInsets.left * self.zoomScale + col * _seatSize.width * self.zoomScale + cumColSpacing;
        if (colOriginX + _seatSize.width * self.zoomScale > point.x) {
            colIndex = col;
            break;
        }
    }
    return colIndex;
}

- (KKSeatLocation)locationAtPoint:(CGPoint)point
{
    NSUInteger row = [self rowIndexAtPoint:point];
    NSUInteger col = NSNotFound;
    if (row != NSNotFound)
        col = [self colIndexAtPoint:point];
    if (col != NSNotFound) {
        return (KKSeatLocation){row, col};
    }
    return KKSeatLocationInvalid;
}

#pragma mark
#pragma mark Zooming Methods

- (BOOL)isZoomed
{
    return self.zoomScale > self.minimumZoomScale;
}

- (void)zoomAtPoint:(CGPoint)point scale:(float)scale animated:(BOOL)animated
{
    CGRect zoomRect = [self zoomRectAtPoint:point scale:scale];
    [self zoomToRect:zoomRect animated:animated];
}

- (CGRect)zoomRectAtPoint:(CGPoint)point scale:(float)scale
{
    CGRect zoomRect;
    
    zoomRect.size.height = self.frame.size.height / scale;
    zoomRect.size.width  = self.frame.size.width  / scale;
    
    zoomRect.origin.x = point.x - (zoomRect.size.width  / 2.0);
    zoomRect.origin.y = point.y - (zoomRect.size.height / 2.0);
    
    return zoomRect;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return _contentView;
}

@end