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
    
    self.cinemaView.maximumSeatsToSelect = 5;
    self.cinemaView.zoomAutomatically = YES;
    self.cinemaView.evenOddOffsetRatio = 0.5;
    
    [self.cinemaView reloadData];
}

#pragma mark
#pragma mark KKCinemaViewDataSource Methods

- (NSUInteger)numberOfRowsInCinemaView:(KKCinemaView*)cinemaView
{
    return 16;
}

- (NSUInteger)numberOfColsInCinemaView:(KKCinemaView *)cinemaView
{
    return 30;
}

- (CGFloat)cinemaView:(KKCinemaView*)cinemaView interRowSpacingForRow:(NSUInteger)row
{
    return 1;
}

- (CGFloat)interColSpacingInCinemaView:(KKCinemaView *)cinemaView
{
    return 1;
}

static NSUInteger prev = 5;
static NSUInteger currentRow = 0;

- (KKSeatType)cinemaView:(KKCinemaView *)cinemaView seatTypeForLocation:(KKSeatLocation)location
{
    if (location.row < 10) {
        NSUInteger noneSeats = prev;
        if (location.row != currentRow && location.row%2 == 0) {
            noneSeats = prev;
            prev--;
            currentRow+=2;
        }
        
        if (location.col < noneSeats) {
            return KKSeatTypeNone;
        }
        
        NSUInteger freeSeats = 19 + location.row;
        
        if (location.col < noneSeats + freeSeats) {
            return KKSeatTypeFree;
        }
        
        return KKSeatTypeNone;
    }
    if (location.row == 11 || location.row == 13) {
        if (location.col == 0 || location.col > 28) {
            return KKSeatTypeNone;
        }
        return KKSeatTypeFree;
    }
    if (location.row == 10 || location.row == 12) {
        if (location.col == 0 || location.col > 27) {
            return KKSeatTypeNone;
        }
        return KKSeatTypeFree;
    }
    if (location.row == 14) {
        if (location.col == 29) {
            return KKSeatTypeNone;
        }
    }
    return KKSeatTypeFree;
}

#pragma mark
#pragma mark KKCinemaViewDelegate Methods

- (BOOL)cinemaView:(KKCinemaView*)view shouldSelectSeatAtLocation:(KKSeatLocation)location
{
    return YES;
}

- (BOOL)cinemaView:(KKCinemaView*)view shouldDeselectSeatAtLocation:(KKSeatLocation)location
{
    return YES;
}

- (void)cinemaView:(KKCinemaView*)view didSelectSeatAtLocation:(KKSeatLocation)location
{
    NSLog(@"Did select: %@", NSStringFromKKSeatLocation(location));
}

- (void)cinemaView:(KKCinemaView*)view didDeselectSeatAtLocation:(KKSeatLocation)location
{
    NSLog(@"Did deselect: %@", NSStringFromKKSeatLocation(location));
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    
}

@end
