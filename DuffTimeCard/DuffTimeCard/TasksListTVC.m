//
//  TasksListTVC.m
//  DuffTimeCard
//
//  Created by Brian Anderson on 5/30/12.
//  Copyright (c) 2012 Duff Research. All rights reserved.
//

#import "TasksListTVC.h"
#import "TaskDetailTVC.h"

@interface TasksListTVC ()

@end

@implementation TasksListTVC

@synthesize projectName = mProjectName;
@synthesize projectID = mProjectID;
@synthesize tasks = mTasks;

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
    
    self.navigationItem.title = mProjectName;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Tasks" style:UIBarButtonItemStylePlain target:nil action:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tasks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TaskCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    Task *currentTask = [self.tasks objectAtIndex:indexPath.row];
    cell.textLabel.text = currentTask.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%g hrs",currentTask.hours];
    
    return cell;
}

#pragma mark - Table view delegate


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    if([[segue identifier] isEqualToString:@"NewTask"])
    {        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd"];
        NSString *todaysDateFormatted = [formatter stringFromDate:[[NSDate alloc] init]];
        
        Task *newTask = [[Task alloc] initWithName:@"New Task" hours:8.0 projectIndex:[self.projectID intValue] notes:@"" date:todaysDateFormatted];
        
        ((TaskDetailTVC *)[segue destinationViewController]).task = newTask;
    }
    else if([[segue identifier] isEqualToString:@"EditTask"])
    {
        ((TaskDetailTVC *)[segue destinationViewController]).task = [self.tasks objectAtIndex:indexPath.row];
        ((TaskDetailTVC *)[segue destinationViewController]).shouldHideSubmitButton = YES;
    }
}

@end
