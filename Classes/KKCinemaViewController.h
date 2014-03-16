//
//  KKViewController.h
//  Cinemas
//
//  Created by Peter Stajger on 12/03/14.
//  Copyright (c) 2014 KinemaKity. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "KKCinemaView.h"

@interface KKCinemaViewController : UIViewController <KKCinemaViewDataSource, KKCinemaViewDelegate>

@property (nonatomic, weak) IBOutlet KKCinemaView* cinemaView;

@end
