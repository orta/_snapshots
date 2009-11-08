//
//  EvolveController.h
//  snapshots
//
//  Created by benmaslen on 24/04/2009.
//  Copyright 2009 ortatherox.com. All rights reserved.
//
#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>


@interface EvolveController : NSObject {
	IBOutlet NSWindow * myWindow;
  IBOutlet NSImageView *backgroundImageView;
  IBOutlet NSImageView *imageView;

}

- (void) givenFilepath: (NSString*)path ;
- (void) givenMostRecentSnapshotPath: (NSString*) path;

@end
