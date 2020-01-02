//
//  DownloadOperation.m
//  GIMICUpdater
//
//  Created by osoumen on 2014/10/03.
//  Copyright (c) 2014年 osoumen. All rights reserved.
//

#import "DownloadOperation.h"
#include "lpc21isp.h"

void EndWrite(int ret);

@implementation DownloadOperation

- (id)init
{
    self = [super init];
    mHexFilePath = nil;
    mPortPath = nil;
    return self;
}

- (void)setHexFilePath:(NSURL*)path
{
    mHexFilePath = path;
}

- (void)setPortPath:(NSString*)path
{
    mPortPath = path;
}

- (void)main
{
    if (mPortPath == nil) {
        return;
    }
    if (mHexFilePath == nil) {
        return;
    }
    
    @autoreleasepool {
        int numArgs = 1;
        char params[10][1024];
        char *arguments[10] = {
            params[0],
            params[1],
            params[2],
            params[3],
            params[4],
            params[5],
            params[6],
            params[7],
            params[8],
            params[9]
        };
        
        arguments[0] = 0;
        
        if (self.fullDebug) {
            strcpy(arguments[numArgs], "-debug5");
            numArgs++;
        }
        if (self.noVerify == NO) {
            strcpy(arguments[numArgs], "-verify");
            numArgs++;
        }
        if (self.eraseBeforeUpload) {
            strcpy(arguments[numArgs], "-wipe");
            numArgs++;
        }
        
        strcpy(arguments[numArgs], "-nosync");
        numArgs++;
        
        strcpy(arguments[numArgs], "-hex");
        numArgs++;
        
        if ([mHexFilePath isFileURL]) {
            [[[mHexFilePath filePathURL] path]
             getFileSystemRepresentation:params[numArgs] maxLength:1024];
        }
        else {
            [[mHexFilePath absoluteString]
             getFileSystemRepresentation:params[numArgs] maxLength:1024];
        }
        numArgs++;
        
        [mPortPath getCString:params[numArgs] maxLength:1024 encoding:NSUTF8StringEncoding];
        numArgs++;
        
        strcpy(arguments[numArgs], "230400");
        numArgs++;
        strcpy(arguments[numArgs], "12000");
        numArgs++;

        int ret = AppDoProgram(numArgs, arguments);
        EndWrite(ret);
    }
}

@end
