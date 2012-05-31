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
#import "DuffTimeCardAppDelegate.h"
#import <AudioToolbox/AudioToolbox.h>

@interface SubmitHoursViewController()

@property (nonatomic) int currentProjectID;
@property (strong, nonatomic) Task *currentTask;
@property (strong, nonatomic) NSArray *tasks;
@property (strong, nonatomic) NSDictionary *projectNamesTable;
@property (strong, nonatomic) NSArray *projectIdsForCurrentUser;

@property (nonatomic) BOOL submitOK;
@property (nonatomic) BOOL shouldSubmitNewTask;
@property (strong, nonatomic) UIView *animateView;

@end

@implementation SubmitHoursViewController

@synthesize hoursLabel = mHoursLabel;
@synthesize projectScroller = mProjectScroller;
@synthesize loadingView = mLoadingView;
@synthesize notesTextField = mNotesTextField;
@synthesize taskNameTextField = mTaskNameTextField;
@synthesize projectPageControl = mProjectPageControl;
@synthesize submitButton = mSubmitButton;
@synthesize syncButton = mSyncButton;
@synthesize fullHour = mFullHour;
@synthesize halfHour = mHalfHour;
@synthesize currentTask = mCurrentTask;
@synthesize currentProjectID = mCurrentProjectID;
@synthesize tasks = mTasks;
@synthesize projectNamesTable = mProjectNamesTable;
@synthesize projectIdsForCurrentUser = mProjectIdsForCurrentUser;

@synthesize animateView = mAnimateView;

@synthesize submitOK = mSubmitOK;
@synthesize shouldSubmitNewTask = mShouldSubmitNewTask;

SystemSoundID mEasterEggSound;

