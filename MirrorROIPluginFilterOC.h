//
//  PluginTemplateFilter.h
//  PluginTemplate
//
//  Copyright (c) CURRENT_YEAR YOUR_NAME. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OsiriXAPI/PluginFilter.h>

typedef enum : NSInteger {
    ExtendSingleLengthUp,
    ExtendSingleLengthDown,
    ExtendSingleLengthBoth,
} ExtendSingleLengthHow;

@interface MirrorROIPluginFilterOC : PluginFilter {

}
@property (assign) IBOutlet NSTextField *textLengthROIname;
@property (assign) IBOutlet NSBox *textMirrorROIname;
@property (assign) IBOutlet NSTextField *activeMirrorROIname;

@property (assign) IBOutlet NSSegmentedControl *segmentExtendSingleLengthHow;

- (long) filterImage:(NSString*) menuName;

@end
