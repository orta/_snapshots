//
//  GrowlHandler.m
//  snapshots
//
//  Created by orta on 12/17/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.

#import "Growl/GrowlApplicationBridge.h"
#import "GrowlHandler.h"


@implementation GrowlHandler

- (void) initializeGrowl
{	
	// Tells the Growl framework that this class will receive callbacks
	[GrowlApplicationBridge setGrowlDelegate:self];
}

- (NSDictionary*) registrationDictionaryForGrowl {
	// For this application, only one notification is registered
	NSArray* defaultNotifications = [NSArray arrayWithObjects:@"Snap Taken", nil];
	NSArray* allNotifications = [NSArray arrayWithObjects:@"Snap Taken", nil];
	
	NSDictionary* growlRegistration = [NSDictionary dictionaryWithObjectsAndKeys: 
                                     defaultNotifications, GROWL_NOTIFICATIONS_DEFAULT,
                                     allNotifications, GROWL_NOTIFICATIONS_ALL, nil];
	
	return growlRegistration;
}

- (void) growlIsReady {
	// Only get called when Growl is starting. Not called when Growl is already running so we leave growlReady to YES by default...
  //	growlReady = YES;
}


- (NSString *) applicationNameForGrowl {
	return @"snapshots"; // Application name defined in GrowlTestConstants
}

- (void) growlNotificationWasClicked:(id)clickContext {
  
	// clickContext is the date/time when the notification occured
	// interval is the number of the seconds between the notification event and the user click event
//  NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:clickContext];
//  NSString* message = [NSString stringWithFormat:userClickedMessage, (int)interval];
//  
//  [alertClicked setMessageText:message];
//  [alertClicked beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
}

- (void) growlNotificationTimedOut:(id)clickContext {
}
#pragma mark Cocoa Delegates Code
- (void) growl:(NSString *) path
{		
  
	// This is the main method to send Growl notifications
	// If the clickContext check box is checked in the UI, the current date/time NSDate will be passed...
	[GrowlApplicationBridge notifyWithTitle:@"Snapped!"
                              description:path
                         notificationName:@"Snap Taken"
                                 iconData:nil
                                 priority:0
                                 isSticky: NO 
                             clickContext: @"updatedfile"];
  
}


@end
