//
//  ViewController.m
//  ELRemotePlistFileDemo
//
//  Created by Eddie Espinal on 11/19/13.
//  Copyright (c) 2013 EspinalLab, LLC. All rights reserved.
//

#import "ViewController.h"
#import "ELRemotePlistFile.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    
    NSString *urlString = @"https://www.dropbox.com/s/1iahe1wl3i56hi1/Manifest.plist?dl=1";
    
    [ELRemotePlistFile sharedInstance];
    
    [ELRemotePlistFile downloadRemotePlistFileAsyncWithURL:[NSURL URLWithString:urlString]
                                                     cache:YES
                                                  filename:@"manifest_filename"
                                      completionBlock:^(NSDictionary *response) {
                                          
                                          //Handle the response dictionary here
                                          NSLog(@"%@", response);
                                      }
                                               failed:^(NSError *error) {
                                                   NSLog(@"%@", error);
                                               }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
