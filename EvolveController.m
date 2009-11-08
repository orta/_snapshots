//
//  EvolveController.m
//  snapshots
//
//  Created by benmaslen on 24/04/2009.
//  Copyright 2009 ortatherox.com. All rights reserved.
//

// Essentially the document controller

#import "EvolveController.h"


@implementation EvolveController

- (void) awakeFromNib{
  [imageView setImageAlignment:NSImageAlignCenter];
}

- (void) givenFilepath: (NSString*) path {
  
}

- (void) givenMostRecentSnapshotPath: (NSString*) path { 
  [imageView setImage:[[NSImage alloc] initWithContentsOfFile:path]];
}

- (void)windowDidResignMain:(NSNotification *)notification{
  [backgroundImageView setImage:[NSImage imageNamed:@"bg-inactive"]];
}

- (void)windowDidBecomeKey:(NSNotification *)notification{
  [backgroundImageView setImage:[NSImage imageNamed:@"bg-active"]];

}







@end
