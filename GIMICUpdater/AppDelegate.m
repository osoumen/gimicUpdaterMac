//
//  AppDelegate.m
//  GIMICUpdater
//
//  Created by osoumen on 2014/10/02.
//  Copyright (c) 2014年 osoumen. All rights reserved.
//

#import "AppDelegate.h"
#import "DownloadOperation.h"
#import "PortChecker.h"

AppDelegate *app = nil;

@implementation AppDelegate

@synthesize showLog;
@synthesize fullDebug;
@synthesize isUpdating;
@synthesize isSyncFailed;

- (void)awakeFromNib
{
    gQueue = [[NSOperationQueue alloc] init];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    app = self;
    isFinished = NO;
    isUpdating = NO;
    isReady = NO;
    btlVers = 0;
    usingBuiltInHex = YES;
    
    portPath = NSLocalizedString(@"portPath", @"");
    
    hexPath = nil;
    
    // アップデート可能チェックを開始させる
    NSNotificationCenter    *center;
    center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(readyToUpdateNotification:)
                   name:@"ReadyToUpdate"
                 object:nil];
    [center addObserver:self
               selector:@selector(disappearPortNotification:)
                   name:@"DisappearPort"
                 object:nil];
    PortChecker *tOperation = [[PortChecker alloc] init];
    [tOperation setPortPath:portPath];
    [gQueue addOperation:tOperation];
    
    // アップデート準備を促すメッセージを表示
    [self printMessage:NSLocalizedString(@"preparingToUpdate", @"")];
}

- (void)loadDefaultHexPath:(int)mbType
{
    NSBundle *bundle = [NSBundle mainBundle];
    
    switch (mbType) {
        case 0:
            hexPath = [NSURL URLWithString:NSLocalizedString(@"hexPath_mb1", @"")
                             relativeToURL:[bundle resourceURL]];
            break;
        case 1:
            hexPath = [NSURL URLWithString:NSLocalizedString(@"hexPath_mb2", @"")
                             relativeToURL:[bundle resourceURL]];
            break;
    }
}

- (void)dealloc
{
    // 通知の解除
    NSNotificationCenter    *center;
    center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self];
}

