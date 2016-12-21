//
//  TextDisplayWindowController.m
//  MirrorROIPlugin
//
//  Created by David Lewis on 09/12/2016.
//
//

#import "TextDisplayWindowController.h"
#import "TextDisplayWindow.h"

@interface TextDisplayWindowController ()

@end

@implementation TextDisplayWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [(TextDisplayWindow *)self.window setDisplayedText:self.displayedText];
    self.window.title = self.title;
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName
{
    return self.title;
}

@end
