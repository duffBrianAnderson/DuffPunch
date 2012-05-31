//
//  Project.m
//  DuffTimeCard
//
//  Created by Brian Anderson on 5/30/12.
//  Copyright (c) 2012 Duff Research. All rights reserved.
//

#import "Project.h"

@implementation Project

@synthesize name = mName;
@synthesize projectID = mProjectID;
@synthesize tasks = mTasks;

- (Project *)initWithName:(NSString *)name withID:(NSNumber *)projectID
{
    self = [super init];
    if(self)
    {
        self.name = name;
        self.projectID = projectID;
        
        return self;
    }
    
    return nil;
}



- (void)addTask:(Task *)task
{
    if(self.tasks == nil)
        self.tasks = [[NSMutableArray alloc] init];
    
    [self.tasks addObject:task];
}


- (int)numTasks
{
    return self.tasks.count;
}

- (NSArray *)getTaskArray
{
   return [self.tasks copy];
}

@end
