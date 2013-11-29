//
//  PhotoOrganizer.m
//  PhotoOrganize
//
//  Created by Chris Hoge on 3/9/12.
//  Copyright (c) 2012 Chris Hoge.
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
            NSLog(@"Target exists: %@\n.", target);
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
    NSString* fileCategory = [imageData objectForKey:@"imageCategory"];
    NSDate* date = [imageData objectForKey:@"date"];
    
    NSString* target = [[NSString alloc] initWithFormat:@"%@/%@/%@",
                        targetDirectory,
                        fileCategory,
                        [directoryFormatter stringFromDate:date]];

    BOOL directory;
    if (![fileManager fileExistsAtPath:target isDirectory:&directory]) {
        [fileManager createDirectoryAtPath:target withIntermediateDirectories:TRUE attributes:nil error:nil];
        NSLog(@"Created %@", target);
    }
    [target autorelease];
    [date release];
    
    return TRUE;

}

-(NSString*)fileName:(NSDictionary *)imageData
{
    NSString*  imageType = [imageData objectForKey:@"imageType"];
    NSString* imageCategory = [imageData objectForKey:@"imageCategory"];
    NSString* md5 = [imageData objectForKey:@"md5"];
	NSDate* date = [imageData objectForKey:@"date"];
        
    NSString* target = [[NSString alloc] initWithFormat:@"%@/%@/%@/%@-%@.%@",
                        targetDirectory,
                        imageCategory,
                        [directoryFormatter stringFromDate:date],
                        [fileFormatter stringFromDate:date],
                        [md5 substringToIndex:5],
                        imageType];
    [target autorelease];
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
		NSData* imageData = [NSData dataWithContentsOfFile:file];
		if (imageData) {			
			NSString* md5 = [PhotoOrganizer computeHash:imageData];
			if ([imageCategory caseInsensitiveCompare:@"dng"] == NSOrderedSame ) {
				NSError* error;
				NSDictionary* dict = [fileManager attributesOfItemAtPath:file error:&error];
				NSDate* date = [dict objectForKey:@"NSFileCreationDate"];
				imageMetadata = [[NSDictionary alloc] initWithObjectsAndKeys:
								 md5, @"md5",
								 file, @"location",
								 imageCategory, @"imageCategory",
								 @"dng", @"imageType",
								 date, @"date",
								 nil];
				[imageMetadata autorelease];
			} else {
				NSBitmapImageRep* rep = [NSBitmapImageRep imageRepWithData:imageData];
				if (rep) {
					unsigned long width = [rep pixelsWide];
					unsigned long height = [rep pixelsHigh];
					if ((width < 480 || height < 480) &&
						[imageCategory compare:@"raw"] != NSOrderedSame) // raw may lie through thumbnail
					{
						NSLog(@"Image smaller than 480 pixels on one edge. Skipping: %@", file);
					} else {
						NSDictionary* exif = [rep valueForProperty:NSImageEXIFData];
                
						NSError* error;
						NSDate* date;
						
						if (!exif) {
							NSDictionary* dict = [fileManager attributesOfItemAtPath:file error:&error];
							date = [dict objectForKey:@"NSFileCreationDate"];
						} else {
							NSString* dateString = [exif objectForKey:@"DateTimeOriginal"];
							dateString = [NSString stringWithFormat:@"%@ %@", dateString, timezone];
							date = [[NSDate alloc] initWithString:dateString]; 
							[date autorelease];
						}
                        
                        if (!date) {
							NSDictionary* dict = [fileManager attributesOfItemAtPath:file error:&error];
							date = [dict objectForKey:@"NSFileCreationDate"];                            
                        }
						
						NSString* imageType = [file pathExtension];
        
						imageMetadata = [[NSDictionary alloc] initWithObjectsAndKeys:
										 md5, @"md5", 
										 file, @"location",
										 imageCategory, @"imageCategory",
										 imageType, @"imageType",
										 date, @"date",
										 nil];
						[imageMetadata autorelease];
					}
				} else {
					NSLog(@"Image read error: %@", file);
				}
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
               NSOrderedSame == [[file pathExtension] caseInsensitiveCompare:@"cr2"])
    {
        return @"raw";
    } else if (NSOrderedSame == [[file pathExtension] caseInsensitiveCompare:@"tiff"] ||
               NSOrderedSame == [[file pathExtension] caseInsensitiveCompare:@"tif"])
    {
        return @"tif";
    } else if (NSOrderedSame == [[file pathExtension] caseInsensitiveCompare:@"psd"]) 
    {
        return @"psd";
    } else if (NSOrderedSame == [[file pathExtension] caseInsensitiveCompare:@"dng"]) 
	{
		return @"dng";
	} else
	{
        return NULL;
    }
}

@end
