//
//  PortChecker.h
//  GIMICUpdater
//
//  Created by osoumen on 2014/10/06.
//  Copyright (c) 2014年 osoumen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PortChecker : NSOperation
{
    NSString    *portPath;
    int         btlVersion;
}

- (void)setPortPath:(NSString*)path;

@end
