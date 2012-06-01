//
//  TasksListTVC.h
//  DuffTimeCard
//
//  Created by Brian Anderson on 5/30/12.
//  Copyright (c) 2012 Duff Research. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Task.h"
#import "Project.h"
#import "RemoteAccess.h"
#import "TaskDetailTVC.h"

@interface TasksListTVC : UITableViewController <RemoteAccessProtocol, TaskDetailTVCDelegate>

@property (strong, nonatomic) NSString *projectName;
@property (strong, nonatomic) NSNumber *projectID;
@property (strong, nonatomic) NSArray *tasks;

@end
