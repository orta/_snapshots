//
//  GrowlHandler.h
//  snapshots
//
//  Created by orta on 12/17/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Growl/GrowlApplicationBridge.h"

@interface GrowlHandler : NSObject <GrowlApplicationBridgeDelegate> {

}
- (void)growl:(NSString *)path;

@end
