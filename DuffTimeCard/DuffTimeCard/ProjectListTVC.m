//
//  ProjectListTVC.m
//  DuffTimeCard
//
//  Created by Brian Anderson on 5/30/12.
//  Copyright (c) 2012 Duff Research. All rights reserved.
//

#import "ProjectListTVC.h"
#import "TasksListTVC.h"

@interface ProjectListTVC ()

@property (strong, nonatomic) NSArray *projectList;

@end

@implementation ProjectListTVC

@synthesize projectList = mProjectList;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) 
    {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self startSync];
}


- (void)startSync
{
    [[RemoteAccess getInstance] synchronizeWithServer:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UITableViewDataSourceProtocol
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.projectList.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ProjectCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    Project *project = [self.projectList objectAtIndex:indexPath.row];
    
    cell.textLabel.text = project.name;
   
    return cell;
}

#pragma mark - UITableViewDelegateProtocol


#pragma mark - RemoteAccessProtocol

- (void)onDataSyncComplete
{
    RemoteAccess *remoteAccess = [RemoteAccess getInstance];
    self.projectList = [remoteAccess.projects allValues];
    
    [self.tableView reloadData];
}


- (void)onSyncError
{
//    [self enableSyncAndSubmitButtons:YES];
//    [self.loadingView stopAnimating];
    UIAlertView *dialog = [[UIAlertView alloc] initWithTitle:@"Error syncing!" message:nil delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [dialog show];
}


- (void)onSubmitComplete
{
    // do nothing, we're not submitting anything from this ViewController
}


- (void)onAuthError
{
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:@"ShowTasks"])
    {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        
        
        Project *selectedProject = [self.projectList objectAtIndex:indexPath.row];
        
        ((TasksListTVC *)[segue destinationViewController]).projectName = selectedProject.name;
        ((TasksListTVC *)[segue destinationViewController]).projectID = selectedProject.projectID;
        ((TasksListTVC *)[segue destinationViewController]).tasks = [selectedProject getTaskArray];
    }
}

@end