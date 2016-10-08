//
//  PluginTemplateFilter.h
//  PluginTemplate
//
//  Copyright (c) CURRENT_YEAR YOUR_NAME. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OsiriXAPI/PluginFilter.h>

@class LengthROIclipboard;


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

@property (nonatomic, retain) LengthROIclipboard *lengthROIclipboard;

- (long) filterImage:(NSString*) menuName;


+(ROI*) roiFromList:(NSMutableArray *)roiList WithType:(int)type2Find;

@end