- (IBAction)onSelectOpen:(id)sender
{
    NSOpenPanel *openPanel	= [NSOpenPanel openPanel];
    NSArray *allowedFileTypes = [NSArray arrayWithObjects:@"hex",nil,nil];
    [openPanel setAllowedFileTypes:allowedFileTypes];
    NSInteger pressedButton = [openPanel runModal];
    
    if ( pressedButton == NSOKButton ) {
        
        // get file path
        NSURL * filePath = [openPanel URL];
        
        // open file here
        //NSLog(@"file opened '%@'", filePath);
        hexPath = filePath;
        usingBuiltInHex = NO;
        if (isReady) {
            [self printUpdateReadyMsg];
        }
    }
    else if( pressedButton == NSCancelButton ){
     	//NSLog(@"Cancel button was pressed.");
    }
    else {
     	// error
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    if (isUpdating) {
        int	iRet = NSRunAlertPanel(NSLocalizedString(@"cancelUpdating1",@""),
                                   NSLocalizedString(@"cancelUpdating2",@""),
                                   NSLocalizedString(@"no",@""),NSLocalizedString(@"yes",@""),nil);
        if (iRet == NSAlertDefaultReturn) {
            return NSTerminateCancel;
        }
    }
    return NSTerminateNow;
}

// 消して新しくメッセージを
- (void)printMessage:(NSString*)msg
{
    [[mMessageView textStorage] setAttributedString:[[NSAttributedString alloc] initWithString:msg]];
}

// メッセージを追加
- (void)putMsg:(NSString*)msg
{
    [mMessageView setEditable:YES];
    [mMessageView insertText:msg];
    [mMessageView setEditable:NO];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

- (IBAction)toggleShowLog:(id)sender
{
    showLog = showLog?NO:YES;
}

- (IBAction)toggleFullDebug:(id)sender
{
    fullDebug = fullDebug?NO:YES;
}

- (IBAction)toggleNoVerify:(id)sender
{
    noVerify = noVerify?NO:YES;
}

- (IBAction)toggleEraseBeforeUpload:(id)sender
{
    eraseBeforeUpload = eraseBeforeUpload?NO:YES;
}

// --- メニューアイテムの使用可否の処理
- (BOOL) validateMenuItem:(NSMenuItem*)anItem
{
	SEL menuAction = [anItem action]; // メニューアイテムのアクションを取得
	
	if (menuAction == @selector(toggleShowLog:)) {
		if (showLog) {
			[anItem setState:NSOnState];
		}
		else {
			[anItem setState:NSOffState];
		}
		return YES;
	}
    
    if (menuAction == @selector(toggleFullDebug:)) {
		if (fullDebug) {
			[anItem setState:NSOnState];
		}
		else {
			[anItem setState:NSOffState];
		}
		return YES;
	}
    
    if (menuAction == @selector(toggleNoVerify:)) {
		if (noVerify) {
			[anItem setState:NSOnState];
		}
		else {
			[anItem setState:NSOffState];
		}
		return YES;
	}
    
    if (menuAction == @selector(toggleEraseBeforeUpload:)) {
		if (eraseBeforeUpload) {
			[anItem setState:NSOnState];
		}
		else {
			[anItem setState:NSOffState];
		}
		return YES;
	}
	
	return YES;
}

- (void)readyToUpdateNotification:(NSNotification*)notification
{
    [app performSelectorOnMainThread:@selector(readyToUpdateProc:)
                          withObject:[[notification userInfo] valueForKey:@"btlVers"]
                       waitUntilDone:NO];
}

- (void)disappearPortNotification:(NSNotification*)notification
{
    [app performSelectorOnMainThread:@selector(disappearPortProc:)
                          withObject:nil
                       waitUntilDone:NO];
}

// アップデートが可能になったときにメインスレッドで実行される処理
- (void)readyToUpdateProc:(NSNumber*)btlVersion
{
    // 開始ボタンを有効化する
    [mStartButton setEnabled:YES];
    isReady = YES;
    btlVers = [btlVersion intValue];
    
    // ファイルが選択されていなかったら内蔵のFWを設定する
    
    if ((hexPath == nil) || (usingBuiltInHex == YES)) {
        // MBの種類を認識して変える
        if (btlVers == BTL_VERS_MB1) {
            [self loadDefaultHexPath:0];
        }
        else if (btlVers == BTL_VERS_MB2) {
            [self loadDefaultHexPath:1];
        }
        else {
            [self loadDefaultHexPath:1];
        }
    }
    
    [self printUpdateReadyMsg];
}

- (void)printUpdateReadyMsg
{
    if (btlVers == BTL_VERS_MB1) {
        [self printMessage:NSLocalizedString(@"detectMB1", @"")];
    }
    else if (btlVers == BTL_VERS_MB2) {
        [self printMessage:NSLocalizedString(@"detectMB2", @"")];
    }
    else {
        [self printMessage:NSLocalizedString(@"detectUnknownMB", @"")];
    }
    [self putMsg:NSLocalizedString(@"readyToUpdate1", @"")];
    [self putMsg:[[hexPath path] lastPathComponent]];
    [self putMsg:NSLocalizedString(@"readyToUpdate2", @"")];
}

// ケーブルが抜かれたときメインスレッドで実行される処理
- (void)disappearPortProc:(id)object
{
    // 開始ボタンを無効化する
    [mStartButton setEnabled:NO];
    isReady = NO;
    
    // 実行中なら停止させる
    if (isUpdating) {
        isUpdating = NO;
        [self.window setStyleMask:[self.window styleMask] | NSClosableWindowMask];
        [self printUpdateReadyMsg];
    }
    // 完了前ならポートチェックを再度開始する
    if (isFinished == NO) {
        PortChecker *tOperation = [[PortChecker alloc] init];
        [tOperation setPortPath:portPath];
        [gQueue addOperation:tOperation];
        [self printMessage:NSLocalizedString(@"preparingToUpdate", @"")];
    }
}

- (IBAction)start:(id)sender
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:portPath] == NO) {
        return;
    }
    
    [self printMessage:NSLocalizedString(@"updating", @"")];
    [mStartButton setEnabled:NO];
    [_window setStyleMask:[_window styleMask] & ~NSClosableWindowMask];
    [mProgressBar setIndeterminate:YES];
    [mProgressBar startAnimation:self];
    isReady = NO;
    isUpdating = YES;
    isSyncFailed = NO;
    DownloadOperation *tOperation = [[DownloadOperation alloc] init];
    [tOperation setHexFilePath:hexPath];
    [tOperation setPortPath:portPath];
    [tOperation setFullDebug:fullDebug];
    [tOperation setNoVerify:noVerify];
    [tOperation setEraseBeforeUpload:eraseBeforeUpload];
    [gQueue addOperation:tOperation];
}

