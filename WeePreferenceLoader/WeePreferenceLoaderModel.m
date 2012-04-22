//
//  WeePreferenceLoaderModel.m
//  zHookTest
//
//  Created by Andrew Richardson on 12-03-11.
//  Copyright (c) 2012. All rights reserved.
//

#import "WeePreferenceLoaderModel.h"

#import <objc/runtime.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <BulletinBoard/BBSectionInfo.h>

// Different from <iOS5
extern NSArray* SpecifiersFromPlist(NSDictionary* plist,
                                    PSSpecifier *specifier,
                                    id target,
                                    NSString *plistName,
                                    NSBundle *curBundle,
                                    NSString** pSpecifierID,
                                    NSMutableArray** pBundleControllers);

#define footerTextKey @"footerText"

#define ROOT_DIR @"/Library/WeePreferenceLoader/Preferences"

@implementation WeePreferenceLoaderModel

- (id) init {
    self = [super init];
    if (self) {
        entries = [NSMutableDictionary dictionary];
        bundleControllers = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void) dealloc {
    [entries release];
    [bundleControllers release];
    
    [super dealloc];
}

- (NSArray *) bundleControllersForSection:(BBSectionInfo *)section {
    return [bundleControllers objectForKey:section.sectionID];
}

- (void) loadEntries {
    [entries removeAllObjects];
    
    NSError *error = nil;
    NSArray *paths = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:ROOT_DIR error:&error];
    if (error) {
        NSLog(@"Loading WeePreferenceLoader entries failed. Error: %@", [error description]);
        return;
    }
    
    for (NSString *path in paths) {
        if (![[path pathExtension] isEqualToString:@"plist"])
            continue;
        
        NSString *fullPath = [ROOT_DIR stringByAppendingPathComponent:path];
        NSMutableDictionary *plist = [NSMutableDictionary dictionaryWithContentsOfFile:fullPath];
        
        NSString *plistName = [[path lastPathComponent] stringByDeletingPathExtension];
        
        NSArray *sectionIDs = [plist objectForKey:@"sectionIDs"];
        if (!sectionIDs) {
            // use single section ID key as backup
            NSString *sectionID = [plist objectForKey:@"sectionID"];
            if (!sectionID) {
                DLog(@"Error: No sectionID specified for WeePreferenceLoader plist %@", plistName);
                continue;
            }
            else
                sectionIDs = [NSArray arrayWithObject:sectionID];
        }
        
        [plist setObject:plistName forKey:@"plistName"];
        
        NSString *bundleName = [plist objectForKey:@"bundle"];
        if (bundleName) {
            NSString *bundlePath = [plist objectForKey:@"bundlePath"];
            if (!bundlePath) {
                // search for bundle
                NSString *fullBundleName = [bundleName stringByAppendingPathExtension:@"bundle"];
                bundlePath = [[fullPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:fullBundleName];
                BOOL found = [[NSFileManager defaultManager] fileExistsAtPath:bundlePath];
                
                if (!found && ![ROOT_DIR isEqualToString:[fullPath stringByDeletingLastPathComponent]]) {
                    bundlePath = [ROOT_DIR stringByAppendingPathComponent:fullBundleName];
                    found = [[NSFileManager defaultManager] fileExistsAtPath:bundlePath];
                }
                
                if (found && bundlePath) {
                    [plist setObject:bundlePath forKey:@"bundlePath"];
                }
                else {
                    // No bundle found, discard plist
                    NSLog(@"Error: WeePreferenceLoader found no bundle found for specified bundle %@", bundleName);
                    continue;
                }
            }
        }
        else {
            [plist setObject:[fullPath stringByDeletingLastPathComponent] forKey:@"plistPath"];
        }
        
        for (NSString *sectionID in sectionIDs) {
            NSMutableArray *weeAppEntries = [entries objectForKey:sectionID];
            if (!weeAppEntries) {
                weeAppEntries = [NSMutableArray arrayWithObject:plist];
                [entries setObject:weeAppEntries forKey:sectionID];
            }
            else
                [weeAppEntries addObject:plist];
        }
    }
}

- (NSDictionary *) loadWeeAppSpecifiersForSectionInfo:(BBSectionInfo *)info {
    NSString *weeBundlePath = info.pathToWeeAppPluginBundle;
    
    NSBundle *weeAppBundle = [NSBundle bundleWithPath:weeBundlePath];
    NSString *weeAppID = info.sectionID;
    
    NSString *path = [[weeAppBundle bundlePath] stringByAppendingPathComponent:@"Preferences.plist"];
    NSMutableDictionary *plist = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    
    if (!plist) {
        // Second try - use bundle name
        path = [[weeAppBundle bundlePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", [[[weeAppBundle bundlePath] lastPathComponent] stringByDeletingPathExtension]]];
        plist = [NSDictionary dictionaryWithContentsOfFile:path];
        
        if (!plist) {
            // Last try - use app ID
            path = [[weeAppBundle bundlePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", weeAppID]];
            plist = [NSDictionary dictionaryWithContentsOfFile:path];
        }
    }
    
    if (!plist) {
        DLog(@"No weeAppBundle plist found for BB section %@", weeAppID);
        return plist;
    }
    
    NSString *plistName = [[path lastPathComponent] stringByDeletingPathExtension];
    
    [plist setObject:plistName forKey:@"plistName"];
    
    // used as a fallback if no bundle is specified
    [plist setObject:[NSNumber numberWithBool:YES] forKey:@"useWeeAppBundle"];
    
    return plist;
}

- (NSArray *) loadSpecifiersForListController:(PSListController *)controller sectionInfo:(BBSectionInfo *)info {    
    NSString *weeBundlePath = info.pathToWeeAppPluginBundle;
    NSBundle *weeAppBundle = [NSBundle bundleWithPath:weeBundlePath];
    NSString *sectionID = info.sectionID;
    
    NSMutableArray *sectionEntries = [NSMutableArray arrayWithArray:[entries objectForKey:sectionID]];
    
    if (weeBundlePath) {
        NSDictionary *bundlePlist = [self loadWeeAppSpecifiersForSectionInfo:info];
        if (bundlePlist)
            [sectionEntries insertObject:bundlePlist atIndex:0];
    }
    
    NSMutableArray *specifiers = [NSMutableArray array];
    
    for (NSDictionary *plist in sectionEntries) {
        NSString *bundleName = [plist objectForKey:@"bundle"];
        NSBundle *bundle = nil;
        
        DLog(@"Loading plist %@", [plist objectForKey:@"plistName"]);
        
        if (bundleName) {
            DLog(@"BB section %@ has a bundle, it is: %@", sectionID, bundleName);
            
            NSString *bundlePath = [plist objectForKey:@"bundlePath"];
            if (bundlePath) {
                bundle = [NSBundle bundleWithPath:bundlePath];
                if (!bundle) {
                    DLog(@"No bundle found for bundlePath %@, will disregard", bundlePath);
                    continue;
                }
            }
            else if (weeBundlePath) {
                // bundlePath should be specified if loaded from WeePreferenceLoader folder, so only applicable
                // for entries loaded from weeAppBundle
                
                bundle = [NSBundle bundleWithPath:[weeBundlePath stringByAppendingFormat:@"/%@.bundle", bundleName]];
                if (!bundle) {
                    bundle = [NSBundle bundleWithPath:[NSString stringWithFormat:@"/Library/WeePreferenceLoader/Preferences/%@.bundle", bundleName]];
                    
//#warning test code
//                    if (!bundle) {
//                        bundle = [NSBundle bundleWithPath:[NSString stringWithFormat:@"/Library/PreferenceBundles/%@.bundle", bundleName]];
//                    }
                }
            }
            
            if (!bundle) {
                DLog(@"Bundle %@ not found for BB section %@, will disregard", bundleName, sectionID);
                continue;
            }
            
            DLog(@"Bundle found for BB section %@! It is: %@", sectionID, bundle);
            Class BundleClass = [bundle principalClass];
            if (BundleClass) {                
                NSMutableArray *sectionControllers = [bundleControllers objectForKey:sectionID];
                if (sectionControllers) {
                    BOOL exists = NO;
                    for (id controller in sectionControllers) {
                        if ([controller isKindOfClass:BundleClass]) {
                            exists = YES;
                            break;
                        }
                    }
                    
                    if (!exists)
                        [sectionControllers addObject:[[BundleClass alloc] init]];
                }
                else {
                    id controller = [[BundleClass alloc] init];
                    sectionControllers = [NSMutableArray arrayWithObject:controller];
                    [bundleControllers setObject:sectionControllers forKey:sectionID];
                }
            }
        }
        else {
            if (weeAppBundle && [(NSNumber *)[plist objectForKey:@"useWeeAppBundle"] boolValue])
                bundle = weeAppBundle;
            else {
                NSString *plistPath = [plist objectForKey:@"plistPath"];
                if (!plistPath)
                    plistPath = ROOT_DIR;
                bundle = [NSBundle bundleWithPath:plistPath];
            }
            
            DLog(@"plist %@ for BB section %@ does NOT have a bundle, we'll use %@ instead", [plist objectForKey:@"plistName"], sectionID, bundle);
        }
        
        NSString *plistName = [plist objectForKey:@"plistName"];
        
        NSArray *bundleSpecifiers = SpecifiersFromPlist(plist,
                                                        [controller specifier],
                                                        controller,
                                                        plistName,
                                                        bundle,
                                                        NULL,
                                                        NULL);
        
        if (bundle && ![[bundle bundlePath] isEqualToString:ROOT_DIR]) {
            for (PSSpecifier *spec in bundleSpecifiers) {
                if ([spec name])
                    [spec setName:NSLocalizedStringWithDefaultValue([spec name], nil, bundle, [spec name], nil)];
                
                NSDictionary *titleDict = [spec titleDictionary];
                if (titleDict) {
                    NSMutableDictionary *localizedTitles = [NSMutableDictionary dictionary];
                    for (id key in [titleDict allKeys]) {
                        NSString *title = [titleDict objectForKey:key];
                        [localizedTitles setObject:NSLocalizedStringWithDefaultValue(title, nil, bundle, title, nil) forKey:key];
                    }
                    [spec setTitleDictionary:localizedTitles];
                }
                
                NSString *footer = [spec propertyForKey:footerTextKey];
                if (footer)
                    [spec setProperty:NSLocalizedStringWithDefaultValue(footer, nil, bundle, footer, nil) forKey:footerTextKey];
            }
        }
        
        if (bundleSpecifiers) {
            if ([(PSSpecifier *)[bundleSpecifiers objectAtIndex:0] cellType] != PSGroupCell) {
                NSString *title = [plist objectForKey:@"title"]; // title can be nil
                [specifiers addObject:[PSSpecifier groupSpecifierWithName:title]];
            }
            [specifiers addObjectsFromArray:bundleSpecifiers];
        }
    }
    
    return specifiers;
}

@end
