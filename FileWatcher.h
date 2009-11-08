#import <Cocoa/Cocoa.h>
#import "UKKQueue.h"
#import "GrowlHandler.h"
#import "EvolveController.h"

@interface FileWatcher : NSObject {
  
  
	IBOutlet NSWindow * myWindow;
	NSString * filePath; // only one to actually render
  NSString * fileName;
  NSString * fileCount;

  
  NSMutableArray * myTriggerFilenames;
	NSMutableArray * myTriggers;
	NSMutableArray * lastTriggerSizes;
  NSMutableArray * shouldUseTrigger;

  
	long targetFileDifference;
  NSString *currentStatus;
  NSString *currentSpaceUsed;

  GrowlHandler *myGrowlHandler;
  IBOutlet EvolveController *evolveController;
  
  int _count;
}

- (IBAction)addFile:(id)sender;
- (IBAction)addAdditionalTrigger:(id)sender;
- (bool) watchFileWithPath: (NSString*)path ;
- (void) watchedFileChangedOrRemoved: (NSNotification *) notification;
- (unsigned long long) getFileSizeForPath:(NSString *) path;
- (void) grabNewcopy:(NSString *) path;
- (void) copyPathToAppSupportFolder;
- (NSString *) mostRecentSnapshotPath;
- (int) snapshotCount;
- (void)calculateFolderSize;
- (NSString *) currentSnapshotPath;
- (void)updateFileCount;

@property (retain) NSString *currentStatus;
@property(retain) NSString *fileName;
@property(retain) NSString *filePath;
@property(retain) NSString *fileCount;
@property(retain) NSString *currentSpaceUsed;
@property(retain) NSMutableArray * myTriggerFilenames;
@property(retain) NSMutableArray * shouldUseTrigger;

@end
