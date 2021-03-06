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

@required
- (void)onDataSyncComplete;
- (void)onSyncError;
- (void)onSubmitComplete;
- (void)onAuthError;
- (void)onResponseReceivedWithStatusCode:(BOOL)success;
- (void)onDeleteComplete;

@end

@interface RemoteAccess : NSObject <NSURLConnectionDataDelegate, NSURLConnectionDelegate>

@property (strong, nonatomic) NSDictionary *projects;

@property (strong, nonatomic) NSArray *tasks;

// this dictionary is a hash table with project ids as the keys and names as values.
@property (strong, nonatomic) NSDictionary *projectNames;
@property (strong, nonatomic) Task *mostRecentTask;
@property (nonatomic) BOOL isLoggedIn;

+ (RemoteAccess *)getInstance;
- (void)loginToServer:(NSString *)serverName email:(NSString *)email password:(NSString *)password delegate:(id <RemoteAccessProtocol>)delgate;
- (void)logout;
- (void)synchronizeWithServer:(id <RemoteAccessProtocol>)delegate;
- (void)submitNewTask:(Task *)task delegate:(id <RemoteAccessProtocol>)delgate;
- (Task *)findMostRecentTask;
- (void)updateTask:(Task *)task taskID:(NSNumber *)taskID delegate:(id <RemoteAccessProtocol>)delegate;
- (void)deleteTask:(NSNumber *)taskID delegate:(id <RemoteAccessProtocol>)delegate;

@end
