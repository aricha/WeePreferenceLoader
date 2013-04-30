//
//  PrivateHeaders.h
//  WeePreferenceLoader
//
//  Created by Andrew Richardson on 2013-04-29.
//
//

#ifndef WeePreferenceLoader_PrivateHeaders_h
#define WeePreferenceLoader_PrivateHeaders_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NSInteger PSCellType;

#pragma mark - Model

@interface PSSpecifier : NSObject
@property(assign, nonatomic) id target;
@property(assign, nonatomic) PSCellType cellType;
@property(retain, nonatomic) NSDictionary *titleDictionary;
@property(retain, nonatomic) NSString *name;
@property(retain, nonatomic) NSMutableDictionary *properties;

+ (id)groupSpecifierWithName:(NSString *)name;
- (id)propertyForKey:(NSString *)key;
- (void)setProperty:(id)property forKey:(NSString *)key;
@end

@interface BBSectionInfo : NSObject <NSCopying, NSCoding>
@property(copy, nonatomic) NSString *pathToWeeAppPluginBundle;
@property(copy, nonatomic) NSString *sectionID;
@end

#pragma mark - View

@interface PreferencesTableCell : UITableViewCell
@end

@interface PSTableCell : PreferencesTableCell
+ (PSCellType)cellTypeFromString:(NSString *)string;
@end

#pragma mark - Controller

@protocol PSController <NSObject>
@property(nonatomic, retain) PSSpecifier *specifier;
@end

@interface PSViewController : UIViewController <PSController>
@end

@interface PSListController : PSViewController
@property(nonatomic, retain) NSArray *specifiers;
@end

#endif
