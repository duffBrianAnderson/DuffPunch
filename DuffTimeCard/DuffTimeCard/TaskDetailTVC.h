//
//  TaskDetailTVC.h
//  DuffTimeCard
//
//  Created by Brian Anderson on 5/31/12.
//  Copyright (c) 2012 Duff Research. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Task.h"

@interface TaskDetailTVC : UITableViewController <UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *projectNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *taskNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *hoursLabel;
@property (weak, nonatomic) IBOutlet UILabel *notesLabel;

@property (strong, nonatomic) Task *task;

@end
