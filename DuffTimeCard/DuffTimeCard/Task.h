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
@property (nonatomic) int hours;
@property (nonatomic) int projectIndex;
@property (strong, nonatomic) NSString *notes;

- (Task *)initWithName:(NSString *)name hours:(int)hours projectIndex:(int)projectIndex notes:(NSString *)notes;

@end
