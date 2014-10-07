//
//  PortChecker.m
//  GIMICUpdater
//
//  Created by osoumen on 2014/10/06.
//  Copyright (c) 2014年 osoumen. All rights reserved.
//

#import "PortChecker.h"

@implementation PortChecker

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
        while ([self checkPortExist] == NO) {
            usleep(100000);
        }
        
        // TODO: アップデートモードであるかチェック
        
        // TODO: MB1かMB2かをチェック
        
        // アップデートが可能になったことを通知
        NSNotificationCenter    *center;
        center = [NSNotificationCenter defaultCenter];
        
        [center postNotificationName:@"ReadyToUpdate" object:self userInfo:nil];
        
        while ([self checkPortExist] == YES) {
            usleep(100000);
        }
        [center postNotificationName:@"DisappearPort" object:self userInfo:nil];
    }
}

@end
