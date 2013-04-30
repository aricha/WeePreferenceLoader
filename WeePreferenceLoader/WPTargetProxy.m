//
//  WPTargetProxy.m
//  WeePreferenceLoader
//
//  Created by Andrew Richardson on 12-06-26.
//  Copyright (c) 2012. All rights reserved.
//

#import "WPTargetProxy.h"
#import <objc/runtime.h>

@implementation WPTargetProxy

- (void) dealloc {
    [_bundleController release];
    
    [super dealloc];
}

- (id) initWithViewController:(UIViewController *)viewController bundleController:(NSObject *)bundleController {
    if ((self = [super init])) {
        _viewController = viewController;
        _bundleController = [bundleController retain];
        
//        // pose as view controller
//        if (_viewController)
//            object_setClass(self, [_viewController class]);
    }
    return self;
}

- (BOOL) respondsToSelector:(SEL)aSelector {
    return [_viewController respondsToSelector:aSelector] || [_bundleController respondsToSelector:aSelector];
}

- (id) forwardingTargetForSelector:(SEL)aSelector {
    id forwardingTarget = nil;
    
    if ([_bundleController respondsToSelector:aSelector])
        forwardingTarget = _bundleController;
    else if ([_viewController respondsToSelector:aSelector])
        forwardingTarget = _viewController;
    
    DLog(@"forwarding selector %@ to target %@", NSStringFromSelector(aSelector), forwardingTarget);
    
    return forwardingTarget;
}

@end
