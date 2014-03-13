//
//  KKViewController.m
//  Cinemas
//
//  Created by Peter Stajger on 12/03/14.
//  Copyright (c) 2014 KinemaKity. All rights reserved.
//

#import "KKCinemaViewController.h"

@interface KKCinemaViewController ()

@end

@implementation KKCinemaViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.cinemaView reloadData];
}

#pragma mark
#pragma mark KKCinemaViewDataSource Methods


- (NSUInteger)numberOfRowsInCinemaView:(KKCinemaView*)cinemaView
{
    return 10;
}

- (NSUInteger)numberOfColsInCinemaView:(KKCinemaView *)cinemaView
{
    return 14;
}

- (CGFloat)cinemaView:(KKCinemaView*)cinemaView interRowSpacingForRow:(NSUInteger)row
{
    return row * 2;
}

- (CGFloat)interColSpacingInCinemaView:(KKCinemaView *)cinemaView
{
    return 1;
}

- (KKSeatType)cinemaView:(KKCinemaView *)cinemaView seatTypeForLocation:(KKSeatLocation)location
{
    if (location.row == 0 || location.row == 9) {
        if (location.col < 2 || location.col > 11) {
            return KKSeatTypeNone;
        }
    }
    
    if (location.row % 2 == 0) {
        return KKSeatTypeFree;
    }
    else
        return KKSeatTypeSelected;
}

@end
