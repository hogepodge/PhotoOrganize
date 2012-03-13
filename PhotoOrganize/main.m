//
//  main.m
//  PhotoOrganize
//
//  Created by Chris Hoge on 3/9/12.
//  Copyright (c) 2012 University of Oregon Neuroinformatics Center. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhotoOrganizer.h"

int main(int argc, const char * argv[])
{

        // insert code here...
        NSLog(@"Hello, World!");
        if (argc != 3) {
            NSLog(@"Usage: PhotoOrganize <source> <target>");
            return 1;
        }
        
        NSString* source = [[NSString alloc] initWithUTF8String:argv[1]];
        NSString* target = [[NSString alloc] initWithUTF8String:argv[2]];
        
        NSLog(@"%@", source);
        NSLog(@"%@", target);
        
        PhotoOrganizer* organizer = [[PhotoOrganizer alloc] initWithSource:source target:target];
        
        while ([organizer step]) {

        }
    
    [source release];
    [target release];
        
    return 0;
}

