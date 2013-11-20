ELRemotePlistFile
=================

A helper class to download plist file hosted on a remote server.

``` objective-c

#import "ELRemotePlistFile.h"

    NSString *urlString = @"https://www.dropbox.com/s/1iahe1wl3i56hi1/Manifest.plist?dl=1";
    
    [[ELRemotePlistFile sharedInstance] downloadRemotePlistFileAsyncWithURL:[NSURL URLWithString:urlString]
                                                                      cache:YES
                                                            completionBlock:^(NSDictionary *response) {
                                                                      //Handle the response dictionary here
                                                                      NSLog(@"%@", response);
                                                                    }
                                                                     failed:^(NSError *error) {
                                                                         NSLog(@"%@", error);
                                                                     }];
																							 
```
