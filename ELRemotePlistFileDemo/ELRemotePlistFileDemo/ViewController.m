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

    NSString *urlString = @"http://radiomusicapp.com/Manifest.plist";
    
    [[ELRemotePlistFile sharedInstance] downloadRemotePlistFileAsyncWithURL:[NSURL URLWithString:urlString]
                                                                      cache:YES
                                                            completionBlock:^(NSDictionary *response) {
                                                                      //Handle the response dictionary here
                                                                      NSLog(@"%@", response);
                                                                    }
                                                                     failed:^(NSError *error) {
                                                                         NSLog(@"%@", error);
                                                                     }];
    
    //Using deserializeDataWithString & stringFromLocalPlistFileWithURLString methods
    id data = [ELRemotePlistFile deserializeDataWithString:[ELRemotePlistFile stringFromLocalPlistFileWithURLString:urlString]];
    NSLog(@"%@", data);
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
