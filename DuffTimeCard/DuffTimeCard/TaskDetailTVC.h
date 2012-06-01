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

@protocol TaskDetailTVCDelegate <NSObject>

@required

- (void)updateAfterSubmission;

@end

@interface TaskDetailTVC : UITableViewController <UIAlertViewDelegate, RemoteAccessProtocol, UITextViewDelegate>

@property (strong, nonatomic) id <TaskDetailTVCDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *projectNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *taskNameLabel;
@property (weak, nonatomic) IBOutlet UIButton *submitButton;
@property (nonatomic) BOOL isExistingTask;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *submittingProgressIndicator;
@property (weak, nonatomic) IBOutlet UIStepper *halfHourStepper;
@property (weak, nonatomic) IBOutlet UIStepper *hourStepper;
@property (weak, nonatomic) IBOutlet UILabel *hoursLabel;
@property (weak, nonatomic) IBOutlet UITextView *notesLabel;

@property (strong, nonatomic) Task *task;

@end
