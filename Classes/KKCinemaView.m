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
    if (KKSeatLocationIsInvalid(location) || KKSeatLocationIsInvalid(otherLocation))
        return NO;
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

@interface NSMutableArray (KKSeatLocation)

- (void)addLocation:(KKSeatLocation)location;
- (void)removeLocation:(KKSeatLocation)location;
- (BOOL)containsLocation:(KKSeatLocation)location;
- (BOOL)containsLocation:(KKSeatLocation)location index:(NSUInteger *)index;

@end

#define DEFAULT_COL_SPACING 1
#define DEFAULT_ROW_SPACING 1

#define MINIMUM_ZOOM_SCALE 1.0
#define MAXIMUM_ZOOM_SCALE 3.0
#define ZOOM_SCALE MAXIMUM_ZOOM_SCALE

@interface KKCinemaView () <UIScrollViewDelegate>

//array of selected locations (wrapped in NSValue)
@property (nonatomic, strong) NSMutableArray* selectedSeatLocations;

//key location, value seat view
@property (nonatomic, strong) NSMutableDictionary* seatViews;

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
    
    id <KKCinemaViewDelegate> _realDelegate;        //helper delegate to forward all delegate methos
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
    
    self.minimumZoomScale = MINIMUM_ZOOM_SCALE;
    self.maximumZoomScale = MAXIMUM_ZOOM_SCALE;
    
    _contentView = [[UIView alloc] initWithFrame:self.bounds];
    _contentView.backgroundColor = self.backgroundColor;
    _contentView.clipsToBounds = YES;
    [self addSubview:_contentView];
    
    //self.delegate = self;   //TODO: create delegate proxy here
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
    [_contentView setBackgroundColor:backgroundColor];
}

