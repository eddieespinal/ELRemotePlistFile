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

@interface ELRemotePlistFile ()

- (BOOL)isNewerFileOnServerWithURL:(NSURL *)url;
- (void)writePlistFileToDisk:(NSDictionary *)dictionary filename:(NSString *)filename;
- (NSString *)cachePathWithFilename:(NSString *)filename;
- (NSString *)cacheDirectory;
- (NSString *)filenameFromURLString:(NSString *)urlString;

@end

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

- (void)downloadRemotePlistFileAsyncWithURL:(NSURL *)url cache:(BOOL)cache completionBlock:(void (^)(NSDictionary *response))completionBlock failed:(void (^)(NSError *error))failedBlock
{

    NSString *filename = [self filenameFromURLString:[url absoluteString]];
    
    if ([self isNewerFileOnServerWithURL:url]) {
        
        //Remote file was modified or is newer, download it.
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60.0];
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
                                 [self writePlistFileToDisk:dictionary filename:filename];
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

    } else {
        //Let's check if we have a cached plist file first and return it if we have one.
        NSDictionary *cachedDictionary = [self readPlistFromDiskWithURLString:[url absoluteString]];
        if (cachedDictionary)
        {
            if (completionBlock) {
                completionBlock(cachedDictionary);
            }
            
            return;
        }
    }

    
}

- (BOOL)isNewerFileOnServerWithURL:(NSURL *)url
{
    // create a HTTP request to get the file information from the web server
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"HEAD"];
    
    NSHTTPURLResponse* response;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
    
    // get the last modified info from the HTTP header
    NSString* httpLastModified = nil;
    if ([response respondsToSelector:@selector(allHeaderFields)])
    {
        httpLastModified = [[response allHeaderFields]
                            objectForKey:@"Last-Modified"];
    }
    
    // setup a date formatter to query the server file's modified date
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'";
    df.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    df.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    
    // get the file attributes to retrieve the local file's modified date
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *plistPath = [self cachePathWithFilename:[self filenameFromURLString:[url absoluteString]]];
    NSDictionary* fileAttributes = [fileManager attributesOfItemAtPath:plistPath error:nil];
    
    // test if the server file's date is later than the local file's date
    NSDate* serverFileDate = [df dateFromString:httpLastModified];
    NSDate* localFileDate = [fileAttributes fileModificationDate];

    //If local file doesn't exist, download it
    if(localFileDate==nil){
        return YES;
    }
    
    BOOL isNewer = ([localFileDate laterDate:serverFileDate] == serverFileDate);
    
    return isNewer;
}

- (NSString *)filenameFromURLString:(NSString *)urlString
{
    return [[urlString lastPathComponent] stringByDeletingPathExtension];
}

- (NSString *)cacheDirectory
{
    NSArray *cachePathArray = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheStringPath = [cachePathArray lastObject];
    
    return cacheStringPath;
}

- (NSString *)cachePathWithFilename:(NSString *)filename
{
    NSString *filePath = [[self cacheDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", filename]];
    
    return filePath;
}

- (NSDictionary *)readPlistFromDiskWithURLString:(NSString *)urlString
{
    NSString *plistPath = [self cachePathWithFilename:[self filenameFromURLString:urlString]];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:plistPath])
    {
        //File doesn't exist
        return nil;
    }
    
    return [NSDictionary dictionaryWithContentsOfFile:plistPath];
}

- (NSString *)stringFromLocalPlistFileWithURLString:(NSString *)urlString
{
    NSString *plistPath = [self cachePathWithFilename:[self filenameFromURLString:urlString]];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:plistPath])
    {
        //File doesn't exist
        return nil;
    }
    
    return [NSString stringWithContentsOfFile:plistPath encoding:NSUTF8StringEncoding error:nil];
}

- (void)writePlistFileToDisk:(NSDictionary *)dictionary filename:(NSString *)filename
{
    NSAssert(filename != nil, @"Filename can't be nil");
    
    NSString *plistPath = [self cachePathWithFilename:filename];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:plistPath])
    {
        [fileManager removeItemAtPath:plistPath error:nil];
    }
    
    [dictionary writeToFile:plistPath atomically:YES];
    
    // reset the file's modification date
    NSError *error = nil;
	NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:[NSDate date], NSFileModificationDate, nil];
	if (![[NSFileManager defaultManager] setAttributes:dict ofItemAtPath:plistPath error:&error]) {
		NSLog(@"Error");
	}
}

- (void)removePlistFromDiskWithURLString:(NSString *)urlString
{
    NSString *plistPath = [self cachePathWithFilename:[self filenameFromURLString:urlString]];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:plistPath])
    {
        [fileManager removeItemAtPath:plistPath error:nil];
    }
}

+ (id)deserializeDataWithString:(NSString *)string
{
    id object = nil;
    
    if (string)
    {
        //attempt to deserialise data as a property list
        NSPropertyListFormat format;
        NSPropertyListReadOptions options = NSPropertyListImmutable;
        object = [NSPropertyListSerialization propertyListWithData:[string dataUsingEncoding:NSUTF8StringEncoding] options:options format:&format error:nil];
    }

    return object;
}


@end
