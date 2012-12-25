//
//  WeePreferenceLoaderModel.m
//  WeePreferenceLoader
//
//  Created by Andrew Richardson on 12-03-11.
//  Copyright (c) 2012. All rights reserved.
//

#import "WeePreferenceLoaderModel.h"

#import <objc/runtime.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <BulletinBoard/BBSectionInfo.h>
#import <Preferences/PSTableCell.h>
#import "WPTargetProxy.h"

// Different from <iOS5
extern NSMutableArray* SpecifiersFromPlist(NSDictionary* plist,
                                    PSSpecifier *specifier,
                                    id target,
                                    NSString *plistName,
                                    NSBundle *curBundle,
                                    NSString** pSpecifierID,
                                    NSMutableArray** pBundleControllers);

extern NSString *const PSFooterTextGroupKey;

#define ROOT_DIR @"/Library/WeePreferenceLoader/Preferences"

// used internally
NSString *const WeePreferenceLoaderTargetProxyKey = @"targetProxy";

// used by the WeeApp bundle's Info.plist
NSString *const WeeAppPreferencePlistNameKey = @"PreferencesPlistName";

// used by the preference plist
NSString *const WeePreferenceLoaderBundleKey = @"bundle";
NSString *const WeePreferenceLoaderBundlePathKey = @"bundlePath";
NSString *const WeePreferenceLoaderSectionsKey = @"sections";
NSString *const WeePreferenceLoaderTitleKey = @"title";

@interface NSObject (WeePreferenceLoaderBundle)

- (id)initWithListController:(PSListController *)controller;
- (void)configureSpecifiers:(NSMutableArray *)specifiers;

@end

@interface WPEntry : NSObject

@property (nonatomic, retain) NSDictionary *plist;
@property (nonatomic, copy) NSString *plistName;
@property (nonatomic, copy) NSString *plistPath;
@property (nonatomic, retain) NSArray *sections;
@property (nonatomic) BOOL fromWeeAppBundle;

@end

@implementation WPEntry

@synthesize plist, plistName, plistPath, sections;

- (void) dealloc {
    [plist release];
    [plistName release];
    [plistPath release];
    [sections release];
    
    [super dealloc];
}

- (id) initWithPlist:(NSDictionary *)aPlist {
    if ((self = [super init])) {
        plist = [aPlist retain];
    }
    return self;
}

@end

@implementation WeePreferenceLoaderModel

- (id) init {
    self = [super init];
    if (self) {
        entries = [NSMutableArray new];
    }
    
    return self;
}

- (void) dealloc {
    [entries release];
    
    [super dealloc];
}

- (NSMutableArray *) entriesForSectionInfo:(BBSectionInfo *)sectionInfo {
    NSMutableArray *matchedEntries = [NSMutableArray arrayWithCapacity:entries.count];
    for (WPEntry *entry in entries) {
        // entries with no specified sections are currently added to all sections
        if (!entry.sections || entry.sections.count == 0 || [entry.sections containsObject:sectionInfo.sectionID])
            [matchedEntries addObject:entry];
    }
    
    WPEntry *weeAppEntry = [self weeAppEntryForSectionInfo:sectionInfo];
    if (weeAppEntry)
        [matchedEntries insertObject:weeAppEntry atIndex:0];
    
    return matchedEntries;
}

- (void) loadEntries {
    [entries removeAllObjects];
    
	if (![[NSFileManager defaultManager] fileExistsAtPath:ROOT_DIR])
		return; // no WeePreferenceLoader bundles exist, no need to load entries
	
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
        WPEntry *entry = [[[WPEntry alloc] initWithPlist:plist] autorelease];
        
        entry.plistName = [[path lastPathComponent] stringByDeletingPathExtension];
        entry.plistPath = [fullPath stringByDeletingLastPathComponent];
        entry.sections = [plist objectForKey:WeePreferenceLoaderSectionsKey];
        
        NSString *bundleName = [plist objectForKey:WeePreferenceLoaderBundleKey];
        if (bundleName) {
            NSString *bundlePath = [plist objectForKey:WeePreferenceLoaderBundlePathKey];
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
                    [plist setObject:bundlePath forKey:WeePreferenceLoaderBundlePathKey];
                }
                else {
                    // No bundle found, discard plist
                    NSLog(@"Error: WeePreferenceLoader could not find specified bundle %@ for plist %@", bundleName, entry.plistName);
                    continue;
                }
            }
        }
        
        [entries addObject:entry];
    }
}

