//
//  Project.h
//  DuffTimeCard
//
//  Created by Brian Anderson on 5/30/12.
//  Copyright (c) 2012 Duff Research. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Task.h"

@interface Project : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSNumber *projectID;
@property (strong, nonatomic) NSMutableArray *tasks;

- (Project *)initWithName:(NSString *)name withID:(NSNumber *)projectID;
- (void)addTask:(Task *)task;
- (int)numTasks;
- (NSArray *)getTaskArray;

@end
