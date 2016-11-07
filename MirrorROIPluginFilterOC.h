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
    AllROI = 0,
    Mirrored_ROI = 1,
    Active_ROI = 2,
    MirroredAndActive_ROI = 3,
    Transform_ROI_Placed = 4,
    AllROI_CT = 5,
    AllROI_PET = 6,
    Transform_Intercalated = 7
} ROI_Type;

typedef enum : NSUInteger {
    CT_Window = 1,
    PET_Window = 2,
    CTandPET_Windows = 3,
    NoType_Defined = 4,
    Front_Window = 5
} ViewerWindow_Type;

typedef enum : NSUInteger {
    MoveROI_Reset = 0,
    MoveROI_Up = 1,
    MoveROI_Right = 2,
    MoveROI_Down = 3,
    MoveROI_Left = 4,
    MoveROI_NE = 5,
    MoveROI_SE = 6,
    MoveROI_SW = 7,
    MoveROI_NW = 8,
    MoveROI_Accept = 9
} MoveROIDirection;

typedef enum : NSInteger {
    tAnyROItype = -999
} ROItypeAdditional;

typedef enum : NSInteger {
    SetPixels_SameName = 0,
    SetPixels_AllROIs = 1,
    SetPixels_AllPixels = 2
} SetROIpixel_Options;

@interface MirrorROIPluginFilterOC : PluginFilter {}


@property (nonatomic, retain) ViewerController *viewerCT;
@property (nonatomic, retain) ViewerController *viewerPET;

@property (assign) IBOutlet NSTextField *labelCT;
@property (assign) IBOutlet NSTextField *labelPET;
@property (assign) IBOutlet NSView *viewTools;

@property (assign) IBOutlet NSSlider *sliderMovevalue;

@property (assign) IBOutlet NSTextField *textLengthROIname;
@property (assign) IBOutlet NSTextField *textMirrorROIname;
@property (assign) IBOutlet NSTextField *textActiveROIname;
@property (assign) IBOutlet NSTextField *textActiveData;
@property (assign) IBOutlet NSTextField *textMirroredData;


@property (assign) IBOutlet NSSegmentedControl *segmentExtendSingleLengthHow;

@property (assign) IBOutlet NSColorWell *colorWellActive;
@property (assign) IBOutlet NSColorWell *colorWellMirrored;
@property (assign) IBOutlet NSColorWell *colorWellTransformPlaced;
@property (assign) IBOutlet NSColorWell *colorWellTransformIntercalated;


@property (assign) IBOutlet NSView *viewMarkers;
@property (assign) IBOutlet NSTextField *markerMeanActive;
@property (assign) IBOutlet NSTextField *markerSDupActive;
@property (assign) IBOutlet NSTextField *markerSDlowActive;
@property (assign) IBOutlet NSTextField *markerMaxActive;
@property (assign) IBOutlet NSTextField *markerMinActive;
@property (assign) IBOutlet NSTextField *markerMeanMirrored;
@property (assign) IBOutlet NSTextField *markerSDupMirrored;
@property (assign) IBOutlet NSTextField *markerSDlowMirrored;
@property (assign) IBOutlet NSTextField *markerMaxMirrored;
@property (assign) IBOutlet NSTextField *markerMinMirrored;



- (long) filterImage:(NSString*) menuName;


+(ROI*) roiFromList:(NSMutableArray *)roiList WithType:(int)type2Find;

@end
