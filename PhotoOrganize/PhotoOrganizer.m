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
            NSLog(@"Source exists: %@", source);
            if (directory) {
                NSLog(@"Source is a directory.");
                enumerator = [fileManager enumeratorAtPath:source];
            } else {
                NSLog(@"Source is not a directory. Exiting.");
                exit(1);
            }
        } else {
            NSLog(@"Source does not exist: %@\nExiting.", source);
            exit(1);
        }
        if ([fileManager fileExistsAtPath:target isDirectory:&directory]) {
            NSLog(@"Target exists: %@\nExiting.", target);
            exit(1);
        } else {
            NSError* error;
            NSLog(@"Target does not exist.");
            [fileManager createDirectoryAtPath:target withIntermediateDirectories:TRUE attributes:nil error:&error];
            if ([fileManager fileExistsAtPath:target isDirectory:&directory]) {
                NSLog(@"Created target: %@.", target);
            } else {
                NSLog(@"Failed to create target: %@\nExiting.",target);
            }
        }
        sourceDirectory = source;
        targetDirectory = [target stringByStandardizingPath];
        NSLog(@"%@", targetDirectory);
        imageDictionary = [[NSMutableDictionary alloc] initWithCapacity:1000];
        NSDate* now = [[NSDate alloc] init];
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"Z"];
        timezone = [formatter stringFromDate:now];
        
        NSLocale *locale= [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        
        fileFormatter = [[NSDateFormatter alloc] init];
        [fileFormatter setLocale:locale];
        [fileFormatter setDateFormat:@"yyyyMMddHHmmss"];
        
        directoryFormatter = [[NSDateFormatter alloc] init];
        [directoryFormatter setLocale:locale];
        [directoryFormatter setDateFormat:@"yyyy/MM/dd"];
        
        NSLog(@"%@", timezone);

        [locale release];        

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
        if ([self insertImage:metadata])
        {
            [self createTargetDirectory:metadata];
            NSString* filename = [self fileName:metadata];
            [fileManager copyItemAtPath:longFile toPath:filename error:nil];
            NSLog(@"Copied %@ to %@", longFile, filename);
        }
        [loopPool drain];
        return TRUE;
    } 
    return FALSE;
}

-(BOOL)createTargetDirectory:(NSDictionary *)imageData
{
    NSDictionary* exif = [imageData objectForKey:@"exif"];
    NSString* fileCategory = [imageData objectForKey:@"imageCategory"];
    NSString* dateString = [exif objectForKey:@"DateTimeOriginal"];
    dateString = [NSString stringWithFormat:@"%@ %@", dateString, timezone];
    NSDate* date = [[NSDate alloc] initWithString:dateString];   
    
    NSString* target = [[NSString alloc] initWithFormat:@"%@/%@/%@",
                        targetDirectory,
                        fileCategory,
                        [directoryFormatter stringFromDate:date]];

    BOOL directory;
    if (![fileManager fileExistsAtPath:target isDirectory:&directory]) {
        [fileManager createDirectoryAtPath:target withIntermediateDirectories:TRUE attributes:nil error:nil];
    }
    [target autorelease];
    [date release];
    
    return TRUE;

}

-(NSString*)fileName:(NSDictionary *)imageData
{
    NSDictionary* exif = [imageData objectForKey:@"exif"];
    NSString* fileType = [imageData objectForKey:@"imageType"];
    NSString* fileCategory = [imageData objectForKey:@"imageCategory"];
    NSString* md5 = [imageData objectForKey:@"md5"];
    NSString* dateString = [exif objectForKey:@"DateTimeOriginal"];
    dateString = [NSString stringWithFormat:@"%@ %@", dateString, timezone];
    NSDate* date = [[NSDate alloc] initWithString:dateString];   
    
    
    NSString* target = [[NSString alloc] initWithFormat:@"%@/%@/%@/%@-%@.%@",
                        targetDirectory,
                        fileCategory,
                        [directoryFormatter stringFromDate:date],
                        [fileFormatter stringFromDate:date],
                        [md5 substringToIndex:4],
                        fileType];
    [target autorelease];
    [date release];
    return target;
}

-(BOOL)insertImage:(NSDictionary *)imageData
{
    if (imageData) {
        NSString* md5 = [imageData objectForKey:@"md5"];
        if ([imageDictionary objectForKey:md5]) {
            NSLog(@"Found duplicate image. Skipping %@.", md5);
            return FALSE;
        } else {
            [imageDictionary setObject:imageData forKey:md5];
            NSLog(@"Found unique image. Cataloged %@.", md5);
            return TRUE;
        }
    }
    return FALSE;
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
    NSString* imageCategory = [PhotoOrganizer identifyCategory:file];
    if (imageCategory) 
    {
        NSLog(@"%@", file);
        NSData* imageData = [NSData dataWithContentsOfFile:file];
        if (imageData)
        {
            NSBitmapImageRep* rep = [NSBitmapImageRep imageRepWithData:imageData];
            if (rep)
            {
                NSString* md5 = [PhotoOrganizer computeHash:imageData];
                NSDictionary* exif = [rep valueForProperty:NSImageEXIFData];
                
                NSError* error;
                if (!exif) {
                    NSDictionary* dict = [fileManager attributesOfItemAtPath:file error:&error];
                    NSString* date = [dict objectForKey:@"NSFileCreationDate"];
                    exif = [[NSDictionary alloc] initWithObjectsAndKeys: 
                            date, @"DateTimeOriginal", nil];
                    [exif autorelease];
                }
        
 
                NSDictionary* attributes = [fileManager attributesOfItemAtPath:file error:&error];
                
                imageMetadata = [[NSDictionary alloc] initWithObjectsAndKeys:
                                 md5, @"md5", 
                                 [NSNumber numberWithUnsignedInt:[rep pixelsWide]], @"width", 
                                 [NSNumber numberWithUnsignedInt:[rep pixelsHigh]], @"height",
                                 file, @"location",
                                 exif, @"exif",
                                 attributes, @"attributes",
                                 imageCategory, @"imageCategory",
                                 [file pathExtension], @"imageType",
                                 nil];
                [imageMetadata autorelease];
            } else {
                NSLog(@"Image read error: %@", file);
            }
        } else {
            NSLog(@"Data read error: %@", file);
        }
    }
    return imageMetadata;
}


+(NSString*)identifyCategory:(NSString *)file
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
