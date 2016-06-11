//
//  fullscreenER.m
//  fullscreenER
//
//  Created by Wolfgang on 9/13/15.
//  Copyright (c) 2015 - 2016 Wolfgang. All rights reserved.
//

#import "fullscreenER.h"

BOOL _willMaximize = NO;
NSInteger osx_ver;
struct CGRect _currentFrame;
static void *cachedFrame = &cachedFrame;

@implementation fullscreenER

+ (void)load {
    osx_ver = [[NSProcessInfo processInfo] operatingSystemVersion].minorVersion;
    ZKSwizzle(fullscreenER_NSWindow, NSWindow);
    NSApplication *application = [NSApplication sharedApplication];
    if ([application windows])
    {
        for (NSWindow *win in [application windows])
        {
            win.styleMask = win.styleMask | NSResizableWindowMask;
            Boolean lockButton = [win showsLockButton];
            [win setShowsLockButton:!lockButton];
            [win setShowsLockButton:lockButton];
        }
    }
    NSLog(@"OS X 10.%ld, fullscreenER loaded...", (long)osx_ver);
}

@end

@implementation fullscreenER_NSWindow

- (BOOL)_allowsFullScreen {
    return YES;
}

- (BOOL)canEnterFullScreenMode {
    return YES;
}

- (BOOL)showsFullScreenButton {
    return YES;
}

- (BOOL)_canEnterFullScreenOrTileMode {
    return YES;
}

- (BOOL)_canEnterTileMode {
    return YES;
}

- (BOOL)_allowedInDashboardSpaceWithCollectionBehavior:(unsigned long long)arg1 {
    return YES;
}

- (BOOL)_allowedInOtherAppsFullScreenSpaceWithCollectionBehavior:(unsigned long long)arg1 {
    return YES;
}

// Full screen toggle
- (void)wb_fullScreen {
    [self toggleFullScreen:self];
}

// Fill screen toggle
- (void)wb_fillScreen {
    if ([self _inFullScreen]) {
        [self toggleFullScreen:self];
    } else {
        _currentFrame = self.frame;
        CGRect futureFrame = osx_ver < 11 ? [self _frameForFullScreenMode] : [self _tileFrameForFullScreen];
        CGRect screenFrame = self.screen.visibleFrame;
        Boolean isMaximized = CGRectEqualToRect(_currentFrame, screenFrame);
        if (!isMaximized) {
            NSValue *cachedFrameValue = [NSValue valueWithRect:(NSRect)NSRectFromCGRect(_currentFrame)];
            objc_setAssociatedObject(self, cachedFrame, cachedFrameValue, OBJC_ASSOCIATION_RETAIN);
            [self setFrame:futureFrame display:true animate:true];
        } else {
            NSValue *cachedValue = objc_getAssociatedObject(self, cachedFrame);
            CGRect cachedFrame = NSRectToCGRect(cachedValue.rectValue);
            [self setFrame:cachedFrame display:true animate:true];
        }
    }
}

- (BOOL)_zoomButtonIsFullScreenButton {
    if (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) == NSAlternateKeyMask) {
        [[self standardWindowButton:NSWindowZoomButton] setAction:@selector(wb_fullScreen)];
        [[self standardWindowButton:NSWindowZoomButton] setAlphaValue:.5 ];
    } else {
        [[self standardWindowButton:NSWindowZoomButton] setAction:@selector(wb_fillScreen)];
        [[self standardWindowButton:NSWindowZoomButton] setAlphaValue:1 ];
    }
    return ZKOrig(BOOL);
}

@end
