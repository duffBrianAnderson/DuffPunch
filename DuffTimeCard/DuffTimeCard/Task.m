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
@synthesize notes = mNotes;

- (Task *)initWithName:(NSString *)name hours:(int)hours projectIndex:(int)projectIndex notes:(NSString *)notes;
{
    self = [super init];
    if(self)
    {
        self.name = name;
        self.hours = hours;
        self.projectIndex = projectIndex;
        self.notes = notes;
        return self;
    }
    
   return nil;
}


- (NSDictionary *)createJSONObjectFromTask
{
    NSArray *keyArray = [NSArray arrayWithObjects:@"task_name", @"hours", @"project_id", @"notes",nil];
    NSLog(@"%d", self.projectIndex);
    NSArray *valueArray = [NSArray arrayWithObjects:self.name, [[NSNumber alloc] initWithInt:self.hours], [[NSNumber alloc] initWithInt:self.projectIndex], self.notes, nil];
    NSDictionary *jsonObj = [[NSDictionary alloc] initWithObjects:valueArray forKeys:keyArray];
    
    return jsonObj;
}

@end
