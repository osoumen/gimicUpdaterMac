//
//  AppDelegate.m
//  GIMICUpdater
//
//  Created by osoumen on 2014/10/02.
//  Copyright (c) 2014年 osoumen. All rights reserved.
//

#import "AppDelegate.h"
#import "DownloadOperation.h"

AppDelegate *app = nil;

@implementation AppDelegate

- (void)awakeFromNib
{
    gQueue = [[NSOperationQueue alloc] init];
}
/*
- (void)dealloc
{
    [gQueue release];
    [super dealloc];
}
*/
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    app = self;
}

- (void)start:(id)sender
{
    DownloadOperation *tOperation = [[DownloadOperation alloc] init];
    [gQueue addOperation:tOperation];
    //[tOperation release];
}

- (void)appendMsg:(NSString*)msg
{
    [dbgPrint insertText:msg];
}

@end

void AppDebugPrintf(int level, const char *fmt, ...)
{
    va_list ap;
    
    if (level <= 2)
    {
        char pTemp[2000];
        va_start(ap, fmt);
        vsprintf(pTemp, fmt, ap);
        if (app != nil) {
            NSString *msg = [NSString stringWithCString:pTemp encoding:NSNonLossyASCIIStringEncoding];
            [app performSelectorOnMainThread:@selector(appendMsg:) withObject:msg waitUntilDone:NO];
        }
        va_end(ap);
    }
}

void AppException(int exception_level)
{
    
}

int AppSyncing(int trials)
{
    return 1;
}

void AppWritten(int size)
{
    
}