//
//  KKCinemaView.h
//  Cinemas
//
//  Created by Peter Stajger on 12/03/14.
//  Copyright (c) 2014 KinemaKity. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KKCinemaView;

typedef enum {
    KKSeatTypeNone,
    KKSeatTypeFree,
//    KKSeatTypeWheelChair, TODO: to be implemented
//    KKSeatTypeLoveSeats,  TODO: to be implemented
    KKSeatTypeReserved,
    KKSeatTypeSelected
} KKSeatType;

typedef struct {
    NSUInteger row;
    NSUInteger col;
} KKSeatLocation;

extern const KKSeatLocation KKSeatLocationInvalid;
bool KKSeatLocationIsInvalid(KKSeatLocation location);
bool KKSeatLocationEqualsToLocation(KKSeatLocation location, KKSeatLocation otherLocation);
NSString* NSStringFromKKSeatLocation(KKSeatLocation location);

@protocol KKCinemaViewDataSource <NSObject>

- (NSUInteger)numberOfRowsInCinemaView:(KKCinemaView*)cinemaView;
- (NSUInteger)numberOfColsInCinemaView:(KKCinemaView*)cinemaView;
- (KKSeatType)cinemaView:(KKCinemaView*)cinemaView seatTypeForLocation:(KKSeatLocation)location;

@optional

/**
 * Asks for height of a gap, between 2 rows. Specified *row* is row that is being offset.
 * Default value is 1;
 */
- (CGFloat)cinemaView:(KKCinemaView*)cinemaView interRowSpacingForRow:(NSUInteger)row;

/**
 * Space between cols. Default value is 1;
 */
- (CGFloat)interColSpacingInCinemaView:(KKCinemaView*)cinemaView;

@end

@protocol KKCinemaViewDelegate <UIScrollViewDelegate>

@optional

/**
 * Determine whether a seat should be selected at given location. Default is YES.
 *
 * @return NO if seat can not be selected. If you return YES, as a consequence, 
 * cinemaView:didSelectSeatAtLocation: will be called.
 */
- (BOOL)cinemaView:(KKCinemaView*)view shouldSelectSeatAtLocation:(KKSeatLocation)location;

//TODO: to be implemented
- (void)cinemaView:(KKCinemaView*)view didSelectSeatAtLocation:(KKSeatLocation)location;
//- (void)cinemaView:(KKCinemaView*)view didDeSelectSeatAtLocation:(KKSeatLocation)location;

@end

@interface KKCinemaView : UIScrollView

@property (nonatomic, weak) IBOutlet id<KKCinemaViewDataSource> dataSource;
@property (nonatomic, weak) id<KKCinemaViewDelegate> delegate;

/**
 * Forces KKCinemaView to reload it's data using dataSource and redraw whole seat layout
 */
- (void)reloadData;

//TODO:
//- add property for seat drawing block
//- delegate to handle interaction with view
//- defautl edge insests as property

@end

@interface NSValue (KKSeatLocation)

+ (instancetype)valueWithKKSeatLocation:(KKSeatLocation)location;
- (KKSeatLocation)seatLocationValue;

@end
