//
//  LoginScreenViewController.m
//  DuffTimeCard
//
//  Created by Brian Anderson on 5/15/12.
//  Copyright (c) 2012 Duff Research. All rights reserved.
//

#import "LoginScreenViewController.h"
#import "NSData+Additions.h"

@interface LoginScreenViewController ()

@property (nonatomic) BOOL keyboardOpen;

@end

@implementation LoginScreenViewController

#define PASSWORD_FIELD_TAG 1

#define TASK_URL @"https://timetrackerservice.herokuapp.com/tasks"

@synthesize keyboardOpen = mKeyboardOpen;
@synthesize emailTextField = mEmailTextField;
@synthesize passwordTextField = mPasswordTextField;
@synthesize loginProgressIndicator = mLoginProgressIndicator;
@synthesize loginButton = mLoginButton;

- (IBAction)textFieldDoneEditing:(id)sender
{
    [sender resignFirstResponder];
    [self animateTextField:sender up:NO];
    self.keyboardOpen = NO;
    
    if([sender tag] == PASSWORD_FIELD_TAG)
    {
        [self onLogin];
    }
}

- (IBAction)backgroundTap:(id)sender
{
    [self.emailTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
    
    if(self.keyboardOpen)
    {
        [self animateTextField:sender up:NO];
        self.keyboardOpen = NO;
    }
}


- (IBAction)startedEditingTextField:(id)sender 
{
    //don't slide up if the keyboard is already open.
    if(!self.keyboardOpen)
    {
       [self animateTextField:sender up:YES];
        self.keyboardOpen = YES;
    }
}


- (void) animateTextField: (UITextField*) textField up: (BOOL) up
{
    const int movementDistance = 90;
    const float movementDuration = 0.3f;
    
    int movement = (up ? -movementDistance : movementDistance);
    
    [UIView beginAnimations: @"anim" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    self.view.frame = CGRectOffset(self.view.frame, 0, movement);
    [UIView commitAnimations];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Logout" style:UIBarButtonItemStylePlain target:nil action:nil];
}

- (void)viewDidUnload
{
    [self setEmailTextField:nil];
    [self setPasswordTextField:nil];
    [self setLoginProgressIndicator:nil];
    [self setLoginButton:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.emailTextField.text = @"";
    self.passwordTextField.text = @"";
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)onLogin 
{
    [self.loginProgressIndicator startAnimating];
    self.loginButton.enabled = NO;
    
    [[RemoteAccess getInstance] loginToServer:TASK_URL email:self.emailTextField.text password:self.passwordTextField.text delegate:self];
}   


#pragma mark - RemoteAccessProtocol methods:

- (void)onResponseReceivedWithStatusCode:(int)statusCode
{
    [self.loginProgressIndicator stopAnimating];
    self.loginButton.enabled = YES;
    
    if(statusCode == 200)
       [self performSegueWithIdentifier:@"loginComplete" sender:self];
    else 
    {
        UIAlertView *dialog = [[UIAlertView alloc] initWithTitle:@"Error logging in!" message:nil delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [dialog show];
    }
}

- (void)onDataSyncComplete
{
    [self.loginProgressIndicator stopAnimating];
    self.loginButton.enabled = YES;
}


- (void)onSyncError
{
    [self.loginProgressIndicator stopAnimating];
    self.loginButton.enabled = YES;
    UIAlertView *dialog = [[UIAlertView alloc] initWithTitle:@"Error logging in!" message:nil delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [dialog show];
}


- (void)onSubmitComplete
{
    // do nothing, we're not submitting anything from this ViewController
}


- (void)onAuthError
{
    [self.loginProgressIndicator stopAnimating];
    self.loginButton.enabled = YES;
    UIAlertView *dialog = [[UIAlertView alloc] initWithTitle:@"Username or password is wrong!" message:nil delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [dialog show];
}

@end
