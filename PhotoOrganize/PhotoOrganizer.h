//
//  PhotoOrganizer.h
//  PhotoOrganize
//
//  Created by Chris Hoge on 3/9/12.
//  Copyright (c) 2012 Chris Hoge.
//

#import <Foundation/Foundation.h>

@interface PhotoOrganizer : NSObject
{
    NSMutableArray* sourceDirectories;
    NSString* targetDirectory;
    
    int currentSource;
    NSDirectoryEnumerator* enumerator;
    
    NSFileManager* fileManager;

    
    NSMutableDictionary* imageDictionary;
    
    NSString* timezone;
    NSDateFormatter* fileFormatter;
    NSDateFormatter* directoryFormatter;
}

-(id)init;
-(id)initWithSources:(NSMutableArray*)sources target:(NSString*)target;
-(BOOL)step;
+(NSString*)computeHash:(NSData*)data;
+(NSString*)identifyCategory:(NSString*)file;
-(NSDictionary*)imageMetadata:(NSString*)file;
-(BOOL)insertImage:(NSDictionary*)imageData;
-(BOOL)createTargetDirectory:(NSDictionary *)imageData;
-(NSString*)fileName:(NSDictionary *)imageData;

@end

