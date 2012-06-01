//
//  TaskDetailTVC.h
//  DuffTimeCard
//
//  Created by Brian Anderson on 5/31/12.
//  Copyright (c) 2012 Duff Research. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Task.h"
#import "RemoteAccess.h"

@interface TaskDetailTVC : UITableViewController <UIAlertViewDelegate, RemoteAccessProtocol>

@property (weak, nonatomic) IBOutlet UILabel *projectNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *taskNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *hoursLabel;
@property (weak, nonatomic) IBOutlet UILabel *notesLabel;
@property (weak, nonatomic) IBOutlet UIButton *submitButton;
@property (nonatomic) BOOL shouldHideSubmitButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *submittingProgressIndicator;

@property (strong, nonatomic) Task *task;

@end
