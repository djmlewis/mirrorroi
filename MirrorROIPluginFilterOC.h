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

typedef enum : NSUInteger {
    CT_Window,
    PET_Window,
    CTandPET_Windows
} ViewerWindow_Type;

@interface MirrorROIPluginFilterOC : PluginFilter {
    

}


@property (nonatomic, retain) ViewerController *viewerCT;
@property (nonatomic, retain) ViewerController *viewerPET;

@property (assign) IBOutlet NSBox *boxQuickCopyButtons;

@property (assign) IBOutlet NSTextField *labelCTviewerName;
@property (assign) IBOutlet NSTextField *labelPETviewerName;

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
