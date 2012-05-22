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
@property (nonatomic) BOOL submitOK;

@end

@implementation SubmitHoursViewController

@synthesize hoursLabel = mHoursLabel;
@synthesize projectScroller = mProjectScroller;
@synthesize loadingView = mLoadingView;
@synthesize notesTextField = mNotesTextField;
@synthesize taskNameTextField = mTaskNameTextField;
@synthesize projectPageControl = mProjectPageControl;
@synthesize currentTask = mCurrentTask;
@synthesize currentProjectID = mCurrentProjectID;
@synthesize tasks = mTasks;
@synthesize projectNamesTable = mProjectNamesTable;
@synthesize projectIdsForCurrentUser = mProjectIdsForCurrentUser;
@synthesize submitOK = mSubmitOK;

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [self setHoursLabel:nil];
    [self setProjectScroller:nil];
    [self setLoadingView:nil];
    [self setTaskNameTextField:nil];
    [self setNotesTextField:nil];
    [self setTaskNameTextField:nil];
    [self setProjectPageControl:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)updateSubmitButton
{
    if([self.taskNameTextField.text length] == 0)
        self.submitOK = NO;
    else
        self.submitOK = YES;
}

- (IBAction)textFieldDoneEditing:(id)sender
{
    [sender resignFirstResponder];
    
    NSLog(@"Done editing");
    
    [self updateSubmitButton];
}

- (IBAction)backgroundTap:(id)senderg
{
    [self.taskNameTextField resignFirstResponder];
    [self.notesTextField resignFirstResponder];
    [self updateSubmitButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"view appearing");
    [self startSync];
}


- (IBAction)startEditingTextField:(id)sender 
{
    [self animateTextField:sender up:YES];
}


- (IBAction)stopEditingTextField:(id)sender 
{
    [self animateTextField:sender up:NO];
}

- (void) animateTextField: (UITextField*) textField up: (BOOL) up
{
    const int movementDistance = 150;
    const float movementDuration = 0.3f;
    
    int movement = (up ? -movementDistance : movementDistance);
    
    [UIView beginAnimations: @"anim" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    self.view.frame = CGRectOffset(self.view.frame, 0, movement);
    [UIView commitAnimations];
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
    if(self.submitOK)
    {
        // use http POST and send the new task up to server
        Task *taskToUpload = [[Task alloc] initWithName:self.taskNameTextField.text hours:[self.hoursLabel.text intValue] projectIndex:self.currentProjectID notes:self.notesTextField.text];
        
        NSLog(@"task: %@, %d, %d, %@", taskToUpload.name, taskToUpload.hours, taskToUpload.projectIndex, taskToUpload.notes);
    }
    else 
    {
        UIAlertView *dialog = [[UIAlertView alloc] initWithTitle:@"Cannot submit task:" message:@"Task must have a name." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [dialog show];
    }
}

- (void)startSync
{
    [self.loadingView startAnimating];
    RemoteAccess *remoteAccess = [RemoteAccess getInstance];
    
    [remoteAccess synchronizeWithServer:self];
}

- (void)onDataSyncComplete
{
    RemoteAccess *remoteAccess = [RemoteAccess getInstance];
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
    self.projectPageControl.numberOfPages = numProjects;
    [self.loadingView stopAnimating];
}

- (void)scrollViewDidScroll:(UIScrollView *)sender 
{
    CGFloat pageWidth = self.projectScroller.frame.size.width;
    int page = floor((self.projectScroller.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    self.projectPageControl.currentPage = page;
    self.currentProjectID = [(NSNumber *)[self.projectIdsForCurrentUser objectAtIndex:page] intValue];
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
