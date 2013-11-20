//
//  ELRemotePlistFile.m
//
//  Created by Eddie Espinal on 11/19/13.
//  Copyright (c) 2013 EspinalLab, LLC. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "ELRemotePlistFile.h"

@interface ELRemotePlistFile()

@end

@implementation ELRemotePlistFile

+ (NSString *)cacheDirectory
{
    NSArray *cachePathArray = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheStringPath = [cachePathArray objectAtIndex:0];
    
    return cacheStringPath;
}

+ (void)downloadRemotePlistFileWithURL:(NSURL *)url completionBlock:(void (^)(NSDictionary *response))completionBlock failed:(void (^)(NSError *error))failedBlock
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
    NSURLResponse *returnedResponse = nil;
    NSError *returnedError = nil;
    NSData *requestData  = [NSURLConnection sendSynchronousRequest:request returningResponse:&returnedResponse error:&returnedError];
    
    // Check if no error, then parse data
    if (returnedError == nil)
    {
        // Parse response into a dictionary
        NSPropertyListFormat format;
        NSString *errorStr = nil;
        NSDictionary *dictionary = [NSPropertyListSerialization propertyListFromData:requestData
                                                                    mutabilityOption:NSPropertyListImmutable
                                                                              format:&format
                                                                    errorDescription:&errorStr];
        if (errorStr == nil)
        {
            @try {
                
                if (completionBlock) {
                    completionBlock(dictionary);
                }
                
            } @catch (NSException *e) {
                // Error retrieving the key
                NSError *error = [NSError errorWithDomain:e.reason code:0 userInfo:nil];
                if (failedBlock) {
                    failedBlock(error);
                }
            }
        }
        else {
            // Error with parsing data into dictionary
            NSError *error = [NSError errorWithDomain:@"Error parsing data into dictionary" code:0 userInfo:nil];
            if (failedBlock) {
                failedBlock(error);
            }
        }
    } else {
        if (failedBlock) {
            failedBlock(returnedError);
        }
    }
}

@end
