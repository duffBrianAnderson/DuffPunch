//
//  RemoteAccess.m
//  DuffTimeCard
//
//  Created by Brian Anderson on 5/17/12.
//  Copyright (c) 2012 Duff Research. All rights reserved.
//

#import "RemoteAccess.h"
#import "NSData+Additions.h"
#import "Task.h"

@interface RemoteAccess()

@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *password;
@property (strong, nonatomic) NSString *authString;

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

static RemoteAccess *mSharedInstance  = nil;

@synthesize authString = mAuthString;
@synthesize tasks = mTasks;
@synthesize projectNames = mProjectNames;
@synthesize projectIdsForCurrentUser = mProjectIdsForCurrentUser;
@synthesize email = mEmail;
@synthesize password = mPassword;
@synthesize isLoggedIn = mIsLoggedIn;
@synthesize mostRecentTask = mMostRecentTask;

@synthesize receivedData = mReceivedData;
@synthesize delegate = mDelegate;

@synthesize isAPreSubmitSync = mIsAPreSubmitSync;

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



- (BOOL)loginToServer:(NSString *)serverName email:(NSString *)email password:(NSString *)password
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:serverName]];
    
    NSString *authString = [NSString stringWithFormat:@"%@:%@",email,password]; 
    NSData *authData = [authString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64Encoding]];    
    [request setValue:authValue forHTTPHeaderField:@"Authorization"];
    
    NSURLResponse *outResponse;
    NSError *outError;
    
    [NSURLConnection sendSynchronousRequest:request returningResponse:&outResponse error:&outError];
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) outResponse;
    int responseStatusCode = [httpResponse statusCode];
    
    if(responseStatusCode == 200)
    {
        // login succeeded
        mEmail = email;
        mPassword = password;
        mAuthString = authString;
        self.authString = authString;
        mIsLoggedIn = YES;
    }
    else 
    {
        mIsLoggedIn = NO;
    }
    
    return mIsLoggedIn;
}


- (void)requestDataFromServer:(NSString *)serverName
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:serverName]];
    
    NSData *authData = [mAuthString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64Encoding]];    
    [request setValue:authValue forHTTPHeaderField:@"Authorization"];

    [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

- (NSArray *)createTaskArrayFromJSON:(NSData *)jsonData
{
    NSMutableArray *tasksBuilder = [[NSMutableArray alloc] init];
    NSArray *jsonTables = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:nil];
    
    NSMutableSet *projectIdForCurrentUserBuilder = [[NSMutableSet alloc] init];
    
    for(NSDictionary *currentTask in jsonTables)
    {
        NSString *name = [currentTask objectForKey:@"task_name"];
        
        // it's possible to get NSNULL for "hours" or "project_id", so make sure we handle this gracefully, by simply not including a NULL project in the project scroller.
        
        id hoursNSNumber = [currentTask objectForKey:@"hours"];
        int hours = 0;
        if(![hoursNSNumber isMemberOfClass:[NSNull class]])
           hours = [(NSNumber *)[currentTask objectForKey:@"hours"] intValue];
        
        
        id projectIDNSNumber = [currentTask objectForKey:@"project_id"];
        int projectIndex = -1;
        if(![projectIDNSNumber isMemberOfClass:[NSNull class]])
           projectIndex = [(NSNumber *)[currentTask objectForKey:@"project_id"] intValue];
        
        id taskDateString = [currentTask objectForKey:@"performed_on"];
        NSString * taskDate = @"null";
        if(![taskDateString isMemberOfClass:[NSNull class]])
            taskDate = (NSString *)taskDateString;
             
        NSString *notes = [currentTask objectForKey:@"notes"];
        
        if(projectIndex != -1)
           [projectIdForCurrentUserBuilder addObject:[[NSNumber alloc] initWithInt:projectIndex]];
        
        Task *taskToAdd = [[Task alloc] initWithName:name hours:hours projectIndex:projectIndex notes:notes date:taskDate];
        [tasksBuilder addObject:taskToAdd];
    }
    
    self.projectIdsForCurrentUser = [projectIdForCurrentUserBuilder allObjects];
    
    return [tasksBuilder copy];
}


- (NSDictionary *)createProjectNamesTableFromJSON:(NSData *)jsonData
{
    NSMutableDictionary *projectsBuilder = [[NSMutableDictionary alloc] init];
    NSArray *jsonDataArray = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:nil];
    
    for(NSDictionary *currentProject in jsonDataArray)
    {
        NSString *name = [currentProject objectForKey:@"name"];
        int projectID =  [(NSNumber *)[currentProject objectForKey:@"id"] intValue];

        [projectsBuilder setValue:name forKey:[NSString stringWithFormat:@"%d", projectID]];
    }
    
    return [projectsBuilder copy];
}


- (void)submitNewTask:(Task *)task delegate:(id <RemoteAccessProtocol>)delegate
{
    self.isAPreSubmitSync = YES;
    self.delegate = delegate;
    // do http post and then return whether it was successful or not.
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:GET_TASK_URL]];
    request.HTTPMethod = @"POST";
    
    NSData *authData = [mAuthString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64Encoding]];    
    [request setValue:authValue forHTTPHeaderField:@"Authorization"];
        
    NSData *newTaskData = [NSJSONSerialization dataWithJSONObject:[task createJSONObjectFromTask] options:nil error:nil];                    
    request.HTTPBody = newTaskData;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [[NSURLConnection alloc] initWithRequest:request delegate:self];
}


- (void)logout
{
    self.email = nil;
    self.password = nil;
    self.authString = nil;
    self.isLoggedIn = false;
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

// ### NSURLConnectionDataDelegate/NSURLConnectionDelegate methods:

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    int code = [httpResponse statusCode];
    NSLog(@"HTTP status code: %d", code);
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
        if([connection.currentRequest.HTTPMethod isEqualToString:@"POST"])
        {
            [self.delegate onSubmitComplete];
            self.delegate = nil;
            self.isAPreSubmitSync = NO;
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
            self.tasks = [self createTaskArrayFromJSON:self.receivedData];

            [self.delegate onDataSyncComplete];
            self.receivedData = nil;
            
            if(!self.isAPreSubmitSync)
              self.delegate = nil;
        }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self.delegate onSyncError];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [self.delegate onAuthError];
}

// #### end delegate methods.

@end
