//
//  PortChecker.m
//  GIMICUpdater
//
//  Created by osoumen on 2014/10/06.
//  Copyright (c) 2014年 osoumen. All rights reserved.
//

#import "PortChecker.h"
#include "lpc21isp.h"

static bool transactionAndMatch(ISP_ENVIRONMENT *IspEnvironment, const char *send, const char *match, unsigned timeOutMilliseconds);
static void transaction(ISP_ENVIRONMENT *IspEnvironment, const char *send, char *Answer, unsigned timeOutMilliseconds);

@implementation PortChecker

- (id)init
{
    self = [super init];
    if (self) {
        btlVersion = 0;
    }
    return self;
}

// ポートが存在するかチェック
- (BOOL)checkPortExist
{
    return [[NSFileManager defaultManager] fileExistsAtPath:portPath];
}

- (void)setPortPath:(NSString*)path
{
    portPath = path;
}

- (void)main
{
    
    @autoreleasepool {

        // ポートが存在するかチェック
        do {
            while ([self checkPortExist] == NO) {
                usleep(100000);
            }
            
            // アップデートモードであるかチェック
            // MB1かMB2かをチェック
        }
        while ([self checkConnection] == NO);
            
        // アップデートが可能になったことを通知
        NSNotificationCenter    *center;
        center = [NSNotificationCenter defaultCenter];
        
        NSDictionary *btlVers = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:btlVersion]
                                                            forKey:@"btlVers"];
        [center postNotificationName:@"ReadyToUpdate" object:self userInfo:btlVers];
        
        while ([self checkPortExist] == YES) {
            usleep(100000);
        }
        [center postNotificationName:@"DisappearPort" object:self userInfo:nil];
    }
}

- (BOOL)checkConnection
{
    BOOL    found = NO;
    ISP_ENVIRONMENT IspEnvironment;
    memset(&IspEnvironment, 0, sizeof(IspEnvironment));       // Clear the IspEnviroment to a known value
    IspEnvironment.micro       = NXP_ARM;                     // Default Micro
    IspEnvironment.FileFormat  = FORMAT_HEX;                  // Default File Format
    IspEnvironment.ProgramChip = TRUE;                        // Default to Programming the chip
    IspEnvironment.nQuestionMarks = 100;
    IspEnvironment.DoNotStart = 0;
    IspEnvironment.BootHold = 0;
    
    char serial_port[1024];
    [portPath getCString:serial_port maxLength:1024 encoding:NSUTF8StringEncoding];
    int fdCom = open(serial_port, O_RDWR | O_NOCTTY | O_NONBLOCK);
    struct termios oldtio, newtio;
    if (fdCom < 0) {
        //int err = errno;
        return NO;
    }
    tcflush(fdCom, TCOFLUSH);
    tcflush(fdCom, TCIFLUSH);
    fcntl(fdCom, F_SETFL, fcntl(fdCom, F_GETFL) & ~O_NONBLOCK);
    tcgetattr(fdCom, &oldtio);
    bzero(&newtio, sizeof(newtio));
    newtio.c_cflag = CS8 | CLOCAL | CREAD;
    newtio.c_ispeed = newtio.c_ospeed = B230400;
    newtio.c_iflag = IGNPAR | IGNBRK | IXON | IXOFF;
    newtio.c_oflag = 0;
    newtio.c_lflag = 0;
    cfmakeraw(&newtio);
    newtio.c_cc[VTIME]    = 1;
    newtio.c_cc[VMIN]     = 0;
    tcflush(fdCom, TCIFLUSH);
    if(tcsetattr(fdCom, TCSANOW, &newtio)) {
        goto closeexit;
    }
    IspEnvironment.fdCom = fdCom;
    ResetTarget(&IspEnvironment, PROGRAM_MODE);
    ClearSerialPortBuffers(&IspEnvironment);
    
    if (!transactionAndMatch(&IspEnvironment, "?", "Synchronized", 100)) {
        goto closeexit;
    }
    if (!transactionAndMatch(&IspEnvironment, "Synchronized\r\n", "Synchronized\r\nOK", 100)) {
        goto closeexit;
    }
    if (!transactionAndMatch(&IspEnvironment, "72000\r\n", "72000\r\nOK", 100)) {
        goto closeexit;
    }
    if (!transactionAndMatch(&IspEnvironment, "J\r\n", "J\r\n0\r\n402718517", 100)) {
        goto closeexit;
    }
    char Answer[128];
    memset(Answer, 0, sizeof(Answer));
    transaction(&IspEnvironment, "K\r\n", Answer, 100);
    btlVersion = ((Answer[6] - '0') << 4) + (Answer[9] - '0');
    
    found = YES;
closeexit:
    tcflush(fdCom, TCOFLUSH);
    tcflush(fdCom, TCIFLUSH);
    tcsetattr(fdCom, TCSANOW, &oldtio);
    close(fdCom);
    return found;
}

@end

static bool transactionAndMatch(ISP_ENVIRONMENT *IspEnvironment, const char *send, const char *match, unsigned timeOutMilliseconds)
{
    char Answer[128];
    memset(Answer,0,sizeof(Answer));
    transaction(IspEnvironment, send, Answer, timeOutMilliseconds);
    if (strncmp(Answer, match, strlen(match)) != 0) {
        ResetTarget(IspEnvironment, PROGRAM_MODE);
        return false;
    }
    return true;
}

static void transaction(ISP_ENVIRONMENT *IspEnvironment, const char *send, char *Answer, unsigned timeOutMilliseconds)
{
    unsigned long realsize;
    SendComPort(IspEnvironment, send);
    ReceiveComPort(IspEnvironment, Answer, 127, &realsize, 2, 1000);
}
