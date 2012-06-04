//
//  TaskDetailTVC.m
//  DuffTimeCard
//
//  Created by Brian Anderson on 5/31/12.
//  Copyright (c) 2012 Duff Research. All rights reserved.
//

#import "TaskDetailTVC.h"
#import "RemoteAccess.h"

@interface TaskDetailTVC ()

@end

@implementation TaskDetailTVC


#define PROJECT_NAME_SECTION_INDEX 0
#define TASK_NAME_SECTION_INDEX 1
#define HOURS_SECTION_INDEX 2
#define NOTES_INDEX 3
#define SUBMISSION_COMPLETE_TAG 4

#define CANCEL_STRING @"Cancel"
#define OK_STRING @"OK"
#define OK_BUTTON_INDEX 1

@synthesize delegate = mDelegate;
@synthesize projectNameLabel = mProjectNameLabel;
@synthesize taskNameLabel = mTaskNameLabel;
@synthesize submitButton = mSubmitButton;
@synthesize task = mTask;
@synthesize isExistingTask = mIsExistingTask;
@synthesize submittingProgressIndicator = mSubbmittingProgressIdicator;
@synthesize halfHourStepper = mHalfHourStepper;
@synthesize hourStepper = mHourStepper;
@synthesize hoursLabel = mHoursLabel;
@synthesize notesLabel = mNotesLabel;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = self.task.name;
    
    NSString *projectName = [[RemoteAccess getInstance].projectNames objectForKey:self.task.projectIndex];
    self.projectNameLabel.text = projectName;
    
    self.taskNameLabel.text = self.task.name;
    self.hoursLabel.text = [NSString stringWithFormat:@"%g", self.task.hours];
    self.hourStepper.value = self.task.hours;
    self.halfHourStepper.value = self.task.hours;
    self.notesLabel.text = self.task.notes;
    
    BOOL cancelTouch = NO;
    if(self.isExistingTask)
    {
        self.submitButton.hidden = YES;
        self.notesLabel.editable = NO;
        cancelTouch = YES;
    }
    
    self.notesLabel.delegate = self;
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    gestureRecognizer.cancelsTouchesInView = cancelTouch;
    [self.tableView addGestureRecognizer:gestureRecognizer];
}

- (void)dismissKeyboard
{
    [self.view endEditing:NO];
}

