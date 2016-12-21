//
//  TextDisplayWindow.m
//  MirrorROIPlugin
//
//  Created by David Lewis on 08/12/2016.
//
//

#import "TextDisplayWindow.h"

@implementation TextDisplayWindow


-(void)setDisplayedText:(NSString *)displayedText {

    self.textView.string = displayedText;
}

@end
