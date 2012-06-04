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

// properties for the refresh header
@property (strong, nonatomic) UIView *refreshHeaderContainer;
@property (strong, nonatomic) UIImageView *refreshArrowImageView;
@property (strong, nonatomic) UILabel *refreshLabel;
@property (strong, nonatomic) UIActivityIndicatorView *refreshSpinner;
@property (nonatomic) BOOL isDragging;
@property (nonatomic) BOOL syncing;

@end

@implementation TasksListTVC

//#define NEW_TASK_VIEW_HEIGHT 66
#define REFRESH_HEADER_HEIGHT 52.0f
#define SYNCING_STRING @"Syncing"
#define PULL_DOWN_REFRESH_MESSAGE @"Pull down to refresh"

@synthesize projectName = mProjectName;
@synthesize projectID = mProjectID;
@synthesize tasks = mTasks;

@synthesize refreshHeaderContainer = mRefreshHeaderContainer;
@synthesize refreshArrowImageView = mRefreshArrowImageView;
@synthesize refreshLabel = mRefreshLabel;
@synthesize refreshSpinner = mRefreshSpinner;
@synthesize isDragging = mIsDragging;
@synthesize syncing = mSyncing;

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

    [self addPullToRefreshHeader];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)addPullToRefreshHeader
{
    int screenWidth = self.view.frame.size.width;

    self.refreshHeaderContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0 - REFRESH_HEADER_HEIGHT, screenWidth, REFRESH_HEADER_HEIGHT)];

    self.refreshLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, screenWidth, REFRESH_HEADER_HEIGHT)];
    self.refreshLabel.backgroundColor = [UIColor clearColor];
    self.refreshLabel.font = [UIFont boldSystemFontOfSize:12.0];
    self.refreshLabel.textAlignment = UITextAlignmentCenter;
    self.refreshLabel.text = PULL_DOWN_REFRESH_MESSAGE;

    self.refreshSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.refreshSpinner.frame = CGRectMake(75.0f, floorf(floorf(REFRESH_HEADER_HEIGHT / 2) - 10), 20.0f, 20.0f);
    self.refreshSpinner.hidesWhenStopped = YES;

    self.refreshArrowImageView = [[UIImageView alloc] initWithFrame:CGRectMake(75.0f, floorf(floorf(REFRESH_HEADER_HEIGHT / 2) - 10), 20.0f, 20.0f)];
    self.refreshArrowImageView.image = [UIImage imageNamed:@"arrow.png"];

    [self.refreshHeaderContainer addSubview:self.refreshSpinner];
    [self.refreshHeaderContainer addSubview:self.refreshArrowImageView];
    [self.refreshHeaderContainer addSubview:self.refreshLabel];
    [self.tableView addSubview:self.refreshHeaderContainer];
}


- (void)startSync
{
    [self showOrHideRefreshHeader:YES];
    [[RemoteAccess getInstance] synchronizeWithServer:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)showOrHideRefreshHeader:(BOOL)show
{
    UIEdgeInsets targetContentInset;
    NSString *stringToSet;

    if(show)
    {
        targetContentInset = UIEdgeInsetsMake(REFRESH_HEADER_HEIGHT, 0, 0, 0);
        stringToSet = SYNCING_STRING;
        [self.refreshSpinner startAnimating];
    }
    else
    {
        targetContentInset = UIEdgeInsetsZero;
        stringToSet = PULL_DOWN_REFRESH_MESSAGE;
        [self.refreshSpinner stopAnimating];
    }

    [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.3];
        self.tableView.contentInset = targetContentInset;
        self.refreshLabel.text = stringToSet;
        self.refreshArrowImageView.hidden = show;
    [UIView commitAnimations];
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
    cell.detailTextLabel.text = currentTask.date;
    
    return cell;
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    TaskDetailTVC *destinationViewController = ((TaskDetailTVC *)[segue destinationViewController]);

    if([[segue identifier] isEqualToString:@"NewTask"])
    {        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd"];
        NSString *todaysDateFormatted = [formatter stringFromDate:[[NSDate alloc] init]];
        
        Task *newTask = [[Task alloc] initWithName:@"New Task" hours:8.0 projectIndex:self.projectID notes:@"" date:todaysDateFormatted];
        
        destinationViewController.delegate = self;
        destinationViewController.task = newTask;
    }
    else if([[segue identifier] isEqualToString:@"EditTask"])
    {
        destinationViewController.task = [self.tasks objectAtIndex:indexPath.row];
        destinationViewController.isExistingTask = YES;
        destinationViewController.delegate = self;
    }
}

#pragma mark - RemoteAccessProtocol

- (void)onDataSyncComplete
{
    [self showOrHideRefreshHeader:NO];
    RemoteAccess *remoteAccess = [RemoteAccess getInstance];
    Project *p = [remoteAccess.projects objectForKey:self.projectID];
    self.tasks = p.getTaskArray;
    
    [self.tableView reloadData];
}


- (void)onSyncError
{
    [self showOrHideRefreshHeader:NO];
    UIAlertView *dialog = [[UIAlertView alloc] initWithTitle:@"Error syncing!" message:nil delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [dialog show];
}


- (void)onSubmitComplete
{
    // do nothing, we're not submitting anything from this ViewController
}


- (void)onAuthError
{
    [self showOrHideRefreshHeader:NO];
    UIAlertView *dialog = [[UIAlertView alloc] initWithTitle:@"Username or password is wrong!" message:nil delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [dialog show];
}

#pragma mark - TaskDetailTVC

- (void)updateAfterSubmission
{
    [self startSync];
}

#pragma mark - UITableViewDelegate methods

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if(self.syncing)
        return;

    self.isDragging = YES;
}


- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if(self.syncing)
        return;

    if(scrollView.contentOffset.y <= -REFRESH_HEADER_HEIGHT)
    {
        [self startSync];
    }
}

@end
