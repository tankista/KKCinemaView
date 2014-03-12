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
- (NSUInteger)cinemaView:(KKCinemaView*)cinemaView numberOfSeatsInRow:(NSUInteger)row;

@end

@interface KKCinemaView : UIView

@property (nonatomic, weak) id<KKCinemaViewDataSource> dataSource;

@end
