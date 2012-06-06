//
//  Task.m
//  DuffTimeCard
//
//  Created by Brian Anderson on 5/17/12.
//  Copyright (c) 2012 Duff Research. All rights reserved.
//

#import "Task.h"

@implementation Task

@synthesize name = mName;
@synthesize hours = mHours;
@synthesize projectIndex = mProjectIndex;
@synthesize taskIndex = mTaskIndex;
@synthesize notes = mNotes;
@synthesize date = mDate;

- (Task *)initWithName:(NSString *)name hours:(double)hours projectIndex:(NSNumber *)projectIndex taskIndex:(NSNumber *)taskIndex notes:(NSString *)notes date:(NSString *)date;
{
    self = [super init];
    if(self)
    {
        self.name = name;
        self.hours = hours;
        self.projectIndex = projectIndex;
        self.taskIndex = taskIndex;
        self.notes = notes;
        self.date = date;
        return self;
    }
    
   return nil;
}


- (NSDictionary *)createJSONObjectFromTask
{
    NSArray *keyArray = [NSArray arrayWithObjects:@"task_name", @"hours", @"project_id", @"notes", @"performed_on", nil];
    NSArray *valueArray = [NSArray arrayWithObjects:self.name, [[NSNumber alloc] initWithDouble:self.hours], self.projectIndex, self.notes, self.date, nil];
    NSDictionary *jsonObj = [[NSDictionary alloc] initWithObjects:valueArray forKeys:keyArray];
    
    return jsonObj;
}

@end