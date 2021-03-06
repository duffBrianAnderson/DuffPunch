//
//  RemoteAccess.m
//  DuffTimeCard
//
//  Created by Brian Anderson on 5/17/12.
//  Copyright (c) 2012 Duff Research. All rights reserved.
//

#import "RemoteAccess.h"
#import "NSData+Additions.h"
#import "Project.h"

@interface RemoteAccess()

@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *password;
@property (strong, nonatomic) NSString *authString;

@property (strong, nonatomic) Task *possibleMostRecentTask;

//This is where we'll store the data that's downloaded before setting to the project and task data.
@property (strong, nonatomic) NSMutableData *receivedData;
@property (weak, nonatomic) id <RemoteAccessProtocol> delegate;


/*
 * When we submit, we first sync up with the server so "synchronizeWithServer" is called.
 * After syncing with the server however, the self.delegate property is nil'd out (see "connectionDidFinishLoading").  We don't want this to happen if we're kicking off a submit task,
 * so we use this property as a flag to say that we're going to submit after this sync so don't set the delegate to nil.
 */
@property (nonatomic) BOOL isAPreSubmitSync;

@end

@implementation RemoteAccess

NSString * const GET_TASK_URL = @"https://timetrackerservice.herokuapp.com/tasks.json";
NSString * const GET_PROJECT_URL = @"https://timetrackerservice.herokuapp.com/projects.json";
NSString * const TASK_URL = @"https://timetrackerservice.herokuapp.com/tasks";

NSString * const POST_COMMAND = @"POST";
NSString * const DELETE_COMMAND = @"DELETE";

static RemoteAccess *mSharedInstance  = nil;

@synthesize projects = mProjects;

@synthesize authString = mAuthString;
@synthesize tasks = mTasks;
@synthesize projectNames = mProjectNames;
@synthesize email = mEmail;
@synthesize password = mPassword;
@synthesize isLoggedIn = mIsLoggedIn;
@synthesize mostRecentTask = mMostRecentTask;

@synthesize receivedData = mReceivedData;
@synthesize delegate = mDelegate;

@synthesize isAPreSubmitSync = mIsAPreSubmitSync;

@synthesize possibleMostRecentTask = mPossibleMostRecentTask;

+ (RemoteAccess *)getInstance
{
    @synchronized (self)
    {
        if(!mSharedInstance)
            mSharedInstance = [[self alloc] init];
        
        return mSharedInstance;
    }
    return nil;
}



- (void)loginToServer:(NSString *)serverName email:(NSString *)email password:(NSString *)password delegate:(id <RemoteAccessProtocol>)delegate
{
    self.delegate = delegate;
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:serverName]];
    
    NSString *authString = [NSString stringWithFormat:@"%@:%@",email,password]; 
    NSData *authData = [authString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64Encoding]];    
    [request setValue:authValue forHTTPHeaderField:@"Authorization"];
    
    // we'll nil these out if the login fails.
    self.email = email;
    self.password = password;
    self.authString = authString;
    
    [[NSURLConnection alloc] initWithRequest:request delegate:self];
}


- (Task *)findMostRecentTask
{
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    
    //set the mostRecent to the first task in self.tasks, and loop through, changing it if necessary.
    NSDate *mostRecentSoFar = [formatter dateFromString:((Task *)[self.tasks objectAtIndex:0]).date];
    int maxIndex = 0;
    
    for(Task *currentTask in self.tasks)
    {        
        NSDate *currentDate = [formatter dateFromString:currentTask.date];
        
        if([mostRecentSoFar compare:currentDate] == NSOrderedAscending && currentTask.projectIndex.intValue != -1)
            maxIndex = [self.tasks indexOfObject:currentTask];
    }
    
    self.mostRecentTask = (Task *)[self.tasks objectAtIndex:maxIndex];
    return self.mostRecentTask;
}


- (void)requestDataFromServer:(NSString *)serverName
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:serverName]];
    
    NSData *authData = [self.authString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64Encoding]];    
    [request setValue:authValue forHTTPHeaderField:@"Authorization"];

   [[NSURLConnection alloc] initWithRequest:request delegate:self];
}