- (WPEntry *) weeAppEntryForSectionInfo:(BBSectionInfo *)info {
    if (!info) {
        return nil;
    }
    
    NSString *weeBundlePath = info.pathToWeeAppPluginBundle;
    NSBundle *weeAppBundle = [NSBundle bundleWithPath:weeBundlePath];
    NSString *weeAppID = info.sectionID;
    
    // if the weeAppBundle has a preference plist within it, it should use the specified key in its info.plist
    // to indicate its name, in which case we retrieve it and use it as a regular bundle
    NSString *plistName = [[weeAppBundle infoDictionary] objectForKey:WeeAppPreferencePlistNameKey];
    
    NSString *path = [[weeBundlePath stringByAppendingPathComponent:plistName] stringByAppendingPathExtension:@"plist"];
    NSMutableDictionary *plist = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    
    if (!plist) {
        // No name specified - try Preferences.plist
        path = [weeBundlePath stringByAppendingPathComponent:@"Preferences.plist"];
        plist = [NSDictionary dictionaryWithContentsOfFile:path];
        
        if (!plist) {
            // Last try - <appID>.plist
            path = [[weeBundlePath stringByAppendingPathComponent:weeAppID] stringByAppendingPathExtension:@"plist"];
            plist = [NSDictionary dictionaryWithContentsOfFile:path];
        }
    }
    
    if (!plist) {
        DLog(@"No weeAppBundle plist found for BB section %@", weeAppID);
        return nil;
    }
    
    WPEntry *entry = [[[WPEntry alloc] initWithPlist:plist] autorelease];
    entry.fromWeeAppBundle = YES;
    
    if (!plistName)
        plistName = [[path lastPathComponent] stringByDeletingPathExtension];
    
    entry.plistName = plistName;
    
    // used as a fallback if no bundle path is specified (bundle path is retrieved later) - this is done
    // so that localized strings and other resources can still be used if a dedicated preferences bundle
    // is not provided
    entry.plistPath = weeBundlePath;
    
    return entry;
}

