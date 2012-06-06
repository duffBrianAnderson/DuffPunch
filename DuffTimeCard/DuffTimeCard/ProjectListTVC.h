//
//  ProjectListTVC.h
//  DuffTimeCard
//
//  Created by Brian Anderson on 5/30/12.
//  Copyright (c) 2012 Duff Research. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RemoteAccess.h"
#import "Project.h"
#import "TasksListTVC.h"

@interface ProjectListTVC : UITableViewController <RemoteAccessProtocol, UITableViewDelegate, TasksListTVCDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *recentTaskCopyButton;

@end
