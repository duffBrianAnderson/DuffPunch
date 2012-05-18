//
//  Project.h
//  DuffTimeCard
//
//  Created by Brian Anderson on 5/17/12.
//  Copyright (c) 2012 Duff Research. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Task.h"

@interface Project : NSObject

@property (strong, nonatomic) NSString *projectName;
@property (strong, nonatomic) NSMutableArray *tasks;

- (Project *)initWithName:(NSString *)name;

- (void)addTask:(Task *)task;

@end
