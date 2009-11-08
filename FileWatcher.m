#import "FileWatcher.h"
#define APP_NAME snapshots
#import "ASIWebThumbnailGenerator.h"


@implementation FileWatcher

- (void) awakeFromNib{
	myTriggers = [[NSMutableArray alloc] init];
	lastTriggerSizes = [[NSMutableArray alloc] init];
  myTriggerFilenames = [[NSMutableArray alloc] init];  
  shouldUseTrigger = [[NSMutableArray alloc] init];  

	targetFileDifference = 5;
	NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
	NSString *growlPath = [[myBundle privateFrameworksPath] stringByAppendingPathComponent:@"Growl.framework"];
	NSBundle *growlBundle = [NSBundle bundleWithPath:growlPath];
	if (growlBundle && [growlBundle load]) {
    myGrowlHandler = [[GrowlHandler alloc] init];
   // Register ourselves as a Growl delegate
		[GrowlApplicationBridge setGrowlDelegate:myGrowlHandler];
	} else {
		NSLog(@"Could not load Growl.framework");
	}
  self.currentStatus = @"Not assigned a file";
}

#pragma mark Adding Triggers
- (IBAction)addAdditionalTrigger:(id)sender {
	// look in the same folder by default
	if(filePath == nil){ 
		[self addFile:self];
		return;
	}
	NSOpenPanel *oPanel = [NSOpenPanel openPanel];
	[oPanel setAllowsMultipleSelection:NO];
	[oPanel beginSheetForDirectory: [filePath stringByDeletingPathExtension] file:nil types:nil	modalForWindow: myWindow modalDelegate:self
                  didEndSelector:@selector(openPanelDidEndAdditionalTrigger:returnCode:contextInfo:) contextInfo:nil];
  
}

- (void)openPanelDidEndAdditionalTrigger:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	NSString * myTriggerURL;
	NSLog(@"addition");
	if (returnCode == NSOKButton) {
    myTriggerURL = [[[sheet filenames] objectAtIndex:0] copy];
  }
	else{
		NSLog(@"Cancelled");
		return;
	}
  if (myTriggerURL) {
    
		NSEnumerator * enumerator = [myTriggers objectEnumerator];
		NSString * element;
		while(element = [enumerator nextObject])
		{
			if ( [myTriggerURL compare:element] == NSOrderedSame ){
				NSLog(@"Duplicate trigger");
				return;
			}
		}
    [self watchFileWithPath:myTriggerURL];
    
  }
}

