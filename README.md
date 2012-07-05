# WeePreferenceLoader #

A tool to load and insert preferences in the iOS Notification Center settings. Inspired heavily by Dustin Howett's PreferenceLoader.

Essentially, this allows you to very easily add preferences for Notification Center widgets (WeeApps) and even for per-app notification settings (BulletinBoard). It supports:

* Adding preferences dynamically via plists
* Loading bundles to add custom code and localization
* Picking up plist files directly from WeeAppPlugin bundles

## Why Use It? ##

* Familiar - designed to be used similarly to PreferenceLoader
* Logical - Notification Center widgets shouldn't add their preferences to an already-crowded main list, but to the actual Notifications settings
* Ease of use - It's as simple as adding your preferences plist file to your widget's bundle

## Usage ##

There are several ways to use WeePreferenceLoader, depending on your use case. This does require knowledge of how plists are formatted to work with the Settings app. For more information on this, see [http://iphonedevwiki.net/index.php/Preferences\_specifier\_plist](http://iphonedevwiki.net/index.php/Preferences_specifier_plist).

### Simple WeeApp Settings ###

To add a basic set of preferences to your Notification Center widget, it's as easy as this:

1. Create a plist file containing your settings. Your plist file requires only an `items` property, containing all of your preference items (formatted identically to a PreferenceLoader plist). 
	* A `title` property is optional - if you specify a title, it will be used as a section header at the beginning of your group of preferences.
2. Name your plist file `Preferences.plist`, or give it a custom name and specify it in your WeeApp's Info.plist file using the "PreferencesPlistName" key.
3. Add the plist file to your WeeApp's bundle, in the root directory (don't place it in a subfolder).
4. You're done! WeePreferenceLoader will automatically pick up your plist file and display your preferences in the Notifications settings for your WeeApp.

To add localizations to your plist file, you can either use the same localization files as your WeeApp, or use a custom bundle with separate localizations. Which brings us to...

### Using a custom bundle ###

A custom bundle allows you to add custom actions and code to your preferences, as well as localizations. Bundles created for WeePreferenceLoader should have their name specified using the `bundle` key in the root level of your plist file. Bundles can be added one of the following ways:

* Adding the bundle within your WeeApp's bundle
* Adding the bundle to `/Library/WeePreferenceLoader/Preferences/`
* Specifying a custom bundle path in your plist file, using the `bundlePath` key (just like PreferenceLoader), and adding your bundle there

If you choose to add an executable with custom code to your bundle, the process for this is a bit different from PreferenceLoader. Most notably, **your bundle's principal class should not be a PSListController**. The principal class can only be used for adding custom actions for your existing specifiers, as well as modifying those specifiers at runtime (more on that later). It will *not* be used as a view controller. However, any additional classes you choose to add (ie. custom cell classes, detail view controllers, etc.) will work normally.

Your bundle's principal class can implement a couple of methods that make customization of the view controller and your specifiers at runtime possible. The first is `-(id)initWithListController:(PSListController *)controller`, which will be used as the default initializer should your class implement it. This will be called *before* your bundle's specifiers have been added, so it is important not to modify the specifiers in this method. You also **must not retain the list controller**, or you will cause a retain cycle and leak memory.

To modify your primary specifiers, you can also choose to implement the method `-(void)configureSpecifiers:(NSMutableArray *)specifiers`. Here you can modify, add to, or remove your specifiers as needed. Note that your bundle will receive only the specifiers contained in your plist, not those from any other plist.

### Adding settings to multiple sections ###

If you wish to add settings to multiple sections in the Notifications settings - for WeeApps, and / or for per-app notification (BulletinBoard) - you can add them by placing your plist in `/Library/WeePreferenceLoader/Preferences`. 

You will also need to specify a `sections` key in the root level of your plist with an array of section IDs you want your preferences to appear in - the section IDs being the bundle IDs of the WeeApps and / or apps that are set up to display BulletinBoard notifications. If you do not specify this key, or if the array is empty, WeePreferenceLoader will show your preferences in all sections. Support for filtering sections will be coming in a future update (but send me an email if you want it done sooner!).

Bundles are loaded the same way for these plists as for plists in WeeApp bundles, so the above instructions still apply.