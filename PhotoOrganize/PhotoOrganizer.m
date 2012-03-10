//
//  PhotoOrganizer.m
//  PhotoOrganize
//
//  Created by Chris Hoge on 3/9/12.
//  Copyright (c) 2012 University of Oregon Neuroinformatics Center. All rights reserved.
//

#import "PhotoOrganizer.h"


@implementation PhotoOrganizer
-(id)init
{
    self = [super init];
    if (self) {

    }
    return self;
}
-(id)initWithSource:(NSString*)source target:(NSString*)target
{
    self = [super init];
    if (self) {
        BOOL directory;
        fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:source isDirectory:&directory] == YES)
        {
            NSLog(@"Source file exists.");
            if (directory) {
                NSLog(@"Source file is a directory.");
                enumerator = [fileManager enumeratorAtPath:source];
            }
        } else {
            NSLog(@"Source does not exist.");
            exit(1);
        }
        if ([fileManager fileExistsAtPath:target isDirectory:&directory]) {
            NSLog(@"Target file exists.");
            if (directory) {
                NSLog(@"Target file is a directory.");
                exit(1);
            }
        } else {
            NSLog(@"Target does not exist.");
        }
    }
    return self;
}

-(BOOL)step
{
    NSString* file = [enumerator nextObject];
    if (file) {
        if (NSOrderedSame == [[file pathExtension] caseInsensitiveCompare:@"jpg"] ||
            NSOrderedSame == [[file pathExtension] caseInsensitiveCompare:@"jpeg"] ||
            NSOrderedSame == [[file pathExtension] caseInsensitiveCompare:@"orf"] ||
            NSOrderedSame == [[file pathExtension] caseInsensitiveCompare:@"nef"] ||
            NSOrderedSame == [[file pathExtension] caseInsensitiveCompare:@"cr2"] ||
            NSOrderedSame == [[file pathExtension] caseInsensitiveCompare:@"tiff"] ||
            NSOrderedSame == [[file pathExtension] caseInsensitiveCompare:@"tif"] ||
            NSOrderedSame == [[file pathExtension] caseInsensitiveCompare:@"psd"] ||
            NSOrderedSame == [[file pathExtension] caseInsensitiveCompare:@"dng"])
            NSLog(@"%@", file);
        return TRUE;
    } else return FALSE;
}

@end