#pragma mark Adding Target and default trigger
- (IBAction)addFile:(id)sender {
	NSOpenPanel *oPanel = [NSOpenPanel openPanel];
  filePath = NSHomeDirectory();
	[oPanel setAllowsMultipleSelection:NO];
	[oPanel beginSheetForDirectory:filePath file:nil types:nil	modalForWindow: myWindow modalDelegate:self
                  didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
  if (returnCode == NSOKButton) {
    
    filePath = [[[sheet filenames] objectAtIndex:0] copy];
    // Main file given
		[myWindow setTitleWithRepresentedFilename:filePath];

    fileName = [[filePath pathComponents] lastObject];
    self.currentStatus = [ NSString  stringWithFormat:@"Looking at %@", fileName ];
	
    NSMutableDictionary *numberInfo = [NSMutableDictionary dictionaryWithContentsOfFile:[[self currentSnapshotPath] stringByAppendingPathComponent:@"count"]];
		NSNumber * currentCount = [numberInfo objectForKey:@"theNumber"];
    _count = [currentCount intValue];

    if(_count > 0){
      NSLog(@"path = %@", [self mostRecentSnapshotPath] );
      [evolveController givenMostRecentSnapshotPath:[self mostRecentSnapshotPath ]];
    }
    [evolveController givenFilepath: filePath];
    [self calculateFolderSize];
    [self updateFileCount];
    
    
  }
	else{
		NSLog(@"Bye bye then");
		return;
	}
  if (filePath) {
    [self watchFileWithPath:filePath];
  }
}

#pragma mark Watching files

-(bool) watchFileWithPath:(NSString *) path {
	NSFileManager *fm = [NSFileManager defaultManager];
  BOOL fileExists = [fm fileExistsAtPath:path];
	if(fileExists == false){
		NSLog(@"file doesn't exist");
    return false;
  }
  UKKQueue* kqueue = [UKKQueue sharedFileWatcher];
  [kqueue addPathToQueue:path];
	NSWorkspace* workspace = [NSWorkspace sharedWorkspace];
  NSNotificationCenter* notificationCenter = [workspace notificationCenter];
  NSArray* notifications = [NSArray arrayWithObjects:
                            UKFileWatcherRenameNotification,
                            UKFileWatcherWriteNotification,
                            //     UKFileWatcherAttributeChangeNotification,
                            UKFileWatcherSizeIncreaseNotification,
                            //     UKFileWatcherLinkCountChangeNotification,
                            //      UKFileWatcherAccessRevocationNotification,
                            nil];
	
	[notificationCenter addObserver:self selector:@selector(watchedFileChangedOrRemoved:) name:UKFileWatcherDeleteNotification object:nil];
	
	int i;
  for (i=0; i<[notifications count]; i++) {
    [notificationCenter addObserver:self selector:@selector(watchedFileChanged:) name:[notifications objectAtIndex:i] object:nil];
  }
  
  [myTriggerFilenames addObject: [path lastPathComponent]];
  NSLog(@"%@ asdas", myTriggerFilenames);
	[myTriggers addObject:path]; // look at that baby! \/
	NSNumber * thisFileSize = [NSNumber numberWithUnsignedLongLong: (unsigned long long) [self getFileSizeForPath:path]];
	[lastTriggerSizes addObject: thisFileSize];
	return true;
}

- (void) watchedFileChangedOrRemoved: (NSNotification *) notification
{	
  //	NSLog(@"file has changed or removed"); 
  //	NSLog(@"%@ path", [[notification userInfo]objectForKey:@"path"] );
	NSString *path = [[notification userInfo]objectForKey:@"path"];
	NSFileManager *fm = [NSFileManager defaultManager];
  BOOL fileExists = [fm fileExistsAtPath:path];
	if(fileExists){
		// file has been changed by a document based window
    //		NSLog(@"%@ Changed - adding again to kqueue", path);
    UKKQueue* kqueue = [UKKQueue sharedFileWatcher];
    [kqueue removePath:path];
    [self grabNewcopy:path]; 
    [kqueue	addPath:path];
	}else{
		//err, file was actually deleted dude.
		NSLog(@"%@ Deleted", path);
	}
	
}

- (void) watchedFileChanged: (NSNotification *) notification
{	// normal notifications
	NSString * path = [[notification userInfo]objectForKey:@"path"];
	[self grabNewcopy: path]; 
}

- (unsigned long long) getFileSizeForPath:(NSString *) path;{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSDictionary * fileAttributes = [fm fileAttributesAtPath:path traverseLink:YES]; // set to no if bugs
	if (fileAttributes != nil) {
		NSNumber *fileSize;
		if (fileSize = [fileAttributes objectForKey:NSFileSize]) {
			return [fileSize unsignedLongLongValue];
		}
	}
	return 0;
}
#pragma mark Moving files around

- (void) grabNewcopy:(NSString *) path ;{
	unsigned long long newSize = [self getFileSizeForPath: path];		
	
	unsigned count = [lastTriggerSizes count];
	while (count--) {
		NSString * theTriggerPath = [myTriggers objectAtIndex:count];
		if ( [theTriggerPath compare:path] == NSOrderedSame ){
      
			NSNumber * tempFileSizeForPath =  [lastTriggerSizes objectAtIndex:count];
			unsigned long long oldFileSizeForPath = [tempFileSizeForPath unsignedLongLongValue];
			
			if(newSize){
				if(oldFileSizeForPath){
					int sizeDifference = newSize - oldFileSizeForPath;
					// make it positive
					if(sizeDifference < 0) sizeDifference *= -1;
					          
					if(sizeDifference > targetFileDifference) {
						NSNumber * thisFileSize = [NSNumber numberWithUnsignedLongLong: (unsigned long long) newSize];
						[lastTriggerSizes replaceObjectAtIndex:count withObject:thisFileSize ];
						[myGrowlHandler growl:fileName];
            
            //	NSLog(@"Getting a copy for the app support dir");
            
						[self copyPathToAppSupportFolder];
            [evolveController givenMostRecentSnapshotPath:[self mostRecentSnapshotPath]];
						return;
					}else{
						NSLog(@"Too small a difference to capture");
					}
				}
			}
		}
	}
}

- (int) getCountAndUpdate{
  NSFileManager *fm;
  fm = [NSFileManager defaultManager];
	NSArray  * paths =  NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,NSUserDomainMask, YES);
  NSString * basePath = ([paths count] > 0) ? [paths objectAtIndex: 0] : NSTemporaryDirectory();
  NSString * destination =  [basePath stringByAppendingPathComponent:@"snapshots"] ;
	if(![fm fileExistsAtPath:destination]) {
		if(![fm createDirectoryAtPath:destination attributes:nil]) {
			NSLog(@"Error creating app support folder");	
		}
	}
	NSArray *thePathComponents = [filePath pathComponents];
	int i = [thePathComponents count];
	i -= 2;
	NSString *theFolder = [thePathComponents objectAtIndex:i];
	NSString *filename = [thePathComponents lastObject];
	destination = [destination stringByAppendingPathComponent:theFolder];
  if(![fm fileExistsAtPath:destination]) {
		if(![fm createDirectoryAtPath:destination attributes:nil]) {
			NSLog(@"Error creating app support sub folder");	
		}
	}
	destination = [destination stringByAppendingPathComponent:filename];
	if(![fm fileExistsAtPath:destination]) {
		if(![fm createDirectoryAtPath:destination attributes:nil]) {
			NSLog(@"Error creating app support sub sub folder");	
		}
	}
  
	if([fm fileExistsAtPath:[destination stringByAppendingPathComponent:@"count"]])	{	
    // get current count add one
		NSMutableDictionary *numberInfo = [NSMutableDictionary dictionaryWithContentsOfFile:[destination stringByAppendingPathComponent:@"count"]];
		NSNumber * currentCount = [numberInfo objectForKey:@"theNumber"];
    [numberInfo setObject:[NSNumber numberWithInt: [currentCount intValue] + 1 ]  forKey:@"theNumber"];
    [numberInfo writeToFile:[destination stringByAppendingPathComponent:@"count"] atomically:NO];
    _count = [currentCount intValue];
    return _count;
	}
  
	else{
		NSLog(@"First time making count at %@", [destination stringByAppendingPathComponent:@"count"]);
		NSMutableDictionary *numberInfo = [NSMutableDictionary dictionary];
		[numberInfo setObject:[NSNumber numberWithInt:0] forKey:@"theNumber"];
		if(![fm fileExistsAtPath:destination]) {
			if(![fm createDirectoryAtPath:destination attributes:nil]) {
				NSLog(@"Error creating app-support sub sub... sub folder");	
			}
		}
    
 		bool worked = [numberInfo writeToFile:[destination stringByAppendingPathComponent:@"count"] atomically:NO];
		if(!worked){
			NSLog(@"couldn't create the count file at %@", destination);
		}    
    return 0;
	}
}

