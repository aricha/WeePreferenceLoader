#line 1 "/Users/andrewr114/Dropbox/Development/WeePreferenceLoader/WeePreferenceLoader/WeePreferenceLoader.xm"




#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <BulletinBoard/BBSectionInfo.h>

#import "WeePreferenceLoaderModel.h"

static WeePreferenceLoaderModel *loader = nil;

#include <substrate.h>
@class BulletinBoardAppDetailController; @class BulletinBoardController; @class PSListController; 

#line 13 "/Users/andrewr114/Dropbox/Development/WeePreferenceLoader/WeePreferenceLoader/WeePreferenceLoader.xm"


static id (*__ungrouped$PSListController$specifiers)(PSListController*, SEL);static id $_ungrouped$PSListController$specifiers(PSListController* self, SEL _cmd) {
    NSArray *specs = __ungrouped$PSListController$specifiers(self, _cmd);
    for (PSSpecifier *spec in specs) {

        DLog(@"Specifier name: %@, titleDict: %@, properties: %@", [spec name], [spec titleDictionary], [spec properties]);
    }
    
    return specs;
}






















static id (*__ungrouped$BulletinBoardController$init)(BulletinBoardController*, SEL);static id $_ungrouped$BulletinBoardController$init(BulletinBoardController* self, SEL _cmd) {
    [loader loadEntries];
    return __ungrouped$BulletinBoardController$init(self, _cmd);
}





static BBSectionInfo* sectionInfoForBBAppDetailController (id controller) {
    return [[(PSListController *)controller specifier] propertyForKey:@"BBSECTION_INFO_KEY"];
}

static id (*__ungrouped$BulletinBoardAppDetailController$forwardingTargetForSelector$)(BulletinBoardAppDetailController*, SEL, SEL);static id $_ungrouped$BulletinBoardAppDetailController$forwardingTargetForSelector$(BulletinBoardAppDetailController* self, SEL _cmd, SEL selector) {
    NSLog(@"-[<BulletinBoardAppDetailController: %p> forwardingTargetForSelector:%@]", self, NSStringFromSelector(selector));
    
    id target = __ungrouped$BulletinBoardAppDetailController$forwardingTargetForSelector$(self, _cmd, selector);
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

static id (*__ungrouped$BulletinBoardAppDetailController$specifiers)(BulletinBoardAppDetailController*, SEL);static id $_ungrouped$BulletinBoardAppDetailController$specifiers(BulletinBoardAppDetailController* self, SEL _cmd) { 
    NSLog(@"-[<BulletinBoardAppDetailController: %p> specifiers]", self); 
    
    id specifiers = MSHookIvar<id>(self, "_specifiers");
        
    if (!specifiers) {
        specifiers = __ungrouped$BulletinBoardAppDetailController$specifiers(self, _cmd);
        
        NSArray *specifiersToAdd = [loader loadSpecifiersForListController:(PSListController *)self 
                                                               sectionInfo:sectionInfoForBBAppDetailController(self)];
        
        if (specifiersToAdd)
            [specifiers addObjectsFromArray:specifiersToAdd];
        
        for (PSSpecifier *spec in specifiers) {
            DLog(@"Specifier name: %@, titleDict: %@, properties: %@", [spec name], [spec titleDictionary], [spec properties]);
        }
    }
    
    return specifiers;
}



static __attribute__((constructor)) void _logosLocalCtor_d0f2e29d() {
    {{Class $$PSListController = objc_getClass("PSListController"); MSHookMessageEx($$PSListController, @selector(specifiers), (IMP)&$_ungrouped$PSListController$specifiers, (IMP*)&__ungrouped$PSListController$specifiers);Class $$BulletinBoardController = objc_getClass("BulletinBoardController"); MSHookMessageEx($$BulletinBoardController, @selector(init), (IMP)&$_ungrouped$BulletinBoardController$init, (IMP*)&__ungrouped$BulletinBoardController$init);Class $$BulletinBoardAppDetailController = objc_getClass("BulletinBoardAppDetailController"); MSHookMessageEx($$BulletinBoardAppDetailController, @selector(forwardingTargetForSelector:), (IMP)&$_ungrouped$BulletinBoardAppDetailController$forwardingTargetForSelector$, (IMP*)&__ungrouped$BulletinBoardAppDetailController$forwardingTargetForSelector$);MSHookMessageEx($$BulletinBoardAppDetailController, @selector(specifiers), (IMP)&$_ungrouped$BulletinBoardAppDetailController$specifiers, (IMP*)&__ungrouped$BulletinBoardAppDetailController$specifiers);}}
    
    loader = [[WeePreferenceLoaderModel alloc] init];
}
