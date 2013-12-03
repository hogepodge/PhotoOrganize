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

-(id)initWithSources:(NSMutableArray*)sources target:(NSString*)target
{
    self = [super init];
    if (self) {
        BOOL directory;
        fileManager = [NSFileManager defaultManager];
        
        // Validate the sources
        for (size_t i = 0; i < [sources count]; ++i) {
            NSString* source = [sources objectAtIndex:i];
            
            if ([fileManager fileExistsAtPath:source isDirectory:&directory] == YES)
            {
                NSLog(@"Source exists: %@", source);
                if (directory) {
                    NSLog(@"Source is a directory.");
                    
                } else {
                    NSLog(@"Source is not a directory. Exiting.");
                    exit(1);
                }
            } else {
                NSLog(@"Source does not exist: %@\nExiting.", source);
                exit(1);
            }
        }
        
        // Validate and create the target
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
        
        sourceDirectories = sources;
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
        [fileFormatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
        
        directoryFormatter = [[NSDateFormatter alloc] init];
        [directoryFormatter setLocale:locale];
        [directoryFormatter setDateFormat:@"yyyy/MM"];
        
        NSLog(@"%@", timezone);

        [locale release];        

    }
    
    currentSource = 0;
    enumerator = [fileManager enumeratorAtPath:[sources objectAtIndex:currentSource]];
    
    return self;
}



-(BOOL)step
{
    NSString* file = [enumerator nextObject];
    if (file) 
    {
        NSString* sourceDirectory = [sourceDirectories objectAtIndex:currentSource];
        NSAutoreleasePool *loopPool = [[NSAutoreleasePool alloc] init];
        NSString* longFile = [NSString stringWithFormat:@"%@/%@", sourceDirectory, file];
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
    } else {
        ++currentSource;
        if (currentSource == [sourceDirectories count]) {
            return FALSE;
        } else {
            enumerator = [fileManager enumeratorAtPath: [sourceDirectories objectAtIndex:currentSource]];
            return [self step];
        }
    }
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
        
    NSString* target = [[NSString alloc] initWithFormat:@"%@/%@/%@/%@_%@.%@",
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
    NSLog(@"%@", file);
    NSDictionary* imageMetadata = nil;
    NSString* imageCategory = [PhotoOrganizer identifyCategory:file];
    NSError* error;
    if (imageCategory) 
    {
        
		NSData* imageData = [NSData dataWithContentsOfFile:file options:0 error:&error];
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
					if ((width < 1025 || height < 1025) &&
						[imageCategory compare:@"raw"] != NSOrderedSame) // raw may lie through thumbnail
					{
						NSLog(@"Image smaller than 1024 pixels on one edge. Skipping: %@", file);
					} else {
                        // TODO: ARW Fails. Fix.
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
			NSLog(@"Data read error: %@ %@", file, error);
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
/*    } else if (NSOrderedSame == [[file pathExtension] caseInsensitiveCompare:@"jp2"]) {
        return @"jp2";*/
    } else if (NSOrderedSame == [[file pathExtension] caseInsensitiveCompare:@"orf"] ||
               NSOrderedSame == [[file pathExtension] caseInsensitiveCompare:@"nef"] ||
               NSOrderedSame == [[file pathExtension] caseInsensitiveCompare:@"cr2"] ||
               NSOrderedSame == [[file pathExtension] caseInsensitiveCompare:@"arw"] ||
               NSOrderedSame == [[file pathExtension] caseInsensitiveCompare:@"raf"])
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
