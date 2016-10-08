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

typedef enum : NSUInteger {
    Mirrored_ROI,
    Active_ROI,
    MirroredAndActive_ROI,
    Transform_ROI
} ROI_Mirror_Type;

@interface MirrorROIPluginFilterOC : PluginFilter {
    

}
@property (assign) IBOutlet NSTextField *textLengthROIname;
@property (assign) IBOutlet NSTextField *textMirrorROIname;
@property (assign) IBOutlet NSTextField *textActiveROIname;
@property (assign) IBOutlet NSSegmentedControl *segmentExtendSingleLengthHow;
@property (assign) IBOutlet NSSegmentedControl *segmentShowHideTransformMarkers;
@property (assign) IBOutlet NSSegmentedControl *segmentTransformMarkersPasteCopySliceOrSeries;

@property (nonatomic, retain) NSMutableArray *arrayTransformROIsCopied;
@property (nonatomic, retain) NSMutableArray *arrayMirrorROIsCopied;
@property (nonatomic, retain) NSMutableArray *arrayActiveROIsCopied;

- (long) filterImage:(NSString*) menuName;


+(ROI*) roiFromList:(NSMutableArray *)roiList WithType:(int)type2Find;

@end
