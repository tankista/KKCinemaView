//
//  KKViewController.m
//  Cinemas
//
//  Created by Peter Stajger on 12/03/14.
//  Copyright (c) 2014 KinemaKity. All rights reserved.
//

#import "KKCinemaViewController.h"

@interface KKCinemaViewController ()

//@property (nonatomic, weak) IBOutlet UIStepper* <#property name#>;

@end

@implementation KKCinemaViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.cinemaView.maximumSeatsToSelect = 4;
    self.cinemaView.zoomAutomatically = YES;
    
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
    return 2;
}

- (CGFloat)interColSpacingInCinemaView:(KKCinemaView *)cinemaView
{
    return 1;
}

- (KKSeatType)cinemaView:(KKCinemaView *)cinemaView seatTypeForLocation:(KKSeatLocation)location
{
    if (location.row == 0 || location.row == 9) {
        
        if (location.col == 7 || location.col == 8) {
            return KKSeatTypeWheelChair;
        }
        if (location.col < 2 || location.col > 12) {
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
    NSLog(@"Did zoom");
}

@end