- (BOOL)interpretMsg:(NSString*)msg
{
    // 表示しないメッセージはNOを返す
    if ([msg hasPrefix:@"Image size"]) {
        NSString    *sizeString = [msg substringFromIndex:13];
        double      imageSIze = [sizeString doubleValue];
        [mProgressBar setMaxValue:imageSIze];
        [mProgressBar setDoubleValue:0];
        return YES;
    }
    return YES;
}

- (void)putError:(NSString*)msg
{
    if (showLog) {
        [self putMsg:@"** "];
        [self putMsg:msg];
    }
}

- (void)writtenBytes:(NSNumber*)written
{
    [mProgressBar incrementBy:[written intValue]];
    if ([mProgressBar doubleValue] > 0) {
        [mProgressBar setIndeterminate:NO];
    }
}

- (void)endWrite:(NSNumber*)returnCode
{
    isUpdating = NO;
    [self.window setStyleMask:[self.window styleMask] | NSClosableWindowMask];
    if (isSyncFailed || ([returnCode intValue] != 0)) {
        NSRunAlertPanel(NSLocalizedString(@"syncFail1",@""),
                        NSLocalizedString(@"syncFail2",@""),
                        NSLocalizedString(@"OK",@""),nil,nil);
        [self printUpdateReadyMsg];
        [mStartButton setEnabled:YES];
    }
    else {
        isFinished = YES;
        [self putMsg:NSLocalizedString(@"endUpdate", @"")];
    }
    [mProgressBar stopAnimation:self];
}

- (void)notifyException:(id)sel
{
    NSRunAlertPanel(NSLocalizedString(@"exception1",@""),
                               NSLocalizedString(@"exception2",@""),
                               NSLocalizedString(@"OK",@""),nil,nil);
}

@end

void AppDebugPrintf(int level, const char *fmt, ...)
{
    va_list ap;
    int debugLevel = app.fullDebug?5:2;
    
    if (level <= debugLevel)
    {
        char pTemp[2000];
        va_start(ap, fmt);
        vsprintf(pTemp, fmt, ap);
        NSString *msg = [NSString stringWithCString:pTemp encoding:NSNonLossyASCIIStringEncoding];
        switch (level) {
            case 1:
                [app performSelectorOnMainThread:@selector(putError:) withObject:msg waitUntilDone:NO];
                break;
            case 2:
            default:
                if ([app interpretMsg:msg] || (app.fullDebug == YES)) {
                    if (app.showLog) {
                        if ((pTemp[0] != '.' && pTemp[0] != '|') || (app.fullDebug == YES)) {
                            [app performSelectorOnMainThread:@selector(putMsg:) withObject:msg waitUntilDone:NO];
                        }
                    }
                }
                break;
        }
        va_end(ap);
    }
}

void AppException(int exception_level)
{
    // 例外発生を通知
    [app performSelector:@selector(notifyException:) withObject:nil afterDelay:NO];
}

int AppSyncing(int trials)
{
    // 同期処理
    if (app.isUpdating) {
        if (trials < 10) {
            return 1;
        }
        else {
            app.isSyncFailed = YES;
        }
    }
    return 0;
}

void AppWritten(int size)
{
    NSNumber *written = [NSNumber numberWithInt:size];
    [app performSelectorOnMainThread:@selector(writtenBytes:) withObject:written waitUntilDone:NO];
}

void EndWrite(int ret)
{
    NSNumber *result = [NSNumber numberWithInt:ret];
    [app performSelectorOnMainThread:@selector(endWrite:) withObject:result waitUntilDone:NO];
}
