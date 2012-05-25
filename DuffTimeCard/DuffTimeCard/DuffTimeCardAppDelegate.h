//
//  DuffTimeCardAppDelegate.h
//  DuffTimeCard
//
//  Created by Brian Anderson on 5/15/12.
//  Copyright (c) 2012 Duff Research. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SubmitHoursViewController.h"

@interface DuffTimeCardAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) SubmitHoursViewController *submitTaskViewController;

@end