- (void)initializeData:(NSData *)jsonData
{
    NSMutableArray *tasksBuilder = [[NSMutableArray alloc] init];
    NSMutableDictionary *projectDictionaryBuilder = [[NSMutableDictionary alloc] init];
    NSArray *jsonTables = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:nil];    
    
    // loop through all tasks and initialize the data.
    for(NSDictionary *currentTask in jsonTables)
    {
        NSString *name = [currentTask objectForKey:@"task_name"];
        
        
        // it's possible to get NSNULL for "hours" or "project_id", so make sure we handle this gracefully
        
        id hoursNSNumber = [currentTask objectForKey:@"hours"];
        double hours = 0;
        if(![hoursNSNumber isMemberOfClass:[NSNull class]])
           hours = [(NSNumber *)[currentTask objectForKey:@"hours"] doubleValue];
        
        NSNumber * projectID = [currentTask objectForKey:@"project_id"];
        if([projectID isMemberOfClass:[NSNull class]])
            projectID = [[NSNumber alloc] initWithInt:-1];
        
        NSNumber *taskIndex = [currentTask objectForKey:@"id"];

        id taskDateString = [currentTask objectForKey:@"performed_on"];
        NSString * taskDate = @"null";
        if(![taskDateString isMemberOfClass:[NSNull class]])
            taskDate = (NSString *)taskDateString;
             
        NSString *notes = [currentTask objectForKey:@"notes"];
        
        Task *taskToAdd = [[Task alloc] initWithName:name hours:hours projectIndex:projectID taskIndex:taskIndex notes:notes date:taskDate];
        [tasksBuilder addObject:taskToAdd];
        
        if(![[projectDictionaryBuilder allKeys] containsObject:projectID])
        {
            Project *p = [[Project alloc] initWithName:[self.projectNames objectForKey:projectID] withID:projectID];
            [p addTask:taskToAdd];
            [projectDictionaryBuilder setObject:p forKey:projectID];
        }
        else 
        {
            Project *p = [projectDictionaryBuilder objectForKey:projectID];
            [p addTask:taskToAdd];
            [projectDictionaryBuilder setObject:p forKey:projectID];
        }
    }
    
    self.tasks = [tasksBuilder copy];
    self.projects = [projectDictionaryBuilder copy];
}


- (NSDictionary *)createProjectNamesTableFromJSON:(NSData *)jsonData
{
    NSMutableDictionary *projectsBuilder = [[NSMutableDictionary alloc] init];
    NSArray *jsonDataArray = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:nil];
    
    
    //add K/V pair for null projects:
    [projectsBuilder setObject:@"No Project" forKey:[[NSNumber alloc] initWithInt:-1]];
    
    for(NSDictionary *currentProject in jsonDataArray)
    {
        NSString *name = [currentProject objectForKey:@"name"];
        NSNumber *projectID =  (NSNumber *)[currentProject objectForKey:@"id"];

        [projectsBuilder setObject:name forKey:projectID];
    }
    
    return [projectsBuilder copy];
}


- (void)submitNewTask:(Task *)task delegate:(id <RemoteAccessProtocol>)delegate
{
    self.isAPreSubmitSync = YES;
    self.delegate = delegate;
    // do http post and then return whether it was successful or not.
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:GET_TASK_URL]];
    request.HTTPMethod = POST_COMMAND;
    
    NSData *authData = [self.authString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64Encoding]];    
    [request setValue:authValue forHTTPHeaderField:@"Authorization"];
        
    NSData *newTaskData = [NSJSONSerialization dataWithJSONObject:[task createJSONObjectFromTask] options:nil error:nil];                    
    request.HTTPBody = newTaskData;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    // the upload might fail, so we shouldn't set the most recent task to a task that never went through.  We use possibleMostRecentTask as a temp. placeholder, and if the upload is successful
    // then we set self.mostRecentTask to this guy:
    self.possibleMostRecentTask = task;
   [[NSURLConnection alloc] initWithRequest:request delegate:self];
}


