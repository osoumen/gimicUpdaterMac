//
//  FetchFirmWareOperation.h
//  GIMICUpdater
//
//  Created by osoumen on 2014/10/11.
//  Copyright (c) 2014年 osoumen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FetchFirmWareOperation : NSOperation <NSURLConnectionDataDelegate>
{
    NSURL       *mFWPageUrl;
    NSString    *mFWUrl;
}
- (void)setFWPageUrl:(NSString*)path;

@end
