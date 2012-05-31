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

#define CANCEL_STRING @"Cancel"
#define OK_STRING @"OK"
#define OK_BUTTON_INDEX 1

@synthesize projectNameLabel = mProjectNameLabel;
@synthesize taskNameLabel = mTaskNameLabel;
@synthesize hoursLabel = mHoursLabel;
@synthesize notesLabel = mNotesLabel;
@synthesize task = mTask;

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
    
    NSString *projectName = [[RemoteAccess getInstance].projectNames objectForKey:[NSString stringWithFormat:@"%d", self.task.projectIndex]];
    self.projectNameLabel.text = projectName;
    
    self.taskNameLabel.text = self.task.name;
    self.hoursLabel.text = [NSString stringWithFormat:@"%g", self.task.hours];
    self.notesLabel.text = self.task.notes;
}

- (void)viewDidUnload
{
    [self setProjectNameLabel:nil];
    [self setTaskNameLabel:nil];
    [self setHoursLabel:nil];
    [self setNotesLabel:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)showDialog:(int)dialogType
{
    UIAlertView *inputDialog;
    UIAlertViewStyle dialogStyle;
    NSString *dialogTitle;
    UIKeyboardType dialogKeyboardtype = UIKeyboardTypeDefault;
    int dialogTag;
    
    switch(dialogType)
    {
        case TASK_NAME_SECTION_INDEX:
        {
            dialogTitle = @"Task name";
            dialogStyle = UIAlertViewStylePlainTextInput;
            dialogTag = TASK_NAME_SECTION_INDEX;
            
            break;
        }
        case HOURS_SECTION_INDEX:
        {
            dialogTitle = @"Hours:";
            dialogStyle = UIAlertViewStylePlainTextInput;
            dialogTag = HOURS_SECTION_INDEX;
            dialogKeyboardtype = UIKeyboardTypeNumberPad;
            break;
        }
        case NOTES_INDEX:
        {
            dialogTitle = @"Notes:";
            dialogStyle = UIAlertViewStylePlainTextInput;
            dialogTag = NOTES_INDEX;
            break;
        }
    }
    
    inputDialog = [[UIAlertView alloc] initWithTitle:dialogTitle message:nil delegate:self cancelButtonTitle:CANCEL_STRING otherButtonTitles:OK_STRING, nil];
    inputDialog.alertViewStyle = dialogStyle;
    inputDialog.tag = dialogTag;
    
    [inputDialog textFieldAtIndex:0].keyboardType = dialogKeyboardtype;
    
    [inputDialog show];
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self showDialog:indexPath.section];
}


#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
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
            case HOURS_SECTION_INDEX:
            {
                labelToChange = self.hoursLabel;
                break;
            }
            case NOTES_INDEX:
            {
                labelToChange = self.notesLabel;
                break;
            }
        }
        

       labelToChange.text = [alertView textFieldAtIndex:0].text;
    }

   [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}

@end
