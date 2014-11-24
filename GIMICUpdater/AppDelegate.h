//
//  AppDelegate.h
//  GIMICUpdater
//
//  Created by osoumen on 2014/10/02.
//  Copyright (c) 2014年 osoumen. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define BTL_VERS_MB1 (0x33)
#define BTL_VERS_MB2 (0x43)

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    IBOutlet NSTextView             *mMessageView;
    NSOperationQueue                *gQueue;
    IBOutlet NSProgressIndicator    *mProgressBar;
    IBOutlet NSButton               *mStartButton;
    IBOutlet NSButton               *mAllowDevelopFW;
    IBOutlet NSMenuItem             *mShowLog;
    IBOutlet NSMenuItem             *mFullDebug;
    IBOutlet NSMenuItem             *mNoVerify;
    IBOutlet NSMenuItem             *mEraseBeforeUpload;
    
    BOOL                            isFinished;     // 書き換えを完了したらYESになる
    BOOL                            isReady;
    BOOL                            isUpdating;
    BOOL                            isSyncFailed;
    
    NSString                        *portPath;      // VCPポートのパス
    NSURL                           *hexPath;       // ファームウェアのパス
    int                             btlVers;
    BOOL                            usingBuiltInHex;
}
@property (assign) IBOutlet NSWindow *window;
@property (readonly) BOOL            isUpdating;
@property BOOL                       isSyncFailed;

- (IBAction)start:(id)sender;
- (IBAction)onSelectOpen:(id)sender;
- (IBAction)toggleDevelopFW:(id)sender;

- (BOOL)showLog;
- (BOOL)fullDebug;

@end
