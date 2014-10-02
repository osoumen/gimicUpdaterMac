//
//  DownloadOperation.m
//  GIMICUpdater
//
//  Created by osoumen on 2014/10/03.
//  Copyright (c) 2014年 osoumen. All rights reserved.
//

#import "DownloadOperation.h"
#include "lpc21isp.h"

@implementation DownloadOperation

- (void)main
{
    char params[][256] = {
        "lpc21isp",
        "-hex",
        "/Users/osoumen/gimicUpdater/gimic.hex",
        "/dev/cu.SLAB_USBtoUART",
        "230400",
        "72000"
    };
    char *arguments[6] = {
        params[0],
        params[1],
        params[2],
        params[3],
        params[4],
        params[5],
    };
    AppDoProgram(6, arguments);
}

@end
