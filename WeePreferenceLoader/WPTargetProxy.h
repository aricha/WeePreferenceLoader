//
//  WPTargetProxy.h
//  WeePreferenceLoader
//
//  Created by Andrew Richardson on 12-06-26.
//  Copyright (c) 2012. All rights reserved.
//

#import <UIKit/UIKit.h>

// WPTargetProxy acts is a proxy object for a PSSpecifier's target - it prioritizes
// the bundle controller as the main target (should one exist), but will forward messages
// to the view controller if the bundle controller does not implement a given method.
@interface WPTargetProxy : NSObject

// viewController should be the view controller actively displaying the target's specifier.
@property (nonatomic, assign) UIViewController *viewController;

// WPTargetProxy acts as the sole intermediary for the bundleController, and so must be its owner
@property (nonatomic, retain) NSObject *bundleController;

- (id) initWithViewController:(UIViewController *)viewController bundleController:(NSObject *)bundleController;

@end
