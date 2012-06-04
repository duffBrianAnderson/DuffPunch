//
//  LoginScreenViewController.h
//  DuffTimeCard
//
//  Created by Brian Anderson on 5/15/12.
//  Copyright (c) 2012 Duff Research. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginScreenViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loginProgressIndicator;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;

@end