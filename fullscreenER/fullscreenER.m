//
//  fullscreenER.m
//  fullscreenER
//
//  Created by Wolfgang on 9/13/15.
//  Copyright (c) 2015 - 2016 Wolfgang. All rights reserved.
//

#import "fullscreenER.h"

#define APP_BLACKLIST @[@"com.apple.notificationcenterui"]
#define CLS_BLACKLIST @[@"NSStatusBarWindow"]

fullscreenER *plugin;
BOOL _willMaximize = NO;
NSInteger osx_ver;
NSWindow *mykeyWindow;
struct CGRect _currentFrame;
static void *cachedFrame = &cachedFrame;

@implementation fullscreenER

+ (fullscreenER*) sharedInstance {
    static fullscreenER* plugin = nil;
    if (plugin == nil)
        plugin = [[fullscreenER alloc] init];
    return plugin;
}

+ (void)load {
    plugin = [fullscreenER sharedInstance];
    osx_ver = [[NSProcessInfo processInfo] operatingSystemVersion].minorVersion;
    
    if (osx_ver >= 9) {
        if (![APP_BLACKLIST containsObject:[[NSBundle mainBundle] bundleIdentifier]]) {
            ZKSwizzle(fullscreenER_NSWindow, NSWindow);
            
            for (NSWindow *win in [NSApp windows])
                [plugin FSER_initialize:win];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                NSMenu *subMenu = [NSApp windowsMenu];
                if (subMenu == nil)
                    subMenu = [[[NSApp mainMenu] itemAtIndex:0] submenu];
                [[subMenu addItemWithTitle:@"Toggle Fullscreen" action:@selector(FSER_toggleFS:) keyEquivalent:@""] setTarget:plugin];
            });
            
            mykeyWindow = [NSApp mainWindow];
            
            NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
            [center addObserver:self selector:@selector(FSER_gainFocus:) name:NSWindowDidBecomeMainNotification object:nil];
            [center addObserver:self selector:@selector(FSER_gainFocus:) name:NSWindowDidBecomeKeyNotification object:nil];
            
            NSLog(@"%@ loaded into %@ on macOS 10.%ld", [self class], [[NSBundle mainBundle] bundleIdentifier], (long)osx_ver);
        } else {
            NSLog(@"fullscreenER is blocked in this application because of issues");
        }
    } else {
        NSLog(@"fullscreenER is blocked in this application because of your version of macOS is too old");
    }
}

- (void)FSER_initialize:(NSWindow*)win
{
    if (![CLS_BLACKLIST containsObject:[win className]])
    {
        Boolean editMask = ![[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/QtCore.framework/Versions/4/QtCore", [[NSBundle mainBundle] privateFrameworksPath]]];
        if (editMask)
            win.styleMask = win.styleMask | NSResizableWindowMask;
        Boolean lockButton = [win showsLockButton];
        [win setShowsLockButton:!lockButton];
        [win setShowsLockButton:lockButton];
    }
}

+ (void)FSER_gainFocus:(NSNotification *)note {
    mykeyWindow = [note object];
}

- (void)FSER_toggleFS:(id)sender {
    if ([mykeyWindow isVisible])
        [mykeyWindow toggleFullScreen:mykeyWindow];
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
    return NO;
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
            [self setFrame:futureFrame display:true animate:false];
        } else {
            NSValue *cachedValue = objc_getAssociatedObject(self, cachedFrame);
            CGRect cachedFrame = NSRectToCGRect(cachedValue.rectValue);
            [self setFrame:cachedFrame display:true animate:false];
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
    return NO;
}

@end
