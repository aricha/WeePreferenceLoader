//
//  WeePreferenceLoaderModel.h
//  zHookTest
//
//  Created by Andrew Richardson on 12-03-11.
//  Copyright (c) 2012. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PSListController, BBSectionInfo;

@interface WeePreferenceLoaderModel : NSObject {
    NSMutableDictionary *bundleControllers;
    NSMutableDictionary *entries;
}

- (NSArray *) bundleControllersForSection:(BBSectionInfo *)section;

- (void) loadEntries;
- (NSDictionary *) loadWeeAppSpecifiersForSectionInfo:(BBSectionInfo *)info;
- (NSArray *) loadSpecifiersForListController:(PSListController *)controller sectionInfo:(BBSectionInfo *)info;

@end