- (void)viewDidLoad
{
    [super viewDidLoad];
     DuffTimeCardAppDelegate *appDelegate = (DuffTimeCardAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.submitTaskViewController = self;
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
    [self setSubmitButton:nil];
    [self setSyncButton:nil];
    [self setFullHour:nil];
    [self setHalfHour:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)resetUIToDefaults
{
    self.hoursLabel.text = @"8";
    self.taskNameTextField.text = @"";
    self.notesTextField.text = @"";
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
}

- (IBAction)backgroundTap:(id)sender
{
    [self.taskNameTextField resignFirstResponder];
    [self.notesTextField resignFirstResponder];
}

- (void)viewWillAppear:(BOOL)animated
{
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

const int fullHourLabelTag = 0;
const int halfHourLabelTag = 1;

- (IBAction)onStepperValueChanged:(UIStepper *)sender 
{
    double newValue = sender.value;
    
    self.fullHour.value = newValue;
    self.halfHour.value = newValue;

    self.hoursLabel.text = [NSString stringWithFormat:@"%g", newValue];
}

- (IBAction)onSubmit
{
    [self enableSyncAndSubmitButtons:NO];
    [self updateSubmitButton];
    
    if([self.taskNameTextField.text isEqualToString:@"DUFF"])
    {
        [self easterEggAnimate];
    }
    else if(self.submitOK)
    {    
        //create the new task
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd"];
        NSString *todaysDateFormatted = [formatter stringFromDate:[[NSDate alloc] init]];
        
        self.currentTask = [[Task alloc] initWithName:self.taskNameTextField.text hours:[self.hoursLabel.text doubleValue] projectIndex:self.currentProjectID notes:self.notesTextField.text date:todaysDateFormatted];
        
        // sync with the server before we push anything up there to prevent screwing things up:
        self.shouldSubmitNewTask = YES;
        [self startSync];
    }
    else 
    {
        [self enableSyncAndSubmitButtons:YES];
        UIAlertView *dialog = [[UIAlertView alloc] initWithTitle:@"Cannot submit task:" message:@"Task must have a name." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [dialog show];
    }
}

- (void)submit
{
    [[RemoteAccess getInstance] submitNewTask:self.currentTask delegate:self];
}

- (void)startSync
{
    [self.loadingView startAnimating];
    RemoteAccess *remoteAccess = [RemoteAccess getInstance];
    
    [remoteAccess synchronizeWithServer:self];
}

//####  RemoteAccessProtocol methods:
- (void)onDataSyncComplete
{
    for(UIView *view in [self.projectScroller subviews])
    {
        if([view isKindOfClass:[UILabel class]])
            [view removeFromSuperview];
    }
    
    RemoteAccess *remoteAccess = [RemoteAccess getInstance];
    self.tasks = remoteAccess.tasks;    
    self.projectNamesTable = remoteAccess.projectNames;
    self.projectIdsForCurrentUser = remoteAccess.projectIdsForCurrentUser;
    
    NSArray *colors = [NSArray arrayWithObjects:[UIColor redColor], [UIColor greenColor], [UIColor blueColor], nil];
    int numProjects = self.projectIdsForCurrentUser.count;
    
    if(numProjects == 0)
    {
        CGRect frame;
        frame.origin.x = 0;
        frame.origin.y = 0;
        frame.size = self.projectScroller.frame.size;
        
        UILabel *subview = [[UILabel alloc] initWithFrame:frame];
        subview.backgroundColor = [colors objectAtIndex:0];
        subview.text = @"No Projects";
        subview.textAlignment = UITextAlignmentCenter;
        [self.projectScroller addSubview:subview];
    }
        
    
    for (int i = 0; i < numProjects; i++)
    {
        CGRect frame;
        frame.origin.x = self.projectScroller.frame.size.width * i;
        frame.origin.y = 0;
        frame.size = self.projectScroller.frame.size;
        
        UILabel *subview = [[UILabel alloc] initWithFrame:frame];
        subview.backgroundColor = [colors objectAtIndex:i % colors.count];
        int idAsInt = [(NSNumber *)[self.projectIdsForCurrentUser objectAtIndex:i] intValue];
        subview.text = [self.projectNamesTable objectForKey:[NSString stringWithFormat:@"%d",idAsInt]];
        subview.textAlignment = UITextAlignmentCenter;
        [self.projectScroller addSubview:subview];
    }
    
    self.projectScroller.contentSize = CGSizeMake(self.projectScroller.frame.size.width * numProjects, self.projectScroller.frame.size.height);
    self.projectPageControl.numberOfPages = numProjects;
    [self.loadingView stopAnimating];
    
    CGFloat pageWidth = self.projectScroller.frame.size.width;
    int page = floor((self.projectScroller.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    self.projectPageControl.currentPage = page;
    [self updateCurrentProjectId:page];
    
    if(self.shouldSubmitNewTask)
    {
        [self submit];
    }
    else 
    {
        [self enableSyncAndSubmitButtons:YES];
    }
}

- (void)onSubmitComplete
{
    NSLog(@"submitting complete");
    UIAlertView *dialog = [[UIAlertView alloc] initWithTitle:@"Submission complete!" message:nil delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [dialog show];
    
    [self enableSyncAndSubmitButtons:YES];
    self.shouldSubmitNewTask = NO;
    self.currentTask = nil;
    [self resetUIToDefaults];
}

- (void)onSyncError
{
    [self enableSyncAndSubmitButtons:YES];
    [self.loadingView stopAnimating];
    UIAlertView *dialog = [[UIAlertView alloc] initWithTitle:@"Error syncing!" message:nil delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [dialog show];
}

- (void)onAuthError
{
    [self enableSyncAndSubmitButtons:YES];
    [self.loadingView stopAnimating];
    UIAlertView *dialog = [[UIAlertView alloc] initWithTitle:@"Username or password is wrong!" message:nil delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [dialog show];
}


// ### end protocol

- (void)updateCurrentProjectId:(int)currentID
{
    if(self.projectIdsForCurrentUser.count > 0)        
       self.currentProjectID = [(NSNumber *)[self.projectIdsForCurrentUser objectAtIndex:currentID] intValue];
}

- (void)scrollViewDidScroll:(UIScrollView *)sender 
{
    CGFloat pageWidth = self.projectScroller.frame.size.width;
    int page = floor((self.projectScroller.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    self.projectPageControl.currentPage = page;
    [self updateCurrentProjectId:page];
}

- (IBAction)onLogout:(id)sender
{
    [[RemoteAccess getInstance] logout];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)easterEggAnimate
{
    UIViewController *animationController = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"animationViewController"];
    [self addChildViewController:animationController];
    
    UIView *animationView = (UIView *)[animationController.view.subviews objectAtIndex:0];
    [self.view addSubview:animationView];
    
    int index = [self.view.subviews indexOfObject:animationView];
    
    
    NSLog(@"index = %d", index);
    
    int rightSide = self.view.frame.size.width;
    animationView.frame = CGRectMake(rightSide, animationView.frame.origin.y, animationView.frame.size.width, animationView.frame.size.height);
    
    [UIView beginAnimations: [NSString stringWithFormat:@"%d", index] context: nil];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationBeginsFromCurrentState: NO];
    [UIView setAnimationDuration:1.0f];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    [UIView setAnimationDidStopSelector:@selector(onEasterEggStop:finished:context:)];
    animationView.frame = CGRectOffset(animationView.frame, -450, 0);
    [UIView commitAnimations];
}

- (void)onEasterEggStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    int indexToRemove = animationID.intValue;
    [[self.view.subviews objectAtIndex:indexToRemove] removeFromSuperview];
    [self enableSyncAndSubmitButtons:YES];
}

- (IBAction)onSync:(id)sender
{
    [self enableSyncAndSubmitButtons:NO];
    [self startSync];
}

- (void)enableSyncAndSubmitButtons:(BOOL)shouldEnable
{
    self.syncButton.enabled = shouldEnable;
    self.submitButton.enabled = shouldEnable;
}


- (IBAction)onCopyMostRecentPressed:(id)sender 
{
    Task *recentTask = [RemoteAccess getInstance].mostRecentTask;
    
    int pageToScrollTo = [self.projectIdsForCurrentUser indexOfObject:[[NSNumber alloc] initWithInt:recentTask.projectIndex]];
    
    // it's possible for the task to have no project, if that's the case, just default to the first project.
    if(recentTask.projectIndex == -1)
        pageToScrollTo = 0;
    
    [self updateCurrentProjectId:pageToScrollTo];
    
    CGRect frame;
    frame.origin.x = self.projectScroller.frame.size.width * pageToScrollTo;
    frame.origin.y = 0;
    frame.size = self.projectScroller.frame.size;
    [self.projectScroller scrollRectToVisible:frame animated:YES];
    
    self.taskNameTextField.text = recentTask.name;
    self.hoursLabel.text = [NSString stringWithFormat:@"%g",recentTask.hours];
    self.fullHour.value = self.halfHour.value = recentTask.hours;
    self.notesTextField.text = recentTask.notes;
}

- (void)onResume
{
    NSLog(@"onResume");
}
@end
