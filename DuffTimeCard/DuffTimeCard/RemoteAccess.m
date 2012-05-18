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
@property (nonatomic) BOOL isLoggedIn;

@end

@implementation RemoteAccess

NSString * const GET_TASK_URL = @"https://timetrackerservice.herokuapp.com/tasks.json";
NSString * const GET_PROJECT_URL = @"https://timetrackerservice.herokuapp.com/projects.json";

static RemoteAccess *mSharedInstance  = nil;

@synthesize authString = mAuthString;
@synthesize tasks = mTasks;
@synthesize projectNames = mProjectNames;
@synthesize serverName = mServerName;
@synthesize email = mEmail;
@synthesize password = mPassword;
@synthesize isLoggedIn = mIsLoggedIn;

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
    
    //NSString *errorMessage = [outError localizedFailureReason];
    
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

- (NSArray *)getTasks
{
    if(!self.tasks)
    {
       NSData *resultData = [self requestDataFromServer:GET_TASK_URL];
       self.tasks = [self createTaskArrayFromJSON:resultData];
    }
    
    return self.tasks;
}

- (NSData *)requestDataFromServer:(NSString *)serverName
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:serverName]];
    
    NSData *authData = [mAuthString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64Encoding]];    
    [request setValue:authValue forHTTPHeaderField:@"Authorization"];
    
    NSURLResponse *outResponse;
    NSError *outError;
    NSLog(@"getting data");
    
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&outResponse error:&outError];
    return returnData;
}

- (NSArray *)createTaskArrayFromJSON:(NSData *)jsonData
{
    NSMutableArray *tasksBuilder = [[NSMutableArray alloc] init];
    NSArray *jsonTables = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:nil];
    
    for(NSDictionary *currentTask in jsonTables)
    {
        NSString *name = [currentTask objectForKey:@"task_name"];
        int hours = [(NSNumber *)[currentTask objectForKey:@"hours"] intValue];
        int projectIndex = [(NSNumber *)[currentTask objectForKey:@"project_id"] intValue];
        NSString *notes = [currentTask objectForKey:@"notes"];
        
        Task *taskToAdd = [[Task alloc] initWithName:name hours:hours projectIndex:projectIndex notes:notes];
        [tasksBuilder addObject:taskToAdd];
    }
    
    return [tasksBuilder copy];
}

- (NSDictionary *)getProjectNamesTable
{
    if(!self.projectNames)
    {
        NSData *resultData = [self requestDataFromServer:GET_PROJECT_URL];
        self.projectNames = [self createProjectNamesTableFromJSON:resultData];
    }
    
    return self.projectNames;
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

@end
