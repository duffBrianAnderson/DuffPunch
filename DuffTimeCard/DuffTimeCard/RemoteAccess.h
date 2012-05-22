//
//  RemoteAccess.h
//  DuffTimeCard
//
//  Created by Brian Anderson on 5/17/12.
//  Copyright (c) 2012 Duff Research. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Task.h"

@protocol RemoteAccessProtocol <NSObject>

- (void)onDataSyncComplete;

@end

@interface RemoteAccess : NSObject <NSURLConnectionDataDelegate>

@property (strong, nonatomic) NSArray *tasks;
@property (strong, nonatomic) NSDictionary *projectNames;
@property (strong, nonatomic) NSArray *projectIdsForCurrentUser;
@property (strong, nonatomic) Task *mostRecentTask;
@property (nonatomic) BOOL isLoggedIn;

+ (RemoteAccess *)getInstance;
- (BOOL)loginToServer:(NSString *)serverName email:(NSString *)email password:(NSString *)password;
- (void)logout;
- (void)synchronizeWithServer:(id <RemoteAccessProtocol>)delegate;
- (BOOL)submitNewTask:(Task *)task;

@end
