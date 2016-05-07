//
//  IPythonNotebookLauncherAppDelegate.m
//  IPython Notebook Launcher
//
//  Copyright (c) 2014 WATANABE Takuma <takumaw@sfo.kuramae.ne.jp>
//

#import "IPythonNotebookLauncherAppDelegate.h"

@implementation IPythonNotebookLauncherAppDelegate


/*
 * Init/Termination functions
 *
 */

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self initUserInterface];
    [self initStandardUserDefaults];
    [self initIPython];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    [self iPythonStop:nil];
    [standardUserDefaults synchronize];
}


/*
 * UI-related functions
 *
 */

- (void)initUserInterface
{
    // Add application icon to system status bar
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setTitle:@"IP[y]"];
    [statusItem setMenu:statusMenu];
    [statusItem setToolTip:@"IPython Notebook Launcher"];
    [statusItem setHighlightMode:YES];
}

- (void)initStandardUserDefaults
{
    // Open StandardUserDefaults
    standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *userDefaultsDefaults = [NSMutableDictionary dictionary];
    
    // Init Start IPython On Startup
    startIPythonOnStartupKey = @"StartIPythonOnStartup";
    
    [userDefaultsDefaults setObject:[NSNumber numberWithBool:YES] forKey:startIPythonOnStartupKey];
    [standardUserDefaults registerDefaults:userDefaultsDefaults];

    startIPythonOnStartupValue = [standardUserDefaults boolForKey:startIPythonOnStartupKey];
    if (startIPythonOnStartupValue) {
        [menuItemStartIPythonOnStartup setState:NSOnState];
    } else {
        [menuItemStartIPythonOnStartup setState:NSOffState];
    }
    
    // Init Open HTTPS in browser
    openHTTPSinBrowserKey = @"OpenHTTPSinBrowser";
    
    [userDefaultsDefaults setObject:[NSNumber numberWithBool:NO] forKey:openHTTPSinBrowserKey];
    [standardUserDefaults registerDefaults:userDefaultsDefaults];
    
    openHTTPSinBrowserValue = [standardUserDefaults boolForKey:openHTTPSinBrowserKey];
    if (openHTTPSinBrowserValue) {
        [menuItemOpenHTTPSinBrowser setState:NSOnState];
        iPythonBaseURL = @"https://localhost:8888";
    } else {
        [menuItemOpenHTTPSinBrowser setState:NSOffState];
        iPythonBaseURL = @"http://localhost:8888";
    }
}

- (IBAction)toggleUserDefaultsStartIPythonOnStartup:(id)sender
{
    NSInteger startIPythonOnStartup = [menuItemStartIPythonOnStartup state];
    if (startIPythonOnStartup == NSOffState) {
        startIPythonOnStartupValue = YES;
        [menuItemStartIPythonOnStartup setState:NSOnState];
    } else {
        startIPythonOnStartupValue = NO;
        [menuItemStartIPythonOnStartup setState:NSOffState];
    }
    [standardUserDefaults setBool:startIPythonOnStartupValue forKey:startIPythonOnStartupKey];
    [standardUserDefaults synchronize];
}

- (IBAction)toggleUserDefaultsOpenHTTPSinBrowser:(id)sender
{
    NSInteger openHTTPSinBrowser = [menuItemOpenHTTPSinBrowser state];
    if (openHTTPSinBrowser == NSOffState) {
        openHTTPSinBrowserValue = YES;
        [menuItemOpenHTTPSinBrowser setState:NSOnState];
        iPythonBaseURL = @"https://localhost:8888";
    } else {
        openHTTPSinBrowserValue = NO;
        [menuItemOpenHTTPSinBrowser setState:NSOffState];
        iPythonBaseURL = @"http://localhost:8888";
    }
    [standardUserDefaults setBool:openHTTPSinBrowserValue forKey:openHTTPSinBrowserKey];
    [standardUserDefaults synchronize];
}

/*
 * IPython Notebook Launcher main functions
 *
 */

-(void)initIPython
{
    ipythonTaskPid = -1;
    [self iPythonStart:nil];
}

