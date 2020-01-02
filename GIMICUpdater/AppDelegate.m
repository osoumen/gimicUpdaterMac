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
    [self printMessage:NSLocalizedString(@"readyToUpdate1", @"")];
	[self putMsg:NSLocalizedString(@"fwVersion", @"")];
    [self putMsg:NSLocalizedString(@"preparingToUpdate", @"")];
}

- (void)loadDefaultHexPath:(int)mbType
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSArray *paths = [bundle pathsForResourcesOfType:@"hex"
                                         inDirectory:nil];
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    NSError *error;
//    NSArray *paths = [fileManager contentsOfDirectoryAtPath:@"/tmp"
//                                                      error:&error];
    NSURL *mb1FWPath = nil;
    NSURL *mb2FWPath = nil;
    
    for (int i=0; i<[paths count]; i++) {
        NSString *fwpath = [paths objectAtIndex:i];
        NSRange result = [fwpath rangeOfString:@"MB1.*\\.hex$"
                                       options:NSRegularExpressionSearch];
        if (result.location != NSNotFound) {
            if (mb1FWPath == nil) {
                mb1FWPath = [NSURL URLWithString:[NSString stringWithFormat:@"%@",fwpath]
                                   relativeToURL:nil];
            }
        }
        result = [fwpath rangeOfString:@"MB2.*\\.hex$"
                               options:NSRegularExpressionSearch];
        if (result.location != NSNotFound) {
            if (mb2FWPath == nil) {
                mb2FWPath = [NSURL URLWithString:[NSString stringWithFormat:@"%@",fwpath]
                                   relativeToURL:nil];
            }
        }
    }
    
    switch (mbType) {
        case 0:
            hexPath = mb1FWPath;
            break;
        case 1:
            hexPath = mb2FWPath;
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
    [openPanel setTitle:NSLocalizedString(@"selecthexfile", @"")];
    NSModalResponse pressedButton = [openPanel runModal];
    
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

// --- メニューアイテムの使用可否の処理
- (BOOL) validateMenuItem:(NSMenuItem*)anItem
{
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
    // ファイルが選択されていなかったら内蔵のFWを設定する
    btlVers = [btlVersion intValue];
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
    
    // 開始ボタンを有効化する
    [mStartButton setEnabled:YES];
    isReady = YES;
    
    // チェックボックスを無効化する
    [mAllowDevelopFW setEnabled:NO];
    
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
    if (hexPath != nil) {
		if (usingBuiltInHex) {
			[self putMsg:NSLocalizedString(@"fwVersion", @"")];
		}
		else {
			[self putMsg:[[hexPath path] lastPathComponent]];
		}
        [self putMsg:NSLocalizedString(@"readyToUpdate2", @"")];
    }
}

// ケーブルが抜かれたときメインスレッドで実行される処理
- (void)disappearPortProc:(id)object
{
    // 開始ボタンを無効化する
    [mStartButton setEnabled:NO];
    isReady = NO;
    
    // チェックボックスを有効化する
    [mAllowDevelopFW setEnabled:YES];
    
    // 実行中なら停止させる
    if (isUpdating) {
        isUpdating = NO;
        [self.window setStyleMask:[self.window styleMask] | NSClosableWindowMask];
        [self printUpdateReadyMsg];
    }
    // ポートチェックを再度開始する
    PortChecker *tOperation = [[PortChecker alloc] init];
    [tOperation setPortPath:portPath];
    [gQueue addOperation:tOperation];
    // 完了前なら初期メッセージを再度表示する
    if (isFinished == NO) {
        [self printMessage:NSLocalizedString(@"preparingToUpdate", @"")];
    }
}

- (IBAction)start:(id)sender
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:portPath] == NO) {
        return;
    }
    if (hexPath == nil) {
        NSRunAlertPanel(NSLocalizedString(@"hexfile_notselected1",@""),
                        NSLocalizedString(@"hexfile_notselected2",@""),
                        NSLocalizedString(@"OK",@""),nil,nil);
        return;
    }
    
    [self printMessage:NSLocalizedString(@"updating", @"")];
    [mStartButton setEnabled:NO];
    [self.window setStyleMask:[self.window styleMask] & ~NSClosableWindowMask];
    [mProgressBar setIndeterminate:YES];
    [mProgressBar startAnimation:self];
    isReady = NO;
    isUpdating = YES;
    isSyncFailed = NO;
    DownloadOperation *tOperation = [[DownloadOperation alloc] init];
    [tOperation setHexFilePath:hexPath];
    [tOperation setPortPath:portPath];
    [tOperation setFullDebug:[mFullDebug state]==NSOnState?YES:NO];
    [tOperation setNoVerify:[mNoVerify state]==NSOnState?YES:NO];
    [tOperation setEraseBeforeUpload:[mEraseBeforeUpload state]==NSOnState?YES:NO];
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
    if ([mShowLog state] == NSOnState) {
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
        [mAllowDevelopFW setEnabled:YES];
    }
    else if ([mProgressBar doubleValue] < [mProgressBar maxValue] ) {
        [self notifyException:self];
        [mProgressBar setDoubleValue:0];
        [mProgressBar setIndeterminate:NO];
    }
    else {
        isFinished = YES;
        [mAllowDevelopFW setEnabled:YES];
        if (btlVers == BTL_VERS_MB1) {
            [self putMsg:NSLocalizedString(@"endUpdateMB1", @"")];
        }
        else {
            [self putMsg:NSLocalizedString(@"endUpdateMB2", @"")];
        }
    }
    [mProgressBar stopAnimation:self];
}

- (void)notifyException:(id)sel
{
    NSRunAlertPanel(NSLocalizedString(@"exception1",@""),
                               NSLocalizedString(@"exception2",@""),
                               NSLocalizedString(@"OK",@""),nil,nil);
}

- (BOOL)showLog
{
    return ([mShowLog state] == NSOnState)?YES:NO;
}

- (BOOL)fullDebug
{
    return ([mFullDebug state] == NSOnState)?YES:NO;
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
				[app performSelectorOnMainThread:@selector(interpretMsg:) withObject:msg waitUntilDone:YES];
				if (app.showLog) {
					if ((pTemp[0] != '.' && pTemp[0] != '|') || (app.fullDebug == YES)) {
						[app performSelectorOnMainThread:@selector(putMsg:) withObject:msg waitUntilDone:NO];
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
