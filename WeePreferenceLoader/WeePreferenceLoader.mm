#line 1 "/Users/andrewr/Dropbox/Development/WeePreferenceLoader/WeePreferenceLoader/WeePreferenceLoader.xm"











#import <objc/runtime.h>
#import <CaptainHook.h>

#import "WeePreferenceLoaderModel.h"

static WeePreferenceLoaderModel *WPLoaderModel() {
    static WeePreferenceLoaderModel *loader = nil;
    
    if (!loader)
        loader = [[WeePreferenceLoaderModel alloc] init];
    
    return loader;
}

#include <substrate.h>
@class BulletinBoardAppDetailController; @class BulletinBoardController; 
static id (*_logos_orig$_ungrouped$BulletinBoardController$init)(BulletinBoardController*, SEL); static id _logos_method$_ungrouped$BulletinBoardController$init(BulletinBoardController*, SEL); static id (*_logos_orig$_ungrouped$BulletinBoardAppDetailController$specifiers)(BulletinBoardAppDetailController*, SEL); static id _logos_method$_ungrouped$BulletinBoardAppDetailController$specifiers(BulletinBoardAppDetailController*, SEL); 

#line 26 "/Users/andrewr/Dropbox/Development/WeePreferenceLoader/WeePreferenceLoader/WeePreferenceLoader.xm"


static id _logos_method$_ungrouped$BulletinBoardController$init(BulletinBoardController* self, SEL _cmd) {
    [WPLoaderModel() loadEntries];
    return _logos_orig$_ungrouped$BulletinBoardController$init(self, _cmd);
}





static char kWPSpecifiersLoaded;

static BBSectionInfo* sectionInfoForBBAppDetailController (id controller) {
    return [[(PSListController *)controller specifier] propertyForKey:@"BBSECTION_INFO_KEY"];
}

static id _logos_method$_ungrouped$BulletinBoardAppDetailController$specifiers(BulletinBoardAppDetailController* self, SEL _cmd) {
    id specifiersToReturn = _logos_orig$_ungrouped$BulletinBoardAppDetailController$specifiers(self, _cmd);
    
    NSMutableArray **specifiersRef = CHIvarRef(self, _specifiers, id);
	NSMutableArray *specifiers = specifiersRef ? *specifiersRef : nil;
    
    
    NSNumber *specsLoaded = objc_getAssociatedObject(specifiers, &kWPSpecifiersLoaded);
    
    if (!specsLoaded || ![specsLoaded boolValue]) {
        DLog(@"adding specifiers!");
        
        
        if (!specifiers || ![specifiers isKindOfClass:[NSMutableArray class]]) {
            specifiers = [[(specifiers ?: @[]) mutableCopy] autorelease];
        }
        
        NSArray *specifiersToAdd = [WPLoaderModel() loadSpecifiersForListController:(PSListController *)self 
                                                                        sectionInfo:sectionInfoForBBAppDetailController(self)];
        
        if (specifiersToAdd) {
            [specifiers addObjectsFromArray:specifiersToAdd];
        }
        
        if (specifiersToReturn != specifiers) {
            
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


static __attribute__((constructor)) void _logosLocalInit() {
{Class _logos_class$_ungrouped$BulletinBoardController = objc_getClass("BulletinBoardController"); MSHookMessageEx(_logos_class$_ungrouped$BulletinBoardController, @selector(init), (IMP)&_logos_method$_ungrouped$BulletinBoardController$init, (IMP*)&_logos_orig$_ungrouped$BulletinBoardController$init);Class _logos_class$_ungrouped$BulletinBoardAppDetailController = objc_getClass("BulletinBoardAppDetailController"); MSHookMessageEx(_logos_class$_ungrouped$BulletinBoardAppDetailController, @selector(specifiers), (IMP)&_logos_method$_ungrouped$BulletinBoardAppDetailController$specifiers, (IMP*)&_logos_orig$_ungrouped$BulletinBoardAppDetailController$specifiers);}  }
#line 86 "/Users/andrewr/Dropbox/Development/WeePreferenceLoader/WeePreferenceLoader/WeePreferenceLoader.xm"
