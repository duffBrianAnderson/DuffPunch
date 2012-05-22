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
@property (strong, nonatomic) id <RemoteAccessProtocol> delegate;

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
        
        id hoursNSNumber = [currentTask objectForKey:@"hours"];
        int hours = 0;
        if(![hoursNSNumber isMemberOfClass:[NSNull class]])
           hours = [(NSNumber *)[currentTask objectForKey:@"hours"] intValue];
        
        int projectIndex = [(NSNumber *)[currentTask objectForKey:@"project_id"] intValue];
        NSString *notes = [currentTask objectForKey:@"notes"];
        
        [projectIdForCurrentUserBuilder addObject:[[NSNumber alloc] initWithInt:projectIndex]];
        
        Task *taskToAdd = [[Task alloc] initWithName:name hours:hours projectIndex:projectIndex notes:notes];
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

- (BOOL)submitNewTask:(Task *)task
{
    BOOL success = false;
    
    // do http post and then return whether it was successful or not.
    return success;
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

// NSURLConnectionDataDelegate methods:

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    int code = [httpResponse statusCode];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if(self.receivedData == nil)
        self.receivedData = [[NSMutableData alloc] initWithData:data];
    else 
      [self.receivedData appendData:data];
        
}

//- (NSInputStream *)connection:(NSURLConnection *)connection needNewBodyStream:(NSURLRequest *)request;
//- (void)connection:(NSURLConnection *)connection   didSendBodyData:(NSInteger)bytesWritten
// totalBytesWritten:(NSInteger)totalBytesWritten
//totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite;

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
        if([GET_PROJECT_URL isEqualToString:connection.currentRequest.URL.absoluteString])
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
            self.delegate = nil;
        }
}




@end
