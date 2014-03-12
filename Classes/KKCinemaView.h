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
    KKSeatTypeReserved,
    KKSeatTypeSelected
} KKSeatType;

typedef struct {
    NSUInteger row;
    NSUInteger col;
} KKSeatLocation;

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

@interface KKCinemaView : UIView

@property (nonatomic, weak) IBOutlet id<KKCinemaViewDataSource> dataSource;

//TODO:
//- add property for seat drawing block
//- delegate to handle interaction with view
//- defautl edge insests as property

@end