- (IBAction)iPythonStart:(id)sender
{
    if (ipythonTaskPid == -1) {
        NSTask *task;
        task = [[NSTask alloc] init];
        [task setCurrentDirectoryPath:NSHomeDirectory()];
        [task setLaunchPath: @"/bin/bash"];
        NSArray *arguments;
        
        if (startIPythonOnStartupValue) {
            arguments = [NSArray arrayWithObjects:
                @"-l", @"-c", @"ipython notebook --parent=1 --no-browser", nil];
        } else {
            arguments = [NSArray arrayWithObjects:
                @"-l", @"-c", @"ipython notebook --parent=1", nil];
        }
        [task setArguments: arguments];

        [task launch];
        ipythonTaskPid = [task processIdentifier];
        
        NSLog(@"Starting IPython %i", ipythonTaskPid);
        
        NSString *newTitle = [NSString stringWithFormat:@"IPython: PID %i", ipythonTaskPid];
        [menuItemStatusline setTitle:newTitle];
    }
}

- (IBAction)iPythonStop:(id)sender
{
    if (ipythonTaskPid != -1) {
        kill(ipythonTaskPid, SIGTERM);
        NSLog(@"Stopping IPython %i", ipythonTaskPid);
        ipythonTaskPid = -1;
        
        NSString *newTitle = [NSString stringWithFormat:@"IPython: Stopped"];
        [menuItemStatusline setTitle:newTitle];
    }
}

- (IBAction)iPythonRestart:(id)sender
{
    [self iPythonStop:nil];
    [self iPythonStart:nil];
}

- (IBAction)iPythonOpenBrowser:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:iPythonBaseURL]];
}

- (IBAction)iPythonOpenConfigDirectory:(id)sender
{
    [[NSWorkspace sharedWorkspace] openFile:
        [@"~/.ipython/profile_default/" stringByExpandingTildeInPath]];
}

- (IBAction)iPythonOpenConfigFile:(id)sender
{
    [[NSWorkspace sharedWorkspace] openFile:
        [@"~/.ipython/profile_default/ipython_config.py" stringByExpandingTildeInPath]];
}

- (IBAction)iPythonOpenConfigNotebookFile:(id)sender
{
    [[NSWorkspace sharedWorkspace] openFile:
        [@"~/.ipython/profile_default/ipython_notebook_config.py" stringByExpandingTildeInPath]];
}

/*
 * IPython Notebook Launcher internal functions
 *
 */

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filepath
{
    [self uploadFileToIPython:filepath];
    return YES;
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filepaths
{
    for (NSString *filepath in filepaths) {
        [self uploadFileToIPython:filepath];
    }
}


- (void)uploadFileToIPython:(NSString *)filepath
{
    NSDate *now = [[NSDate alloc] init];
    
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"yyyy-MM-dd-HH:mm"];
    NSString *timestamp = [timeFormat stringFromDate:now];
    
    NSString *filename = [[filepath lastPathComponent] stringByDeletingPathExtension];
    NSString *notebookName = [NSString stringWithFormat:@"%@ (%@).ipynb", filename, timestamp];
    
    NSString *notebookNameEscaped = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                          NULL,
                                                                                                          (CFStringRef)notebookName,
                                                                                                          NULL,
                                                                                                          (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                          kCFStringEncodingUTF8 ));
    
    NSURL *requestUrl = [NSURL URLWithString:
                         [NSString stringWithFormat:[iPythonBaseURL stringByAppendingString:@"/api/notebooks/%@"], notebookNameEscaped]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestUrl];
    [request setHTTPMethod:@"PUT"];
    
    NSMutableData *requestBody = [NSMutableData data];
    [requestBody appendData:[@"{\"content\":" dataUsingEncoding:NSUTF8StringEncoding]];
    [requestBody appendData:[NSData dataWithContentsOfFile:filepath]];
    [requestBody appendData:[@"}" dataUsingEncoding:NSUTF8StringEncoding]];
    
    [request setHTTPBody:requestBody];
    [request setHTTPShouldHandleCookies:NO];
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    [NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    responseData = [[NSMutableData alloc] initWithData:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [responseData appendData:data];
}

- (void)connectionDidFinishLoading: (NSURLConnection *)connection
{
    NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    
    NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:
                                  [responseString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    
    NSString *notebookNameReceived = [responseDict valueForKeyPath:@"name"];
    NSString *notebookNameReceivedEscaped = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                                  NULL,
                                                                                                                  (CFStringRef)notebookNameReceived,
                                                                                                                  NULL,
                                                                                                                  (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                                  kCFStringEncodingUTF8 ));
    
    NSString *notebookURLReceived = [NSString stringWithFormat:[iPythonBaseURL stringByAppendingString:@"/notebooks/%@"],
                                     notebookNameReceivedEscaped];
    
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:notebookURLReceived]];
    
    NSLog(@"Opening %@", notebookURLReceived);
}

@end
