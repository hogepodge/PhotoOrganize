//
//  PhotoOrganizer.m
//  PhotoOrganize
//
//  Created by Chris Hoge on 3/9/12.
//  Copyright (c) 2012 University of Oregon Neuroinformatics Center. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "PhotoOrganizer.h"
#import "NSData_MD5.h"
#import "objc/runtime.h"



@implementation PhotoOrganizer
-(id)init
{
    self = [super init];
    if (self) {
        imageDictionary = [[NSMutableDictionary alloc] initWithCapacity:1000];
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
            NSError* error;
            NSLog(@"Target does not exist.");
            [fileManager createDirectoryAtPath:target withIntermediateDirectories:TRUE attributes:nil error:&error];
            if ([fileManager fileExistsAtPath:target isDirectory:&directory]) {
                NSLog(@"Target created: %@.", target);
            } else {
                NSLog(@"Target failed to be created: %@",target);
            }
        }
        sourceDirectory = source;
        targetDirectory = target;
        imageDictionary = [[NSMutableDictionary alloc] initWithCapacity:1000];
    }

    return self;
}

-(BOOL)step
{
    NSString* file = [enumerator nextObject];
    if (file) 
    {
        NSAutoreleasePool *loopPool = [[NSAutoreleasePool alloc] init];
        NSString* longFile = [NSString stringWithFormat:@"%@%@", sourceDirectory, file];
        NSDictionary* metadata = [self imageMetadata:longFile];
        if (metadata) {
            NSString* md5 = [metadata objectForKey:@"md5"];
            if ([imageDictionary objectForKey:md5]) {
                NSLog(@"Found Duplicate image.");
            } else {
                [imageDictionary setObject:metadata forKey:md5];
                NSLog(@"Inserted image: %@", md5);
            }
        }
        [loopPool drain];
        return TRUE;
    } 
    else return FALSE;
}

+(NSString*)computeHash:(NSData*) data
{
    NSString* md5 = NULL;

    if (data) {

        md5 = [data MD5];
    } else {
        NSLog(@"Bad data.");
    }
    return md5;
}

-(NSDictionary*)imageMetadata:(NSString*) file
{
    file = [file stringByStandardizingPath];
    NSDictionary* imageMetadata = nil;
    NSString* imageType = [PhotoOrganizer identifyType:file];
    if (imageType) {
        NSData* imageData = [NSData dataWithContentsOfFile:file];

        NSString* md5 = [PhotoOrganizer computeHash:imageData];
        NSBitmapImageRep* rep = [NSBitmapImageRep imageRepWithData:imageData];
        
        NSDictionary* exif = [rep valueForProperty:NSImageEXIFData];

        
        NSError* error;
        NSDictionary* attributes = [fileManager attributesOfItemAtPath:file error:&error];
                
        imageMetadata = [[NSDictionary alloc] initWithObjectsAndKeys:
                         md5, @"md5", 
                         [NSNumber numberWithUnsignedInt:[rep pixelsWide]], @"width", 
                         [NSNumber numberWithUnsignedInt:[rep pixelsHigh]], @"height",
                         file, @"location",
                         exif, @"exif",
                         attributes, @"attributes",
                         nil];
        
        [imageMetadata autorelease];
    }

    return imageMetadata;
}


+(NSString*)identifyType:(NSString *)file
{
    if (NSOrderedSame == [[file pathExtension] caseInsensitiveCompare:@"jpg"] ||
        NSOrderedSame == [[file pathExtension] caseInsensitiveCompare:@"jpeg"])
    {
        return @"jpg";
    } else if (NSOrderedSame == [[file pathExtension] caseInsensitiveCompare:@"orf"] ||
               NSOrderedSame == [[file pathExtension] caseInsensitiveCompare:@"nef"] ||
               NSOrderedSame == [[file pathExtension] caseInsensitiveCompare:@"cr2"] ||
               NSOrderedSame == [[file pathExtension] caseInsensitiveCompare:@"dng"])
    {
        return @"raw";
    } else if (NSOrderedSame == [[file pathExtension] caseInsensitiveCompare:@"tiff"] ||
               NSOrderedSame == [[file pathExtension] caseInsensitiveCompare:@"tif"])
    {
        return @"tif";
    } else if (NSOrderedSame == [[file pathExtension] caseInsensitiveCompare:@"psd"]) 
    {
        return @"psd";
    } else {
        return NULL;
    }
}



@end
