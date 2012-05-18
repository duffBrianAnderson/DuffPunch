//
//  SubmitHoursViewController.m
//  DuffTimeCard
//
//  Created by Brian Anderson on 5/16/12.
//  Copyright (c) 2012 Duff Research. All rights reserved.
//

#import "SubmitHoursViewController.h"
#import "Task.h"
#import "RemoteAccess.h"

@interface SubmitHoursViewController()

@property (nonatomic) int currentProjectID;
@property (strong, nonatomic) Task *currentTask;
@property (strong, nonatomic) NSArray *tasks;
@property (strong, nonatomic) NSDictionary *projectNamesTable;

@end

@implementation SubmitHoursViewController

@synthesize hoursLabel = mHoursLabel;
@synthesize currentTaskButton = mCurrentTaskButton;
@synthesize currentTask = mCurrentTask;
@synthesize currentProjectID = mCurrentProjectID;
@synthesize tasks = mTasks;
@synthesize projectNamesTable = mProjectNamesTable;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    RemoteAccess *remoteAccess = [RemoteAccess getInstance];
    
    self.tasks = [remoteAccess getTasks];    
    self.projectNamesTable = [remoteAccess getProjectNamesTable];
}

- (void)viewDidUnload
{
    [self setHoursLabel:nil];
    [self setCurrentTaskButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)onStepperValueChanged:(id)sender 
{
    int newValue = (int)((UIStepper *)sender).value;
    self.hoursLabel.text = [NSString stringWithFormat:@"%d", newValue];
}

- (IBAction)onSubmit
{
   // use http post and send the new task up to server
}

@end
