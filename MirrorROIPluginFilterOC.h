//
//  PluginTemplateFilter.h
//  PluginTemplate
//
//  Copyright (c) CURRENT_YEAR YOUR_NAME. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>
#import <OsiriXAPI/PluginFilter.h>

struct ROIValues {
    float mean;
    float sdev;
    float min;
    float max;
};

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
    Transform_Intercalated = 7,
    Jiggle_ROI = 8
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

typedef enum : NSInteger {
    UseFusedWindows = 0,
    UsePETWindowAlone = 1
} FusedOrPetAloneWindowSetting;

typedef enum : NSInteger {
    AllData, Summary, Roi,ThreeD, PixelsFlat, sep1, PixelsSummary,PixelsAll, sep2, JiggleRoi, sep3, PETRois
} ExportDataType;

typedef enum : NSInteger {
    ExportAsFile = -1,
    ViewInWindow = 0
} ExportDataHow;

typedef enum : NSInteger {
    JumpUndefined,JumpFirst,JumpDecrease,JumpIncrease,JumpLast
} JumpToIndexValue;


@interface MirrorROIPluginFilterOC : PluginFilter {}

@property (nonatomic, retain) NSWindowController *windowControllerMain;
@property (nonatomic, retain) ViewerController *viewerCT;
@property (nonatomic, retain) ViewerController *viewerPET;

@property (assign) IBOutlet NSTextField *labelCT;
@property (assign) IBOutlet NSTextField *labelPET;
@property (assign) IBOutlet NSTextField *labelWarningNoTools;
@property (assign) IBOutlet NSTextField *labelWarningNoAdjust;
@property (assign) IBOutlet NSView *viewTools;
@property (assign) IBOutlet NSView *viewAdjust;

@property (assign) IBOutlet NSLevelIndicator *levelJiggleIndex;

@property (assign) IBOutlet NSButton *buttonJiggleWorse;
@property (assign) IBOutlet NSButton *buttonJiggleBetter;
@property (assign) IBOutlet NSButton *buttonJiggleSetNew;
@property (assign) IBOutlet NSTextField *textJiggleRank;

@property (assign) IBOutlet NSPopUpButton *popupExportData;
@property (assign) IBOutlet NSComboBox *comboAnatomicalSite;

@property (assign) IBOutlet NSColorWell *colorWellActive;
@property (assign) IBOutlet NSColorWell *colorWellMirrored;
@property (assign) IBOutlet NSColorWell *colorWellTransformPlaced;
@property (assign) IBOutlet NSColorWell *colorWellTransformIntercalated;

@property (assign) IBOutlet SKView *skView;
@property (retain) SKScene *skScene;

@property (strong) NSMutableArray *arrayJiggleROIvalues;

- (long) filterImage:(NSString*) menuName;


+(ROI*) roiFromList:(NSMutableArray *)roiList WithType:(int)type2Find;

@end
