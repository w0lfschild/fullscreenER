//
//  Load.m
//  _fulllscreenER
//
//  Created by Wolfgang on 9/13/15.
//  Copyright (c) 2015 Wolfgang. All rights reserved.
//

#import "ZKSwizzle.h"
@import AppKit;

BOOL _isMaximized = NO;
BOOL _willMaximize = NO;

BOOL _makecopy = YES;

NSInteger osx_ver;
struct CGRect _cachedFrame;

@interface Load : NSObject
@end

//@implementation NSView (ViewHierarchyLogging)
//- (void)logViewHierarchy
//{
//    NSLog(@"View: %@", self);
//    for (NSView *subview in self.subviews)
//    {
//        [subview logViewHierarchy];
//    }
//}
//@end

@implementation Load

+ (void)load {
    osx_ver = [[NSProcessInfo processInfo] operatingSystemVersion].minorVersion;
    NSLog(@"OS X 10.%ld, _fullscreenER loaded...", (long)osx_ver);
    
    NSApplication *application = [NSApplication sharedApplication];
    if (application.windows)
    {
        for (NSWindow *win in application.windows)
        {
            win.styleMask = win.styleMask | NSResizableWindowMask;
            /*
             NSClosableWindowMask |
             NSTitledWindowMask |
             NSMiniaturizableWindowMask |
             NSTexturedBackgroundWindowMask |
             NSResizableWindowMask |
             NSFullSizeContentViewWindowMask;
             */
            
            NSButton *FS = [[NSButton alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
            [win.contentView.superview addSubview:FS];
        }
    }

//    for (NSWindow *window in application.windows)
//    {
//        [window.contentView logViewHierarchy];
//    }
}

@end

//ZKSwizzleInterface(_addInject, NSApplication, NSObject);
//@implementation _addInject
//- (void)DumpObjcMethods:(Class)clz {
//    
//    unsigned int methodCount = 0;
//    Method *methods = class_copyMethodList(clz, &methodCount);
//    
//    NSLog(@"Found %d methods on '%s'\n", methodCount, class_getName(clz));
//    
//    for (unsigned int i = 0; i < methodCount; i++) {
//        Method method = methods[i];
//        
//        NSLog(@"\t'%s' has method named '%s' of encoding '%s'\n",
//               class_getName(clz),
//               sel_getName(method_getName(method)),
//               method_getTypeEncoding(method));
//        
//        /**
//         *  Or do whatever you need here...
//         */
//    }
//}
//@end


@interface NSWindow (Maximizer)
- (void)setFrame:(struct CGRect)arg1 display:(BOOL)arg2 animate:(BOOL)arg3;
- (struct CGRect)_tileFrameForFullScreen;
- (struct CGRect)_frameForFullScreenMode;
- (BOOL)_inFullScreen;
@end

ZKSwizzleInterface(_Maximize_NSWindow, NSWindow, NSResponder);
@implementation _Maximize_NSWindow

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

- (BOOL)_allowedInOtherAppsFullScreenSpaceWithCollectionBehavior:(unsigned long long)arg1 {
    return YES;
}

- (BOOL)_hasActiveAppearanceForStandardWindowButton:(unsigned long long)arg1 {
    return YES;
}

// Full screen toggle
- (void)_W0fullScreen {
    NSWindow *this = (NSWindow*)self;
    [this toggleFullScreen:this];
}

// Fill screen toggle (will also exit fullscreen if currently fullscreen)
- (void)_W0fillScreen {
    NSWindow *this = (NSWindow*)self;
    
    if ([this _inFullScreen]) {
        [this toggleFullScreen:this];
    } else {
        CGRect maxFrame;
        if (osx_ver < 11) {
            maxFrame = [this _frameForFullScreenMode];
        } else {
            maxFrame = [this _tileFrameForFullScreen];
        }
        if (!_isMaximized) {
            _cachedFrame = this.frame;
            _isMaximized = YES;
            [this setFrame:maxFrame display:true animate:true];
        } else {
            _isMaximized = NO;
            [this setFrame:_cachedFrame display:true animate:true];
        }
    }
}

- (BOOL)_zoomButtonIsFullScreenButton {
    NSButton *zoom = [(NSWindow*)self standardWindowButton:NSWindowZoomButton];
    if (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) == NSAlternateKeyMask) {
        [zoom setAction:@selector(_W0fullScreen)];
        [zoom setAlphaValue:.5 ];
        //        NSLog(@"Fullscreen");
    } else {
        [zoom setAction:@selector(_W0fillScreen)];
        [zoom setAlphaValue:1 ];
        //        NSLog(@"Plus");
    }
    
    return NO;
}
@end
