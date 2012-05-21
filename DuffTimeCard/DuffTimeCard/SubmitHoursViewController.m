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
@property (strong, nonatomic) NSArray *projectIdsForCurrentUser;

@end

@implementation SubmitHoursViewController

@synthesize hoursLabel = mHoursLabel;
@synthesize currentTaskButton = mCurrentTaskButton;
@synthesize projectScroller = mProjectScroller;
@synthesize loadingView = mLoadingView;
@synthesize currentTask = mCurrentTask;
@synthesize currentProjectID = mCurrentProjectID;
@synthesize tasks = mTasks;
@synthesize projectNamesTable = mProjectNamesTable;
@synthesize projectIdsForCurrentUser = mProjectIdsForCurrentUser;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSLog(@"viewDidLoad");
    
//    if([remoteAccess synchronizeWithServer])
//    {
//       self.tasks = remoteAccess.tasks;    
//       self.projectNamesTable = remoteAccess.projectNames;
//       self.projectIdsForCurrentUser = remoteAccess.projectIdsForCurrentUser;
//    }
//    
//    NSArray *colors = [NSArray arrayWithObjects:[UIColor redColor], [UIColor greenColor], [UIColor blueColor], nil];
//    int numProjects = self.projectIdsForCurrentUser.count;
//    for (int i = 0; i < numProjects; i++)
//    {
//        CGRect frame;
//        frame.origin.x = self.projectScroller.frame.size.width * i;
//        frame.origin.y = 0;
//        frame.size = self.projectScroller.frame.size;
//        
//        UILabel *subview = [[UILabel alloc] initWithFrame:frame];
//        subview.backgroundColor = [colors objectAtIndex:i];
//        int idAsInt = [(NSNumber *)[self.projectIdsForCurrentUser objectAtIndex:i] intValue];
//        subview.text = [self.projectNamesTable objectForKey:[NSString stringWithFormat:@"%d",idAsInt]];
//        [self.projectScroller addSubview:subview];
//    }
//    
//    self.projectScroller.contentSize = CGSizeMake(self.projectScroller.frame.size.width * numProjects, self.projectScroller.frame.size.height);
}

- (void)viewDidUnload
{
    [self setHoursLabel:nil];
    [self setCurrentTaskButton:nil];
    [self setProjectScroller:nil];
    [self setLoadingView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"view appearing");
    [self startSync];
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
   // use http POST and send the new task up to server
}

- (void)startSync
{
    [self.loadingView startAnimating];
    RemoteAccess *remoteAccess = [RemoteAccess getInstance];
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, NULL), ^{
        BOOL success = [remoteAccess synchronizeWithServer];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(success)
            {
                self.tasks = remoteAccess.tasks;    
                self.projectNamesTable = remoteAccess.projectNames;
                self.projectIdsForCurrentUser = remoteAccess.projectIdsForCurrentUser;
                
                NSArray *colors = [NSArray arrayWithObjects:[UIColor redColor], [UIColor greenColor], [UIColor blueColor], nil];
                int numProjects = self.projectIdsForCurrentUser.count;
                for (int i = 0; i < numProjects; i++)
                {
                    CGRect frame;
                    frame.origin.x = self.projectScroller.frame.size.width * i;
                    frame.origin.y = 0;
                    frame.size = self.projectScroller.frame.size;
                    
                    UILabel *subview = [[UILabel alloc] initWithFrame:frame];
                    subview.backgroundColor = [colors objectAtIndex:i];
                    int idAsInt = [(NSNumber *)[self.projectIdsForCurrentUser objectAtIndex:i] intValue];
                    subview.text = [self.projectNamesTable objectForKey:[NSString stringWithFormat:@"%d",idAsInt]];
                    subview.textAlignment = UITextAlignmentCenter;
                    [self.projectScroller addSubview:subview];
                }
                
                self.projectScroller.contentSize = CGSizeMake(self.projectScroller.frame.size.width * numProjects, self.projectScroller.frame.size.height);
                [self.loadingView stopAnimating];
            }
            else 
            {
                NSLog(@"error");       
            }
        });
    });
}

- (IBAction)onLogout:(id)sender 
{
    [[RemoteAccess getInstance] logout];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onSync:(id)sender 
{
    for(UIView *view in [self.projectScroller subviews])
    {
        if([view isKindOfClass:[UILabel class]])
           [view removeFromSuperview];
    }
    [self startSync];
}
@end
