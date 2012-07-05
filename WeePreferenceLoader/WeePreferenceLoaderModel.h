//
//  WeePreferenceLoaderModel.h
//  WeePreferenceLoader
//
//  Created by Andrew Richardson on 12-03-11.
//  Copyright (c) 2012. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const WeePreferenceLoaderBundleControllerKey;

@class UIViewController, PSListController, BBSectionInfo, WPEntry;

@interface WeePreferenceLoaderModel : NSObject {
    NSMutableArray *entries;
}

- (void) loadEntries;
- (NSMutableArray *) entriesForSectionInfo:(BBSectionInfo *)sectionInfo;
- (WPEntry *) weeAppEntryForSectionInfo:(BBSectionInfo *)info;
- (NSArray *) loadSpecifiersForListController:(PSListController *)controller sectionInfo:(BBSectionInfo *)info;

// in order to maintain compatibility with Preferences methods like lazyLoadBundle:,
// must use a proxy target to allow both the view controller (ie. PSListController)
// and the dynamically loaded bundle controller to handle their respective methods
- (void) addProxyTargetsForSpecifiers:(NSArray *)specifiers
                   withViewController:(UIViewController *)controller
                     bundleController:(NSObject *)bundleController;

@end
