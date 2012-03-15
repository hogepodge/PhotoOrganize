//
//  PhotoOrganizer.h
//  PhotoOrganize
//
//  Created by Chris Hoge on 3/9/12.
//  Copyright (c) 2012 University of Oregon Neuroinformatics Center. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PhotoOrganizer : NSObject
{
    NSString* sourceDirectory;
    NSString* targetDirectory;
    
    NSFileManager* fileManager;
    NSDirectoryEnumerator* enumerator;
    
    NSMutableDictionary* imageDictionary;
    
    NSString* timezone;
    NSDateFormatter* fileFormatter;
    NSDateFormatter* directoryFormatter;
}

-(id)init;
-(id)initWithSource:(NSString*)source target:(NSString*)target;
-(BOOL)step;
+(NSString*)computeHash:(NSData*)data;
+(NSString*)identifyCategory:(NSString*)file;
-(NSDictionary*)imageMetadata:(NSString*)file;
-(BOOL)insertImage:(NSDictionary*)imageData;

@end
