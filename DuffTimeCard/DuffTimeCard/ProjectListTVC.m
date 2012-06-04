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
@property (strong, nonatomic) UIView *noProjectFooterView;

// properties for the refresh header
@property (strong, nonatomic) UIView *refreshHeaderContainer;
@property (strong, nonatomic) UIImageView *refreshArrowImageView;
@property (strong, nonatomic) UILabel *refreshLabel;
@property (strong, nonatomic) UIActivityIndicatorView *refreshSpinner;
@property (nonatomic) BOOL isDragging;
@property (nonatomic) BOOL syncing;

@end

@implementation ProjectListTVC

#define REFRESH_HEADER_HEIGHT 52.0f
#define SYNCING_STRING @"Syncing"
#define PULL_DOWN_REFRESH_MESSAGE @"Pull down to refresh"
#define NO_PROJECTS_STRING @"No projects"

@synthesize recentTaskCopyButton = mRecentTaskCopyButton;

@synthesize noProjectFooterView = mNoProjectFooterView;

@synthesize projectList = mProjectList;
@synthesize refreshHeaderContainer = mRefreshHeaderContainer;
@synthesize refreshArrowImageView = mRefreshArrowImageView;
@synthesize refreshLabel = mRefreshLabel;
@synthesize refreshSpinner = mRefreshSpinner;
@synthesize isDragging = mIsDragging;
@synthesize syncing = mSyncing;

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

    self.tableView.delegate = self;
    [self addNoProjectsTextView];
    [self addPullToRefreshHeader];
    
    [self startSync];
}

- (void)viewDidUnload
{
    [self setRefreshHeaderContainer:nil];
    [self setRefreshArrowImageView:nil];
    [self setRefreshLabel:nil];
    [self setRefreshSpinner:nil];
    [self setRecentTaskCopyButton:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.projectList = [[RemoteAccess getInstance].projects allValues];
    [self.tableView reloadData];
}

- (void)addNoProjectsTextView
{
    CGSize s = self.tableView.frame.size;
    UIFont *font = [UIFont boldSystemFontOfSize:20.0f];
    CGSize noProjectLabelDimensions = [NO_PROJECTS_STRING sizeWithFont:font];
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, s.width, s.height - 100)];
    UILabel *textView = [[UILabel alloc] initWithFrame:CGRectMake((s.width / 2) - noProjectLabelDimensions.width / 2, (s.height / 2) - noProjectLabelDimensions.height / 2, noProjectLabelDimensions.width, noProjectLabelDimensions.height)];
    
    textView.text = NO_PROJECTS_STRING;
    textView.font = font;
    
    self.noProjectFooterView = view;
    self.noProjectFooterView.hidden = YES;

    [view addSubview:textView];    
    self.tableView.tableFooterView = view;
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


#pragma mark - RemoteAccessProtocol

- (void)onDataSyncComplete
{
    [self showOrHideRefreshHeader:NO];
    RemoteAccess *remoteAccess = [RemoteAccess getInstance];
    self.projectList = [remoteAccess.projects allValues];
    
    self.noProjectFooterView.hidden = (self.projectList.count == 0) ? NO : YES;
    self.recentTaskCopyButton.enabled = (self.projectList.count == 0) ? NO: YES;
    
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
    else if([[segue identifier] isEqualToString:@"copyRecentTask"])
    {
        Task *mostRecentTask = [RemoteAccess getInstance].mostRecentTask;
        
        // mostRecentTask will be null if we haven't submitted anything yet, so just get the most recent task from the task list.
        ((TaskDetailTVC *) [segue destinationViewController]).task = (mostRecentTask) ? mostRecentTask : [[RemoteAccess getInstance] findMostRecentTask];
    }
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
