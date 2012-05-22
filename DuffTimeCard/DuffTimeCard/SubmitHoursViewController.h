//
//  SubmitHoursViewController.h
//  DuffTimeCard
//
//  Created by Brian Anderson on 5/16/12.
//  Copyright (c) 2012 Duff Research. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RemoteAccess.h"

@interface SubmitHoursViewController : UIViewController <RemoteAccessProtocol>

@property (weak, nonatomic) IBOutlet UILabel *hoursLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *projectScroller;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingView;
@property (weak, nonatomic) IBOutlet UITextField *notesTextField;
@property (weak, nonatomic) IBOutlet UITextField *taskNameTextField;

// used for keyboard dismissal
- (IBAction)textFieldDoneEditing:(id)sender;
- (IBAction)backgroundTap:(id)sender;

@end