- (void)viewDidUnload
{
    [self setProjectNameLabel:nil];
    [self setTaskNameLabel:nil];
    [self setHoursLabel:nil];
    [self setNotesLabel:nil];
    [self setSubmitButton:nil];
    [self setSubmittingProgressIndicator:nil];
    [self setHalfHourStepper:nil];
    [self setHourStepper:nil];
    [self setHoursLabel:nil];
    [self setNotesLabel:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)onHoursChanged:(id)sender 
{
    double newValue = ((UIStepper *)sender).value;
    
    self.hourStepper.value = newValue;
    self.halfHourStepper.value = newValue;
    
    [self.hoursLabel setText:[NSString stringWithFormat:@"%g", newValue]];
}


- (void)showDialog:(int)dialogType
{
    UIAlertView *inputDialog;
    UIAlertViewStyle dialogStyle;
    NSString *dialogTitle;
    int dialogTag;
    NSString *dialogString;
    
    switch(dialogType)
    {
        case TASK_NAME_SECTION_INDEX:
        {
            dialogTitle = @"Task name";
            dialogStyle = UIAlertViewStylePlainTextInput;
            dialogTag = TASK_NAME_SECTION_INDEX;
            dialogString = self.taskNameLabel.text;
            
            break;
        }
        default:
        {
            return;
        }
    }
    
    inputDialog = [[UIAlertView alloc] initWithTitle:dialogTitle message:nil delegate:self cancelButtonTitle:CANCEL_STRING otherButtonTitles:OK_STRING, nil];
    inputDialog.alertViewStyle = dialogStyle;
    inputDialog.tag = dialogTag;
    [inputDialog textFieldAtIndex:0].text = dialogString;
    
    [inputDialog show];
}

/*
 * check all fields, make sure everything is valid before trying to submit the new task.
 */
- (BOOL)submitOK
{
    self.task.name = self.taskNameLabel.text;
    self.task.hours = self.hoursLabel.text.doubleValue;
    self.task.notes = self.notesLabel.text;
    
    return YES;
}

- (void)submitTask
{
    RemoteAccess *remoteAccess = [RemoteAccess getInstance];
    
    [remoteAccess synchronizeWithServer:self];
}


- (IBAction)submitButtonPressed:(id)sender
{
    [self.submitButton setTitle:@"Submitting" forState:UIControlStateNormal];
    [self.submittingProgressIndicator startAnimating];
    
    self.submitButton.enabled = NO;
    
    if([self.taskNameLabel.text isEqualToString:@"DUFF"])
    {
        [self easterEggAnimate];
    }
    else if([self submitOK])
    {    
        // sync with the server before we push anything up there to prevent screwing things up:
        [self submitTask];
    }
    else 
    {
        self.submitButton.enabled = YES;
        UIAlertView *dialog = [[UIAlertView alloc] initWithTitle:@"Cannot submit task:" message:@"Task must have a name." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [dialog show];
    }
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self showDialog:indexPath.section];
}


#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == SUBMISSION_COMPLETE_TAG)
    {
        [self.navigationController popViewControllerAnimated:YES];
        [self.delegate updateAfterSubmission];
        return;
    }
    
    
    if(buttonIndex == OK_BUTTON_INDEX)
    {
        UILabel *labelToChange;
        switch (alertView.tag) 
        {
            case TASK_NAME_SECTION_INDEX:
            {
                labelToChange = self.taskNameLabel;
                break;
            }
        }
        

       labelToChange.text = [alertView textFieldAtIndex:0].text;
    }

   [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}

    
    
#pragma mark - RemoteAccessProtocol
    
- (void)onResponseReceivedWithStatusCode:(int)statusCode
{
    // do nothing.
}

- (void)onDataSyncComplete
{
    [[RemoteAccess getInstance] submitNewTask:self.task delegate:self];
}

- (void)onSubmitComplete
{
    [self.submitButton setTitle:@"Submit" forState:UIControlStateNormal];    
    [self.submittingProgressIndicator stopAnimating];
    
    UIAlertView *dialog = [[UIAlertView alloc] initWithTitle:@"Submission complete!" message:nil delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    dialog.tag = SUBMISSION_COMPLETE_TAG;
    [dialog show];
}

- (void)onSyncError
{
    self.submitButton.enabled = YES;
    [self.submitButton setTitle:@"Submit" forState:UIControlStateNormal];    
    [self.submittingProgressIndicator stopAnimating];
    
    UIAlertView *dialog = [[UIAlertView alloc] initWithTitle:@"Error syncing!" message:nil delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [dialog show];
}

- (void)onAuthError
{
    self.submitButton.enabled = YES;
    [self.submitButton setTitle:@"Submit" forState:UIControlStateNormal];    
    [self.submittingProgressIndicator stopAnimating];
    
    UIAlertView *dialog = [[UIAlertView alloc] initWithTitle:@"Username or password is wrong!" message:nil delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [dialog show];
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text 
{
    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}


#pragma mark - EasterEgg

- (void)easterEggAnimate
{
    UIViewController *animationController = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"animationViewController"];
    [self addChildViewController:animationController];
    
    UIView *animationView = (UIView *)[animationController.view.subviews objectAtIndex:0];
    [self.view addSubview:animationView];
    
    int index = [self.view.subviews indexOfObject:animationView];
    
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

    self.submitButton.enabled = YES;
    [self.submitButton setTitle:@"Submit" forState:UIControlStateNormal];    
    [self.submittingProgressIndicator stopAnimating];
}

@end
