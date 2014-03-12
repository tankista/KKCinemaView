//
//  KKCinemaViewDataSource.m
//  Cinemas
//
//  Created by Peter Stajger on 12/03/14.
//  Copyright (c) 2014 KinemaKity. All rights reserved.
//

#import "KKCinemaViewDataSource.h"

@implementation KKCinemaViewDataSource

- (NSUInteger)numberOfRowsInCinemaView:(KKCinemaView*)cinemaView
{
    return 10;
}

- (NSUInteger)cinemaView:(KKCinemaView*)cinemaView numberOfSeatsInRow:(NSUInteger)row
{
    return 14;
}

@end
