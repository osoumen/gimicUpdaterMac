//
//  DownloadOperation.h
//  GIMICUpdater
//
//  Created by osoumen on 2014/10/03.
//  Copyright (c) 2014年 osoumen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DownloadOperation : NSOperation
{
    NSURL       *mHexFilePath;
    NSString    *mPortPath;
}
@property BOOL        fullDebug;
@property BOOL        noVerify;
@property BOOL        eraseBeforeUpload;

- (void)setHexFilePath:(NSURL*)path;
- (void)setPortPath:(NSString*)path;

@end
