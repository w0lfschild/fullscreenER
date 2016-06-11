//
//  fullscreenER.h
//  fullscreenER
//
//  Created by Wolfgang Baird on 9/10/15.
//  Copyright © 2015 -2016 Wolfgang Baird. All rights reserved.
//

@import AppKit;
#import "ZKSwizzle.h"

@interface fullscreenER : NSObject

+ (void)load;

@end

@interface NSWindow (fullscreenER)

- (void)setFrame:(struct CGRect)arg1 display:(BOOL)arg2 animate:(BOOL)arg3;
- (struct CGRect)_tileFrameForFullScreen;
- (struct CGRect)_frameForFullScreenMode;
- (BOOL)_inFullScreen;
- (void)setShowsLockButton:(BOOL)arg1;
- (BOOL)showsLockButton;

@end

@interface fullscreenER_NSWindow : NSWindow

@end