- (void)updateTask:(Task *)task taskID:(NSNumber *)taskID delegate:(id <RemoteAccessProtocol>)delegate
{
//    NSString *editTaskURL = @"https://timetrackerservice.herokuapp.com/tasks/175.json";
//    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:editTaskURL]];
//    request.HTTPMethod = @"PUT";
//
//    NSData *authData = [self.authString dataUsingEncoding:NSUTF8StringEncoding];
//    NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64Encoding]];
//    [request setValue:authValue forHTTPHeaderField:@"Authorization"];
//
//    Task *theTask = [[Task alloc] initWithName:@"Updated name" hours:20 projectIndex:[[NSNumber alloc] initWithInt:-1] notes:@"Updated notes" date:@"1987-11-11"];
//    NSData *newTaskData = [NSJSONSerialization dataWithJSONObject:[theTask createJSONObjectFromTask] options:nil error:nil];
//    request.HTTPBody = newTaskData;
//    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
//
//    [[NSURLConnection alloc] initWithRequest:request delegate:self];
}


- (void)deleteTask:(NSNumber *)taskID delegate:(id <RemoteAccessProtocol>)delegate
{
    self.delegate = delegate;
    NSString *deleteTaskURL = [NSString stringWithFormat:@"%@/%d%@", TASK_URL, taskID.intValue, @".json"];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:deleteTaskURL]];
    request.HTTPMethod = DELETE_COMMAND;

    NSData *authData = [self.authString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64Encoding]];
    [request setValue:authValue forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    [[NSURLConnection alloc] initWithRequest:request delegate:self];
}


- (void)logout
{
    self.email = nil;
    self.password = nil;
    self.authString = nil;
    self.isLoggedIn = false;
    
    self.tasks = nil;
    self.projectNames = nil;
    self.projects = nil;
}


/**
 * We need to hit the server twice, first to get the hashtable of projectId's to project names, and the second to pull down all the tasks for the current user. The second is kicked off
 * in the NSURLConnectionDataDelegate method "connectionDidFinishLoading"
 */
- (void)synchronizeWithServer:(id <RemoteAccessProtocol>)delegate
{        
    self.delegate = delegate;
    [self requestDataFromServer:GET_PROJECT_URL];
}

#pragma mark - NSURLConnectionDataDelegate/NSURLConnectionDelegate methods:

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    int code = [httpResponse statusCode];
    NSLog(@"HTTP status code: %d", code);
    
    if([connection.currentRequest.URL.absoluteString isEqualToString:TASK_URL])
    {
        BOOL loginSuccess = (code == 200) ? YES : NO;   
        if(loginSuccess)
        {
            self.isLoggedIn = YES;
        }
        else 
        {
            self.email = nil;
            self.password = nil;
            self.authString = nil;
            self.isLoggedIn = NO;
        }
        
        [self.delegate onResponseReceivedWithStatusCode:loginSuccess];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if(self.receivedData == nil)
        self.receivedData = [[NSMutableData alloc] initWithData:data];
    else 
      [self.receivedData appendData:data];
        
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString *requestMethod = connection.currentRequest.HTTPMethod;
        if([connection.currentRequest.HTTPMethod isEqualToString:POST_COMMAND])
        {
            [self.delegate onSubmitComplete];
            self.delegate = nil;
            self.isAPreSubmitSync = NO;
            self.mostRecentTask = self.possibleMostRecentTask;
            self.receivedData = nil;
        }
        else if ([requestMethod isEqualToString:DELETE_COMMAND])
        {
            [self.delegate onDeleteComplete];
            self.delegate = nil;
        }
        else if([GET_PROJECT_URL isEqualToString:connection.currentRequest.URL.absoluteString])
        {            
            self.projectNames = [self createProjectNamesTableFromJSON:self.receivedData];
            
            // now get all the tasks:
            self.receivedData = nil;
            [self requestDataFromServer:GET_TASK_URL];
        }
        else if([GET_TASK_URL isEqualToString:connection.currentRequest.URL.absoluteString])
        {            
            [self initializeData:self.receivedData];
            
            [self.delegate onDataSyncComplete];
            self.receivedData = nil;
            
            if(!self.isAPreSubmitSync)
              self.delegate = nil;
        }
    
    self.receivedData = nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self.delegate onSyncError];
    self.receivedData = nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [self.delegate onAuthError];
    self.receivedData = nil;
}

@end
