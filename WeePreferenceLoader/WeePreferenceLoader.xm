
// Using Logos by Dustin Howett
// See http://iphonedevwiki.net/index.php/Logos

#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <BulletinBoard/BBSectionInfo.h>

#import "WeePreferenceLoaderModel.h"

static WeePreferenceLoaderModel *loader = nil;

%hook BulletinBoardController

- (id) init {
    [loader loadEntries];
    return %orig;
}

%end

%hook BulletinBoardAppDetailController

static BBSectionInfo* sectionInfoForBBAppDetailController (id controller) {
    return [[(PSListController *)controller specifier] propertyForKey:@"BBSECTION_INFO_KEY"];
}

- (id)forwardingTargetForSelector:(SEL)selector {
    %log;
    
    id target = %orig;
    if (!target) {
        NSArray *controllers = [loader bundleControllersForSection:sectionInfoForBBAppDetailController(self)];
        if (controllers) {
            for (id controller in controllers) {
                if ([controller respondsToSelector:selector]) {
                    DLog(@"Bundle controller %@ responds to %@ !", controller, NSStringFromSelector(selector));
                    target = controller;
                    break;
                }
            }
            if (!target) {
                DLog(@"No bundle controller found that responds to %@", NSStringFromSelector(selector));
            }
        }
        else {
            DLog(@"No bundle controllers found for section %@", sectionInfoForBBAppDetailController(self).sectionID);
        }
    }
    
    return target;
}

- (id)specifiers { 
    %log; 
    
    id specifiers = MSHookIvar<id>(self, "_specifiers");
        
    if (!specifiers) {
        specifiers = %orig;
        
        NSArray *specifiersToAdd = [loader loadSpecifiersForListController:(PSListController *)self 
                                                               sectionInfo:sectionInfoForBBAppDetailController(self)];
        
        if (specifiersToAdd)
            [specifiers addObjectsFromArray:specifiersToAdd];
        
#ifdef DEBUG
        for (PSSpecifier *spec in specifiers) {
            DLog(@"Specifier name: %@, titleDict: %@, properties: %@", [spec name], [spec titleDictionary], [spec properties]);
        }
#endif
    }
    
    return specifiers;
}

%end

%ctor {
    %init;
    
    loader = [[WeePreferenceLoaderModel alloc] init];
}
