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

@end
