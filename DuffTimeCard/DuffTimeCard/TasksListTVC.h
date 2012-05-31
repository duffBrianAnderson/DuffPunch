//
//  TasksListTVC.h
//  DuffTimeCard
//
//  Created by Brian Anderson on 5/30/12.
//  Copyright (c) 2012 Duff Research. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Task.h"

@interface TasksListTVC : UITableViewController

@property (strong, nonatomic) NSString *projectName;
@property (strong, nonatomic) NSNumber *projectID;
@property (strong, nonatomic) NSArray *tasks;

@end
