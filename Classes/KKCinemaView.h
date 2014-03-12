//
//  KKCinemaView.h
//  Cinemas
//
//  Created by Peter Stajger on 12/03/14.
//  Copyright (c) 2014 KinemaKity. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KKCinemaView;

@protocol KKCinemaViewDataSource <NSObject>

- (NSUInteger)numberOfRowsInCinemaView:(KKCinemaView*)cinemaView;
- (NSUInteger)numberOfColsInCinemaView:(KKCinemaView*)cinemaView;
//- (NSUInteger)cinemaView:(KKCinemaView*)cinemaView numberOfSeatsInRow:(NSUInteger)row;

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

@end
