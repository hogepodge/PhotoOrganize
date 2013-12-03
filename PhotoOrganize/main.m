//
//  main.m
//  PhotoOrganize
//
//  Created by Chris Hoge on 3/9/12.
//  Copyright (c) 2012 Chris Hoge.
//

#import <Foundation/Foundation.h>
#import "PhotoOrganizer.h"

int main(int argc, const char * argv[])
{
    if (argc < 3) {
        NSLog(@"Usage: PhotoOrganize <source1> ... <sourceN> <target>");
        return 1;
    }
    
    NSMutableArray *sources = [[NSMutableArray alloc] init];
    for (size_t i = 0; i < (argc-2); ++i) {
        NSString* source = [[NSString alloc] initWithUTF8String:argv[i+1]];
        [sources insertObject:source atIndex:i];
    }
    
    NSString* target = [[NSString alloc] initWithUTF8String:argv[argc-1]];
    
    NSLog(@"%@", sources);
    NSLog(@"%@", target);
    
    PhotoOrganizer* organizer = [[PhotoOrganizer alloc] initWithSources:sources target:target];
    
    while ([organizer step]) {
    }
    
    [sources release];
    [target release];
    
    return 0;
}