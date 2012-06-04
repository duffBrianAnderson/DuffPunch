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

@interface ProjectListTVC : UITableViewController <RemoteAccessProtocol, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *recentTaskCopyButton;

@end
