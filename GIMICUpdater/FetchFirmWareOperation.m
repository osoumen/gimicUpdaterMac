//
//  FetchFirmWareOperation.m
//  GIMICUpdater
//
//  Created by osoumen on 2014/10/11.
//  Copyright (c) 2014年 osoumen. All rights reserved.
//

#import "FetchFirmWareOperation.h"
#import "HTMLParser.h"

@implementation FetchFirmWareOperation

- (id)init
{
    self = [super init];
    mFWPageUrl = nil;
    mFWUrl = nil;
    return self;
}

- (void)setFWPageUrl:(NSString*)path
{
    mFWPageUrl = [NSURL URLWithString:path];
}

- (void)main
{
    NSNotificationCenter    *center;
    center = [NSNotificationCenter defaultCenter];

    NSURLRequest *req = [NSURLRequest requestWithURL:mFWPageUrl
                                         cachePolicy:NSURLRequestUseProtocolCachePolicy
                                     timeoutInterval:15.0];
    NSError *error;
    NSURLResponse *res;
    NSData *data = [NSURLConnection sendSynchronousRequest:req
                                         returningResponse:&res
                                                     error:&error];
    if (error) {
        NSLog(@"%@", error);
        [center postNotificationName:@"succeedFetchFirmWare" object:self userInfo:nil];
        return;
    }
    
    NSString *html = [[NSString alloc] initWithBytes:data.bytes
                                              length:data.length
                                            encoding:NSUTF8StringEncoding];
    
    // "FW"を含み、".zip"で終わる 一番最初のhrefを取得する
    HTMLParser *parser = [[HTMLParser alloc] initWithString:html
                                                      error:&error];
    HTMLNode *bodyNode = [parser body];
    NSArray *aNodes = [bodyNode findChildTags:@"a"];
    for (HTMLNode *node in aNodes) {
        NSString *href = [node getAttributeNamed:@"href"];
        NSRange match = [href rangeOfString:@"FW.*\\.zip$"
                                    options:NSRegularExpressionSearch];
        if (match.location != NSNotFound && match.length > 0) {
            mFWUrl = href;
            //NSLog(@"%@", href);
            break;
        }
    }
    
    if (mFWUrl) {
        req = [NSURLRequest requestWithURL:[NSURL URLWithString:mFWUrl]
                               cachePolicy:NSURLRequestUseProtocolCachePolicy
                           timeoutInterval:30.0];
        data = [NSURLConnection sendSynchronousRequest:req
                                     returningResponse:&res
                                                 error:&error];
        if (error) {
            NSLog(@"%@", error);
            [center postNotificationName:@"succeedFetchFirmWare" object:self userInfo:nil];
            return;
        }
        [data writeToFile:@"/tmp/gimic_fw.zip"
               atomically:YES];
        [self unzip];
    }
    
    // 通知
    NSDictionary *btlVers = nil;
    if (mFWUrl) {
        btlVers = [NSDictionary dictionaryWithObject:mFWUrl
                                              forKey:@"fwFile"];
    }
    [center postNotificationName:@"succeedFetchFirmWare" object:self userInfo:btlVers];
}

- (void)unzip {
    NSString* zipPath = @"/tmp/gimic_fw.zip";
    NSString* targetFolder = @"/tmp";
    NSArray *arguments = [NSArray arrayWithObjects:@"-o", zipPath, nil];
    NSTask *unzipTask = [[NSTask alloc] init];
    [unzipTask setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
    [unzipTask setLaunchPath:@"/usr/bin/unzip"];
    [unzipTask setCurrentDirectoryPath:targetFolder];
    [unzipTask setArguments:arguments];
    [unzipTask launch];
    [unzipTask waitUntilExit];
}

@end
