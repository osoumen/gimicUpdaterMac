//
//  AppDelegate.h
//  GIMICUpdater
//
//  Created by osoumen on 2014/10/02.
//  Copyright (c) 2014年 osoumen. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    IBOutlet NSTextView *dbgPrint;
    NSOperationQueue *gQueue;
}
@property (assign) IBOutlet NSWindow *window;

- (void)start:(id)sender;
- (void)appendMsg:(NSString*)msg;

@end
