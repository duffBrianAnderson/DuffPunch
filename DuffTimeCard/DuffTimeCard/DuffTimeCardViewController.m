//
//  DuffTimeCardViewController.m
//  DuffTimeCard
//
//  Created by Brian Anderson on 5/15/12.
//  Copyright (c) 2012 Duff Research. All rights reserved.
//

#import "DuffTimeCardViewController.h"
#import "NSData+Additions.h"
#import "RemoteAccess.h"

@interface DuffTimeCardViewController ()

@end

@implementation DuffTimeCardViewController

NSString * const TASK_URL = @"https://timetrackerservice.herokuapp.com/tasks";

@synthesize emailTextField = mEmailTextField;
@synthesize passwordTextField = mPasswordTextField;
@synthesize loginProgressIndicator = mLoginProgressIndicator;
@synthesize loginButton = mLoginButton;

- (IBAction)textFieldDoneEditing:(id)sender
{
    [sender resignFirstResponder];
}

- (IBAction)backgroundTap:(id)sender
{
    [self.emailTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
}


- (IBAction)startedEditingTextField:(id)sender 
{
    [self animateTextField:sender up:YES];
}


- (IBAction)endedEditingTextField:(id)sender 
{
    [self animateTextField:sender up:NO];
}

- (void) animateTextField: (UITextField*) textField up: (BOOL) up
{
    const int movementDistance = 50; // tweak as needed
    const float movementDuration = 0.3f; // tweak as needed
    
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
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [self setEmailTextField:nil];
    [self setPasswordTextField:nil];
    [self setLoginProgressIndicator:nil];
    [self setLoginButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (IBAction)onLogin 
{
    [self.loginProgressIndicator startAnimating];
    self.loginButton.enabled = NO;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, NULL), ^{
        BOOL success = [self loginWithEmail:self.emailTextField.text password:self.passwordTextField.text];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.loginProgressIndicator stopAnimating];
            self.loginButton.enabled = YES;
            
            if(success)
                [self performSegueWithIdentifier:@"loginComplete" sender:self];
            else
                [self displayInvalidCredentialsDialog];
        });
    });
}   

- (void)displayInvalidCredentialsDialog
{
    UIAlertView *dialog = [[UIAlertView alloc] initWithTitle:@"Error logging in:" message:@"Please try again" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [dialog show];
}

- (BOOL)loginWithEmail:(NSString *)email password:(NSString *)password
{
    BOOL success;
    
    RemoteAccess *remoteAccess = [RemoteAccess getInstance];
    success = [remoteAccess loginToServer:TASK_URL email:email password:password];

    
    return success;
}

@end