- (void)reloadData
{
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
    
    //remove all seats
    [self.seatViews removeAllObjects];
    
    _colSpacing = DEFAULT_COL_SPACING;
    if ([self.dataSource respondsToSelector:@selector(interColSpacingInCinemaView:)]) {
        _colSpacing = [self.dataSource interColSpacingInCinemaView:self];
    }
    
    //calcuclate seat size
    CGFloat seatWidth = (CGRectGetWidth(_drawingRect) - (_numberOfCols-1)*_colSpacing)/_numberOfCols;
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
            seatView.backgroundColor = [self colorForSeatType:seatType];
            
            [_contentView addSubview:seatView];
            
            //save view to seatView by its location but not KKSeatTypeNone
            if (seatType != KKSeatTypeNone) {
                [self.seatViews setObject:seatView forKey:NSStringFromKKSeatLocation(location)];
            }
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

- (NSMutableArray *)selectedSeatLocations
{
    if (_selectedSeatLocations == nil) {
        _selectedSeatLocations = [[NSMutableArray alloc] init];
    }
    return _selectedSeatLocations;
}

- (NSMutableDictionary *)seatViews
{
    if (_seatViews == nil) {
        _seatViews = [[NSMutableDictionary alloc] init];
    }
    return _seatViews;
}

- (NSArray *)locationsOfSelectedSeats
{
    return _selectedSeatLocations ? [NSArray arrayWithArray:_selectedSeatLocations] : nil;
}

#pragma mark
#pragma mark Private Methods

- (void)panGestureRecognized:(UIPanGestureRecognizer*)recognizer
{
    /**
     TODO:
     - check if location is out of drawing bounds (within edge insets and last drawed row of seats)
     - dispatch selection/deselection of same seat only once at a time (pan gesture is called after each panning)
     */
    
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
    /**
     TODO:
     - check if location is out of drawing bounds (within edge insets and last drawed row of seats)
     */
    
    CGPoint tapPoint = [recognizer locationInView:self];
    
    if ([recognizer state] == UIGestureRecognizerStateRecognized) {
        KKSeatLocation location = [self locationAtPoint:tapPoint];
        
        if ([self isZoomed] == NO && self.zoomAutomatically) {
            [self zoomAtLocation:location animated:YES];
        }
        else {
            [self didSelectSeatAtLocation:location];
        }
    }
}

- (void)didSelectSeatAtLocation:(KKSeatLocation)location
{
    if ([self.selectedSeatLocations containsLocation:location]) {
        [self deselectSeatAtLocation:location];
    }
    else {
        [self selectSeatAtLocation:location];
    }
}

- (void)selectSeatAtLocation:(KKSeatLocation)location
{
    //if is invalid or type None
    if (KKSeatLocationIsInvalid(location))
        return;
    
    //if selected seat is of type None
    UIView *seatView = [self seatAtLocation:location];
    if (seatView == nil)
        return;
    
    BOOL shouldSelect = YES;
    if ([self.delegate respondsToSelector:@selector(cinemaView:shouldSelectSeatAtLocation:)]) {
        shouldSelect = [self.delegate cinemaView:self shouldSelectSeatAtLocation:location];
    }
    
    if (shouldSelect) {
        [self.selectedSeatLocations addLocation:location];

        //visually select seat
        seatView.backgroundColor = [self colorForSeatType:KKSeatTypeSelected];
        
        if ([self.delegate respondsToSelector:@selector(cinemaView:didSelectSeatAtLocation:)]) {
            [self.delegate cinemaView:self didSelectSeatAtLocation:location];
        }
        
        if (self.maximumSeatsToSelect > 0 && self.zoomAutomatically && self.maximumSeatsToSelect == [self.selectedSeatLocations count]) {
            [self unzoomAnimated:YES];
        }
    }
}

- (void)deselectSeatAtLocation:(KKSeatLocation)location
{
    if (KKSeatLocationIsInvalid(location))
        return;
    
    UIView *seatView = [self seatAtLocation:location];
    if (seatView == nil)
        return;
    
    BOOL shouldDeselect = YES;
    if ([self.delegate respondsToSelector:@selector(cinemaView:shouldDeselectSeatAtLocation:)]) {
        shouldDeselect = [self.delegate cinemaView:self shouldDeselectSeatAtLocation:location];
    }
    
    if (shouldDeselect) {
        [self.selectedSeatLocations removeLocation:location];

        //visually deselect seat
        KKSeatType seatType = [self.dataSource cinemaView:self seatTypeForLocation:location];
        seatView.backgroundColor = [self colorForSeatType:seatType];
        
        if ([self.delegate respondsToSelector:@selector(cinemaView:didDeselectSeatAtLocation:)]) {
            [self.delegate cinemaView:self didDeselectSeatAtLocation:location];
        }
    }
}

- (UIView*)seatAtLocation:(KKSeatLocation)location
{
    return [self.seatViews objectForKey:NSStringFromKKSeatLocation(location)];
}

- (UIColor*)colorForSeatType:(KKSeatType)type
{
    if (type == KKSeatTypeNone) {
        return self.backgroundColor;
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
    else if (type == KKSeatTypeWheelChair) {
        static dispatch_once_t onceToken;
        static UIColor* color;
        dispatch_once(&onceToken, ^{
            color = [UIColor grayColor];
        });
        return color;
    }
    return nil;
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
    zoomRect.origin.y
    = point.y - (zoomRect.size.height / 2.0);
    
    return zoomRect;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return _contentView;
}

- (void)zoomAtLocation:(KKSeatLocation)location animated:(BOOL)animated
{
    UIView *seatView = [self seatAtLocation:location];
    CGPoint center = seatView.center;
    [self zoomAtPoint:center scale:ZOOM_SCALE animated:animated];
}

- (void)unzoomAnimated:(BOOL)animated
{
    if ([self isZoomed]) {
        [self zoomToRect:self.bounds animated:animated];
    }
}

#pragma mark
#pragma mark Delegate Forwarding Methods

- (void)setDelegate:(id<KKCinemaViewDelegate>)delegate
{
    _realDelegate = delegate;
    [super setDelegate:self];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if (aSelector == @selector(viewForZoomingInScrollView:)) {
        return YES;
    }
    else if ([_realDelegate respondsToSelector:aSelector]) {
        return YES;
    }
    return [super respondsToSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    if ([_realDelegate respondsToSelector:aSelector]) {
        return _realDelegate;
    }
    return [super forwardingTargetForSelector:aSelector];
}

@end

@implementation NSValue (KKSeatLocation)

+ (instancetype)valueWithKKSeatLocation:(KKSeatLocation)location
{
    return [NSValue value:&location withObjCType:@encode(KKSeatLocation)];
}

- (KKSeatLocation)seatLocationValue
{
    KKSeatLocation location;
    [self getValue:&location];
    return location;
}

@end

@implementation NSMutableArray (KKSeatLocation)

- (void)addLocation:(KKSeatLocation)location
{
    NSAssert(KKSeatLocationIsInvalid(location) == NO, @"Seat location is invalid");
    if ([self containsLocation:location] == NO) {
        NSValue *value = [NSValue valueWithKKSeatLocation:location];
        [self addObject:value];
    }
}

- (void)removeLocation:(KKSeatLocation)location
{
    NSAssert(KKSeatLocationIsInvalid(location) == NO, @"Seat location is invalid");
    
    NSUInteger index;
    if ([self containsLocation:location index:&index]) {
        [self removeObjectAtIndex:index];
    }
}

- (BOOL)containsLocation:(KKSeatLocation)location index:(NSUInteger *)index
{
    if (KKSeatLocationIsInvalid(location))
        return NO;
    
    __block BOOL contains = NO;
    [self enumerateObjectsUsingBlock:^(NSValue* value, NSUInteger idx, BOOL *stop) {
        if (KKSeatLocationEqualsToLocation([value seatLocationValue], location)) {
            contains = YES;
            if (index != NULL) {
                *index = idx;
            }
            *stop = YES;
        }
    }];
    
    return contains;
}

- (BOOL)containsLocation:(KKSeatLocation)location
{
    return [self containsLocation:location index:NULL];
}

@end






















