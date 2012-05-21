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

@property (strong, nonatomic) NSString *serverName;
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *password;
@property (strong, nonatomic) NSString *authString;

@end

@implementation RemoteAccess

NSString * const GET_TASK_URL = @"https://timetrackerservice.herokuapp.com/tasks.json";
NSString * const GET_PROJECT_URL = @"https://timetrackerservice.herokuapp.com/projects.json";

static RemoteAccess *mSharedInstance  = nil;

@synthesize authString = mAuthString;
@synthesize tasks = mTasks;
@synthesize projectNames = mProjectNames;
@synthesize projectIdsForCurrentUser = mProjectIdsForCurrentUser;
@synthesize serverName = mServerName;
@synthesize email = mEmail;
@synthesize password = mPassword;
@synthesize isLoggedIn = mIsLoggedIn;
@synthesize mostRecentTask = mMostRecentTask;

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
        mServerName = serverName;
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


- (BOOL)synchronizeWithServer
{
    BOOL success = true;
    
    NSURLResponse *projectResponse = [[NSHTTPURLResponse alloc] init];
    NSURLResponse *taskResponse = [[NSHTTPURLResponse alloc] init];
    
    // get complete project list:
    NSData *projectsData = [self requestDataFromServer:GET_PROJECT_URL response:projectResponse];
    self.projectNames = [self createProjectNamesTableFromJSON:projectsData];
    
    //get the tasks for this user:
    NSData *tasksData = [self requestDataFromServer:GET_TASK_URL response:taskResponse];
    self.tasks = [self createTaskArrayFromJSON:tasksData];
    
    int x = [(NSHTTPURLResponse *)projectResponse statusCode];
    int y = [(NSHTTPURLResponse *)taskResponse statusCode];
    
//    NSLog(@"%d, %d", x , y);
//    
//    if(x != 200 || y != 200)
//        success = false;
    
    return success;
}


- (NSData *)requestDataFromServer:(NSString *)serverName response:(NSURLResponse *)response
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:serverName]];
    
    NSData *authData = [mAuthString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64Encoding]];    
    [request setValue:authValue forHTTPHeaderField:@"Authorization"];
    
//    NSURLResponse *outResponse;
//    NSError *outError;
    
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
    return returnData;
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

- (void)logout
{
    self.email = nil;
    self.password = nil;
    self.authString = nil;
    self.isLoggedIn = false;
}

@end