- (NSArray *) loadSpecifiersForListController:(PSListController *)listController sectionInfo:(BBSectionInfo *)info {
    if (!info) {
        NSLog(@"Error: no BB section info given for controller %@", listController);
        return nil;
    }
    
    NSString *weeBundlePath = info.pathToWeeAppPluginBundle;
    NSString *sectionID = info.sectionID;
    
    NSMutableArray *sectionEntries = [self entriesForSectionInfo:info];
    
    NSMutableArray *specifiers = [NSMutableArray array];
    
    for (WPEntry *entry in sectionEntries) {
        NSString *bundleName = [entry.plist objectForKey:WeePreferenceLoaderBundleKey];
        NSBundle *bundle = nil;
        id bundleController = nil;
        
        DLog(@"Loading plist %@", entry.plistName);//[plist objectForKey:WeePreferenceLoaderPlistNameKey]);
        
        if (bundleName) {
            DLog(@"BB section %@ has a bundle, it is: %@", sectionID, bundleName);
            
            NSString *bundlePath = [entry.plist objectForKey:WeePreferenceLoaderBundlePathKey];
            if (bundlePath) {
                bundle = [NSBundle bundleWithPath:bundlePath];
                if (!bundle) {
                    NSLog(@"Error: WeePreferenceLoader found no bundle for plist %@ with specified bundlePath %@", entry.plistName, bundlePath);
                    continue;
                }
            }
            else if (weeBundlePath) {
                // bundlePath should be specified if loaded from WeePreferenceLoader folder (either by the plist itself, or
                // by WeePreferenceLoader at runtime), so should only be applicable to entries loaded from weeAppBundle
                bundle = [NSBundle bundleWithPath:[weeBundlePath stringByAppendingFormat:@"/%@.bundle", bundleName]];
                if (!bundle) {
                    bundle = [NSBundle bundleWithPath:[NSString stringWithFormat:@"/Library/WeePreferenceLoader/Preferences/%@.bundle", bundleName]];
                }
            }
            
            if (!bundle) {
                NSLog(@"WeePreferenceLoader found no bundle %@ for sectionID %@, will disregard", bundleName, sectionID);
                continue;
            }
            
            DLog(@"Bundle found for BB section %@! It is: %@", sectionID, bundle);
            
            // implicitly loads the entire bundle, making all classes contained in the bundle available for use
            Class BundleClass = [bundle principalClass];
            
            if (BundleClass) {
                // provide list controller if bundle controller will accept it (optional)
                if ([BundleClass instancesRespondToSelector:@selector(initWithListController:)])
                    bundleController = [[[BundleClass alloc] initWithListController:listController] autorelease];
                else
                    bundleController = [[BundleClass new] autorelease];
            }
            
            DLog(@"Bundle class: %@, controller instance: %@", BundleClass, bundleController);
        }
        else {
            NSString *plistPath = entry.plistPath;
            if (!plistPath)
                plistPath = ROOT_DIR;
            bundle = [NSBundle bundleWithPath:plistPath];
            
            DLog(@"plist %@ for BB section %@ does NOT have a bundle, we'll use %@ instead", entry.plistName, sectionID, bundle);
        }
        
        NSMutableArray *bundleSpecifiers = SpecifiersFromPlist(entry.plist,
                                                               [listController specifier],
                                                               listController,
                                                               entry.plistName,
                                                               bundle,
                                                               NULL,
                                                               NULL);
        
        // just in case Apple decides to make them immutable
        if (![bundleSpecifiers isKindOfClass:[NSMutableArray class]])
            bundleSpecifiers = [NSMutableArray arrayWithArray:bundleSpecifiers];
        
        // localize strings
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
                
                NSString *footer = [spec propertyForKey:PSFooterTextGroupKey];
                if (footer)
                    [spec setProperty:NSLocalizedStringWithDefaultValue(footer, nil, bundle, footer, nil) forKey:PSFooterTextGroupKey];
            }
        }
        
        if (bundleSpecifiers) {
            if (bundleController) {
                // give bundle controller a chance to modify the specifiers at runtime
                if ([bundleController respondsToSelector:@selector(configureSpecifiers:)])
                    [bundleController configureSpecifiers:bundleSpecifiers];
                
                // only necessary if a bundle controller actually exists
                [self addProxyTargetsForSpecifiers:bundleSpecifiers
                                withViewController:listController
                                  bundleController:bundleController];
            }
            
            if ([(PSSpecifier *)[bundleSpecifiers objectAtIndex:0] cellType] != [PSTableCell cellTypeFromString:@"PSGroupCell"]) {
                NSString *title = [entry.plist objectForKey:WeePreferenceLoaderTitleKey]; // title can be nil
                [specifiers addObject:[PSSpecifier groupSpecifierWithName:title]];
            }
            
            [specifiers addObjectsFromArray:bundleSpecifiers];
        }
    }
    
    return specifiers;
}

- (void) addProxyTargetsForSpecifiers:(NSArray *)specifiers
                   withViewController:(UIViewController *)controller
                     bundleController:(NSObject *)bundleController
{
    for (PSSpecifier *spec in specifiers) {
        WPTargetProxy *targetProxy = [[[WPTargetProxy alloc] initWithViewController:controller
                                                                   bundleController:bundleController] autorelease];
        [spec setTarget:targetProxy];
        // use an associated object to ensure proxy is released at the correct time
        objc_setAssociatedObject(spec, WeePreferenceLoaderTargetProxyKey, targetProxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

@end
