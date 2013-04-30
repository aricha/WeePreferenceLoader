//
//  WeePreferenceLoader.xm
//  WeePreferenceLoader
//
//  Created by Andrew Richardson on 12-03-11.
//  Copyright (c) 2012. All rights reserved.
//

// Using Logos by Dustin Howett
// See http://iphonedevwiki.net/index.php/Logos

#import <objc/runtime.h>
#import <CaptainHook.h>

#import "WeePreferenceLoaderModel.h"

static WeePreferenceLoaderModel *WPLoaderModel() {
    static WeePreferenceLoaderModel *loader = nil;
    
    if (!loader)
        loader = [[WeePreferenceLoaderModel alloc] init];
    
    return loader;
}

%hook BulletinBoardController

- (id) init {
    [WPLoaderModel() loadEntries];
    return %orig;
}

%end

%hook BulletinBoardAppDetailController

static char kWPSpecifiersLoaded;

static BBSectionInfo* sectionInfoForBBAppDetailController (id controller) {
    return [[(PSListController *)controller specifier] propertyForKey:@"BBSECTION_INFO_KEY"];
}

- (id)specifiers {
    id specifiersToReturn = %orig;
    
    NSMutableArray **specifiersRef = CHIvarRef(self, _specifiers, id);
	NSMutableArray *specifiers = specifiersRef ? *specifiersRef : nil;
    
    // use an assoc. object to check if we've added our specifiers to the list yet
    NSNumber *specsLoaded = objc_getAssociatedObject(specifiers, &kWPSpecifiersLoaded);
    
    if (!specsLoaded || ![specsLoaded boolValue]) {
        DLog(@"adding specifiers!");
        
        // just in case Apple makes them immutable
        if (!specifiers || ![specifiers isKindOfClass:[NSMutableArray class]]) {
            specifiers = [[(specifiers ?: @[]) mutableCopy] autorelease];
        }
        
        NSArray *specifiersToAdd = [WPLoaderModel() loadSpecifiersForListController:(PSListController *)self 
                                                                        sectionInfo:sectionInfoForBBAppDetailController(self)];
        
        if (specifiersToAdd) {
            [specifiers addObjectsFromArray:specifiersToAdd];
        }
        
        if (specifiersToReturn != specifiers) {
            // orig. implementation wants a unique array to be returned, so make it unique ourselves
            DLog(@"orig. %@ uses unique array %@, ivar is %@", NSStringFromSelector(_cmd), specifiersToReturn, specifiers);
            specifiersToReturn = [NSMutableArray arrayWithArray:specifiers];
        }
        
#ifdef DEBUG
        for (PSSpecifier *spec in specifiers) {
            DLog(@"Specifier name: %@, target: %@, titleDictionary: %@, properties: %@", [spec name], [spec target], [spec titleDictionary], [spec properties]);
        }
#endif
        
        objc_setAssociatedObject(@(YES), &kWPSpecifiersLoaded, specifiers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return specifiersToReturn;
}

%end
