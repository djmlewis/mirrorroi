//
//  TextDisplayWindow.h
//  MirrorROIPlugin
//
//  Created by David Lewis on 08/12/2016.
//
//

#import <Cocoa/Cocoa.h>

@interface TextDisplayWindow : NSPanel


@property (assign) IBOutlet NSTextView *textView;

-(void)setDisplayedText:(NSString *)displayedText;

@end
