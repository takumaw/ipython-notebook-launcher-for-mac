//
//  IPythonNotebookLauncherAppDelegate.h
//  IPython Notebook Launcher
//
//  Copyright (c) 2014 WATANABE Takuma <takumaw@sfo.kuramae.ne.jp>
//

#import <Cocoa/Cocoa.h>

@interface IPythonNotebookLauncherAppDelegate : NSObject <NSApplicationDelegate> {
    // UI related
    IBOutlet NSMenu *statusMenu;
    NSStatusItem *statusItem;
    NSImage *statusImage;
    
    IBOutlet NSMenuItem *menuItemStatusline;
    IBOutlet NSMenuItem *menuItemIPStart;
    IBOutlet NSMenuItem *menuItemIPStop;
    IBOutlet NSMenuItem *menuItemIPRestart;
    IBOutlet NSMenuItem *menuItemStartIPythonOnStartup;
    IBOutlet NSMenuItem *menuItemOpenHTTPSinBrowser;
    
    // User Defaults related
    NSUserDefaults *standardUserDefaults;
    NSString *startIPythonOnStartupKey;
    BOOL startIPythonOnStartupValue;
    NSString *openHTTPSinBrowserKey;
    BOOL openHTTPSinBrowserValue;
    
    // main
    int ipythonTaskPid;
    NSString *iPythonBaseURL;
    NSMutableData *responseData;
}

// UI related
- (IBAction)iPythonStart:(id)sender;
- (IBAction)iPythonStop:(id)sender;
- (IBAction)iPythonRestart:(id)sender;
- (IBAction)iPythonOpenBrowser:(id)sender;
- (IBAction)iPythonOpenConfigDirectory:(id)sender;
- (IBAction)iPythonOpenConfigFile:(id)sender;
- (IBAction)iPythonOpenConfigNotebookFile:(id)sender;

- (IBAction)toggleUserDefaultsStartIPythonOnStartup:(id)sender;
- (IBAction)toggleUserDefaultsOpenHTTPSinBrowser:(id)sender;

// Apps functionality
- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename;
- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames;

- (void)uploadFileToIPython:(NSString *)filename;
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)connectionDidFinishLoading: (NSURLConnection *)connection;

@property (assign) IBOutlet NSWindow *window;

@end