- (void) copyPathToAppSupportFolder {
  
  //e.g. ~/Library/Application Support/snapshots/Desktop/test.txt/1

  [self getCountAndUpdate];
  
  
  ASIWebThumbnailGenerator *generator = [[[ASIWebThumbnailGenerator alloc] init] autorelease];
  [generator setUrl: filePath];
//  [generator setPageSize:NSMakeSize(1000,0)];
  [generator setSourceSize:NSMakeSize(1024,768)];
  //[generator setDestinationSize:NSMakeSize(300,200)];
  [generator start];
  
  NSImage *img = [generator image];
  NSArray *representations;
  NSData *bitmapData;
  
  representations = [img representations];
  bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations 
                                                        usingType:NSPNGFileType properties:nil];
  [bitmapData writeToFile: [self mostRecentSnapshotPath] atomically:YES];
  [self calculateFolderSize];
  [self updateFileCount];

}

- (NSString *) currentSnapshotPath{
  NSArray  * paths =  NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
  NSString * basePath = ([paths count] > 0) ? [paths objectAtIndex: 0] : NSTemporaryDirectory();
  NSString * destination =  [basePath stringByAppendingPathComponent:@"snapshots"] ;
  NSArray * thePathComponents = [filePath pathComponents];
  int i = [thePathComponents count];
  i -= 2;
  NSString *theFolder = [thePathComponents objectAtIndex:i];
	NSString *filename = [thePathComponents lastObject];
  NSString * fullPath = [[destination stringByAppendingPathComponent: theFolder] stringByAppendingPathComponent: filename];
  return fullPath;
}

- (NSString * ) mostRecentSnapshotPath {
  return [[self currentSnapshotPath] stringByAppendingPathComponent:[ NSString stringWithFormat:@"%i.png", _count]];
}




- (void)calculateFolderSize { 
  NSString *path = [self currentSnapshotPath]; 
  NSDirectoryEnumerator *e = [[NSFileManager defaultManager] enumeratorAtPath: path];
  NSString *file;
  unsigned long long totalSize = 0;
  while ((file = [e nextObject])) {
    NSDictionary *attributes = [e fileAttributes];
    NSNumber *fileSize = [attributes objectForKey:NSFileSize];
    totalSize += [fileSize longLongValue];
  }
  if(totalSize < 10){
    self.currentSpaceUsed = [NSString stringWithFormat:@"Snapshot folder is empty"];
    return;
  }
  
  float floatSize = totalSize;
  if (totalSize < 1023){
		self.currentSpaceUsed = [NSString stringWithFormat:@"Snapshots come to  %lld bytes", totalSize];
    return;
  }
  
	floatSize = floatSize / 1024;
	if (floatSize<1023){
		self.currentSpaceUsed = [NSString stringWithFormat:@"Snapshots come to %1.1f KB", floatSize];
    return;
  }
  
	floatSize = floatSize / 1024;
  if (floatSize<1023){
		self.currentSpaceUsed = [NSString stringWithFormat:@"Snapshots come to %1.1f MB", floatSize];
    return;
  }
  
	floatSize = floatSize / 1024;
	self.currentSpaceUsed = [NSString stringWithFormat:@"Snapshots come to %1.1f GB", floatSize];
  
}

- (void)updateFileCount{
  if(0 == _count){
    self.fileCount = @"Taken first Snap";
    return;
  }
    self.fileCount = [NSString stringWithFormat:@"Holding %i Snaps", (_count + 1)];
}
- (int) snapshotCount{
  return _count;
}


@synthesize currentStatus;
@synthesize currentSpaceUsed;

@synthesize fileName;
@synthesize filePath;
@synthesize fileCount;

@synthesize myTriggerFilenames;
@synthesize shouldUseTrigger;

@end
