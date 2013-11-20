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

@implementation ELRemotePlistFile

+ (instancetype)sharedInstance
{
    static ELRemotePlistFile *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[ELRemotePlistFile alloc] init];
    });
    
    return _sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        
        NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:4 * 1024 * 1024
                                                             diskCapacity:20 * 1024 * 1024
                                                                 diskPath:nil];
        [NSURLCache setSharedURLCache:URLCache];
    }
    return self;
}

- (void)downloadRemotePlistFileAsyncWithURL:(NSURL *)url cache:(BOOL)cache completionBlock:(void (^)(NSDictionary *response))completionBlock failed:(void (^)(NSError *error))failedBlock
{

    NSString *filename = [ELRemotePlistFile filenameFromURLString:[url absoluteString]];
    
    //Let's check if we have a cached plist file first and return it if we have one.
    NSDictionary *cachedDictionary = [ELRemotePlistFile readPlistFromDiskWithURLString:[url absoluteString]];
    if (cachedDictionary)
    {
        if (completionBlock) {
            completionBlock(cachedDictionary);
        }
        
        return;
    }

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
    {
        // Check if no error, then parse data
        if (connectionError == nil)
        {
            // Parse response into a dictionary
            NSPropertyListFormat format;
            NSString *errorStr = nil;
            NSDictionary *dictionary = [NSPropertyListSerialization propertyListFromData:data
                                                                        mutabilityOption:NSPropertyListImmutable
                                                                                  format:&format
                                                                        errorDescription:&errorStr];
            if (errorStr == nil)
            {
                @try
                {
                    if (completionBlock)
                    {
                        completionBlock(dictionary);
                        
                        if (cache)
                        {
                            [ELRemotePlistFile writePlistFileToDisk:dictionary filename:filename];
                        }
                    }
                    
                }
                @catch (NSException *e)
                {
                    // Error retrieving the key
                    NSError *error = [NSError errorWithDomain:e.reason code:0 userInfo:nil];
                    if (failedBlock) {
                        failedBlock(error);
                    }
                }
            }
            else
            {
                // Error with parsing data into dictionary
                NSError *error = [NSError errorWithDomain:@"Error parsing data into dictionary" code:0 userInfo:nil];
                if (failedBlock)
                {
                    failedBlock(error);
                }
            }
        }
        else
        {
            if (failedBlock)
            {
                failedBlock(connectionError);
            }
        }
    }];
    
}

- (void)removeAllCache
{
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    
}

+ (NSString *)filenameFromURLString:(NSString *)urlString
{
    return [[urlString lastPathComponent] stringByDeletingPathExtension];
}

+ (NSString *)cacheDirectory
{
    NSArray *cachePathArray = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheStringPath = [cachePathArray lastObject];
    
    return cacheStringPath;
}

+ (NSString *)cachePathWithFilename:(NSString *)filename
{
    NSString *filePath = [[ELRemotePlistFile cacheDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", filename]];
    
    return filePath;
}

+ (NSDictionary *)readPlistFromDiskWithURLString:(NSString *)urlString
{
    NSString *plistPath = [ELRemotePlistFile cachePathWithFilename:[ELRemotePlistFile filenameFromURLString:urlString]];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:plistPath])
    {
        //File doesn't exist
        return nil;
    }
    
    return [NSDictionary dictionaryWithContentsOfFile:plistPath];
}

+ (void)writePlistFileToDisk:(NSDictionary *)dictionary filename:(NSString *)filename
{
    NSAssert(filename != nil, @"Filename can't be nil");
    
    NSString *plistPath = [ELRemotePlistFile cachePathWithFilename:filename];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:plistPath])
    {
        [fileManager removeItemAtPath:plistPath error:nil];
    }
    
    [dictionary writeToFile:plistPath atomically:YES];
}

+ (void)removePlistFromDiskWithURLString:(NSString *)urlString
{
    NSString *plistPath = [ELRemotePlistFile cachePathWithFilename:[ELRemotePlistFile filenameFromURLString:urlString]];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:plistPath])
    {
        [fileManager removeItemAtPath:plistPath error:nil];
    }
}


@end
