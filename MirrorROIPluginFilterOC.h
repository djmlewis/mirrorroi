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
    GrowRegionMirrored = 0,
    GrowRegionSingle = 1,
    GrowRegionNAC = 2
} GrowRegionHow;

typedef enum : NSInteger {
    ExtendSingleLengthUp = 0,
    ExtendSingleLengthDown,
    ExtendSingleLengthBoth
} ExtendSingleLengthHow;

typedef enum : NSUInteger {
    GrowingRegion = -1,
    AllROI = 0,
    Mirrored_ROI = 1,
    Active_ROI = 2,
    MirroredAndActive_ROI = 3,
    Transform_ROI_Placed = 4,
    AllROI_CT = 5,
    AllROI_PET = 6,
    Transform_Intercalated = 7,
    Jiggle_ROI = 8,
    TextRectangleROIs = 9
} ROI_Type;

typedef enum : NSUInteger {
    CT_Window = 1,
    PET_Window = 2,
    CTandPET_Windows = 3,
    NoType_Defined = 4,
    Front_Window = 5
} ViewerWindow_Type;

typedef enum : NSInteger {
    ActiveMirroredInSingleSlice = 0,
    ActiveMirroredIn3D = 1,
    ActiveOnlyInSingleSlice = 2,
    ActiveOnlyIn3D = 3
} ActiveMirrorGenerateHow;

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
    JiggleRoi_View,
    JiggleRoi_Save,
    PETRois,
    //not on menu:
    AllROIdata,
    RoiSummary,
    RoiData,
    RoiThreeD,
    RoiPixelsFlat,
    PixelsGridAllData,
    PixelsGridSummary,
    BookmarkedDataSummary,
    BookmarkedDataPixelGrids,
    BookmarkedDataPixelGridsTransposed,
    BookmarkedData1LineSummary,
    BookmarkedDataSelected1LineSummariesConjoined
} ExportDataType;

typedef enum : NSInteger {
    ExportAs1LineFile = -2,
    ExportAsFile = -1,
    ViewInWindow = 0,
    BookmarkString = 1
} ExportDataHow;

//typedef enum : NSInteger {
//    ExportSummary = 0,
//    ExportPixelGridsTransposed = 1,
//    ExportPixelGrids = 2
//} ExportWhichData;

typedef enum : NSInteger {
    BookmarkSubtract = -1,
    BookmarkTrash = 0,
    BookmarkAdd = 1,
    BookmarkExport = 2,
    BookmarkQuickLook = 3,
    BookmarkPLISTimport = 4,
    Bookmark1LineExport = 5
} BookmarkEAST;

typedef enum : NSInteger {
    KeyImageOff = -1,
    KeyImageOn = 1
} KeyImageSetting;

typedef enum : NSUInteger {
    NoActive = 0,
    ActiveOnly = 1,
    ActiveAndMirrored = 2
} PixelDataStatus;

typedef enum : NSInteger {
    WriteComments = -1,
    ReadComments = 1
} ReadWriteComments;

typedef enum : NSInteger {
    ComboArrayDelete = -1,
    ComboArrayLoad = 0,
    ComboArrayAdd = 1
} ComboBoxArrayAlteration;

typedef enum : NSInteger {
    Combo_Vaccines_Delete = -1,
    Combo_Vaccines = 1,
    Combo_Vaccines_Load = 11,
    Combo_Vaccines_Save = 21,
    Combo_TreatmentSites_Delete = -2,
    Combo_TreatmentSites = 2,
    Combo_TreatmentSites_Load = 12,
    Combo_TreatmentSites_Save = 22,
    Combo_AnatomicalSites_Delete = -3,
    Combo_AnatomicalSites = 3,
    Combo_AnatomicalSites_Load = 13,
    Combo_AnatomicalSites_Save = 23,
    Combo_Placebo_Delete = -4,
    Combo_Placebo = 4,
    Combo_Placebo_Load = 14,
    Combo_Placebo_Save = 24
} ComboBoxIdentifier;


typedef enum : NSInteger {
    JumpUndefined,JumpFirst,JumpDecrease,JumpIncrease,JumpLast
} JumpToIndexValue;


@interface MirrorROIPluginFilterOC : PluginFilter {}

@property (assign) IBOutlet NSImageView *imageViewTempy;

@property (nonatomic, retain) NSWindowController *windowControllerMain;
@property (nonatomic, retain) ViewerController *viewerCT;
@property (nonatomic, retain) ViewerController *viewerPET;

@property (assign) IBOutlet NSTextField *labelDicomStudy;
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
@property (assign) IBOutlet NSComboBox *comboTreatmentSite;
@property (assign) IBOutlet NSComboBox *comboVaccines;
@property (assign) IBOutlet NSComboBox *comboPlaceboUsed;
@property (assign) IBOutlet NSTextField *textFieldVaccineDayOffset;
@property (assign) IBOutlet NSTextField *textFieldWarningPatientDetails;
@property (assign) IBOutlet NSTextView *textViewComments2;

@property (assign) IBOutlet NSColorWell *colorWellActive;
@property (assign) IBOutlet NSColorWell *colorWellMirrored;
@property (assign) IBOutlet NSColorWell *colorWellTransformPlaced;
@property (assign) IBOutlet NSColorWell *colorWellTransformIntercalated;

@property (assign) IBOutlet SKView *skView;
@property (retain) SKScene *skScene;

@property (strong) NSMutableDictionary *dictBookmarks;
@property (strong) NSMutableArray *arrayBookmarkedSites;
@property (assign) IBOutlet NSArrayController *arrayControllerBookmarks;
@property (strong) NSArray *arraySortSelectorsBookmarks;
@property (strong) NSMutableArray *arrayJiggleROIvalues;

- (long) filterImage:(NSString*) menuName;


+(ROI*) roiFromList:(NSMutableArray *)roiList WithType:(int)type2Find;

@end
