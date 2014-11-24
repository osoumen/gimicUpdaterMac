//
//  FetchFirmWareOperation.m
//  GIMICUpdater
//
//  Created by osoumen on 2014/10/11.
//  Copyright (c) 2014年 osoumen. All rights reserved.
//

#import "FetchFirmWareOperation.h"
#import "HTMLParser.h"

NSLock* _lock = nil;

@implementation FetchFirmWareOperation

- (id)init
{
    self = [super init];
    mFWPageUrl = nil;
    mFWUrl = nil;
    if (_lock == nil) {
        _lock = [[NSLock alloc] init];
    }
    return self;
}

- (void)setFWPageUrl:(NSString*)path
{
    mFWPageUrl = [NSURL URLWithString:path];
}

- (void)allowDevelopFW:(BOOL)allow
{
    includeDevFW = allow;
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

    NSString* pattern = @"FW.*_(\\d{8})\\.zip$";
    NSRegularExpression* regex = [NSRegularExpression
                                  regularExpressionWithPattern:pattern
                                  options:NSRegularExpressionCaseInsensitive
                                  error:&error];
    int fwVers = 0;
    
    for (HTMLNode *node in aNodes) {
        NSString *href = [node getAttributeNamed:@"href"];
        
        if (href) {
            NSTextCheckingResult *match= [regex firstMatchInString:href
                                                           options:0
                                                             range:NSMakeRange(0, href.length)];

            if (match != nil && [match rangeAtIndex:0].location != NSNotFound) {
                NSString *versStr = [href substringWithRange:[match rangeAtIndex:1]];
                if ([versStr intValue] > fwVers) {
                    fwVers = [versStr intValue];
                    mFWUrl = href;
                    //NSLog(@"%@", href);
                    if (!includeDevFW) {
                        break;
                    }
                }
            }
        }
    }
    
    NSDictionary *btlVers = nil;
    
    if (mFWUrl) {
        // 取得出来たならダウンロードを実行する
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
        
        NSRange range = [mFWUrl rangeOfString:@"openfile=.*zip$"
                                      options:NSRegularExpressionSearch];
        range.length -= 9;
        range.location += 9;
        NSString *fwZipName = [mFWUrl substringWithRange:range];
        NSString *fwDlPath = [NSString stringWithFormat:@"%@/%@",
                              NSLocalizedString(@"fwDownloadPath", @""),fwZipName];
        
        [_lock lock];
        @try {
            [data writeToFile:fwDlPath
                   atomically:YES];
            [self deleteOldFW];
            [self unzip:fwDlPath];
        }
        @finally {
            [_lock unlock];
        }
        
        btlVers = [NSDictionary dictionaryWithObject:fwZipName forKey:@"fwName"];
    }
    
    // 通知
    [center postNotificationName:@"succeedFetchFirmWare" object:self userInfo:btlVers];
}

- (void)unzip:(NSString*)zipPath
{
    NSString* targetFolder = NSLocalizedString(@"fwDownloadPath", @"");
    NSArray *arguments = [NSArray arrayWithObjects:@"-o", zipPath, nil];
    NSTask *unzipTask = [[NSTask alloc] init];
    [unzipTask setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
    [unzipTask setLaunchPath:@"/usr/bin/unzip"];
    [unzipTask setCurrentDirectoryPath:targetFolder];
    [unzipTask setArguments:arguments];
    [unzipTask launch];
    [unzipTask waitUntilExit];
}

- (void)deleteOldFW
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *paths = [fileManager contentsOfDirectoryAtPath:@"/tmp"
                                                      error:&error];
    for (int i=0; i<[paths count]; i++) {
        NSString *fwpath = [paths objectAtIndex:i];
        NSRange result = [fwpath rangeOfString:@"MB1.*\\.hex$"
                                       options:NSRegularExpressionSearch];
        if (result.location != NSNotFound) {
            [fileManager removeItemAtPath:[NSString stringWithFormat:@"/tmp/%@",fwpath]
                                    error:&error];
        }
        result = [fwpath rangeOfString:@"MB2.*\\.hex$"
                               options:NSRegularExpressionSearch];
        if (result.location != NSNotFound) {
            [fileManager removeItemAtPath:[NSString stringWithFormat:@"/tmp/%@",fwpath]
                                    error:&error];
        }
    }
}
@end
