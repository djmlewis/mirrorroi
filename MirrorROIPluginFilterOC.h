//
//  PluginTemplateFilter.h
//  PluginTemplate
//
//  Copyright (c) CURRENT_YEAR YOUR_NAME. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OsiriXAPI/PluginFilter.h>


typedef enum : NSInteger {
    ExtendSingleLengthUp = 0,
    ExtendSingleLengthDown,
    ExtendSingleLengthBoth,
} ExtendSingleLengthHow;

typedef enum : NSUInteger {
    Mirrored_ROI = 1,
    Active_ROI = 2,
    MirroredAndActive_ROI = 3,
    Transform_ROI = 4
} ROI_Mirror_Type;

typedef enum : NSUInteger {
    CT_Window = 1,
    PET_Window = 2,
    CTandPET_Windows = 3,
    NoType_Defined = 4,
    Front_Window = 5
} ViewerWindow_Type;

typedef enum : NSInteger {
    tAnyROItype = -999
} ROItypeAdditional;

typedef enum : NSInteger {
    SetPixels_SameName = 0,
    SetPixels_AllROIs = 1,
    SetPixels_AllPixels = 2
} SetROIpixel_Options;

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
