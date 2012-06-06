//
//  Task.h
//  DuffTimeCard
//
//  Created by Brian Anderson on 5/17/12.
//  Copyright (c) 2012 Duff Research. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Task : NSObject

@property (strong, nonatomic) NSString *name;
@property (nonatomic) double hours;
@property (nonatomic) NSNumber *projectIndex;
@property (nonatomic) NSNumber *taskIndex;
@property (strong, nonatomic) NSString *notes;
@property (strong, nonatomic) NSString *date;

- (Task *)initWithName:(NSString *)name hours:(double)hours projectIndex:(NSNumber *)projectIndex taskIndex:(NSNumber *)taskIndex notes:(NSString *)notes date:(NSString *)date;
- (NSDictionary *)createJSONObjectFromTask;

@end
