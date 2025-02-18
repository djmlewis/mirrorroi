//
//  PluginTemplateFilter.m
//  PluginTemplate
//
//  Copyright (c) CURRENT_YEAR YOUR_NAME. All rights reserved.
//

#import "MirrorROIPluginFilterOC.h"
#import "ROIValues.h"
#import "TextDisplayWindowController.h"

#import <OsiriXAPI/PluginFilter.h>
#import <OsiriXAPI/Notifications.h>
#import <OsiriXAPI/DicomStudy.h>
#import <OsiriXAPI/DicomSeries.h>
#import <OsiriXAPI/BrowserController.h>


@implementation MirrorROIPluginFilterOC


#pragma mark - Plugin

- (void) initPlugin {
    // Register the preference defaults early.
    [self initDefaults];
    [self initNotfications];
    self.dictBookmarks = [NSMutableDictionary dictionary];
    self.arrayJiggleROIvalues = [NSMutableArray array];
    //self.arrayBookmarkedSites = [NSMutableArray array];
    self.arraySortSelectorsBookmarks = [NSArray arrayWithObject: [[NSSortDescriptor alloc] initWithKey:nil ascending:YES]];
}
-(void)dealloc {
    //[self.skScene release];
    //[self.windowControllerMain release];
    //[self.viewerCT release];
    //[self.viewerPET release];
    //[self.arrayJiggleROIvalues release];
    [super dealloc];
}
- (void) willUnload {
    
    [super willUnload];
}
- (long) filterImage:(NSString*) menuName {
    
    //essential use this with OWNER specified so it looks in OUR bundle for resource.
    self.windowControllerMain = [[NSWindowController alloc] initWithWindowNibName:@"MirrorWindow" owner:self];
    [self.windowControllerMain showWindow:self];
    //load stats first
    [self loadStatsScene];
    [self smartAssignCTPETwindows];
    [self clearJiggleROIsAndValuesAndResetDisplayed];
    
    BOOL completedOK = YES;
    
    if(completedOK) return 0; // No Errors
    else return -1;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath containsString:kColor_Stem]) {
        [self refreshDisplayedDataForCT];
    }
}
#pragma mark - Initialisations
-(void)initDefaults {
    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
    [defaults setObject:NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] forKey:kUserDefault_1LineSummaryOpenDirectory];
    
    [defaults setValue:[NSArchiver archivedDataWithRootObject:[NSColor yellowColor]] forKey:kColor_Active];
    [defaults setValue:[NSArchiver archivedDataWithRootObject:[NSColor blueColor]] forKey:kColor_Mirrored];
    [defaults setValue:[NSArchiver archivedDataWithRootObject:[NSColor greenColor]] forKey:kColor_TransformPlaced];
    [defaults setValue:[NSArchiver archivedDataWithRootObject:[NSColor redColor]] forKey:kColor_TransformIntercalated];
    [defaults setValue:[NSArchiver archivedDataWithRootObject:[NSColor purpleColor]] forKey:kColor_Jiggle];
    [defaults setValue:@"Transform" forKey:kTransformROInameDefault];
    [defaults setValue:@"Mirrored" forKey:kMirroredROInameDefault];
    [defaults setValue:@"Active" forKey:kActiveROInameDefault];
    
    [defaults setValue:[NSNumber numberWithInteger:0] forKey:kExportMenuSelectedIndexDefault];
    [defaults setValue:[NSNumber numberWithInteger:0] forKey:kSegmentFusedOrPETSegmentDefault];
    [defaults setValue:[NSNumber numberWithInteger:1] forKey:kMirrorMoveByPixels];
    [defaults setValue:[NSNumber numberWithInteger:1] forKey:kJiggleBoundsPixels];
    //[defaults setValue:[NSNumber numberWithInteger:2] forKey:kExtendSingleTransformDefault];
    
    [defaults setValue:[NSNumber numberWithBool:YES] forKey:kTransposeExportedDataDefault];
    [defaults setValue:[NSNumber numberWithBool:YES] forKey:kAddReportWhenSaveBookmarkedDataDefault];
    [defaults setValue:[NSNumber numberWithBool:NO] forKey:kIncludeOriginalInJiggleDefault];
    [defaults setValue:[NSNumber numberWithBool:YES] forKey:kRankJiggleDefault];
    [defaults setValue:[NSNumber numberWithBool:NO] forKey:kExportKeyImagesWhenSetting];
    [defaults setValue:[NSNumber numberWithFloat:0.2] forKey:kKeyImageHeightFractionDefault];
    
    //the sortKeys used in sorting jiggleROI are in an Array, each key a dict
    NSMutableArray *arrayOfKeys = [NSMutableArray array];
    [arrayOfKeys addObject:@{kJiggleSortKey : @"distance",kJiggleCheckKey : @"1"}];
    [arrayOfKeys addObject:@{kJiggleSortKey : @"mean",kJiggleCheckKey : @"0"}];
    [arrayOfKeys addObject:@{kJiggleSortKey : @"meanfloor",kJiggleCheckKey : @"1"}];
    [arrayOfKeys addObject:@{kJiggleSortKey : @"sdev",kJiggleCheckKey : @"0"}];
    [arrayOfKeys addObject:@{kJiggleSortKey : @"sdevfloor",kJiggleCheckKey : @"1"}];
    [arrayOfKeys addObject:@{kJiggleSortKey : @"median",kJiggleCheckKey : @"0"}];
    [arrayOfKeys addObject:@{kJiggleSortKey : @"midrange",kJiggleCheckKey : @"1"}];
    [arrayOfKeys addObject:@{kJiggleSortKey : @"range",kJiggleCheckKey : @"1"}];
    [arrayOfKeys addObject:@{kJiggleSortKey : @"min",kJiggleCheckKey : @"0"}];
    [arrayOfKeys addObject:@{kJiggleSortKey : @"max",kJiggleCheckKey : @"0"}];
    [defaults setObject:arrayOfKeys forKey:kJiggleSortsArrayName];
    
    NSMutableArray *arrayOfjROIs = [NSMutableArray array];
    [arrayOfjROIs addObject:@{kJiggleROIsArrayKey : @"1"}];
    [defaults setObject:arrayOfjROIs forKey:kJiggleROIsArrayName];
    
    //comboBoxes arrays
    [defaults setObject:[NSMutableArray arrayWithArray:[MirrorROIPluginFilterOC arrayFromFileAtURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"TreatmentSites" withExtension:@"txt"]]] forKey:kDefaultArrayTreatmentSites];
    [defaults setObject:[NSMutableArray arrayWithArray:[MirrorROIPluginFilterOC arrayFromFileAtURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"Vaccines" withExtension:@"txt"]]] forKey:kDefaultArrayVaccines];
    [defaults setObject:[NSMutableArray arrayWithArray:[MirrorROIPluginFilterOC arrayFromFileAtURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"Placebos" withExtension:@"txt"]]] forKey:kDefaultArrayPlacebos];
    [defaults setObject:[NSMutableArray arrayWithArray:[MirrorROIPluginFilterOC arrayFromFileAtURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"AnatomicalSites" withExtension:@"txt"]]] forKey:kDefaultArrayAnatomicalSites];
    
    //override or complement Osirix Defaults
    [[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"ROITEXTIFSELECTED"];
    [[NSUserDefaults standardUserDefaults] setObject:NSLocalizedString(@"Growing Region", nil) forKey:@"growingRegionROIName"];
    [defaults setObject:[NSNumber numberWithFloat:0.9] forKey:kGrowingRegionROILowerThresholdMirroredDefault];
    [defaults setObject:[NSNumber numberWithFloat:2.0] forKey:kGrowingRegionROILowerThresholdSingleDefault];
    [defaults setObject:[NSNumber numberWithFloat:1000.0] forKey:kGrowingRegionROIUpperThresholdDefault];
    [defaults setObject:[NSNumber numberWithFloat:1.0] forKey:kGrowingRegionROIMultiplierDefault];
    [defaults setObject:[NSNumber numberWithFloat:1.0] forKey:kGrowingRegionROIIterationsDefault];
    [defaults setObject:[NSNumber numberWithFloat:1.0] forKey:kGrowingRegionROIPixelsDefault];
    
    //register the defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    
    //add observers for defaults changes so app can respond
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kColor_Active options:NSKeyValueObservingOptionNew context:nil];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kColor_Mirrored options:NSKeyValueObservingOptionNew context:nil];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kColor_TransformPlaced options:NSKeyValueObservingOptionNew context:nil];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kColor_TransformIntercalated options:NSKeyValueObservingOptionNew context:nil];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kColor_Jiggle options:NSKeyValueObservingOptionNew context:nil];
}

+(BOOL)userDefaultBooleanForKey:(NSString *)key {
    return [[NSUserDefaults standardUserDefaults] boolForKey:key];
}
-(void)initNotfications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:OsirixCloseViewerNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:OsirixViewerControllerDidLoadImagesNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:OsirixDCMUpdateCurrentImageNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:OsirixNewStudySelectedNotification object:nil];
}
-(void)handleNotification:(NSNotification *)notification {
    if ([notification.name isEqualToString:OsirixViewerControllerDidLoadImagesNotification] ||
        [notification.name isEqualToString:OsirixCloseViewerNotification]) {
        [self smartAssignCTPETwindows];
    }
    else if ([notification.name isEqualToString:OsirixDCMUpdateCurrentImageNotification] &&
             notification.object == self.viewerCT.imageView) {
        [self resetJiggleControlsAndRefresh];
    }
    else if ([notification.name isEqualToString:OsirixNewStudySelectedNotification]) {
        DicomStudy *study = [notification.userInfo objectForKey:@"Selected Study"];
        [self populateTreatmentFieldsFromCommentsWithStudy:study];
    }
}

#pragma mark - Array functions
+(NSString *)stringForVerticalDataArray:(NSMutableArray *)arrayOfData withName:(NSString *)name {
    [arrayOfData insertObject:name atIndex:0];
    return [arrayOfData componentsJoinedByString:@"\n"];
}
+(NSString *)stringForDataArray:(NSMutableArray *)arrayOfData forceTranspose:(BOOL)forceTranspose {
    if (arrayOfData.count>0) {
        NSMutableArray *arrayOfRowStrings = [NSMutableArray arrayWithCapacity:arrayOfData.count];
        if (forceTranspose || [MirrorROIPluginFilterOC userDefaultBooleanForKey:kTransposeExportedDataDefault]) {
            //find the max length of the rows = the number of rows we need when we switch
            NSUInteger maxRowLength = 0;
            for (NSUInteger r=0; r<arrayOfData.count; r++) {
                maxRowLength = MAX(maxRowLength,[[arrayOfData objectAtIndex:r] count]);
            }
            //Make an array to hold these rows of data
            NSMutableArray *arrayTransposedRows = [NSMutableArray arrayWithCapacity:maxRowLength];
            for (int c=0; c<maxRowLength; c++) {
                [arrayTransposedRows addObject:[NSMutableArray array]];
            }
            //r is the original row with data from ROI in slice 0..count
            //i is the item in each roiArray
            //go thru the new array of possible maxRowLength cols, askeach ROI data array  if it can contribute. If roiarray.count<maxRowLength use @"" as a placeholder
            for (int roiArraysIndex=0; roiArraysIndex<arrayOfData.count; roiArraysIndex++) {
                NSMutableArray *arrayOfDataFromROIatIndex = [arrayOfData objectAtIndex:roiArraysIndex];
                NSUInteger roiArrayCount = arrayOfDataFromROIatIndex.count;
                for (int roiarrayDataIndex=0; roiarrayDataIndex<maxRowLength; roiarrayDataIndex++) {
                    if (roiarrayDataIndex<roiArrayCount) {
                        [[arrayTransposedRows objectAtIndex:roiarrayDataIndex] addObject:[arrayOfDataFromROIatIndex objectAtIndex:roiarrayDataIndex]];
                    }
                    else {
                        [[arrayTransposedRows objectAtIndex:roiarrayDataIndex] addObject:@""];
                    }
                }
            }
            // now fuse the new cols as rows
            for (int r=0; r<arrayTransposedRows.count; r++) {
                [arrayOfRowStrings addObject:[[arrayTransposedRows objectAtIndex:r]componentsJoinedByString:@"\t"]];
            }
        }
        else {
            // just fuse the new cols as rows
            for (int r=0; r<arrayOfData.count; r++) {
                [arrayOfRowStrings addObject:[[arrayOfData objectAtIndex:r]componentsJoinedByString:@"\t"]];
            }
        }
        //  fuse the new rows as table
        return [arrayOfRowStrings componentsJoinedByString:@"\n"];
    }
    return @"";
}

#pragma mark - help and Info
- (IBAction)infoTapped:(NSButton *)sender {
    [MirrorROIPluginFilterOC alertWithMessage:[NSString stringWithFormat:@"Build Version %@\nCreated By DJM Lewis\n© 2017 djml.eu\n All Rights Reserved E&OE",[[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey]] andTitle:@"MirrorROI plugin" critical:NO];
}

#pragma mark - Windows
+(void)alertWithMessage:(NSString *)message andTitle:(NSString *)title critical:(BOOL)critical{
    if (critical) {
        NSRunCriticalAlertPanel(NSLocalizedString(title,nil), NSLocalizedString(message,nil) , NSLocalizedString(@"Close",nil), nil, nil);
    } else {
        NSRunAlertPanel(NSLocalizedString(title,nil), NSLocalizedString(message,nil) , NSLocalizedString(@"Close",nil), nil, nil);
    }
}
+(void)alertSound {
    [[NSSound soundNamed:@"Basso"] play];
}
+(BOOL)proceedAfterAlert:(NSString *)query {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleCritical;
    alert.messageText = query;
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    return ([alert runModal] == NSAlertFirstButtonReturn);
}

-(IBAction)assignWindowClicked:(NSButton *)sender {
    [self assignViewerWindow:[ViewerController frontMostDisplayed2DViewer] forType:sender.tag];
    [self adjustFusedSelectAccordingToWindows];
}
-(void)assignViewerWindow:(ViewerController *)viewController forType:(ViewerWindow_Type)type {
    [self clearTreatmentFields];
    [self trashAllBookmarks];
    [self setAnatomicalSiteName:@""];
    
    if (type == CT_Window || type == CTandPET_Windows)
    {
        self.viewerCT = viewController;
        if (viewController != nil) {
            self.labelCT.stringValue = viewController.window.title;
            self.labelCT.toolTip = viewController.window.title;
            [self clearJiggleROIsAndValuesAndResetDisplayed];
        }
        else
        {
            self.labelCT.stringValue = @"Not Assigned";
            self.labelPET.toolTip = nil;
        }
    }
    if (type == PET_Window || type == CTandPET_Windows)
    {
        self.viewerPET = viewController;
        if (viewController != nil) {
            self.labelPET.stringValue = viewController.window.title;
            self.labelPET.toolTip = viewController.window.title;
            [self populateTreatmentFieldsFromCommentsWithStudy:[self.viewerPET currentStudy]];
        }
        else
        {
            self.labelPET.stringValue = @"Not Assigned";
            self.labelPET.toolTip = nil;
        }
    }
    [self showHideControlsIfViewersValid];
    [MirrorROIPluginFilterOC deselectROIforViewer:viewController];
    
}
+(void)deselectROIforViewer:(ViewerController *)viewController {
    if (viewController != nil) {
        //make a dummy just for the tag == 0 for deselect
        NSMenuItem *dummy = [[[NSMenuItem alloc] init] autorelease];
        dummy.tag = 0;
        [viewController roiSelectDeselectAll:dummy];
        [viewController needsDisplayUpdate];
    }
}
-(void)showHideControlsIfViewersValid {
    self.viewTools.hidden = ![self validCTandPETwindows];
    self.viewAdjust.hidden = self.viewTools.hidden;
    self.labelWarningNoTools.hidden = !self.viewTools.hidden;
    self.labelWarningNoAdjust.hidden = self.labelWarningNoTools.hidden;
}
-(IBAction)smartAssignCTPETwindowsClicked:(id)sender {
    [self smartAssignCTPETwindows];
}
-(void)smartAssignCTPETwindows {
    BOOL notfoundCT = YES;
    BOOL notfoundPET = YES;
    NSUInteger i = 0;
    //clear the values
    [self assignViewerWindow:nil forType:CTandPET_Windows];
    //try to find
    while (i<self.viewerControllersList.count && (notfoundCT || notfoundPET)) {
        ViewerController *vc = [self.viewerControllersList objectAtIndex:i];
        if ([vc.modality isEqualToString:@"CT"]) {
            [self assignViewerWindow:vc forType:CT_Window];
            notfoundCT = NO;
        }
        else if([vc.modality isEqualToString:@"PT"]) {
            [self assignViewerWindow:vc forType:PET_Window];
            notfoundPET = NO;
        }
        i++;
    }
    [self adjustFusedSelectAccordingToWindows];
}
-(void)adjustFusedSelectAccordingToWindows {
    if (self.viewerCT != nil && self.viewerPET != nil) {
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:kSegmentFusedOrPETSegmentDefault];
    } else if (self.viewerPET != nil) {
        [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:kSegmentFusedOrPETSegmentDefault];
    }
}
-(BOOL)valid2DViewer:(ViewerController *)active2Dviewer {
    if (active2Dviewer == nil || ([self.viewerControllersList indexOfObjectIdenticalTo:active2Dviewer] == NSNotFound)) return false;
    return true;
}
-(BOOL)validCTandPETwindows {
    switch ([MirrorROIPluginFilterOC useFusedOrPetAloneWindow]) {
        case UseFusedWindows:
            return ([self valid2DViewer:self.viewerCT] && [self valid2DViewer:self.viewerPET]);
            break;
        case UsePETWindowAlone:
            return [self valid2DViewer:self.viewerPET];
            break;
        default:
            return false;
            break;
    }
}
-(BOOL)validSliceCountInCTandPETwindows {
    if (([[self.viewerCT pixList] count] == [[self.viewerPET pixList] count])
        && ([[self.viewerCT roiList] count] == [[self.viewerCT pixList] count])
        && ([[self.viewerPET roiList] count] == [[self.viewerPET pixList] count]))
    {
        return YES;
    }
    else
    {
        return [MirrorROIPluginFilterOC proceedAfterAlert:@"PET and CT windows have mismatched number of slices. If you continue the app may crash or data may be missed. Continue?"];
        //[MirrorROIPluginFilterOC alertWithMessage: andTitle:@"Unable To Proceed"];
        //return NO;
    }
}
- (IBAction)fuseDefusetapped:(NSButton *)sender {
    NSMenuItem *dummy = [[[NSMenuItem alloc] init] autorelease];
    [self.viewerCT blendWindows:dummy];
}

+(FusedOrPetAloneWindowSetting)useFusedOrPetAloneWindow {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kSegmentFusedOrPETSegmentDefault];
}
-(ViewerController *)viewerForTransformsAccordingToFusedOrPetAloneWindowSetting {
    switch ([MirrorROIPluginFilterOC useFusedOrPetAloneWindow]) {
        case UsePETWindowAlone:
            return self.viewerPET;
            break;
        case UseFusedWindows:
            return self.viewerCT;
            break;
        default:
            return nil;
            break;
    }
}
- (IBAction)segmentUseCTPETorPETaloneTapped:(NSSegmentedControl *)sender {
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self showHideControlsIfViewersValid];
}
- (IBAction)roiSelectorTapped:(id)sender {
    [self.viewerPET setROIToolTag:tROISelector];
    [self.viewerCT setROIToolTag:tROISelector];
}

#pragma mark - Import Lists
- (IBAction)importComboBoxListFileTapped:(NSButton *)sender {
    switch (sender.tag) {
        case Combo_Vaccines_Load:
        case Combo_TreatmentSites_Load:
        case Combo_AnatomicalSites_Load:
        case Combo_Placebo_Load:
            [self selectArrayListFileForCombo:sender.tag];
            break;
        case Combo_Vaccines_Save:
        case Combo_TreatmentSites_Save:
        case Combo_AnatomicalSites_Save:
        case Combo_Placebo_Save:
            [self saveArrayFileForCombo:sender.tag];
            break;
            
        default:
            break;
    }
}
-(void)selectArrayListFileForCombo:(ComboBoxIdentifier)comboBox {
    // Get the main window for the document.
    NSWindow* window = self.windowControllerMain.window;
    // Create and configure the panel.
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:NO];
    [panel setAllowsMultipleSelection:NO];
    [panel setMessage:@"Import a file with a new list"];
    
    // Display the panel attached to the document's window.
    [panel beginSheetModalForWindow:window completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            [self importComboArrayFileAtURL:[[panel URLs] objectAtIndex:0] forComboBox:comboBox];
        }
    }];
    
}
-(void)saveArrayFileForCombo:(ComboBoxIdentifier)comboBox {
    NSArray *array = [self arrayForComboBox:comboBox];
    if (array.count > 0) {
        NSSavePanel *savePanel = [NSSavePanel savePanel];
        savePanel.allowedFileTypes = [NSArray arrayWithObject:@"txt"];
        savePanel.nameFieldStringValue = [[MirrorROIPluginFilterOC fileNamePrefixForComboBox:comboBox] stringByAppendingPathExtension:@"txt"];
        if ([savePanel runModal] == NSFileHandlingPanelOKButton) {
            NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:nil];
            [[array componentsJoinedByString:@"\n"] writeToURL:savePanel.URL atomically:YES encoding:NSUnicodeStringEncoding error:&error];
        }
    }
    else {
        [MirrorROIPluginFilterOC alertWithMessage:@"There are no items in the list" andTitle:[NSString stringWithFormat:@"Export Items for %@",[MirrorROIPluginFilterOC fileNamePrefixForComboBox:comboBox]] critical:YES];
    }
}
+(NSMutableArray *)arrayFromFileAtURL:(NSURL *) url {
    NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:nil];
    NSString *string = [NSString stringWithContentsOfURL:url usedEncoding:nil error:&error];
    NSMutableArray *array = [NSMutableArray arrayWithArray:[string componentsSeparatedByString:@"\n"]];
    //purge blank lines
    NSMutableIndexSet *set = [NSMutableIndexSet indexSet];
    for (NSUInteger i=0; i<array.count; i++) {
        if ([[array objectAtIndex:i] length]<1) {
            [set addIndex:i];
        }
    }
    if (set.count>0) {
        [array removeObjectsAtIndexes:set];
    }
    return array;
}
-(void)importComboArrayFileAtURL:(NSURL *)url forComboBox:(ComboBoxIdentifier)comboBox {
    NSMutableArray *array = [MirrorROIPluginFilterOC arrayFromFileAtURL:url];
    if (array.count>0) {
        switch (comboBox) {
            case Combo_Vaccines_Load:
                [[NSUserDefaults standardUserDefaults] setObject:array forKey:kDefaultArrayVaccines];
                break;
            case Combo_TreatmentSites_Load:
                [[NSUserDefaults standardUserDefaults] setObject:array forKey:kDefaultArrayTreatmentSites];
                break;
            case Combo_AnatomicalSites_Load:
                [[NSUserDefaults standardUserDefaults] setObject:array forKey:kDefaultArrayAnatomicalSites];
                break;
            case Combo_Placebo_Load:
                [[NSUserDefaults standardUserDefaults] setObject:array forKey:kDefaultArrayPlacebos];
                break;
                
            default:
                break;
        }
    }
    else {
        [MirrorROIPluginFilterOC alertWithMessage:[NSString stringWithFormat:@"The file could not be loaded either because it could not be opened or it did not contain readable text. The file must be text with a single item on each line."] andTitle:@"Error loading file" critical:YES];
    }
}

#pragma mark - ComboBox
+(NSString *)fileNamePrefixForComboBox:(ComboBoxIdentifier)comboBox {
    switch (comboBox) {
        case Combo_Vaccines_Save:
            return @"Vaccines";
        case Combo_TreatmentSites_Save:
            return @"Treatment Sites";
        case Combo_AnatomicalSites_Save:
            return @"Anatomical Sites";
        case Combo_Placebo_Save:
            return @"Placebos";
            break;
            
        default:
            return nil;
            break;
    }
}
-(NSArray *)arrayForComboBox:(ComboBoxIdentifier)comboBox {
    switch (comboBox) {
        case Combo_Vaccines_Save:
            return [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultArrayVaccines];
        case Combo_TreatmentSites_Save:
            return [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultArrayTreatmentSites];
        case Combo_AnatomicalSites_Save:
            return [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultArrayAnatomicalSites];
        case Combo_Placebo_Save:
            return [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultArrayPlacebos];
            
        default:
            return nil;
            break;
    }
}
-(void) alterArrayForComboBox:(NSComboBox *)cbox forIdentifier:(NSString *)identifier withAlteration:(ComboBoxArrayAlteration)alteration {
    NSMutableArray *array = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:identifier]];
    switch (alteration) {
        case ComboArrayAdd:
            if (cbox.stringValue.length > 0 && ![array containsObject:cbox.stringValue]) {
                [array addObject:cbox.stringValue];
            }
            break;
        case ComboArrayDelete:
            [array removeObject:cbox.stringValue];
            break;
            
        default:
            break;
    }
    [[NSUserDefaults standardUserDefaults] setObject:array forKey: identifier];
}
- (IBAction)alterComboBoxItemTapped:(NSButton *)sender {
    //    [self willChangeValueForKey:@"arrayVaccines"];
    //    [self.arrayVaccines addObject:[[NSDate date] description]];
    //    [self didChangeValueForKey:@"arrayVaccines"];
    //NSUserDefaults call returns NSArray so we have to do arrayWithArray
    
    switch (sender.tag) {
        case Combo_TreatmentSites:
            [self alterArrayForComboBox:self.comboTreatmentSite forIdentifier:kDefaultArrayTreatmentSites withAlteration:ComboArrayAdd];
            break;
        case Combo_TreatmentSites_Delete:
            [self alterArrayForComboBox:self.comboTreatmentSite forIdentifier:kDefaultArrayTreatmentSites withAlteration:ComboArrayDelete];
            break;
        case Combo_Vaccines:
            [self alterArrayForComboBox:self.comboVaccines forIdentifier:kDefaultArrayVaccines withAlteration:ComboArrayAdd];
            break;
        case Combo_Vaccines_Delete:
            [self alterArrayForComboBox:self.comboVaccines forIdentifier:kDefaultArrayVaccines withAlteration:ComboArrayDelete];
            break;
        case Combo_Placebo:
            [self alterArrayForComboBox:self.comboPlaceboUsed forIdentifier:kDefaultArrayPlacebos withAlteration:ComboArrayAdd];
            break;
        case Combo_Placebo_Delete:
            [self alterArrayForComboBox:self.comboPlaceboUsed forIdentifier:kDefaultArrayPlacebos withAlteration:ComboArrayDelete];
            break;
        case Combo_AnatomicalSites:
            [self alterArrayForComboBox:self.comboAnatomicalSite forIdentifier:kDefaultArrayAnatomicalSites withAlteration:ComboArrayAdd];
            break;
        case Combo_AnatomicalSites_Delete:
            [self alterArrayForComboBox:self.comboAnatomicalSite forIdentifier:kDefaultArrayAnatomicalSites withAlteration:ComboArrayDelete];
            break;
        default:
            break;
    }
    
}

#pragma mark - TextDisplayWindowController
+ (void)showStringInWindow:(NSString *)string withTitle:(NSString *)title{
    //do not use withOwner in initWithWindowNibName, so it uses the links in the nib file to connect window with the TextDisplayWindowController
    TextDisplayWindowController *windowController = [[TextDisplayWindowController alloc] initWithWindowNibName:@"TDWindow"];
    [windowController setDisplayedText:string];
    [windowController setTitle:title];
    [windowController showWindow:self];
}

#pragma mark - Create Active
- (IBAction)growRegionClicked:(NSButton *)sender {
    if ([self anatomicalSiteDefined])
    {
        switch (sender.tag) {
            case GrowRegionMirrored:
                [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"growingRegionAlgorithm"];
                [[NSUserDefaults standardUserDefaults] setFloat:[[NSUserDefaults standardUserDefaults] floatForKey:kGrowingRegionROILowerThresholdMirroredDefault] forKey:@"growingRegionLowerThreshold"];
                [[NSUserDefaults standardUserDefaults] setFloat:[[NSUserDefaults standardUserDefaults] floatForKey:kGrowingRegionROIUpperThresholdDefault] forKey:@"growingRegionUpperThreshold"];
                break;
            case GrowRegionSingle:
                [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"growingRegionAlgorithm"];
                [[NSUserDefaults standardUserDefaults] setFloat:[[NSUserDefaults standardUserDefaults] floatForKey:kGrowingRegionROILowerThresholdSingleDefault] forKey:@"growingRegionLowerThreshold"];
                [[NSUserDefaults standardUserDefaults] setFloat:[[NSUserDefaults standardUserDefaults] floatForKey:kGrowingRegionROIUpperThresholdDefault] forKey:@"growingRegionUpperThreshold"];
                break;
            case GrowRegionNAC:
                [[NSUserDefaults standardUserDefaults] setInteger:3 forKey:@"growingRegionAlgorithm"];
                [[NSUserDefaults standardUserDefaults] setFloat:[[NSUserDefaults standardUserDefaults] floatForKey:kGrowingRegionROIMultiplierDefault] forKey:@"growingRegionMultiplier"];
                [[NSUserDefaults standardUserDefaults] setFloat:[[NSUserDefaults standardUserDefaults] floatForKey:kGrowingRegionROIIterationsDefault] forKey:@"growingRegionIterations"];
                [[NSUserDefaults standardUserDefaults] setFloat:[[NSUserDefaults standardUserDefaults] floatForKey:kGrowingRegionROIPixelsDefault] forKey:@"growingRegionRadius"];
                break;
            default:
                break;
        }
        [self.viewerPET.window makeKeyAndOrderFront:nil];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        [[NSApplication sharedApplication] sendAction:@selector(segmentationTest:) to:self.viewerPET from:self.viewerPET];
#pragma clang diagnostic pop
    }
}

#pragma mark - Create Transforms
-(IBAction)addTransformROIs:(NSButton *)sender {
    if ([MirrorROIPluginFilterOC useFusedOrPetAloneWindow] == UsePETWindowAlone || [self validSliceCountInCTandPETwindows])
    {
        [self addBoundingTransformROIS];
    }
}
-(void)addBoundingTransformROIS {
    ViewerController *viewerToAdd = [self viewerForTransformsAccordingToFusedOrPetAloneWindowSetting];
    if (viewerToAdd != nil)
    {
        [viewerToAdd setROIToolTag:tMesure];
        [self deleteTransformsFromViewer:viewerToAdd];
        
        //find the first and last pixIndex with an ACTIVE ROI
        NSMutableIndexSet *indexesWithROI= [[NSMutableIndexSet alloc]init];
        NSString *activeROIname = [self roiNameForType:GrowingRegion];
        for (NSUInteger pixIndex = 0; pixIndex < [[self.viewerPET pixList] count]; pixIndex++)
        {
            for(ROI	*curROI in [[self.viewerPET roiList] objectAtIndex: pixIndex])
            {
                if ([curROI.name isEqualToString:activeROIname])
                {
                    [indexesWithROI addIndex:pixIndex];
                    break;
                }
            }
        }
        if(indexesWithROI.count==0) {
            [MirrorROIPluginFilterOC alertWithMessage:@"No PET slices have ROIs" andTitle:@"Creating transforms" critical:YES];
        }
        else if (indexesWithROI.count==1) {
            [self addLengthROIWithStart:[self pointForImageIndex:indexesWithROI.firstIndex inWindow:viewerToAdd start:YES]
                                 andEnd:[self pointForImageIndex:indexesWithROI.firstIndex inWindow:viewerToAdd start:NO]
                     toViewerController:viewerToAdd
                                atIndex:indexesWithROI.firstIndex
                               withType:Transform_ROI_Placed];
            [self displayImageInCTandPETviewersWithIndex:indexesWithROI.firstIndex];
            
        }
        else if(indexesWithROI.count>1) {
            [self addLengthROIWithStart:[self pointForImageIndex:indexesWithROI.firstIndex inWindow:viewerToAdd start:YES]
                                 andEnd:[self pointForImageIndex:indexesWithROI.firstIndex inWindow:viewerToAdd start:NO]
                     toViewerController:viewerToAdd
                                atIndex:indexesWithROI.firstIndex
                               withType:Transform_ROI_Placed];
            
            [self addLengthROIWithStart:[self pointForImageIndex:indexesWithROI.firstIndex inWindow:viewerToAdd start:YES]
                                 andEnd:[self pointForImageIndex:indexesWithROI.firstIndex inWindow:viewerToAdd start:NO]
                     toViewerController:viewerToAdd
                                atIndex:indexesWithROI.lastIndex
                               withType:Transform_ROI_Placed];
            
            [self displayImageInCTandPETviewersWithIndex:indexesWithROI.firstIndex];
        }
    }
    else
    {
        [MirrorROIPluginFilterOC alertWithMessage:@"Unable to add bounding transforms as no valid viewer" andTitle:@"Creating transforms" critical:YES];
    }
}
-(void)displayImageInCTandPETviewersWithIndex:(short)index {
    //do it in ImageView for correct order
    [self.viewerPET.imageView setIndexWithReset:index :YES];
    [self.viewerPET adjustSlider];
    [self.viewerPET needsDisplayUpdate];
    
    [self.viewerCT.imageView setIndexWithReset:index :YES];
    [self.viewerCT adjustSlider];
    [self.viewerCT needsDisplayUpdate];
    
}
-(void)addLengthROIWithStart:(NSPoint)startPoint andEnd:(NSPoint)endPoint toViewerController:(ViewerController *)active2Dwindow atIndex:(NSUInteger)index withType:(ROI_Type)type {
    ROI *newR = [active2Dwindow newROI:tMesure];
    [newR setThickness:6.0];
    newR.name = [self roiNameForType:type];
    [MirrorROIPluginFilterOC  setROIcolour:newR forType:type];
    [newR.points addObject:[active2Dwindow newPoint:startPoint.x :startPoint.y]];
    [newR.points addObject:[active2Dwindow newPoint:endPoint.x :endPoint.y]];
    // wrong way [[[active2Dwindow roiList] objectAtIndex:index] addObject:newR];
    [self addROI2Pix:newR atSlice:index inViewer:active2Dwindow hidden:NO];
}

-(NSPoint)pointForImageIndex:(short)index inWindow:(ViewerController *)vc start:(BOOL)start {
    NSPoint point = NSMakePoint(100.0, 100.0);
    CGFloat divisor = 0.3;//end
    if (start) { divisor = 0.6;}//start
    if (index < vc.pixList.count) {
        long h = [[vc.pixList objectAtIndex:index] pheight];
        long w = [[vc.pixList objectAtIndex:index] pwidth];
        point.y = h / 2.0;
        point.x = w * divisor;
    }
    return point;
}
- (IBAction)completeTransformSeries:(NSButton *)sender {
    [self completeLengthROIseries];
}
-(void)completeLengthROIseries {
    ViewerController *viewerToAdd = [self viewerForTransformsAccordingToFusedOrPetAloneWindowSetting];
    
    if ([self valid2DViewer:viewerToAdd])
    {
        NSMutableArray  *allROIsList = [viewerToAdd roiList];
        NSMutableArray *indicesOfDCMPixWithMeasureROI = [NSMutableArray arrayWithCapacity:allROIsList.count];
        NSMutableArray *measureROIs = [NSMutableArray arrayWithCapacity:allROIsList.count];
        
        //collect up the ROIs
        for (int index = 0;index<allROIsList.count; index++) {
            ROI *measureROI = [MirrorROIPluginFilterOC roiFromList:[allROIsList objectAtIndex:index] WithType:tMesure];
            if (measureROI != nil) {
                //do this here as completeLengthROIseriesForViewerController ignores the first / last
                measureROI.offsetTextBox_x = 10000.0;
                measureROI.name = [self roiNameForType:Transform_ROI_Placed];
                [measureROIs addObject:measureROI];
                [indicesOfDCMPixWithMeasureROI addObject:[NSNumber numberWithInt:index]];
            }
        }
        switch (indicesOfDCMPixWithMeasureROI.count)
        {
            case 0:
                [MirrorROIPluginFilterOC alertWithMessage:@"No bounding transforms detected" andTitle:@"Completing transform series" critical:YES];
                break;
            case 1:
                [MirrorROIPluginFilterOC alertWithMessage:@"Only 1 bounding transform detected" andTitle:@"Completing transform series" critical:YES];
                break;
            default:
                //-1 as we go in pairs and so skip the last one as it gets picked up below as [indicesOfDCMPixWithMeasureROI objectAtIndex:roiNumber+1] unsignedIntegerValue]
                for (int i=0; i<indicesOfDCMPixWithMeasureROI.count-1; i++)
                {
                    [self completeLengthROIseriesForViewerController:viewerToAdd
                                                         betweenROI1:[measureROIs objectAtIndex:i]
                                                             andROI2:[measureROIs objectAtIndex:i+1]
                                                          fromSlice1:[[indicesOfDCMPixWithMeasureROI objectAtIndex:i] unsignedIntegerValue]
                                                            toSlice2:[[indicesOfDCMPixWithMeasureROI objectAtIndex:i+1] unsignedIntegerValue]];
                }
                break;
        }
        [viewerToAdd needsDisplayUpdate];
    }
    else
    {
        [MirrorROIPluginFilterOC alertWithMessage:@"Invalid viewer" andTitle:@"Completing transform series" critical:YES];
    }
}
-(void)completeLengthROIseriesForViewerController:(ViewerController *)active2Dwindow betweenROI1:(ROI *)roi1 andROI2:(ROI *)roi2 fromSlice1:(NSUInteger)firstSlice toSlice2:(NSUInteger)lastSlice{
    
    MyPoint *roi1_Point0 = [roi1.points objectAtIndex:0];
    MyPoint *roi1_Point1 = [roi1.points objectAtIndex:1];
    MyPoint *roi2_Point0 = [roi2.points objectAtIndex:0];
    MyPoint *roi2_Point1 = [roi2.points objectAtIndex:1];
    float numberOfSliceIntervals = lastSlice-firstSlice;
    float Xincrement1 = (roi2_Point0.point.x - roi1_Point0.point.x)/numberOfSliceIntervals;
    float Xincrement2 = (roi2_Point1.point.x - roi1_Point1.point.x)/numberOfSliceIntervals;
    float XincrementCurrent1 = Xincrement1;
    float XincrementCurrent2 = Xincrement2;
    float Yincrement1 = (roi2_Point0.point.y - roi1_Point0.point.y)/numberOfSliceIntervals;
    float Yincrement2 = (roi2_Point1.point.y - roi1_Point1.point.y)/numberOfSliceIntervals;
    float YincrementCurrent1 = Yincrement1;
    float YincrementCurrent2 = Yincrement2;
    //skip first and last index
    for (NSUInteger nextIndex = firstSlice+1; nextIndex<lastSlice; nextIndex++)
    {
        ROI *newROI = [roi1 copy];
        newROI.locked = NO;
        [MirrorROIPluginFilterOC  setROIcolour:newROI forType:Transform_Intercalated];
        [[[newROI points] objectAtIndex:0] move:XincrementCurrent1 :YincrementCurrent1];
        [[[newROI points] objectAtIndex:1] move:XincrementCurrent2 :YincrementCurrent2];
        [self addROI2Pix:newROI atSlice:nextIndex inViewer:active2Dwindow hidden:NO];
        
        XincrementCurrent1 += Xincrement1;
        XincrementCurrent2 += Xincrement2;
        YincrementCurrent1 += Yincrement1;
        YincrementCurrent2 += Yincrement2;
    }
}
-(void)extendROI:(ROI *)roi withinSeriesFromStart:(NSUInteger)start toEnd:(NSUInteger)end inViewerController:(ViewerController *)active2Dwindow {
    NSMutableArray  *allROIsList = [active2Dwindow roiList];
    for (NSUInteger nextIndex = start; nextIndex<end; nextIndex++) {
        if (nextIndex<allROIsList.count)
        {
            ROI *roiC = [roi copy];
            roiC.locked = NO;
            [self addROI2Pix:roiC atSlice:nextIndex inViewer:active2Dwindow hidden:NO];
        }
    }
}
- (IBAction)jumpToFirstLastTransform:(NSButton *)sender {
    ViewerController *viewerToAdd = [self viewerForTransformsAccordingToFusedOrPetAloneWindowSetting];
    switch (sender.tag) {
        case JumpIncrease:
            [self displayImageInCTandPETviewersWithIndex:MIN(self.viewerPET.imageView.curImage+1, self.viewerPET.imageView.dcmPixList.count-1)];
            break;
        case JumpDecrease:
            [self displayImageInCTandPETviewersWithIndex:MAX(self.viewerPET.imageView.curImage-1, 0)];
            break;
        case JumpFirst:
        case JumpLast:
        {
            NSMutableIndexSet *set = [MirrorROIPluginFilterOC indicesInViewer:viewerToAdd withROIofType:tMesure];
            if (set.count>0) {
                if (sender.tag == JumpFirst)
                {
                    [self displayImageInCTandPETviewersWithIndex:set.firstIndex];
                }
                else
                {
                    [self displayImageInCTandPETviewersWithIndex:set.lastIndex];
                }
            }
            break;
        }
        default:
            break;
    }
}

#pragma mark - Do Mirror
- (IBAction)mirrorActiveROI3D:(NSButton *)sender {
    //only generate mirror roi if asked to
    switch (sender.tag) {
        case ActiveMirroredIn3D:
        case ActiveMirroredInSingleSlice:
        {
            [self copyTransformsAndMirrorActivesIn3D:sender.tag];
        }
            break;
        case ActiveOnlyIn3D:
        case ActiveOnlyInSingleSlice:
        {
            [self mirrorActiveROIUsingLengthROIn3D:sender.tag];
        }
            break;
        default:
            break;
    }
}
-(void)copyTransformsAndMirrorActivesIn3D:(NSInteger)in3D {
    if ([MirrorROIPluginFilterOC useFusedOrPetAloneWindow] == UsePETWindowAlone || [self copyTransformROIsFromCT2PETIn3D:in3D])
    {
        [self mirrorActiveROIUsingLengthROIn3D:in3D];
        [self.viewerPET needsDisplayUpdate];
        [self.viewerCT needsDisplayUpdate];
        [self resetJiggleControlsAndRefresh];
    }
}
-(BOOL)copyTransformROIsFromCT2PETIn3D:(NSInteger)in3D {
    if ([MirrorROIPluginFilterOC useFusedOrPetAloneWindow] == UseFusedWindows
        && [self validCTandPETwindows]
        && [self validSliceCountInCTandPETwindows])
    {
        BOOL copiedSomething = NO;
        NSUInteger startSlice = 0;
        NSUInteger endSlice = 0;
        NSString *transformname = [self roiNameForType:Transform_ROI_Placed];
        if (in3D) {
            [self deleteROIsFromViewerController:self.viewerPET withName:transformname];
            startSlice = 0;
            endSlice = self.viewerPET.roiList.count;
        }
        else
        {
            startSlice = [[self.viewerPET imageView] curImage];
            endSlice = startSlice+1;
            [self deleteROIsInSlice:startSlice inViewerController:self.viewerPET withName:transformname];
        }
        
        for (NSUInteger pixIndex = startSlice; pixIndex<endSlice; pixIndex++) {
            for (ROI *roi in [[self.viewerCT roiList] objectAtIndex:pixIndex]) {
                if ([roi.name isEqualToString:transformname])//(roi.type == tMesure)
                {
                    ROI *roiC = [roi copy];
                    roiC.locked = NO;
                    [self addROI2Pix:roiC atSlice:pixIndex inViewer:self.viewerPET hidden:NO];
                    copiedSomething = YES;
                }
            }
        }
        if (copiedSomething) {
            return YES;
        }
        else
        {
            [MirrorROIPluginFilterOC alertWithMessage:@"Unable to complete as no valid transforms were found" andTitle:@"Copy transforms" critical:YES];
            return NO;
        }
    }
    else
    {
        [MirrorROIPluginFilterOC alertWithMessage:@"Unable to complete as either the viewer windows are not assigned, or the number of slices in each window do not match" andTitle:@"Copy transforms" critical:YES];
        return NO;
    }
}

-(void)mirrorActiveROIUsingLengthROIn3D:(ActiveMirrorGenerateHow)activeMirrorGenerate {
    BOOL mirroredSomething = NO;
    
    NSMutableArray  *roisInAllSlices  = [self.viewerPET roiList];
    NSUInteger startSlice = 0;
    NSUInteger endSlice = 0;
    if (activeMirrorGenerate == ActiveMirroredIn3D || activeMirrorGenerate == ActiveOnlyIn3D) {
        startSlice = 0;
        endSlice = roisInAllSlices.count;
        [self deleteROIsFromViewerController:self.viewerPET withName:[self roiNameForType:Mirrored_ROI]];
        [self deleteROIsFromViewerController:self.viewerPET withName:[self roiNameForType:Active_ROI]];
        [self deleteROIsFromViewerController:self.viewerCT withName:[self roiNameForType:Active_ROI]];
        [self deleteROIsFromViewerController:self.viewerCT withName:[self roiNameForType:Mirrored_ROI]];
        [self clearJiggleROIsAndValuesFromAllSlices];
    }
    else //ActiveMirroredInSingleSlice or ActiveOnlySingleSlice - not curently used
    {
        startSlice = [[self.viewerPET imageView] curImage];
        endSlice = startSlice+1;
        [self deleteROIsInSlice:startSlice inViewerController:self.viewerPET withName:[self roiNameForType:Mirrored_ROI]];
        [self deleteROIsInSlice:startSlice inViewerController:self.viewerPET withName:[self roiNameForType:Active_ROI]];
        [self deleteROIsInSlice:startSlice inViewerController:self.viewerCT withName:[self roiNameForType:Active_ROI]];
        [self deleteROIsInSlice:startSlice inViewerController:self.viewerCT withName:[self roiNameForType:Mirrored_ROI]];
        [self clearJiggleROIsAndValuesFromSlice:startSlice];
    }
    
    for (NSUInteger slice=startSlice; slice<endSlice; slice++) {
        NSMutableArray *roisInThisSlice = [roisInAllSlices objectAtIndex:slice];
        ROI *roi2Clone = [MirrorROIPluginFilterOC roiFromList:roisInThisSlice WithName:[self roiNameForType:GrowingRegion]];
        //[MirrorROIPluginFilterOC roiFromList:roisInThisSlice WithType:tPlain];
        if (roi2Clone != nil) {
            //rename to keep in sync
            roi2Clone.name = [self roiNameForType:Active_ROI];
            [MirrorROIPluginFilterOC  setROIcolour:roi2Clone forType:Active_ROI];
            //only generate mirror roi if asked to
            switch (activeMirrorGenerate) {
                case ActiveMirroredIn3D:
                case ActiveMirroredInSingleSlice:
                {
                    NSPoint deltaXY = [MirrorROIPluginFilterOC deltaXYFromROI:roi2Clone usingLengthROI:[MirrorROIPluginFilterOC roiFromList:roisInThisSlice WithType:tMesure]];
                    
                    if ([MirrorROIPluginFilterOC isValidDeltaPoint:deltaXY]) {
                        ROI *createdROI  = [[ROI alloc]
                                            initWithTexture:[MirrorROIPluginFilterOC flippedBufferHorizontalFromROI:roi2Clone]
                                            textWidth:roi2Clone.textureWidth
                                            textHeight:roi2Clone.textureHeight
                                            textName:[self roiNameForType:Mirrored_ROI]
                                            positionX:roi2Clone.textureUpLeftCornerX+deltaXY.x
                                            positionY:roi2Clone.textureUpLeftCornerY-deltaXY.y // must be minus to correctly invert the negatives
                                            spacingX:roi2Clone.pixelSpacingX
                                            spacingY:roi2Clone.pixelSpacingY
                                            imageOrigin:roi2Clone.imageOrigin];
                        [MirrorROIPluginFilterOC  setROIcolour:createdROI forType:Mirrored_ROI];
                        [self addROI2Pix:createdROI atSlice:slice inViewer:self.viewerPET hidden:NO];
                        
                        [MirrorROIPluginFilterOC forceRecomputeDataForROI:createdROI];
                        [self addROItoCTAtSlice:slice forActiveROI:roi2Clone mirroredROI:createdROI];
                        mirroredSomething = YES;
                    }
                }
                    break;
                case ActiveOnlyIn3D:
                case ActiveOnlyInSingleSlice:
                {
                    [self addROItoCTAtSlice:slice forActiveROI:roi2Clone mirroredROI:nil];
                    mirroredSomething = YES;//to pass test
                }
                    break;
                default:
                    break;
            }
        }
    }
    [MirrorROIPluginFilterOC deselectROIforViewer:self.viewerPET];
    [MirrorROIPluginFilterOC deselectROIforViewer:self.viewerCT];
    [self.viewerPET needsDisplayUpdate];
    [self.viewerCT needsDisplayUpdate];
    if (!mirroredSomething) {
        [MirrorROIPluginFilterOC alertWithMessage:@"Unable to mirror anything" andTitle:@"Mirror Active ROI" critical:YES];
    }
}

#pragma mark - Delta point
+(NSPoint)deltaXYFromROI:(ROI*)roi2Clone usingLengthROI:(ROI*)lengthROI {
    NSPoint deltaPoint = [self invalidDeltaPoint];
    
    if (roi2Clone && lengthROI) {
        //assume point 1 is ipsi, its OK for x calculations
        NSPoint ipsi = [(MyPoint *)[lengthROI.points objectAtIndex:0] point];
        NSPoint contra  = [(MyPoint *)[lengthROI.points objectAtIndex:1] point];
        // now check ipsi is ipsi
        if (fabs(roi2Clone.textureUpLeftCornerX-ipsi.x)>fabs(roi2Clone.textureUpLeftCornerX-contra.x))
        {//ipsi is really contra so swap
            NSPoint ipsiCopy = ipsi;
            ipsi = contra;
            contra = ipsiCopy;
        }
        
        //magic adds +1 to the delta to fudge edges. But + / - depends o
        /*
         X must be mirrored, so left edge [ must move thus (mirroring is along X axis and within the edges, so left edge stays where it is.
         roi         ipsi            contra    mirrored
         [ABCD]                               [DCBA][dcba]
         -------                  ------
         –––––--------I---------------C-------------
         offset      translation      offset
         |<--------------- delta ----------------->|
         
         delta = 2*offset+translation-width
         offset = (ipsi - ROI leftX)
         width is subtracted as 2xoffset places the left border beyond the delta on right shift and we need to bring it back, and on left shift we need to move it outside the delta
         A negative width increases a negative delta when shifting left and decreases it when shifting right
         ceilf corrects for integer math on textureUpLeftCornerX with floats in the calculation
         */
        
        deltaPoint.x = ceilf((2.0*(ipsi.x-roi2Clone.textureUpLeftCornerX))+(contra.x-ipsi.x)-(roi2Clone.textureWidth));
        
        /*
         Y is not mirrored and must only move by the translation to keep the floor of the texture aligned with the anchor translation.
         */
        deltaPoint.y = floorf(ipsi.y-contra.y);
        
    }
    return deltaPoint;
}
+(BOOL)isValidDeltaPoint:(NSPoint)delta2test{
    return delta2test.x != CGFLOAT_MAX && delta2test.y != CGFLOAT_MAX;
}
+(NSPoint)invalidDeltaPoint{
    return NSMakePoint(CGFLOAT_MAX, CGFLOAT_MAX);
}

#pragma mark - ROI functions
+(ROI*) roiFromList:(NSMutableArray *)roiList WithType:(int)type2Find{
    for (ROI *roi in roiList) {
        if (roi.type == type2Find){
            return roi;}
    }
    return nil;
}
+(ROI*) roiFromList:(NSMutableArray *)roiList WithName:(NSString *)name2Find{
    for (ROI *roi in roiList) {
        if ([roi.name isEqualToString:name2Find]){
            return roi;}
    }
    return nil;
}
+(NSMutableArray*) roiArrayFromList:(NSMutableArray *)roiList WithName:(NSString *)name2Find{
    NSMutableArray *roiarray = [NSMutableArray arrayWithCapacity:roiList.count];
    for (ROI *roi in roiList) {
        if ([roi.name isEqualToString:name2Find]){
            [roiarray addObject:roi];}
    }
    return roiarray;
}
+(NSMutableIndexSet *)indicesInViewer:(ViewerController *)viewer withROIofType:(int)type2Find {
    NSMutableIndexSet *set = [NSMutableIndexSet indexSet];
    for (NSUInteger roiIndex =0; roiIndex<viewer.roiList.count;roiIndex++) {
        NSMutableArray *roisInSlice = [viewer.roiList objectAtIndex:roiIndex];
        for (ROI *roi in roisInSlice) {
            if (roi.type == type2Find)
            {
                [set addIndex:roiIndex];
                break;
            }
        }
    }
    return set;
}
-(NSMutableArray *)arrayOfIndexesOfSlicesWithROIofType:(ROI_Type)type{
    NSString *roiname = [self roiNameForType:type];
    NSMutableArray *arrayOfSlicesIndexes = [NSMutableArray array];
    for (int pix = 0; pix<self.viewerPET.roiList.count; pix++) {
        BOOL foundROI = NO;
        for (ROI *roi in [self.viewerPET.roiList objectAtIndex:pix]) {
            if ([roi.name isEqualToString:roiname]) {
                if (!foundROI) {
                    [arrayOfSlicesIndexes addObject:[NSNumber numberWithInteger:pix]];
                }
                foundROI = YES;
            }
        }
    }
    return arrayOfSlicesIndexes;
}
- (IBAction)moveMirrorROI:(NSButton *)sender {
    int moveX = 0;
    int moveY = 0;
    int moveMirrorBy = (int)[[NSUserDefaults standardUserDefaults] integerForKey:kMirrorMoveByPixels];
    switch (sender.tag) {
        case MoveROI_Up:
            moveY = -moveMirrorBy;
            break;
        case MoveROI_Down:
            moveY = moveMirrorBy;
            break;
        case MoveROI_Right:
            moveX = moveMirrorBy;
            break;
        case MoveROI_Left:
            moveX = -moveMirrorBy;
            break;
        case MoveROI_NE:
            moveY = -moveMirrorBy;
            moveX = moveMirrorBy;
            break;
        case MoveROI_SE:
            moveY = moveMirrorBy;
            moveX = moveMirrorBy;
            break;
        case MoveROI_SW:
            moveY = moveMirrorBy;
            moveX = -moveMirrorBy;
            break;
        case MoveROI_NW:
            moveY = -moveMirrorBy;
            moveX = -moveMirrorBy;
            break;
        default:
            break;
    }
    
    [self moveMirrorROIByAmount:NSMakePoint([[NSNumber numberWithInt:moveX] floatValue],[[NSNumber numberWithInt:moveY] floatValue] )];
}
- (void)moveMirrorROIByAmount:(NSPoint)amount {
    short activeSlice = [[self.viewerPET imageView] curImage];
    NSMutableArray  *roisInAllSlices  = [self.viewerPET roiList];
    NSMutableArray *roisInThisSlice = [roisInAllSlices objectAtIndex:activeSlice];
    for (int i=0; i<roisInThisSlice.count;i++) {
        ROI *roi2Clone = [roisInThisSlice objectAtIndex:i];
        if ([roi2Clone.name isEqualToString:[self roiNameForType:Mirrored_ROI]]) {
            ROI *createdROI = [[ROI alloc]
                               initWithTexture:roi2Clone.textureBuffer
                               textWidth:roi2Clone.textureWidth
                               textHeight:roi2Clone.textureHeight
                               textName:roi2Clone.name
                               positionX:roi2Clone.textureUpLeftCornerX+amount.x
                               positionY:roi2Clone.textureUpLeftCornerY+amount.y
                               spacingX:roi2Clone.pixelSpacingX
                               spacingY:roi2Clone.pixelSpacingY
                               imageOrigin:roi2Clone.imageOrigin];
            [createdROI setNSColor:roi2Clone.NSColor globally:NO];
            
            [roisInThisSlice removeObjectAtIndex:i];
            [self addROI2Pix:createdROI atSlice:activeSlice inViewer:self.viewerPET hidden:NO];
            //move the polygon
            [self deleteROIsInSlice:activeSlice inViewerController:self.viewerCT withName:createdROI.name];
            [self addROItoCTAtSlice:activeSlice forActiveROI:nil mirroredROI:createdROI];
            
            //we found the mirror skip rest
            break;
        }
    }
    
    [self.viewerPET needsDisplayUpdate];
    [self.viewerCT needsDisplayUpdate];
    [self refreshDisplayedDataForCT];
}

#pragma mark - Add Replace ROI
-(void)addTextROI2PixatCurrentSliceInBothViewersWithText:(NSString *)text {
    [self addTextROI2PixatSlice:[[self.viewerPET imageView] curImage] inViewer:self.viewerPET hidden:NO withText:text andColour:kPETtextColour];
    [self addTextROI2PixatSlice:[[self.viewerCT imageView] curImage] inViewer:self.viewerCT hidden:NO withText:text andColour:kCTtextColour];
}
-(void)addTextROI2PixatSlice:(NSUInteger)slice inViewer:(ViewerController *)viewer hidden:(BOOL)hidden withText:(NSString *)text andColour:(NSColor *)colour {
    //override HIDDEN as it makes things locked
    hidden = NO;
    
    [self deleteROIsFromViewerController:viewer withName:text];
    ROI *roi = [viewer newROI:tText];
    [roi setThickness:8.0 globally:NO];//number of points above/below 12 the value is multiplied by 2
    [roi setNSColor:colour globally:NO];
    [roi setName:text];
    [self addROI2Pix:roi atSlice:slice inViewer:viewer hidden:NO];
    NSRect rect= roi.rect;
    rect.origin = NSMakePoint(roi.pix.pwidth*0.5, roi.pix.pheight*[[NSUserDefaults standardUserDefaults] floatForKey:kKeyImageHeightFractionDefault]);
    [roi setROIRect:rect];
    [self.viewerCT setROIToolTag:tROISelector];
    [self.viewerPET setROIToolTag:tROISelector];
}
-(IBAction)addTagRectsToActiveROIinPETviewerForAnatomicalSite:(id)sender {
    if ([self anatomicalSiteDefined]) {
        NSString *site = [self anatomicalSiteName];
        //it objects to modifying roilist while enumerating, so collect info and then do it
        NSMutableArray *slices = [NSMutableArray arrayWithCapacity:self.viewerPET.roiList.count];
        for (NSUInteger i=0; i<self.viewerPET.roiList.count;i++) {
            for (ROI *roi in [self.viewerPET.roiList objectAtIndex:i]) {
                if ([roi.name isEqualToString:[self roiNameForType:Active_ROI]])
                {
                    [slices addObject:[NSArray arrayWithObjects:
                                       [NSNumber numberWithUnsignedInteger:i],
                                       [NSValue valueWithRect:NSMakeRect(roi.textureUpLeftCornerX, roi.textureUpLeftCornerY, roi.textureWidth, roi.textureHeight)], nil]];
                }
            }
        }
        for (NSArray *array in slices) {
            ROI *square = [self.viewerPET newROI:tROI];
            NSUInteger slice = [array[0] unsignedIntegerValue];
            NSRect rect = [array[1] rectValue];
            [square setROIRect:rect];
            [square setNSColor:[NSColor orangeColor] globally:NO];
            [square setName:site];
            [self addROI2Pix:square atSlice:slice inViewer:self.viewerPET hidden:NO];
        }
    }
}
-(void)addROI2Pix:(ROI *)roi2add atSlice:(NSUInteger)slice inViewer:(ViewerController *)viewer hidden:(BOOL)hidden {
    //override HIDDEN as it makes things locked
    //hidden = NO;
    
    if (slice <[[viewer pixList] count] && slice <[[viewer roiList] count])
    {
        //Correct the origin only if the orientation is the same
        DCMPix *pix = [[viewer pixList] objectAtIndex:slice];
        roi2add.pix = pix;
        roi2add.hidden = hidden;
        [roi2add setOriginAndSpacing: pix.pixelSpacingX :pix.pixelSpacingY :[DCMPix originCorrectedAccordingToOrientation: pix]];
        [[viewer.roiList objectAtIndex: slice] addObject: roi2add];
        roi2add.curView = viewer.imageView;
        [MirrorROIPluginFilterOC forceRecomputeDataForROI:roi2add];
    }
    else
    {
        NSLog(@"addROI2Pix: Slice index %li not in range of pixlist %li and roilist %li counts", (long) slice, (long)[[viewer pixList] count], (long)[[viewer roiList] count]);
    }
}
-(void)replaceROIInPix:(ROI *)roi2add atIndex:(NSUInteger)index inSlice:(NSUInteger)slice inViewer:(ViewerController *)viewer hidden:(BOOL)hidden {
    //override HIDDEN as it makes things locked
    hidden = NO;
    
    if (slice <[[viewer pixList] count] && slice <[[viewer roiList] count]
        && index<[[[viewer roiList] objectAtIndex:slice] count])
    {
        //Correct the origin only if the orientation is the same
        DCMPix *pix = [[viewer pixList] objectAtIndex:slice];
        roi2add.pix = pix;
        roi2add.hidden = hidden;
        [roi2add setOriginAndSpacing: pix.pixelSpacingX :pix.pixelSpacingY :[DCMPix originCorrectedAccordingToOrientation: pix]];
        [[viewer.roiList objectAtIndex: slice] replaceObjectAtIndex:index withObject:roi2add];
        roi2add.curView = viewer.imageView;
        [MirrorROIPluginFilterOC forceRecomputeDataForROI:roi2add];
    }
}
-(void)addROItoCTAtSlice:(NSUInteger)slice forActiveROI:(ROI *)activeROI mirroredROI:(ROI *)mirroredROI {
    if ([self valid2DViewer:self.viewerCT])
    {
        if (activeROI) {
            ROI *aP = [activeROI copy];
            aP.locked = NO;
            [self addROI2Pix:aP atSlice:slice inViewer:self.viewerCT hidden:NO];
        }
        if (mirroredROI) {
            ROI *mP = [mirroredROI copy];
            mP.locked = NO;
            [self addROI2Pix:mP atSlice:slice inViewer:self.viewerCT hidden:NO];
        }
    }
}

#pragma mark - Delete Rename ROIs
+(BOOL)roiOKtoDelete:(ROI *)r {
    return (r.type != tText && r.type != tROI);
}
-(void)deleteTransformsFromViewer:(ViewerController *)viewer {
    [self unlockROIsIn2DViewer:viewer withSeriesName:nil];
    NSMutableArray *rois2delete = [NSMutableArray array];
    for (NSMutableArray *roisinslice in [viewer roiList]) {
        for (ROI *roi in roisinslice) {
            if (roi.type == tMesure) {
                [MirrorROIPluginFilterOC unlockROI:roi];
                [rois2delete addObject:roi];
            }
        }
    }
    [ROI deleteROIs:rois2delete];
}

- (IBAction)deleteActiveViewerROIsOfType:(NSButton *)sender {
    
    switch (sender.tag) {
        case TextRectangleROIs:
            [self clearLabelsInViewer:self.viewerCT];
            [self clearLabelsInViewer:self.viewerPET];
            break;
        case MirroredAndActive_ROI:
            [self deleteROIsFromViewerController:self.viewerPET withName:[self roiNameForType:Active_ROI]];
            [self deleteROIsFromViewerController:self.viewerPET withName:[self roiNameForType:Mirrored_ROI]];
            break;
        case GrowingRegion:
        case Active_ROI:
            [self deleteROIsFromViewerController:self.viewerPET withName:[self roiNameForType:sender.tag]];
            break;
        case Jiggle_ROI:
            [self clearJiggleROIsAndValuesAndResetDisplayed];
            break;
        case Transform_ROI_Placed:
            [self deleteROIsFromViewerController:self.viewerPET withName:[self roiNameForType:Transform_ROI_Placed]];
            [self deleteROIsFromViewerController:self.viewerCT withName:[self roiNameForType:Transform_ROI_Placed]];
        case AllROI_CT:
            [self deleteAllROIsFromViewerController:self.viewerCT];
            break;
        case AllROI_PET:
            [self deleteAllROIsFromViewerController:self.viewerPET];
            break;
        case AllROI:
            [self deleteAllROIsFromViewerController:self.viewerPET];
            [self deleteAllROIsFromViewerController:self.viewerCT];
            break;
            
        default:
            break;
    }
}
+(void)unlockROI:(ROI*)roi {
    roi.locked = NO;
    roi.hidden = NO;//triggers locked!!!
}
-(void)unlockROIsIn2DViewer:(ViewerController *)viewer withSeriesName:(NSString *)name{
    for (NSMutableArray *roiIndex in viewer.roiList) {
        for (ROI *roi in roiIndex) {
            if (name == nil || [roi.name isEqualToString:name]) {
                [MirrorROIPluginFilterOC unlockROI:roi];
            }
        }
    }
}
-(void)clearLabelsInViewer:(ViewerController *)active2Dwindow{
    NSMutableArray *roisToDelete = [NSMutableArray arrayWithCapacity:active2Dwindow.roiList.count];
    for (NSUInteger roiIndex =0; roiIndex<active2Dwindow.roiList.count;roiIndex++) {
        for (ROI *roi in [active2Dwindow.roiList objectAtIndex:roiIndex]) {
            if (roi.type == tText || roi.type == tROI ) {
                [MirrorROIPluginFilterOC unlockROI:roi];
                [roisToDelete addObject:roi];
            }
        }
    }
    [ROI deleteROIs: roisToDelete];
    [active2Dwindow needsDisplayUpdate];
}

- (void)deleteROIsFromViewerController:(ViewerController *)active2Dwindow withName:(NSString *)name {
    if (active2Dwindow)
    {
        [self unlockROIsIn2DViewer:active2Dwindow withSeriesName:name];
        [active2Dwindow deleteSeriesROIwithName:name];
        [active2Dwindow needsDisplayUpdate];
        if (active2Dwindow == self.viewerCT) {
            [self resetJiggleControlsAndRefresh];
        }
    }
}
- (void)deleteROIsInSlice:(NSUInteger)slice inViewerController:(ViewerController *)active2Dwindow withName:(NSString *)name {
    if (active2Dwindow && slice<active2Dwindow.roiList.count)
    {
        [self unlockROIsIn2DViewer:active2Dwindow withSeriesName:name];
        NSMutableArray *roisInSlice = [active2Dwindow.roiList objectAtIndex:slice];
        NSMutableArray *roisToDelete = [NSMutableArray arrayWithCapacity:roisInSlice.count];
        for (NSUInteger i = 0; i<[roisInSlice count];i++) {
            ROI *roi = [roisInSlice objectAtIndex:i];
            if ([roi.name isEqualToString:name]) {
                [MirrorROIPluginFilterOC unlockROI:roi];
                [roisToDelete addObject:roi];
            }
        }
        [ROI deleteROIs: roisToDelete];
        [active2Dwindow needsDisplayUpdate];
        if (active2Dwindow == self.viewerCT && [name isEqualToString:kJiggleROIName]) {
            [self resetJiggleControlsAndRefresh];
        }
    }
}
- (void)deleteAllROIsFromViewerController:(ViewerController *)active2Dwindow {
    if (active2Dwindow)
    {
        [self unlockROIsIn2DViewer:active2Dwindow withSeriesName:nil];
        NSMutableArray *roisToDelete = [NSMutableArray array];
        for (NSUInteger pixIndex = 0; pixIndex < [[active2Dwindow roiList] count]; pixIndex++)
        {
            for(ROI	*curROI in [[active2Dwindow roiList] objectAtIndex: pixIndex])
            {
                BOOL ok = [MirrorROIPluginFilterOC roiOKtoDelete:curROI];
                if (ok) {
                    [MirrorROIPluginFilterOC unlockROI:curROI];
                    [roisToDelete addObject: curROI];
                }
            }
        }
        
        [ROI deleteROIs: roisToDelete];
        
        if (active2Dwindow == self.viewerCT) {[self clearJiggleROIsAndValuesAndResetDisplayed];}
        [active2Dwindow needsDisplayUpdate];
    }
}
- (void)renameROIsInSlice:(NSUInteger)slice inViewerController:(ViewerController *)active2Dwindow containingName:(NSString *)name withNewName:(NSString *)newName{
    if (active2Dwindow && slice<active2Dwindow.roiList.count)
    {
        for (ROI *roi in [active2Dwindow.roiList objectAtIndex:slice]) {
            if ([roi.name containsString:name]) {
                roi.name = newName;
            }
        }
        [active2Dwindow needsDisplayUpdate];
    }
}

#pragma mark - Buffer
+(unsigned char*)flippedBufferHorizontalFromROI:(ROI *)roi2Clone{
    int textureBuffer_Length = roi2Clone.textureHeight * roi2Clone.textureWidth;
    int textureBuffer_Width = roi2Clone.textureWidth;
    int textureBuffer0Width = textureBuffer_Width-1;
    
    unsigned char   *tempBuffer = (unsigned char*)malloc(textureBuffer_Length*sizeof(unsigned char));
    
    for (int pixelIndex = 0; pixelIndex<textureBuffer_Length; pixelIndex+=textureBuffer_Width) {
        //copy the row mask
        //invert the mask to flip horizontal
        for (int col=0; col<textureBuffer_Width; col++) {
            tempBuffer[pixelIndex+col] = roi2Clone.textureBuffer[pixelIndex+textureBuffer0Width-col];
        }
    }
    return tempBuffer;
}

#pragma mark - Colour
- (IBAction)colourWellAction:(NSColorWell *)sender {
    [[NSUserDefaults standardUserDefaults] setObject:[NSArchiver archivedDataWithRootObject:sender.color] forKey:sender.identifier];
}
+(NSColor *)colourFromData:(NSData *)data {
    if (data != nil) return (NSColor *)[NSUnarchiver unarchiveObjectWithData:data];
    return [NSColor blackColor];
}
+(NSColor *)colourForType:(ROI_Type)type {
    NSColor *colour = [NSColor blackColor];
    switch (type) {
        case GrowingRegion:
            colour = [NSColor greenColor];
            break;
        case Active_ROI:
            colour = [MirrorROIPluginFilterOC colourFromData:[[NSUserDefaults standardUserDefaults] dataForKey:kColor_Active]];
            break;
        case Mirrored_ROI:
            colour = [MirrorROIPluginFilterOC colourFromData:[[NSUserDefaults standardUserDefaults] dataForKey:kColor_Mirrored]];
            break;
        case Transform_ROI_Placed:
            colour = [MirrorROIPluginFilterOC colourFromData:[[NSUserDefaults standardUserDefaults] dataForKey:kColor_TransformPlaced]];
            break;
        case Transform_Intercalated:
            colour = [MirrorROIPluginFilterOC colourFromData:[[NSUserDefaults standardUserDefaults] dataForKey:kColor_TransformIntercalated]];
            break;
        case Jiggle_ROI:
            colour = [MirrorROIPluginFilterOC colourFromData:[[NSUserDefaults standardUserDefaults] dataForKey:kColor_Jiggle]];
            break;
        default:
            break;
    }
    return colour;
}
-(NSString *)roiNameForType:(ROI_Type)type {
    switch (type) {
        case GrowingRegion:
            return [[NSUserDefaults standardUserDefaults] objectForKey:kGrowingRegionROInameDefault];
            break;
        case Active_ROI:
            return [[NSUserDefaults standardUserDefaults] objectForKey:kActiveROInameDefault];
            break;
        case Mirrored_ROI:
            return [[NSUserDefaults standardUserDefaults] objectForKey:kMirroredROInameDefault];
            break;
        case Transform_ROI_Placed:
        case Transform_Intercalated:
            return [[NSUserDefaults standardUserDefaults] objectForKey:kTransformROInameDefault];
            break;
        case MirroredAndActive_ROI:
            return [NSString stringWithFormat:@"%@-%@",[self roiNameForType:Active_ROI],[self roiNameForType:Mirrored_ROI]];
            break;
        default:
            return @"";
            break;
    }
}

+(void)setROIcolour:(ROI *)roi forType:(ROI_Type)type {
    [roi setNSColor:[[MirrorROIPluginFilterOC colourForType:type] colorWithAlphaComponent:0.5] globally:NO];
}

#pragma mark - ROI Data
+(void)forceRecomputeDataForROI:(ROI *)roi {
    if (roi != nil) {
        [roi recompute];
        [roi computeROIIfNedeed];
    }
}
-(ROI *)ROIfromCurrentSliceInViewer:(ViewerController *)viewer withName:(NSString *)name {
    if (viewer != nil)
    {
        return [self ROIfromSlice:[[viewer imageView] curImage] inViewer:viewer withName:name];
    }
    return nil;
}
-(ROI *)ROIfromSlice:(NSInteger)slice inViewer:(ViewerController *)viewer withName:(NSString *)name {
    if (viewer != nil && slice<viewer.roiList.count)
    {
        for (ROI *roi in [[viewer roiList] objectAtIndex:slice]) {
            if ([roi.name isEqualToString:name]) {
                return roi;
            }
        }
    }
    return nil;
}
-(ROI *)ROIfromFirstMatchedSliceInViewer:(ViewerController *)viewer withName:(NSString *)name {
    if (viewer != nil)
    {
        for (int pixIndex=0; pixIndex<viewer.roiList.count; pixIndex++) {
            for (ROI *roi in [[viewer roiList] objectAtIndex:pixIndex]) {
                if ([roi.name isEqualToString:name]) {
                    return roi;
                }
            }
        }
    }
    return nil;
}

#pragma mark - anatomicalSite
-(NSString *)anatomicalSiteName {
    return self.comboAnatomicalSite.stringValue;
}
-(void)setAnatomicalSiteName:(NSString *)name {
    self.comboAnatomicalSite.stringValue = name;
    [self.comboAnatomicalSite becomeFirstResponder];
    [[self.comboAnatomicalSite currentEditor] setSelectedRange: NSMakeRange(0, name.length)];
}
-(NSString *)dividerForExportFileFromAnatomicalSite:(NSString *)anatomicalSite {
    return [NSString stringWithFormat:@"#   %@   ############################################",anatomicalSite];
}
-(BOOL)anatomicalSiteDefined {
    if (self.comboAnatomicalSite.stringValue.length > 0)
    {
        return YES;
    }
    else
    {
        [MirrorROIPluginFilterOC alertWithMessage:@"No anatomical site is entered - please enter a description and try again." andTitle:@"Anatomical Site Undefined" critical:YES];
        return NO;
    }
    
}

#pragma mark - Database Comments & Reports
- (void)attachDatabaseReportBookmarksDataFileAtURL:(NSURL*)url {
    DicomStudy *study = [self.viewerPET currentStudy];
    [[BrowserController currentBrowser] importReport:url.path UID:study.studyInstanceUID];
}
-(NSString *)participantDetailsString {
    DicomStudy *study = [self.viewerPET currentStudy];
    return [NSString stringWithFormat:@"%@\t%@\nVaccine\tScan Day\tActive Site\tPlacebo\tComments\n%@\t%@\nSeries Analysed: %@",study.name,study.patientID,study.comment,study.comment2,[self petSeriesNameWithNoBadCharacters:NO]];
}
-(NSString *)participantNameVaccineDay1Line {
    DicomStudy *study = [self.viewerPET currentStudy];
    NSArray *commentsArray = [[study comment] componentsSeparatedByString:@"\t"];
    return [NSString stringWithFormat:@"%@\t%@\t%@",
            [MirrorROIPluginFilterOC correctedStringForNullString:study.name],
            [MirrorROIPluginFilterOC correctedStringForNullString:[commentsArray objectAtIndex:ComboArray_Vaccine]],
            [MirrorROIPluginFilterOC correctedStringForNullString:[commentsArray objectAtIndex:ComboArray_Day]]];
}
-(NSMutableArray *)participantNameVaccineArray {
    NSMutableArray *array = [NSMutableArray array];
    DicomStudy *study = [self.viewerPET currentStudy];
    NSArray *commentsArray = [[study comment] componentsSeparatedByString:@"\t"];
    [array addObject:[NSArray arrayWithObjects:@"# Name",[MirrorROIPluginFilterOC correctedStringForNullString:study.name], nil]];
    [array addObject:[NSArray arrayWithObjects:@"Vaccine",[MirrorROIPluginFilterOC correctedStringForNullString:[commentsArray objectAtIndex:ComboArray_Vaccine]], nil]];
    [array addObject:[NSArray arrayWithObjects:@"Day",[MirrorROIPluginFilterOC correctedStringForNullString:[commentsArray objectAtIndex:ComboArray_Day]], nil]];
    return array;
}
-(NSMutableArray *)participantDetailsArray {
    DicomStudy *study = [self.viewerPET currentStudy];
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:5];
    [array addObject:[[NSString stringWithFormat:@"%@",study.name] stringByReplacingOccurrencesOfString:@"\t" withString:@" "]];
    [array addObject:[[NSString stringWithFormat:@"%@",study.patientID]stringByReplacingOccurrencesOfString:@"\t" withString:@" "]];
    [array addObject:[[NSString stringWithFormat:@"%@",study.comment]stringByReplacingOccurrencesOfString:@"\t" withString:@" "]];
    [array addObject:[[NSString stringWithFormat:@"%@",study.comment2]stringByReplacingOccurrencesOfString:@"\t" withString:@" "]];
    [array addObject:[[NSString stringWithFormat:@"%@",[self petSeriesNameWithNoBadCharacters:NO]]stringByReplacingOccurrencesOfString:@"\t" withString:@" "]];
    return array;
}

-(NSString *)participantID {
    return [[self.viewerPET currentStudy] patientID];
}
+(NSString *)correctedStringForNullString:(NSString *)string {
    if (string == nil) {return @"";}
    return string;
}
-(IBAction)clearTreatmentFieldsTapped:(id)sender {
    [self clearTreatmentFields];
}
-(void)clearTreatmentFields {
    self.labelDicomStudy.stringValue = @"";
    self.comboVaccines.stringValue = @"";
    self.comboTreatmentSite.stringValue = @"";
    self.textFieldVaccineDayOffset.stringValue = @"";
    self.textViewComments2.string = @"";
    self.comboPlaceboUsed.stringValue = @"";
    
}
-(void)populateTreatmentFieldsFromCommentsWithStudy:(DicomStudy *)selectedStudy {
    //if (self.windowControllerMain.window.visible) {
    if (selectedStudy == nil) { selectedStudy = [[BrowserController currentBrowser] selectedStudy];}
    if (selectedStudy == nil || (self.viewerPET != nil && ![selectedStudy.name isEqualToString:[[self.viewerPET currentStudy] name]])) {
        self.textFieldWarningPatientDetails.stringValue = @"⚠️";
    } else {
        self.textFieldWarningPatientDetails.stringValue = @"";
        self.labelDicomStudy.stringValue = [MirrorROIPluginFilterOC correctedStringForNullString:selectedStudy.name];
        NSArray *commentsArray = [[selectedStudy comment] componentsSeparatedByString:@"\t"];
        if (commentsArray.count >= 4) {
            self.comboVaccines.stringValue = [MirrorROIPluginFilterOC correctedStringForNullString:[commentsArray objectAtIndex:ComboArray_Vaccine]];
            self.textFieldVaccineDayOffset.stringValue = [MirrorROIPluginFilterOC correctedStringForNullString:[commentsArray objectAtIndex:ComboArray_Day]];
            self.comboTreatmentSite.stringValue = [MirrorROIPluginFilterOC correctedStringForNullString:[commentsArray objectAtIndex:ComboArray_TreatmentSite]];
            self.comboPlaceboUsed.stringValue = [MirrorROIPluginFilterOC correctedStringForNullString:[commentsArray objectAtIndex:ComboArray_PlaceboUsed]];
        } else {
            [self clearTreatmentFields];
        }
        self.textViewComments2.string = [MirrorROIPluginFilterOC correctedStringForNullString:[selectedStudy comment2]];
    }
    //    }
}
+(NSString *)dayOffsetWithLeadingZerosFromString:(NSString *)string {
    if (string == nil) return @"";
    if ([string hasPrefix:@"0"]) return string;
    if ([string floatValue] <10) {
        string = [@"0" stringByAppendingString:string];
    }
    return string;
}
-(IBAction)readWriteCommentsFromFieldsTapped:(NSButton *)sender {
    switch (sender.tag) {
        case WriteComments:
        {
            DicomStudy *selectedStudy = [[BrowserController currentBrowser] selectedStudy];//[self.viewerPET currentStudy]
            [selectedStudy setComment:[NSString stringWithFormat:@"%@\t%@\t%@\t%@",
                                       [MirrorROIPluginFilterOC correctedStringForNullString:self.comboVaccines.stringValue],
                                       [MirrorROIPluginFilterOC dayOffsetWithLeadingZerosFromString:self.textFieldVaccineDayOffset.stringValue],
                                       [MirrorROIPluginFilterOC correctedStringForNullString:self.comboTreatmentSite.stringValue],
                                       [MirrorROIPluginFilterOC correctedStringForNullString:self.comboPlaceboUsed.stringValue]
                                       ]];
            [selectedStudy setComment2:[MirrorROIPluginFilterOC correctedStringForNullString:self.textViewComments2.string]];
        }
            break;
        case ReadComments:
            [self populateTreatmentFieldsFromCommentsWithStudy:[[BrowserController currentBrowser] selectedStudy]];
            break;
            
        default:
            break;
    }
}

#pragma mark - Key Images
- (IBAction)keyImageTapped:(NSButton*)sender {
    [self setKeyImageInCurrentViews:sender.tag];
}
-(void)setKeyImageInCurrentViews:(KeyImageSetting)setKey {
    switch (setKey) {
        case KeyImageOff:
            if ([self.viewerPET isKeyImage:[self.viewerPET.imageView curImage]]) {
                [self.viewerPET setKeyImage:nil];
            }
            if ([self.viewerCT isKeyImage:[self.viewerCT.imageView curImage]]) {
                [self.viewerCT setKeyImage:nil];
            }
            break;
        case KeyImageOn:
            if ([self anatomicalSiteDefined]) {
                [self addTextROI2PixatCurrentSliceInBothViewersWithText:[self anatomicalSiteName]];
                //setKeyImage toggles, so only toggle ON
                if (![self.viewerPET isKeyImage:[self.viewerPET.imageView curImage]]) {
                    [self.viewerPET setKeyImage:nil];
                }
                if (![self.viewerCT isKeyImage:[self.viewerCT.imageView curImage]]) {
                    [self.viewerCT setKeyImage:nil];
                }
                if ([MirrorROIPluginFilterOC userDefaultBooleanForKey:kExportKeyImagesWhenSetting]) {
                    [self exportKeyImagesFromViewersTypes:CTandPET_Windows];
                }
            }
            break;
        default:
            break;
    }
}
-(IBAction)exportKeyImagesFromViewersTypesTapped:(id)sender {
    [self exportKeyImagesFromViewersTypes:CTandPET_Windows];
}
-(void)exportKeyImagesFromViewersTypes:(ViewerWindow_Type)types {
    NSMutableArray *arrayKeyImagesData = [NSMutableArray array];
    switch (types) {
        case PET_Window:
            arrayKeyImagesData = [self arrayKeyImagesFromViewer:self.viewerPET];
            break;
        case CT_Window:
            arrayKeyImagesData = [self arrayKeyImagesFromViewer:self.viewerCT];
            break;
        case CTandPET_Windows:
            arrayKeyImagesData = [self arrayKeyImagesFromViewer:self.viewerPET];
            [arrayKeyImagesData addObjectsFromArray:[self arrayKeyImagesFromViewer:self.viewerCT]];
            break;
        default:
            break;
    }
    [self saveImageFilesFromArray:arrayKeyImagesData];
}
-(NSString *)imageFileNameForIndex:(int)index andViewer:(ViewerController *)viewer {
    return [MirrorROIPluginFilterOC fileNameWithNoBadCharacters:[NSString stringWithFormat:@"%@-%04li.png",viewer.window.title,(long)index]];
}
-(NSMutableArray *)arrayKeyImagesFromViewer:(ViewerController *)viewer {
    NSMutableArray *arrayKeyImagesData = [NSMutableArray array];
    int pixIndex = [viewer.imageView curImage];
    NSImage *image = [viewer.imageView exportNSImageCurrentImageWithSize:0];//size 0 avoids rescale which destroys image??;
    //[self.imageViewTempy setImage:image];
    
    NSData *tiffData = [image TIFFRepresentation];
    NSBitmapImageRep *bitmapData = [NSBitmapImageRep imageRepWithData:tiffData];
    NSData *pngData = [bitmapData representationUsingType:NSBitmapImageFileTypePNG properties:[NSDictionary dictionary]];
    NSMutableDictionary *imageAndFilenameDict = [NSMutableDictionary dictionary];
    [imageAndFilenameDict setObject:[self imageFileNameForIndex:pixIndex andViewer:viewer] forKey:@"name"];
    [imageAndFilenameDict setObject:pngData forKey:@"data"];
    [arrayKeyImagesData addObject:imageAndFilenameDict];
    
    return arrayKeyImagesData;
}
-(void)saveImageFilesFromArray:(NSMutableArray *)arrayOfFileNamesAndImages {
    if (arrayOfFileNamesAndImages.count > 0)
    {
        NSOpenPanel* panel = [NSOpenPanel openPanel];
        [panel setCanChooseDirectories:YES];
        [panel setCanCreateDirectories:YES];
        [panel setCanChooseFiles:NO];
        [panel setAllowsMultipleSelection:NO];
        [panel setMessage:@"Select location to save Key Image files"];
        
        if ([panel runModal] == NSFileHandlingPanelOKButton) {
            NSURL *dirUrl = [panel.URLs objectAtIndex:0];
            for (NSMutableDictionary* filenameImageDict in arrayOfFileNamesAndImages) {
                NSData *imageData = [filenameImageDict objectForKey:@"data"];
                NSString *filename = [MirrorROIPluginFilterOC fileNameWithNoBadCharacters:[filenameImageDict objectForKey:@"name"]];
                NSURL *fileURL = [dirUrl URLByAppendingPathComponent:filename];
                [imageData writeToURL:fileURL atomically:YES];
            }
        }
    }
}

#pragma mark - Bookmarks
- (IBAction)addSubtractTrashExportViewBookmarks:(NSButton *)sender {
    switch (sender.tag) {
        case BookmarkAdd:
            [self addBookmarkDataForCurrentSite];
            break;
        case BookmarkSubtract:
            [self subtractBookmarkDataForSelectedSite];
            break;
        case BookmarkTrash:
            [self trashAllBookmarks];
            break;
        case BookmarkExport:
            [self exportBookmarkedData:ExportAsFile];
            break;
        case Bookmark1LineExport:
            [self exportBookmarkedData:ExportAs1LineFile];
            break;
        case BookmarkQuickLook:
            [self exportBookmarkedData:ViewInWindow];
            break;
        case BookmarkPLISTimport:
            [self bookmarkedDataImport];
            break;
        default:
            break;
    }
}
-(void)subtractBookmarkDataForSelectedSite {
    if ([self.arrayControllerBookmarks.arrangedObjects count] > 0 && [MirrorROIPluginFilterOC proceedAfterAlert:@"Delete selected bookmarked data? This cannot be undone"]) {
        [self.arrayControllerBookmarks.selectionIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
            if (index < [self.arrayControllerBookmarks.arrangedObjects count]) {
                [self.dictBookmarks removeObjectForKey:[self.arrayControllerBookmarks.arrangedObjects objectAtIndex:index]];
            }
        }];
        [self.arrayControllerBookmarks removeObjectsAtArrangedObjectIndexes:self.arrayControllerBookmarks.selectionIndexes];
    }
}
-(void)trashAllBookmarks {
    //easier to use this method to clear the array
    if ([self.arrayControllerBookmarks.arrangedObjects count] > 0 && [MirrorROIPluginFilterOC proceedAfterAlert:@"Delete all bookmarked data? This cannot be undone"]) {
        //        [self willChangeValueForKey:@"arrayBookmarkedSites"];
        //        [self.arrayBookmarkedSites removeAllObjects];
        //        [self didChangeValueForKey:@"arrayBookmarkedSites"];
        [self.arrayControllerBookmarks setContent:[NSMutableArray array]];
        [self.dictBookmarks removeAllObjects];
    }
}
-(void)addBookmarkDataForCurrentSite {
    if ([self anatomicalSiteDefined]) {
        NSString *anatSite = [self anatomicalSiteName];
        // arrayControllerBookmarks just lists the names of the bookmarks
        [self.arrayControllerBookmarks removeObject:anatSite];//erase to replace
        [self.arrayControllerBookmarks addObject:anatSite];
        
        //self.dictBookmarks is a dict of sites, each site has a dict - each dict has 2 strings, for summary and for pixels
        [self.dictBookmarks setObject:[self bookmarkDictForSite:anatSite] forKey:anatSite];
    }
}
-(NSMutableDictionary *)bookmarkDictForSite:(NSString *)anatSite {
    //Do 3D calculation FIRST as this resets the pixels nicely
    NSMutableDictionary *data3D_A = [self dataDictFor3DROIdataForType:Active_ROI];
    NSMutableDictionary *data3D_M = [self dataDictFor3DROIdataForType:Mirrored_ROI];
    //now get raw pixels
    NSMutableDictionary *dictRaw = [self dataDictForRawPixelsDeltaForSite:anatSite];
    
    NSMutableDictionary *dictForSite = [NSMutableDictionary dictionaryWithCapacity:3];
    
    NSData *rois =[self archivedArrayOFAMTroisForSite:anatSite];
    if (rois != nil) dictForSite[kBookmarkKeyAMTrois] = rois;
    dictForSite[kBookmarkKeyPixelsGrids] = [self dataStringRawPixelsFromDict:dictRaw];
    dictForSite[kBookmarkKeyXYZTaggedPixelsGrids] = [self dataStringfromTaggedXYZPixelsArrays:[dictRaw objectForKey:kDeltaNameXYZTaggedRawPixelDataTag]];
    dictForSite[kBookmarkKeyPixelsGridsNotYetTransposedArray] = [dictRaw objectForKey:kDeltaNameAMSDPix1LineTransposedArray];
    dictForSite[kBookmarkKey1LineSummary] = [self dataStringFor1LineSummaryFromRawDict:dictRaw dict3D:data3D_A forSite:anatSite];
    dictForSite[kBookmarkKeySummary] =
    [NSString stringWithFormat:
     @"ROI\tMean\tSEM\t#Pixels\tSD\tMax\tMin\tTotal\tVolume\n"
     "%@ %@ Active (3D):\t%@\t%@\t%@\t%@\t%@\t%@\t%@\t%@\n"
     "%@ %@ Active:\t%@\t%@\t%@\t%@\t%@\t%@\t%@\t%@\n"
     @"%@"
     ,
     [self participantID],anatSite, data3D_A[@"mean"],@"",@"",data3D_A[@"dev"],data3D_A[@"max"],data3D_A[@"min"],data3D_A[@"total"],data3D_A[@"volume"],
     [self participantID],anatSite, dictRaw[kDeltaNameActiveMean],dictRaw[kDeltaNameActiveSEM],dictRaw[kDeltaNameCount],dictRaw[kDeltaNameActiveSD],dictRaw[kDeltaNameActiveMax],dictRaw[kDeltaNameActiveMin],dictRaw[kDeltaNameActiveSum],data3D_A[@"volume"],
     [self dataStringForMirroredSubtractedDividedDataFromRawDict:dictRaw dict3D_M:data3D_M forSite:anatSite]
     ];
    
    //chuck in the whole 3Ddata dicts as they are just strings EXCEPT for rois which cannot be archived
    NSMutableDictionary *dict3DAcleaned = [NSMutableDictionary dictionaryWithCapacity:data3D_A.count-1];
    for (NSString *key in data3D_A.allKeys) {
        if (![key isEqualToString:@"rois"]) {
            dict3DAcleaned[key] = data3D_A[key];
        }
    }
    dictForSite[kBookmarkKeyDataDict_3DA] = dict3DAcleaned;
    NSMutableDictionary *dict3DMcleaned = [NSMutableDictionary dictionaryWithCapacity:data3D_M.count-1];
    for (NSString *key in data3D_A.allKeys) {
        if (![key isEqualToString:@"rois"]) {
            dict3DMcleaned[key] = data3D_M[key];
        }
    }
    //add the two columns of data for A and M pixels for convenience
    dictForSite[kPixelsAMvertical] = [self dataDictForROIpixelsFromDictA:data3D_A andDictM:data3D_M forSite:anatSite];
    
    dictForSite[kBookmarkKeyDataDict_3DM] = dict3DMcleaned;
    //extract the numbers from dictRaw into a new dict. dictRaw shoud be safe as has been initialised but it cannot be just included as it has non-archivable content
    dictForSite[kBookmarkKeyDataDict_Raw] = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                             dictRaw[kDeltaNameCount],kDeltaNameCount,
                                             dictRaw[kDeltaNameActiveMean],kDeltaNameActiveMean,
                                             dictRaw[kDeltaNameActiveSD],kDeltaNameActiveSD,
                                             dictRaw[kDeltaNameActiveSEM],kDeltaNameActiveSEM,
                                             dictRaw[kDeltaNameActiveMax],kDeltaNameActiveMax,
                                             dictRaw[kDeltaNameActiveMin],kDeltaNameActiveMin,
                                             dictRaw[kDeltaNameActiveSum],kDeltaNameActiveSum,
                                             dictRaw[kDeltaNameMirroredMean],kDeltaNameMirroredMean,
                                             dictRaw[kDeltaNameMirroredSD],kDeltaNameMirroredSD,
                                             dictRaw[kDeltaNameMirroredSEM],kDeltaNameMirroredSEM,
                                             dictRaw[kDeltaNameMirroredMax],kDeltaNameMirroredMax,
                                             dictRaw[kDeltaNameMirroredMin],kDeltaNameMirroredMin,
                                             dictRaw[kDeltaNameMirroredSum],kDeltaNameMirroredSum,
                                             dictRaw[kDeltaNameDividedMean],kDeltaNameDividedMean,
                                             dictRaw[kDeltaNameDividedSD],kDeltaNameDividedSD,
                                             dictRaw[kDeltaNameDividedSEM],kDeltaNameDividedSEM,
                                             dictRaw[kDeltaNameDividedPixMin],kDeltaNameDividedPixMin,
                                             dictRaw[kDeltaNameDividedPixMax],kDeltaNameDividedPixMax,
                                             dictRaw[kDeltaNameDividedPixTotal],kDeltaNameDividedPixTotal,
                                             dictRaw[kDeltaNameSubtractedMean],kDeltaNameSubtractedMean,
                                             dictRaw[kDeltaNameSubtractedSD],kDeltaNameSubtractedSD,
                                             dictRaw[kDeltaNameSubtractedSEM],kDeltaNameSubtractedSEM,
                                             dictRaw[kDeltaNameSubtractedPixMin],kDeltaNameSubtractedPixMin,
                                             dictRaw[kDeltaNameSubtractedPixMax],kDeltaNameSubtractedPixMax,
                                             dictRaw[kDeltaNameSubtractedPixTotal],kDeltaNameSubtractedPixTotal,
                                             nil];
    
    return dictForSite;
}

-(NSString *) dataStringfromTaggedXYZPixelsArrays:(NSMutableArray *)taggedPixelsArray {
    NSMutableArray *lines = [NSMutableArray array];
    for (NSMutableArray *slice in taggedPixelsArray) {
        // each slice has hopefully only one roi otherwise we are in stum
        for (NSMutableArray *roi in slice) {
            // each roi has an array of tagged pixels
            for (NSMutableArray *pixels in roi) {
                // each pixel has a value and then XYZ as floats in a 4 element array
                for (NSMutableArray *pixel in pixels) {
                    [lines addObject: [pixel componentsJoinedByString:@"\t"]];
                }
            }
        }
    }
    
    return [lines componentsJoinedByString:@"\n"]; //@"\n\ndataStringfromTaggedXYZPixelsArrays\n\n";
}

-(NSString *)dataStringForMirroredSubtractedDividedDataFromRawDict:(NSMutableDictionary *)dictRaw dict3D_M:(NSMutableDictionary *)data3D_M forSite:(NSString *)anatSite {
    //kDeltaNameDividedMean is a number or ""
    if ([[dictRaw[kDeltaNameDividedMean] description] length]>0) {
        return [NSString stringWithFormat:
                @"%@ %@ Divided:\t%@\t%@\t%@\t%@\t%@\t%@\t%@\t%@\n"
                "%@ %@ Subtracted:\t%@\t%@\t%@\t%@\t%@\t%@\t%@\t%@\n"
                "%@ %@ Mirrored:\t%@\t%@\t%@\t%@\t%@\t%@\t%@\t%@\n"
                "%@ %@ Mirrored (3D):\t%@\t%@\t%@\t%@\t%@\t%@\t%@\t%@\n"
                ,
                [self participantID],anatSite, dictRaw[kDeltaNameDividedMean],dictRaw[kDeltaNameDividedSEM],dictRaw[kDeltaNameCount],dictRaw[kDeltaNameDividedSD],dictRaw[kDeltaNameDividedPixMax],dictRaw[kDeltaNameDividedPixMin],dictRaw[kDeltaNameDividedPixTotal],@"",
                [self participantID],anatSite, dictRaw[kDeltaNameSubtractedMean],dictRaw[kDeltaNameSubtractedSEM],dictRaw[kDeltaNameCount],dictRaw[kDeltaNameSubtractedSD],dictRaw[kDeltaNameSubtractedPixMax],dictRaw[kDeltaNameSubtractedPixMin],dictRaw[kDeltaNameSubtractedPixTotal],@"",
                [self participantID],anatSite, dictRaw[kDeltaNameMirroredMean],dictRaw[kDeltaNameMirroredSEM],dictRaw[kDeltaNameCount],dictRaw[kDeltaNameMirroredSD],dictRaw[kDeltaNameMirroredMax],dictRaw[kDeltaNameMirroredMin],dictRaw[kDeltaNameMirroredSum],@"",
                [self participantID],anatSite, data3D_M[@"mean"],@"",@"",data3D_M[@"dev"],data3D_M[@"max"],data3D_M[@"min"],data3D_M[@"total"],data3D_M[@"volume"]
                
                ];
    }
    return @"";
}
-(NSMutableDictionary *)dataDictForROIpixelsFromDictA:(NSMutableDictionary *)dictA andDictM:(NSMutableDictionary *)dictM forSite:(NSString *)site{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"site"] = site;
    NSMutableArray *array = [NSMutableArray arrayWithArray:[self participantNameVaccineArray]];
    [array addObject:[NSArray arrayWithObjects:@"Site",site, nil]];
    [array addObject:[NSArray arrayWithObjects:@"VOLUME",dictA[@"volume"], nil]];
    //if ([dictA[@"pixels"] count]>0)
    {
        NSMutableArray *a = dictA[@"pixels"];
        [a insertObject:dictA[@"roiname"] atIndex:0];
        [array addObject:a];
    }
    //if ([dictM[@"pixels"] count]>0)
    {
        NSMutableArray *m = dictM[@"pixels"];
        [m insertObject:dictM[@"roiname"] atIndex:0];
        [array addObject:m];
    }
    dict[@"data"] = [MirrorROIPluginFilterOC stringForDataArray:array forceTranspose:YES];
    return dict;
}
-(NSString *)dataStringFor1LineSummaryFromRawDict:(NSMutableDictionary *)dictRaw dict3D:(NSMutableDictionary *)dict3D forSite:(NSString *)anatSite {
    //kDeltaNameDividedMean is a number or ""
    return [NSString stringWithFormat:
            k1LineSummaryHeaders
            "%@\t%@\t%@\t%@\t%@\t%@\t%@\t%@\t%@\t%@\t%@\t%@\n"
            ,
            [self participantNameVaccineDay1Line],
            anatSite,
            dictRaw[kDeltaNameActiveMean],
            dictRaw[kDeltaNameActiveSum],
            dictRaw[kDeltaNameMirroredMean],
            dictRaw[kDeltaNameMirroredSum],
            dictRaw[kDeltaNameSubtractedMean],
            dictRaw[kDeltaNameSubtractedPixTotal],
            dictRaw[kDeltaNameDividedMean],
            dictRaw[kDeltaNameDividedPixTotal],
            dict3D[@"volume"],
            dictRaw[kDeltaNameCount]
            ];
}
-(NSString *)dataStringRawPixelsFromDict:(NSMutableDictionary *)dict {
    NSString *calculatedRowsString = @"";
    //kDeltaNameDividedPix1Line is an array of values
    if ([[dict objectForKey:kDeltaNameDividedPix1Line] count]>0) {
        calculatedRowsString = [NSString stringWithFormat:
                                @"%@\t%@\n%@\t%@\n%@\t%@",
                                @"Divided",
                                [[dict objectForKey:kDeltaNameDividedPix1Line] componentsJoinedByString:@"\t"],
                                @"Subtracted",
                                [[dict objectForKey:kDeltaNameSubtractedPix1Line] componentsJoinedByString:@"\t"],
                                @"Mirrored",
                                [[dict objectForKey:kDeltaNameMirroredPix1Line] componentsJoinedByString:@"\t"]
                                ];
    }
    return [NSString stringWithFormat:
            @"%@\t%@\n%@",
            @"Active",
            [[dict objectForKey:kDeltaNameActivePix1Line] componentsJoinedByString:@"\t"],
            calculatedRowsString
            ];
}
-(NSMutableDictionary *)bookMarkStringsForAllSitesConjoined {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSMutableArray *summaryRows = [NSMutableArray arrayWithCapacity:self.dictBookmarks.count];
    NSMutableArray *pixelsAMvertical = [NSMutableArray arrayWithCapacity:self.dictBookmarks.count];
    NSMutableArray *onelineSummaryRows = [NSMutableArray arrayWithCapacity:self.dictBookmarks.count];
    NSMutableArray *pixelGridRows = [NSMutableArray arrayWithCapacity:self.dictBookmarks.count];
    NSMutableArray *pixelGridXYZTaggedRows = [NSMutableArray arrayWithCapacity:self.dictBookmarks.count+1];
    [pixelGridXYZTaggedRows addObject:@"SITE\tX\tY\tZ\tVALUE"];
    NSMutableArray *pixelGridTransposedRows = [NSMutableArray arrayWithCapacity:self.dictBookmarks.count+1];
    [pixelGridTransposedRows addObject:[self participantDetailsArray]];
    NSArray *keys = [self.dictBookmarks.allKeys sortedArrayUsingSelector:@selector(compare:)];
    for (NSString *key in keys) {
        [pixelGridRows addObject:[self dividerForExportFileFromAnatomicalSite:key]];
        [pixelGridRows addObject:[[self.dictBookmarks objectForKey:key] objectForKey:kBookmarkKeyPixelsGrids]];

        [pixelGridXYZTaggedRows addObject:[[self.dictBookmarks objectForKey:key] objectForKey:kBookmarkKeyXYZTaggedPixelsGrids]];
 
        [pixelGridTransposedRows addObjectsFromArray:[[self.dictBookmarks objectForKey:key] objectForKey:kBookmarkKeyPixelsGridsNotYetTransposedArray]];
 
        [summaryRows addObject:[self dividerForExportFileFromAnatomicalSite:key]];
        [summaryRows addObject:[[self.dictBookmarks objectForKey:key] objectForKey:kBookmarkKeySummary]];
 
        [onelineSummaryRows addObject:[[self.dictBookmarks objectForKey:key] objectForKey:kBookmarkKey1LineSummary]];
        
        [pixelsAMvertical addObject:[[self.dictBookmarks objectForKey:key] objectForKey:kPixelsAMvertical] ?: [NSMutableDictionary dictionary]];
    }
    [dict setObject:[pixelGridXYZTaggedRows componentsJoinedByString:@"\n"] forKey:kConjoinedXYZTaggedPixelGrids] ;
    [dict setObject:pixelsAMvertical forKey:kPixelsAMverticalAllSites] ;
    [dict setObject:[MirrorROIPluginFilterOC removeDoubleLinesFromString:[onelineSummaryRows componentsJoinedByString:@"\n"]] forKey:kConjoined1LineSummary] ;
    [dict setObject:[MirrorROIPluginFilterOC removeDoubleLinesFromString:[NSString stringWithFormat:@"%@\n%@",[self participantDetailsString], [summaryRows componentsJoinedByString:@"\n"]]] forKey:kConjoinedSummary] ;
    [dict setObject:[MirrorROIPluginFilterOC removeDoubleLinesFromString:[NSString stringWithFormat:@"%@\n%@",[self participantDetailsString], [pixelGridRows componentsJoinedByString:@"\n"]]] forKey:kConjoinedPixelGrids] ;
    [dict setObject:[MirrorROIPluginFilterOC removeDoubleLinesFromString:[MirrorROIPluginFilterOC stringForDataArray:pixelGridTransposedRows forceTranspose:YES]] forKey:kConjoinedPixelGridsTransposed] ;
    
    return dict;
}
+(NSString *)removeDoubleLinesFromString:(NSString *)string {
    NSString *clean = string;
    NSRange loc = [clean rangeOfString:@"\n\n"];
    while (loc.location != NSNotFound) {
        clean = [clean stringByReplacingOccurrencesOfString:@"\n\n" withString:@"\n"];
        loc = [clean rangeOfString:@"\n\n"];
    }
    return clean;
}
-(NSString *)bookmarkedDataFilename:(ExportDataType)whichData {
    NSString *fileName = [NSString stringWithFormat:@"%@-%@",
                          [self fileNamePrefixForExportType:whichData withAnatomicalSite:NO],
                          [self petSeriesNameWithNoBadCharacters:YES]
                          ];
    return [MirrorROIPluginFilterOC fileNameWithNoBadCharacters:fileName];
}
#pragma mark - Bookmarks Import Export
-(void)bookmarkedDataImport {
    // Get the main window for the document.
    NSWindow* window = self.windowControllerMain.window;
    // Create and configure the panel.
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:NO];
    [panel setAllowsMultipleSelection:NO];
    [panel setRequiredFileType:@"plist"];
    [panel setMessage:@"Import '.plist' file with bookmarked data.\nWARNING ! This will overwrite  existing data with the same anatomical site name"];
    
    // Display the panel attached to the document's window.
    [panel beginSheetModalForWindow:window completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *url = [[panel URLs] objectAtIndex:0];
            if ([[url pathExtension] isEqualToString:@"plist"]) {
                NSString *corrFn = [[url lastPathComponent] stringByDeletingPathExtension];
                NSString *viewerN = [self petSeriesNameWithNoBadCharacters:YES];
                if ([viewerN isEqualToString:corrFn] ||
                    [MirrorROIPluginFilterOC proceedAfterAlert:@"The file name does not match the current PET series name - proceed with the import?"]) {
                    NSMutableDictionary *replaceDict = [NSMutableDictionary dictionaryWithContentsOfURL:url];
                    if (replaceDict.count>0) {
                        for (NSString *key in replaceDict) {
                            [self.dictBookmarks setObject:replaceDict[key] forKey:key];
                            // arrayControllerBookmarks just lists the names of the bookmarks
                            [self.arrayControllerBookmarks removeObject:key];//erase to replace
                            [self.arrayControllerBookmarks addObject:key];
                        }
                    } else {
                        [MirrorROIPluginFilterOC alertWithMessage:@"No bookmarks were found in the file" andTitle:@"Bookmarked Data Import" critical:YES];
                    }
                }
            } else {
                [MirrorROIPluginFilterOC alertWithMessage:@"The file is not a '.plist' file and so cannot be imported" andTitle:@"Bookmarked Data Import" critical:YES];
            }
        }
    }];
}
- (void)exportBookmarkedData:(ExportDataHow)exportHow {
    NSURL *savedLocation = nil;
    NSMutableDictionary *dict = [self bookMarkStringsForAllSitesConjoined];
    switch (exportHow) {
        case ExportAsFile:
        {
            savedLocation = [self saveData: [dict objectForKey:kConjoinedSummary]
                                  withName:[self bookmarkedDataFilename:BookmarkedDataSummary]];
            if (savedLocation != nil)
            {
                NSMutableArray *arrayOfpixelsAMVertical = [dict objectForKey:kPixelsAMverticalAllSites];
                //this is an array of dicts by name
                for (NSMutableDictionary *dict in arrayOfpixelsAMVertical) {
                    NSString *filename = [MirrorROIPluginFilterOC fileNameWithNoBadCharacters:[NSString stringWithFormat:@"%@%@-%@",[self fileNamePrefixForExportType:PixelsAMvertical withAnatomicalSite:NO],dict[@"site"],[self petSeriesNameWithNoBadCharacters:YES]]];
                    [dict[@"data"] writeToURL:[[[savedLocation URLByDeletingLastPathComponent] URLByAppendingPathComponent:filename isDirectory:NO] URLByAppendingPathExtension:@"txt"] atomically:YES];
                }

                [[dict objectForKey:kConjoinedXYZTaggedPixelGrids] writeToURL:[[[savedLocation URLByDeletingLastPathComponent] URLByAppendingPathComponent:[self bookmarkedDataFilename:BookmarkKeyXYZTaggedPixelsGrids] isDirectory:NO] URLByAppendingPathExtension:@"txt"] atomically:YES];
                
                [[dict objectForKey:kConjoined1LineSummary] writeToURL:[[[savedLocation URLByDeletingLastPathComponent] URLByAppendingPathComponent:[self bookmarkedDataFilename:BookmarkedData1LineSummary] isDirectory:NO] URLByAppendingPathExtension:@"txt"] atomically:YES];
                [[dict objectForKey:kConjoinedPixelGrids] writeToURL:[[[savedLocation URLByDeletingLastPathComponent] URLByAppendingPathComponent:[self bookmarkedDataFilename:BookmarkedDataPixelGrids] isDirectory:NO] URLByAppendingPathExtension:@"txt"] atomically:YES];
                [[dict objectForKey:kConjoinedPixelGridsTransposed] writeToURL:[[[savedLocation URLByDeletingLastPathComponent] URLByAppendingPathComponent:[self bookmarkedDataFilename:BookmarkedDataPixelGridsTransposed] isDirectory:NO] URLByAppendingPathExtension:@"txt"] atomically:YES];
                [self exportBookmarkedDataDictToURL:savedLocation];
                [self exportBookmarkedAMTroisToURL:savedLocation];
                if ([MirrorROIPluginFilterOC userDefaultBooleanForKey:kAddReportWhenSaveBookmarkedDataDefault]) {
                    [self attachDatabaseReportBookmarksDataFileAtURL:savedLocation];
                }
            }
        }
            break;
        case ExportAs1LineFile:
        {
            [self export1LineSummary];
        }
            break;
        case ViewInWindow:
            [MirrorROIPluginFilterOC showStringInWindow:[dict objectForKey:kConjoinedSummary]
                                              withTitle:[self bookmarkedDataFilename:BookmarkedDataSummary]];
            [MirrorROIPluginFilterOC showStringInWindow:[dict objectForKey:kConjoined1LineSummary]
                                              withTitle:[self bookmarkedDataFilename:BookmarkedData1LineSummary]];
            [MirrorROIPluginFilterOC showStringInWindow:[dict objectForKey:kConjoinedPixelGrids]
                                              withTitle:[self bookmarkedDataFilename:BookmarkedDataPixelGrids]];
            [MirrorROIPluginFilterOC showStringInWindow:[dict objectForKey:kConjoinedPixelGridsTransposed]
                                              withTitle:[self bookmarkedDataFilename:BookmarkedDataPixelGridsTransposed]];
            [MirrorROIPluginFilterOC showStringInWindow:[dict objectForKey:kConjoinedXYZTaggedPixelGrids]
                                              withTitle:[self bookmarkedDataFilename:BookmarkKeyXYZTaggedPixelsGrids]];
            NSMutableArray *arrayOfpixelsAMVertical = [dict objectForKey:kPixelsAMverticalAllSites];
            //this is an array of dicts by name
            for (NSMutableDictionary *dict in arrayOfpixelsAMVertical) {
                NSString *site = dict[@"site"];
                NSString *datastring = dict[@"data"];
                NSString *filename = [MirrorROIPluginFilterOC fileNameWithNoBadCharacters:[NSString stringWithFormat:@"%@-%@",[self fileNamePrefixForExportType:PixelsAMvertical withAnatomicalSite:NO],site]];
                [MirrorROIPluginFilterOC showStringInWindow:datastring withTitle:filename];
            }

            break;
        default:
            break;
    }
    
}
-(void)exportBookmarkedDataDictToURL:(NSURL *)url {
    if (url != nil) {
        NSString *fn = [self petSeriesNameWithNoBadCharacters:YES];
        url = [[[url URLByDeletingLastPathComponent] URLByAppendingPathComponent:fn isDirectory:NO] URLByAppendingPathExtension:@"plist"];
        [self.dictBookmarks writeToURL:url atomically:YES];
    }
}
#pragma mark - export import AMTrois
-(void)exportBookmarkedAMTroisToURL:(NSURL *)url {
    if (url != nil) {
        //iterate thru the bookmarks extracting the rois and saving by name
        for (NSString *key in self.dictBookmarks) {
            NSData *arrayofrois = [self.dictBookmarks[key] objectForKey:kBookmarkKeyAMTrois];
            NSString *sitefilename = [MirrorROIPluginFilterOC fileNameWithNoBadCharacters:[NSString stringWithFormat:@"%@-%@",key,[self petSeriesNameWithNoBadCharacters:YES]]];
            url = [[[url URLByDeletingLastPathComponent] URLByAppendingPathComponent:sitefilename isDirectory:NO] URLByAppendingPathExtension:@"rois_series"];
            [arrayofrois writeToURL:url atomically:YES];
        }
    }
}
- (IBAction)amtRoiLoadFromBookmark:(NSButton *)sender {
    [self setAnatomicalSiteName:[self amtRoiLoadFromSelectedBookmark]];
}
- (NSString *)amtRoiLoadFromSelectedBookmark {
    NSMutableArray *names = [NSMutableArray arrayWithCapacity:self.arrayControllerBookmarks.selectionIndexes.count];
    [self.arrayControllerBookmarks.selectionIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        if (index < [self.arrayControllerBookmarks.arrangedObjects count]) {
            NSString *name = [self.arrayControllerBookmarks.arrangedObjects objectAtIndex:index];
            if ([self amtRoiLoadedOKfromBookmarkNamed:name]) {
                [names addObject:name];
            }
            else {
                [MirrorROIPluginFilterOC alertWithMessage:name andTitle:@"Unable To Load ROI for this anatomical site" critical:NO];
            }
        }
    }];
    if (names.count>0) {
        return [names componentsJoinedByString:@" + "];
    }
    return @"";
}
- (BOOL)amtRoiLoadedOKfromBookmarkNamed:(NSString *)name {
    NSData *roisPerMovies = [self.dictBookmarks[name] objectForKey:kBookmarkKeyAMTrois];
    if (roisPerMovies != nil) {
        NSURL *temporaryDirectory = [[[NSURL fileURLWithPath:NSHomeDirectory()] URLByAppendingPathComponent:@"tempROIexport"] URLByAppendingPathExtension:@"rois_series"];
        [roisPerMovies writeToURL:temporaryDirectory atomically:YES];
        if ([[NSFileManager defaultManager] fileExistsAtPath:temporaryDirectory.path]) {
            [self.viewerPET roiLoadFromSeries: temporaryDirectory.path];
            [[NSFileManager defaultManager] removeItemAtURL:temporaryDirectory error:NULL];
            return YES;
        }
    }
    return NO;
}
#pragma mark -  Export Import the ROIs as Osirix
-(NSData *)archivedArrayOFAMTroisForSite:(NSString *)site {
    BOOL roisFound = NO;
    NSMutableArray *roisPerMovies = [NSMutableArray  array];
    NSMutableArray  *roisPerSeries = [NSMutableArray  array];
    for( int x = 0; x < self.viewerPET.pixList.count; x++)
    {
        NSMutableArray  *roisPerImages = [NSMutableArray  array];
        for( int i = 0; i < [[self.viewerPET.roiList objectAtIndex: x] count]; i++)
        {
            ROI	*curROI = [[self.viewerPET.roiList objectAtIndex: x] objectAtIndex: i];
            if ([curROI.name isEqualToString:[self roiNameForType:Mirrored_ROI]] || [curROI.name isEqualToString:[self roiNameForType:Active_ROI]]) {
                [roisPerImages addObject: curROI];
                roisFound = YES;
            }
        }
        [roisPerSeries addObject: roisPerImages];
    }
    if (roisFound) {
        //we only support 1 movie
        [roisPerMovies addObject:roisPerSeries];
        return [NSArchiver archivedDataWithRootObject:roisPerMovies];
    }
    return nil;
}
-(void)doExportAMTroi {
    NSData *roisPerMovies = [self archivedArrayOFAMTroisForSite:[self anatomicalSiteName]];
    if(roisPerMovies != nil)
    {
        NSSavePanel *savePanel = [NSSavePanel savePanel];
        savePanel.allowedFileTypes = [NSArray arrayWithObject:@"rois_series"];
        savePanel.nameFieldStringValue = [MirrorROIPluginFilterOC fileNameWithNoBadCharacters:[NSString stringWithFormat:@"%@-%@",[self anatomicalSiteName],[self petSeriesNameWithNoBadCharacters:YES]]];
        if ([savePanel runModal] == NSFileHandlingPanelOKButton) {
            [roisPerMovies writeToURL:savePanel.URL atomically:YES];
        }
    }
    else
    {
        [MirrorROIPluginFilterOC alertWithMessage:@"No ROI found to export" andTitle:@"ROI Export" critical:NO];
    }
    
}
- (IBAction) importROIFromFiles: (id) sender {
    
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseDirectories:NO];
    oPanel.allowedFileTypes = [NSArray arrayWithObjects:@"rois_series", nil];
    
    if ([oPanel runModal] == NSOKButton)
    {
        [self.viewerPET roiLoadFromSeries: [[oPanel filenames] lastObject]];
    }
}

#pragma mark -  1LineSummary Export
-(NSURL *)url1LineSummarySaveDirectory {
    NSString *path = [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefault_1LineSummarySaveDirectory] ?: NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    return [NSURL fileURLWithPath:path];
    //    NSURL *dirURL = [NSURL fileURLWithPath:path];
    //    NSArray *directories = dirURL ? [NSArray arrayWithObject:dirURL] : NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    //    return directories.firstObject;
}
-(void)export1LineSummary {
    NSArray *selectedSites = self.arrayControllerBookmarks.selectedObjects;
    if (selectedSites.count == 0) {
        selectedSites = nil;//nil signals all sites
    }
    NSString *stringsConjoined = [self bookmarkStringsFor1LineSummariesConjoinedForSites:selectedSites];
    [self saveData: stringsConjoined withName:[self bookmarkedDataFilename:BookmarkedData1LineSummary]];
}
-(NSString *)bookmarkStringsFor1LineSummariesConjoinedForSites:(NSArray *)sites {
    NSMutableArray *onelineSummaryRows = [NSMutableArray arrayWithCapacity:self.dictBookmarks.count];
    NSArray *keys = [self.dictBookmarks.allKeys sortedArrayUsingSelector:@selector(compare:)];
    for (NSString *key in keys) {
        if (sites == nil || [sites containsObject:key]) {
            [onelineSummaryRows addObject:[[self.dictBookmarks objectForKey:key] objectForKey:kBookmarkKey1LineSummary]];
        }
    }
    return [onelineSummaryRows componentsJoinedByString:@"\n"];
}

#pragma mark -  Data Export
-(NSString *)fileNamePrefixForExportType:(ExportDataType)type withAnatomicalSite:(BOOL)withSite {
    NSString *typeString = @"";
    switch (type) {
        case RoiData:
            typeString =  @"-RoiData";
            break;
        case RoiPixelsFlat:
            typeString =  @"-ROIPixelsFlatData";
            break;
        case PixelsGridSummary:
            typeString =  @"-PixelsGridSummaryData";
            break;
        case PixelsGridAllData:
            typeString =  @"-PixelsGridAllData";
            break;
        case RoiSummary:
            typeString =  @"-ROISummaryData";
            break;
        case RoiThreeD:
            typeString =  @"-ROI3DData";
            break;
        case AllROIdata:
            typeString =  @"-ROIAllData";
            break;
        case PETRois:
            typeString =  @"-PETROIs";
            break;
        case BookmarkedDataSummary:
            typeString =  @"∑";
            break;
        case BookmarkedData1LineSummary:
            typeString =  @"∈";
            break;
        case BookmarkedDataSelected1LineSummariesConjoined:
            typeString =  @"∉";
            break;
        case PixelsAMvertical:
            typeString =  @"☯";
            break;
        case BookmarkedDataPixelGrids:
            typeString =  @"⊞";
            break;
        case BookmarkedDataPixelGridsTransposed:
            typeString =  @"∭";
            break;
        case BookmarkKeyXYZTaggedPixelsGrids:
            typeString =  @"ℨ";
            break;
        default:
            typeString =  @"?";
            break;
    }
    if (withSite) {
        return [[self anatomicalSiteName] stringByAppendingString:typeString];
    }
    return typeString;
}
- (IBAction)exportDataTapped:(NSButton *)sender {
    if ([self anatomicalSiteDefined]) {
        [self exportData:sender.tag];
    }
}
-(void)exportData:(ExportDataType)exportType {
    switch (exportType) {
        case PETRois:
            [self doExportAMTroi];
            break;
        case JiggleRoi_View:
            [MirrorROIPluginFilterOC showStringInWindow:[self jiggleROIsummaryStringWithActiveROIinSliceString]
                                              withTitle:[self jiggleROIfileName]];
            break;
        case JiggleRoi_Save:
            [self saveData:[self jiggleROIsummaryStringWithActiveROIinSliceString]
                  withName:[self jiggleROIfileName]];
            break;
        default:
            break;
    }
}

#pragma mark -  ROI does calculations
+(NSMutableDictionary *)blank3DdataDict {
    NSMutableDictionary *blank= [NSMutableDictionary dictionaryWithCapacity:6];
    [blank setDictionary:@{@"mean":@"",@"dev":@"",@"max":@"",@"min":@"",@"total":@"0",@"volume":@"0",@"pixels":[NSMutableArray array],@"count":@"0",@"roiname":@""}];
    return blank;
}
-(NSMutableDictionary *)dataDictFor3DROIdataForType:(ROI_Type)type {
    NSMutableDictionary *dataDict = [MirrorROIPluginFilterOC blank3DdataDict];
    [self.viewerPET roiSelectDeselectAll: nil];
    NSString *roiname = [self roiNameForType:type];
    ROI *roi = [self ROIfromFirstMatchedSliceInViewer:self.viewerPET withName:roiname];
    if (roi != nil) {
        NSString *error = nil;
        [self.viewerPET computeVolume:roi points:nil generateMissingROIs:NO generatedROIs:nil computeData:dataDict error:&error];
        dataDict[@"roiname"] = roiname;
        //roi.dataValues = array of numbers - one per slice - merge from all rois
        NSMutableArray *mergedPix = [NSMutableArray array];
        for (NSMutableArray *roisinslice in self.viewerPET.roiList) {
            for (ROI *roi in roisinslice) {
                if ([roi.name isEqualToString:roiname]) {
                    [mergedPix addObjectsFromArray:roi.dataValues];
                }
            }
        }
        dataDict[@"pixels"] = mergedPix;
        dataDict[@"count"] = [NSNumber numberWithUnsignedInteger: mergedPix.count];
        if (error != nil) {
            [MirrorROIPluginFilterOC alertWithMessage:error andTitle:@"Error computing 3D ROI" critical:NO];
        }
    }
    return dataDict;
}
-(NSString *)dataStringFor3DROIdataFromDict:(NSMutableDictionary *)dataDict {
    if (dataDict != nil && dataDict.count>0) {
        NSUInteger capacity = self.viewerPET.roiList.count;
        NSMutableArray *arrayOfRows = [NSMutableArray arrayWithCapacity:capacity];
        //each row has the data for one roi
        for (NSString *key in dataDict) {
            if (![key isEqualToString:@"rois"]) {
                [arrayOfRows addObject:[NSString stringWithFormat:@"%@\t%@",key,dataDict[key]]];
            }
        }
        if (arrayOfRows.count>0) {
            return [arrayOfRows componentsJoinedByString:@"\n"];
        }
    }
    return @"";
}

#pragma mark -  Calculate delta from raw pixels
-(PixelDataStatus)active:(NSMutableArray *)active matchesMirrored:(NSMutableArray *)mirrored {
    //check number of slices
    if (active.count == 0) {
        return NoActive;
    }
    NSUInteger aC = 0, mC = 0;
    for (NSUInteger i=0; i<active.count; i++) {
        // asinle bad slice triggers fail
        aC += [[active objectAtIndex:i] count];
        mC += [[mirrored objectAtIndex:i] count];
    }
    if (aC > 0 && aC == mC) {
        return ActiveAndMirrored;
    }
    if (aC >0) {
        return ActiveOnly;
    }
    return NoActive;
}
-(NSMutableDictionary *)dataDictForRawPixelsDeltaForSite:(NSString *)site {
    NSMutableArray *dataAflat = [NSMutableArray array];
    NSMutableArray *dataMflat = [NSMutableArray array];
    NSMutableArray *dataA_1Line = [NSMutableArray array];
    NSMutableArray *dataM_1Line = [NSMutableArray array];
    NSMutableArray *dataD_1Line = [NSMutableArray array];
    NSMutableArray *dataS_1Line = [NSMutableArray array];
    
    /* Get XYZ tagged raw pixel values */
    NSMutableArray *dataXYZTagged_A = [self makeArrayBySliceOf2DarraysWithXYZTaggedPixelsFromROIsInSliceOfType:Active_ROI forSite:site];

    NSMutableArray *dataA2D = [self makeArrayBySliceOf2DarraysWithPixelsFromROIsInSliceOfType:Active_ROI];
    NSMutableArray *dataM2D = [self makeArrayBySliceOf2DarraysWithPixelsFromROIsInSliceOfType:Mirrored_ROI];
    /* makeArrayBySliceOf2DarraysWithPixelsFromROIsInSliceOfType
     returns an array. Each object is from each pix image in the series. dataA2D.count == number of slices with matched rois
     There is a risk that one slice may contain a roi only A or M but this is unlikely. If so it fails the test A.count == M.count and only A is analysed.
     Within each slice object is an array of 2D grids from each of the ROIs matching the search within that slice PixImage, one grid per ROI
     Within the grid object is an array of rows X wide and Y long
     */
    NSMutableArray *subtracted = [NSMutableArray array];
    NSMutableArray *divided = [NSMutableArray array];
    NSUInteger countOfPixels = 0;
    CGFloat sumOfSubtract = 0.0;
    CGFloat maxOfSubtract = -INT_MAX;
    CGFloat minOfSubtract = INT_MAX;
    CGFloat sumOfDivide = 0.0;
    CGFloat maxOfDivide = -INT_MAX;
    CGFloat minOfDivide = INT_MAX;
    CGFloat sumOfA = 0.0;
    CGFloat maxOfA = -INT_MAX;
    CGFloat minOfA = INT_MAX;
    CGFloat sumOfM = 0.0;
    CGFloat maxOfM = -INT_MAX;
    CGFloat minOfM = INT_MAX;
    
    //check if we have A and M or just A
    PixelDataStatus activeAndMirroredStatus = [self active:dataA2D matchesMirrored:dataM2D];
    if (activeAndMirroredStatus == ActiveAndMirrored) {
        //we step over the first level of array, by slice
        for (int pixIndex=0; pixIndex<dataA2D.count; pixIndex++) {
            NSMutableArray *roisInSliceArray_A = [dataA2D objectAtIndex:pixIndex];
            NSMutableArray *roisInSliceArray_M = [dataM2D objectAtIndex:pixIndex];
            //Now we step thru these to extract the roi, and then the pixel rows for that roi
            //we check each roisInSliceArray_A.count == roisInSliceArray_M.count
            //if mismatched we cannot handle this! Go to next slice
            if (roisInSliceArray_A.count != roisInSliceArray_M.count) {
                NSLog(@"Number of ROIs unequal in slice %i. Skipped",pixIndex);
                continue;
            }
            //each roiIndex has a 2D array of Y axis rows of pixels for that roi in a 2D grid
            //so we have to unpack those and mirror the final Y rows for the mirrored roi
            for (int roiIndex=0; roiIndex<roisInSliceArray_A.count; roiIndex++) {
                //these are our 2D arrays of rows with pixels, y = row index on Y axis
                NSMutableArray *pixelsGridA = [roisInSliceArray_A objectAtIndex:roiIndex];
                NSMutableArray *pixelsGridM = [roisInSliceArray_M objectAtIndex:roiIndex];
                //we make flat arrays to hold the same pixels but in a flat 1D row for that ROI
                NSMutableArray *dataForROIflatA = [NSMutableArray array];
                NSMutableArray *dataForROIflatM = [NSMutableArray array];
                NSMutableArray *roiSubtract = [NSMutableArray array];
                NSMutableArray *roiDivide = [NSMutableArray array];
                for (int y=0; y<pixelsGridA.count;y++) {
                    NSMutableArray *rowAatY = [pixelsGridA objectAtIndex:y];
                    NSMutableArray *rowMatY = [pixelsGridM objectAtIndex:y];
                    countOfPixels += rowAatY.count;
                    for (int col=0; col<rowAatY.count; col++) {
                        //Do the maths on the actual floats
                        CGFloat A = [[rowAatY objectAtIndex:col] floatValue];
                        //reversed - we use rowMatY.count-col-1 to take the last pixel first in M
                        CGFloat M = [[rowMatY objectAtIndex:rowMatY.count-col-1] floatValue];
                        sumOfA += A;
                        maxOfA = fmaxf(maxOfA, A);
                        minOfA = fminf(minOfA, A);
                        sumOfM += M;
                        maxOfM = fmaxf(maxOfM, M);
                        minOfM = fminf(minOfM, M);
                        
                        CGFloat subtraction = A-M;
                        CGFloat division = A/M;
                        maxOfDivide = fmaxf(maxOfDivide, division);
                        minOfDivide = fminf(minOfDivide, division);
                        maxOfSubtract = fmaxf(maxOfSubtract, subtraction);
                        minOfSubtract = fminf(minOfSubtract, subtraction);
                        sumOfSubtract += subtraction;
                        sumOfDivide += division;
                        //add the results to our 1D rows also reflecting the reversed M
                        [roiSubtract addObject:[NSNumber numberWithFloat:subtraction]];
                        [roiDivide addObject:[NSNumber numberWithFloat:division]];
                        
                        //add the results to our 1 Line also reflecting the reversed M
                        [dataS_1Line addObject:[NSNumber numberWithFloat:subtraction]];
                        [dataD_1Line addObject:[NSNumber numberWithFloat:division]];
                        
                        //add the NSNumbers to our flat 1D row, we note the reversal
                        [dataForROIflatA addObject:[rowAatY objectAtIndex:col]];
                        [dataForROIflatM addObject:[rowMatY objectAtIndex:rowMatY.count-col-1]];//reversed for mirrored ROI
                        
                        //add the NSNumbers to our 1Line, we note the reversal but its irrelevant, could do straight div/subtractions tho
                        [dataA_1Line addObject:[rowAatY objectAtIndex:col]];
                        [dataM_1Line addObject:[rowMatY objectAtIndex:rowMatY.count-col-1]];//reversed for mirrored ROI
                        
                    }//end of row at Y
                }//end of Pixels grid for ROI
                //we finished all the pixels in this grid for this ROI so update the flat arrays
                [subtracted addObject:roiSubtract];
                [divided addObject:roiDivide];
                [dataAflat addObject:dataForROIflatA];
                [dataMflat addObject:dataForROIflatM];
            }//end of all the ROIs in this slice
        }//end of the slices
    }
    // lets do maths for A at least
    else if (activeAndMirroredStatus == ActiveOnly) {
        //we step over the first level of array, by slice
        for (int pixIndex=0; pixIndex<dataA2D.count; pixIndex++) {
            NSMutableArray *roisInSliceArray_A = [dataA2D objectAtIndex:pixIndex];
            //Now we step thru these to extract the roi, and then the pixel rows for that roi
            for (int roiIndex=0; roiIndex<roisInSliceArray_A.count; roiIndex++) {
                //these are our 2D arrays of rows with pixels, y = row index on Y axis
                NSMutableArray *pixelsGridA = [roisInSliceArray_A objectAtIndex:roiIndex];
                //we make flat arrays to hold the same pixels but in a flat 1D row for that ROI
                NSMutableArray *dataForROIflatA = [NSMutableArray array];
                for (int y=0; y<pixelsGridA.count;y++) {
                    NSMutableArray *rowAatY = [pixelsGridA objectAtIndex:y];
                    countOfPixels += rowAatY.count;
                    for (int col=0; col<rowAatY.count; col++) {
                        //Do the maths on the actual floats
                        CGFloat A = [[rowAatY objectAtIndex:col] floatValue];
                        sumOfA += A;
                        maxOfA = fmaxf(maxOfA, A);
                        minOfA = fminf(minOfA, A);
                        //add the NSNumbers to our flat 1D row, we note the reversal
                        [dataForROIflatA addObject:[rowAatY objectAtIndex:col]];
                        //add the NSNumbers to our 1Line,
                        [dataA_1Line addObject:[rowAatY objectAtIndex:col]];
                    }//end of row at Y
                }//end of Pixels grid for ROI
                //we finished all the pixels in this grid for this ROI so update the flat arrays
                [dataAflat addObject:dataForROIflatA];
            }//end of all the ROIs in slice
        } // end of slices
    }
    
    NSMutableDictionary *dict = [MirrorROIPluginFilterOC blankDataDictForRawPixelsDelta];
    CGFloat sd;
    CGFloat countOfPixelsF = [[NSNumber numberWithUnsignedInteger:countOfPixels] floatValue];
    [dict setObject:[NSNumber numberWithUnsignedInteger:countOfPixels] forKey:kDeltaNameCount];
    [dict setObject:dataAflat forKey:kDeltaNameActivePixFlatAndNotMirrored];
    [dict setObject:dataA2D forKey:kDeltaNameActivePixGrid];
    [dict setObject:dataXYZTagged_A forKey:kDeltaNameXYZTaggedRawPixelDataTag];
    [dict setObject:dataA_1Line forKey:kDeltaNameActivePix1Line];
    [dict setObject:[NSNumber numberWithFloat:sumOfA] forKey:kDeltaNameActiveSum];
    [dict setObject:[NSNumber numberWithFloat:sumOfA/countOfPixelsF] forKey:kDeltaNameActiveMean];
    [dict setObject:[NSNumber numberWithFloat:maxOfA] forKey:kDeltaNameActiveMax];
    [dict setObject:[NSNumber numberWithFloat:minOfA] forKey:kDeltaNameActiveMin];
    sd = [MirrorROIPluginFilterOC stDevForArrayOfRows:dataAflat withMean:sumOfA/countOfPixelsF andCountF:countOfPixelsF startingAtRow:0];
    [dict setObject:[NSNumber numberWithFloat:sd] forKey:kDeltaNameActiveSD];
    [dict setObject:[NSNumber numberWithFloat:sd/sqrtf(countOfPixelsF)] forKey:kDeltaNameActiveSEM];
    
    //trasnpose the pixel grids
    NSMutableArray *transposeArray = [NSMutableArray arrayWithCapacity:4];
    NSMutableArray *tempA = [NSMutableArray arrayWithObjects:[NSString stringWithFormat:@"%@-%@",[self anatomicalSiteName],@"Active"], nil];
    [tempA addObjectsFromArray:dataA_1Line];
    [transposeArray addObject:tempA];
    
    if (activeAndMirroredStatus == ActiveAndMirrored) {
        //blank dict initialises these anyway
        [dict setObject:dataMflat forKey:kDeltaNameMirroredPixFlatAndMirroredInRows];
        [dict setObject:dataM2D forKey:kDeltaNameMirroredPixGrid];
        [dict setObject:[NSNumber numberWithFloat:sumOfM] forKey:kDeltaNameMirroredSum];
        [dict setObject:[NSNumber numberWithFloat:sumOfM/countOfPixelsF] forKey:kDeltaNameMirroredMean];
        [dict setObject:[NSNumber numberWithFloat:maxOfM] forKey:kDeltaNameMirroredMax];
        [dict setObject:[NSNumber numberWithFloat:minOfM] forKey:kDeltaNameMirroredMin];
        sd = [MirrorROIPluginFilterOC stDevForArrayOfRows:dataMflat withMean:sumOfM/countOfPixelsF andCountF:countOfPixelsF startingAtRow:0];
        [dict setObject:[NSNumber numberWithFloat:sd] forKey:kDeltaNameMirroredSD];
        [dict setObject:[NSNumber numberWithFloat:sd/sqrtf(countOfPixelsF)] forKey:kDeltaNameMirroredSEM];
        
        [dict setObject:subtracted forKey:kDeltaNameSubtractedPix];
        [dict setObject:divided forKey:kDeltaNameDividedPix];
        [dict setObject:[NSNumber numberWithFloat:sumOfSubtract] forKey:kDeltaNameSubtractedPixTotal];
        [dict setObject:[NSNumber numberWithFloat:sumOfDivide] forKey:kDeltaNameDividedPixTotal];
        [dict setObject:[NSNumber numberWithFloat:minOfSubtract] forKey:kDeltaNameSubtractedPixMin];
        [dict setObject:[NSNumber numberWithFloat:maxOfSubtract] forKey:kDeltaNameSubtractedPixMax];
        [dict setObject:[NSNumber numberWithFloat:minOfDivide] forKey:kDeltaNameDividedPixMin];
        [dict setObject:[NSNumber numberWithFloat:maxOfDivide] forKey:kDeltaNameDividedPixMax];
        CGFloat subtractedMean = sumOfSubtract/countOfPixelsF;
        [dict setObject:[NSNumber numberWithFloat:subtractedMean] forKey:kDeltaNameSubtractedMean];
        CGFloat dividedMean = sumOfDivide/countOfPixelsF;
        [dict setObject:[NSNumber numberWithFloat:dividedMean] forKey:kDeltaNameDividedMean];
        // SDEVs
        sd = [MirrorROIPluginFilterOC stDevForArrayOfRows:subtracted withMean:subtractedMean andCountF:countOfPixelsF startingAtRow:0];
        [dict setObject:[NSNumber numberWithFloat:sd] forKey:kDeltaNameSubtractedSD];
        [dict setObject:[NSNumber numberWithFloat:sd/sqrtf(countOfPixelsF)] forKey:kDeltaNameSubtractedSEM];
        sd = [MirrorROIPluginFilterOC stDevForArrayOfRows:divided withMean:dividedMean andCountF:countOfPixelsF startingAtRow:0];
        [dict setObject:[NSNumber numberWithFloat:sd] forKey:kDeltaNameDividedSD];
        [dict setObject:[NSNumber numberWithFloat:sd/sqrtf(countOfPixelsF)] forKey:kDeltaNameDividedSEM];
        
        [dict setObject:dataM_1Line forKey:kDeltaNameMirroredPix1Line];
        [dict setObject:dataS_1Line forKey:kDeltaNameSubtractedPix1Line];
        [dict setObject:dataD_1Line forKey:kDeltaNameDividedPix1Line];
        
        NSMutableArray *temp = [NSMutableArray array];
        temp = [NSMutableArray arrayWithObjects:[NSString stringWithFormat:@"%@-%@",[self anatomicalSiteName],@"Divided"], nil];
        [temp addObjectsFromArray:dataD_1Line];
        [transposeArray addObject:temp];
        temp = [NSMutableArray arrayWithObjects:[NSString stringWithFormat:@"%@-%@",[self anatomicalSiteName],@"Subtracted"], nil];
        [temp addObjectsFromArray:dataS_1Line];
        [transposeArray addObject:temp];
        temp = [NSMutableArray arrayWithObjects:[NSString stringWithFormat:@"%@-%@",[self anatomicalSiteName],@"Mirrored"], nil];
        [temp addObjectsFromArray:dataM_1Line];
        [transposeArray addObject:temp];
    }
    [dict setObject:transposeArray forKey:kDeltaNameAMSDPix1LineTransposedArray];
    
    return dict;
}

+(NSMutableDictionary *)blankDataDictForRawPixelsDelta {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    //if active
    [dict setObject:@"" forKey:kDeltaNameCount];
    
    [dict setObject:[NSMutableArray array] forKey:kDeltaNameAMSDPix1LineTransposedArray];
    
    [dict setObject:[NSMutableArray array] forKey:kDeltaNameActivePixFlatAndNotMirrored];
    [dict setObject:[NSMutableArray array] forKey:kDeltaNameActivePixGrid];
    [dict setObject:[NSMutableArray array] forKey:kDeltaNameXYZTaggedRawPixelDataTag];
    [dict setObject:[NSMutableArray array] forKey:kDeltaNameActivePix1Line];
    [dict setObject:@"" forKey:kDeltaNameActiveSum];
    [dict setObject:@"" forKey:kDeltaNameActiveMean];
    [dict setObject:@"" forKey:kDeltaNameActiveMax];
    [dict setObject:@"" forKey:kDeltaNameActiveMin];
    [dict setObject:@"" forKey:kDeltaNameActiveSD];
    [dict setObject:@"" forKey:kDeltaNameActiveSEM];
    
    //if mirror
    [dict setObject:[NSMutableArray array] forKey:kDeltaNameMirroredPixFlatAndMirroredInRows];
    [dict setObject:[NSMutableArray array] forKey:kDeltaNameMirroredPixGrid];
    [dict setObject:[NSMutableArray array] forKey:kDeltaNameMirroredPix1Line];
    [dict setObject:@"" forKey:kDeltaNameMirroredSum];
    [dict setObject:@"" forKey:kDeltaNameMirroredMean];
    [dict setObject:@"" forKey:kDeltaNameMirroredMax];
    [dict setObject:@"" forKey:kDeltaNameMirroredMin];
    [dict setObject:@"" forKey:kDeltaNameMirroredSD];
    [dict setObject:@"" forKey:kDeltaNameMirroredSEM];
    
    [dict setObject:[NSMutableArray array] forKey:kDeltaNameSubtractedPix];
    [dict setObject:[NSMutableArray array] forKey:kDeltaNameSubtractedPix1Line];
    [dict setObject:@"" forKey:kDeltaNameSubtractedPixTotal];
    [dict setObject:@"" forKey:kDeltaNameSubtractedPixMin];
    [dict setObject:@"" forKey:kDeltaNameSubtractedPixMax];
    [dict setObject:@"" forKey:kDeltaNameSubtractedMean];
    [dict setObject:@"" forKey:kDeltaNameSubtractedSD];
    [dict setObject:@"" forKey:kDeltaNameSubtractedSEM];
    
    [dict setObject:[NSMutableArray array] forKey:kDeltaNameDividedPix];
    [dict setObject:[NSMutableArray array] forKey:kDeltaNameDividedPix1Line];
    [dict setObject:@"" forKey:kDeltaNameDividedPixTotal];
    [dict setObject:@"" forKey:kDeltaNameDividedPixMin];
    [dict setObject:@"" forKey:kDeltaNameDividedPixMax];
    [dict setObject:@"" forKey:kDeltaNameDividedMean];
    [dict setObject:@"" forKey:kDeltaNameDividedSD];
    [dict setObject:@"" forKey:kDeltaNameDividedSEM];
    
    return dict;
}

-(NSMutableArray *)makeArrayBySliceOf2DarraysWithPixelsFromROIsInSliceOfType:(ROI_Type)type{
    //we step thru each pixImage, check the ROIs for ones that match, and build an array that has the 2Dgrids frome ach ROI as objects. This array we add to an umbrella array for the series
    NSString *roiname = [self roiNameForType:type];
    NSMutableArray *arrayOfSlices = [NSMutableArray array];
    for (int pix = 0; pix<self.viewerPET.roiList.count; pix++) {
        NSMutableArray *arrayOfROIsInSlice = [NSMutableArray array];;
        for (ROI *roi in [self.viewerPET.roiList objectAtIndex:pix]) {
            if ([roi.name isEqualToString:roiname]) {
                NSMutableArray *roiData = [self rawPixelsDelta_extractPixelsInOrderedRowsFromROI:roi];
                [arrayOfROIsInSlice addObject:roiData];
            }
        }//end of rois in slice
        [arrayOfSlices addObject:arrayOfROIsInSlice];
    }//end of slices
    return arrayOfSlices;
}
-(NSMutableArray *)rawPixelsDelta_extractPixelsInOrderedRowsFromROI:(ROI *)roi{
    NSMutableArray *arrayOfPixelsRows = [NSMutableArray array];
    if (roi.pix != nil) {
        long height = roi.pix.pheight, width = roi.pix.pwidth;
        
        float *computedfImage = [roi.pix computefImage];
        long textWidth = roi.textureWidth, textHeight = roi.textureHeight;
        long textureUpLeftCornerX = roi.textureUpLeftCornerX, textureUpLeftCornerY = roi.textureUpLeftCornerY;
        unsigned char *buf = roi.textureBuffer;
        
        for( long y = 0; y < textHeight; y++)
        {
            NSMutableArray *rowPixels = [NSMutableArray array];
            for( long x = 0; x < textWidth; x++)
            {
                if( buf [ x + y * textWidth] != 0)
                {
                    long xx = (x + textureUpLeftCornerX);
                    long yy = (y + textureUpLeftCornerY);
                    
                    if( xx >= 0 && xx < width && yy >= 0 && yy < height)
                    {
                        {
                            [rowPixels addObject:[NSNumber numberWithFloat: computedfImage[ (yy * width) + xx]]];
                        }
                    }
                }
            }
            if (rowPixels.count > 0) {
                //this needs to be watched - here NO Y MIRROR is assumed, so we can skip empty rows as the Y are the same in both ROIs
                //if Y mirroring then we woudl have to account for that
                [arrayOfPixelsRows addObject:rowPixels];
            }
        }
    }
    return arrayOfPixelsRows;
}
-(NSMutableArray *)makeArrayBySliceOf2DarraysWithXYZTaggedPixelsFromROIsInSliceOfType:(ROI_Type)type forSite:(NSString *)site {
    //we step thru each pixImage, check the ROIs for ones that match, and build an array that has the XYZ tagged 2Dgrids from each ROI as objects. This array we add to an umbrella array for the series
    NSString *roiname = [self roiNameForType:type];
    NSMutableArray *arrayOfSlices = [NSMutableArray array];
    for (int pix = 0; pix<self.viewerPET.roiList.count; pix++) {
        NSMutableArray *arrayOfROIsInSlice = [NSMutableArray array];;
        for (ROI *roi in [self.viewerPET.roiList objectAtIndex:pix]) {
            if ([roi.name isEqualToString:roiname]) {
                NSMutableArray *roiData = [self rawPixelsDelta_extractPixelsInXYZTaggedOrderedRowsFromROI:roi forSite:site];
                if (roiData.count > 0) {
                    [arrayOfROIsInSlice addObject:roiData];
                }
            }
        }//end of rois in slice
        if (arrayOfROIsInSlice.count > 0) {
            [arrayOfSlices addObject:arrayOfROIsInSlice];
        }
    }//end of slices
    return arrayOfSlices;
}
-(NSMutableArray *)rawPixelsDelta_extractPixelsInXYZTaggedOrderedRowsFromROI:(ROI *)roi forSite:(NSString *)site{
    NSMutableArray *arrayOfPixelsRows = [NSMutableArray array];
    if (roi.pix != nil) {
        long height = roi.pix.pheight, width = roi.pix.pwidth;
        
        float *computedfImage = [roi.pix computefImage];
        long textWidth = roi.textureWidth, textHeight = roi.textureHeight;
        long textureUpLeftCornerX = roi.textureUpLeftCornerX, textureUpLeftCornerY = roi.textureUpLeftCornerY;
        unsigned char *buf = roi.textureBuffer;
        NSNumber *zz = [NSNumber numberWithFloat:roi.pix.originZ];
        
        for( long y = 0; y < textHeight; y++)
        {
            NSMutableArray *rowPixels = [NSMutableArray array];
            for( long x = 0; x < textWidth; x++)
            {
                if( buf [ x + y * textWidth] != 0)
                {
                    long xx = (x + textureUpLeftCornerX);
                    long yy = (y + textureUpLeftCornerY);
                    
                    if( xx >= 0 && xx < width && yy >= 0 && yy < height)
                    {
                        {
                            float pixval = computedfImage[ (yy * width) + xx];
                            NSArray *pixelTaggedArray = [NSArray arrayWithObjects:
                                                         site,
                                                         [NSNumber numberWithFloat:[[NSNumber numberWithLong:xx] floatValue]],
                                                         [NSNumber numberWithFloat:[[NSNumber numberWithLong:yy] floatValue]],
                                                         zz,
                                                         [NSNumber numberWithFloat:pixval],
                                                         nil];
                            [rowPixels addObject:pixelTaggedArray];
                        }
                    }
                }
            }
            if (rowPixels.count > 0) {
                [arrayOfPixelsRows addObject:rowPixels];
            }
        }
    }
    return arrayOfPixelsRows;
}

-(NSMutableDictionary *)dictOfrawPixelsDelta_make2DarrayWithPixelsFromROIsForType:(ROI_Type)type{
    NSString *roiname = [self roiNameForType:type];
    NSMutableDictionary *dictOfROIgrids = [NSMutableDictionary dictionary];
    for (int pix = 0; pix<self.viewerPET.roiList.count; pix++) {
        BOOL foundROI = NO;
        for (ROI *roi in [self.viewerPET.roiList objectAtIndex:pix]) {
            if ([roi.name isEqualToString:roiname]) {
                NSMutableArray *roiData = [self rawPixelsDelta_extractPixelsInOrderedRowsFromROI:roi];
                if (!foundROI) {
                    [dictOfROIgrids setObject:roiData forKey:[NSString stringWithFormat:@"-%03li",(long)pix]];
                }
                foundROI = YES;
            }
        }
    }
    return dictOfROIgrids;
}

#pragma mark - Statistical calculations
+(CGFloat)stDevForArrayOfRows:(NSMutableArray *)array withMean:(CGFloat)mean andCountF:(CGFloat)countF startingAtRow:(int)startingRow {
    CGFloat variance = 0.0;
    for (int row=startingRow; row<array.count; row++)
        for (int col = 0; col<[[array objectAtIndex:row] count]; col++ ) {
            variance += powf([[[array objectAtIndex:row] objectAtIndex:col] floatValue] - mean, 2.0);
        }
    return sqrtf(variance/countF);
}

#pragma mark - File Save
-(NSURL *)saveData:(NSString *)dataString withName:(NSString *)name {
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    BOOL onelineSummary = [name hasPrefix:@"∈"];
    if (onelineSummary) {
        savePanel.directoryURL = [self url1LineSummarySaveDirectory];
    }
    savePanel.allowedFileTypes = [NSArray arrayWithObject:@"txt"];
    savePanel.nameFieldStringValue = name;
    if ([savePanel runModal] == NSFileHandlingPanelOKButton) {
        NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:nil];
        [dataString writeToURL:savePanel.URL atomically:YES encoding:NSUnicodeStringEncoding error:&error];
        if (error.code == 0)
        {
            if (onelineSummary) {
                [[NSUserDefaults standardUserDefaults] setObject:savePanel.directoryURL.path forKey:kUserDefault_1LineSummarySaveDirectory];
            }
            return savePanel.URL;
        }
    }
    return nil;
}
+(NSString *)fileNameWithNoBadCharacters:(NSString *)original {
    if (original == nil) {
        original = @"Untitled";
    }
    return [original stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
}
-(NSString *)petSeriesNameWithNoBadCharacters:(BOOL)includePatientName {
    NSString *patname = @"";
    if (includePatientName) {
        patname = [NSString stringWithFormat:@"%@-",[[self.viewerPET currentStudy] name]];
    }
    NSString *name = [NSString stringWithFormat:@"%@%@",patname,[[self.viewerPET currentSeries] name]];
    return [MirrorROIPluginFilterOC fileNameWithNoBadCharacters:name];
}
#pragma mark - Plot Data
-(void)loadStatsScene {
    
    // Load the SKScene from 'GameScene.sks'
    self.skScene = [SKScene sceneWithSize:self.skView.frame.size];
    self.skScene.scaleMode = SKSceneScaleModeResizeFill;
    self.skScene.backgroundColor = [NSColor clearColor];
    self.skView.allowsTransparency = YES;
    [self.skView presentScene:self.skScene];
    self.skView.showsFPS = NO;
    self.skView.showsNodeCount = NO;
    [self addStatsMarkersWithName:kSpriteName_Active position:3.0];
    [self addStatsMarkersWithName:kSpriteName_Mirror position:5.0];
    [self addStatsMarkersWithName:kSpriteName_Jiggle position:1.0];
    [self hideNodeNamed:kSpriteName_Active hidden:YES];
    [self hideNodeNamed:kSpriteName_Mirror hidden:YES];
    [self hideNodeNamed:kSpriteName_Jiggle hidden:YES];
    
}
-(void)addStatsMarkersWithName:(NSString *)name position:(CGFloat)position{
    CGFloat posY = self.skView.frame.size.height*position*kHeightFraction;
    CGFloat posYT = self.skView.frame.size.height*(position+1)*kHeightFraction;
    
    SKSpriteNode *median = [SKSpriteNode spriteNodeWithColor:[NSColor redColor] size:CGSizeMake(kSpriteWidthMedian, kSpriteHeightMedian)];
    median.name = [name stringByAppendingString:kSpriteName_Median];
    [self.skScene addChild:median];
    median.position = CGPointMake(0.0, posY);
    
    SKSpriteNode *rangeA = [SKSpriteNode spriteNodeWithColor:[NSColor darkGrayColor] size:CGSizeMake(0.0, kSpriteHeightRange)];
    rangeA.name = [name stringByAppendingString:kSpriteName_Range];
    [self.skScene addChild:rangeA];
    rangeA.position = CGPointMake(0.0, posY);
    
    SKSpriteNode *midrange = [SKSpriteNode spriteNodeWithColor:[NSColor darkGrayColor] size:CGSizeMake(kSpriteWidthMidRange, kSpriteHeightMidRange)];
    midrange.name = [name stringByAppendingString:kSpriteName_MidRange];
    [rangeA addChild:midrange];
    //midrange moves with range
    
    SKSpriteNode *sdevA = [SKSpriteNode spriteNodeWithColor:[NSColor blackColor] size:CGSizeMake(0.0, kSpriteHeightSD)];
    sdevA.name = [name stringByAppendingString:kSpriteName_SDEV];
    [self colourNode:sdevA forName:name];
    [self.skScene addChild:sdevA];
    sdevA.position = CGPointMake(0.0, posY);
    
    SKSpriteNode *meanA = [SKSpriteNode spriteNodeWithColor:[NSColor blackColor] size:CGSizeMake(kSpriteWidthMean, kSpriteHeightMean)];
    meanA.name = [name stringByAppendingString:kSpriteName_Mean];
    [sdevA addChild:meanA];
    //mean moves with SD
    
    SKLabelNode *statsA = [SKLabelNode labelNodeWithFontNamed:@"Helvetica"];
    statsA.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    statsA.text = name;
    statsA.name = [name stringByAppendingString:kSpriteName_Text];
    statsA.fontSize = 12;
    statsA.fontColor = [NSColor blackColor];
    [self.skScene addChild:statsA];
    statsA.position = CGPointMake(CGRectGetMidX(self.skView.bounds),posYT);
    
    
}
-(void)colourNode:(SKSpriteNode *)node forName:(NSString *)name {
    if (node != nil) {
        if ([name isEqualToString:kSpriteName_Active]) {
            node.color = [MirrorROIPluginFilterOC colourForType:Active_ROI];
        }
        else if ([name isEqualToString:kSpriteName_Mirror]){
            node.color = [MirrorROIPluginFilterOC colourForType:Mirrored_ROI];
        }
        else if ([name isEqualToString:kSpriteName_Jiggle]){
            node.color = [MirrorROIPluginFilterOC colourForType:Jiggle_ROI];
        }
    }
}
- (IBAction)refreshDisplayedDataCTTapped:(NSButton *)sender {
    [self refreshDisplayedDataForCT];
}
-(void)refreshDisplayedDataForCT {
    [self refreshDisplayedDataForViewer:self.viewerCT];
}
- (void)refreshDisplayedDataForViewer:(ViewerController *)viewer{
    if ([self valid2DViewer:viewer])
    {
        ROI *activeRoi = [self ROIfromCurrentSliceInViewer:viewer withName:[self roiNameForType:Active_ROI]];
        ROI *mirroredRoi = [self ROIfromCurrentSliceInViewer:viewer withName:[self roiNameForType:Mirrored_ROI]];
        ROI *jiggleRoi = [self ROIfromCurrentSliceInViewer:viewer withName:kJiggleSelectedROIName];
        //if (activeRoi != nil && mirroredRoi != nil) {
        [MirrorROIPluginFilterOC forceRecomputeDataForROI:activeRoi];
        [MirrorROIPluginFilterOC forceRecomputeDataForROI:mirroredRoi];
        [MirrorROIPluginFilterOC forceRecomputeDataForROI:jiggleRoi];
        
        //draw the boxes
        float minGrey = INT_MAX;
        float maxGrey = -INT_MAX;
        
        if (activeRoi != nil) {
            minGrey = fminf(minGrey, activeRoi.min);
            minGrey = fminf(minGrey, activeRoi.mean-activeRoi.dev);
            maxGrey = fmaxf(maxGrey, activeRoi.mean+activeRoi.dev);
            maxGrey = fmaxf(maxGrey, activeRoi.max);
        }
        
        if (mirroredRoi != nil) {
            minGrey = fminf(minGrey, mirroredRoi.min);
            minGrey = fminf(minGrey, mirroredRoi.mean-mirroredRoi.dev);
            maxGrey = fmaxf(maxGrey, mirroredRoi.mean+mirroredRoi.dev);
            maxGrey = fmaxf(maxGrey, mirroredRoi.max);
        }
        
        if (jiggleRoi != nil) {
            minGrey = fminf(minGrey, jiggleRoi.min);
            minGrey = fminf(minGrey, jiggleRoi.mean-jiggleRoi.dev);
            maxGrey = fmaxf(maxGrey, jiggleRoi.mean+jiggleRoi.dev);
            maxGrey = fmaxf(maxGrey, jiggleRoi.max);
        }
        
        float ratio = 0;
        if (minGrey != maxGrey) {
            ratio = (self.skView.frame.size.width-(2.0*kSceneMargin))/(maxGrey-minGrey);
        }
        
        if (activeRoi != nil) {
            [self setLocationOfSpriteNamed:kSpriteName_Active
                                    forROI:activeRoi
                                   minGrey:minGrey
                                     ratio:ratio];
        }
        if (mirroredRoi != nil) {
            [self setLocationOfSpriteNamed:kSpriteName_Mirror
                                    forROI:mirroredRoi
                                   minGrey:minGrey
                                     ratio:ratio];
        }
        if (jiggleRoi != nil) {
            [self setLocationOfSpriteNamed:kSpriteName_Jiggle
                                    forROI:jiggleRoi
                                   minGrey:minGrey
                                     ratio:ratio];
        }
        
        [self hideNodeNamed:kSpriteName_Active hidden:activeRoi == nil];
        [self hideNodeNamed:kSpriteName_Mirror hidden:mirroredRoi == nil];
        [self hideNodeNamed:kSpriteName_Jiggle hidden:jiggleRoi == nil];
        
        self.skView.hidden = activeRoi == nil && mirroredRoi == nil && jiggleRoi == nil;
    }
}
-(void)setLocationOfSpriteNamed:(NSString *)name forROI:(ROI *)roi minGrey:(CGFloat)minGrey ratio:(CGFloat)ratio{
    CGFloat median = [ROIValues medianForROI:roi];
    CGFloat adjmedian = (median-minGrey)*ratio+kSceneMargin;
    CGFloat adjmean = (roi.mean-minGrey)*ratio+kSceneMargin;
    CGFloat adjsdev = roi.dev*ratio;
    CGFloat adjmin = (roi.min-minGrey)*ratio+kSceneMargin;
    CGFloat adjmax = (roi.max-minGrey)*ratio+kSceneMargin;
    CGFloat adjrange = (adjmax-adjmin);
    //CGFloat midrange = [ROIValues midRangeForMin:roi.min andMax:roi.max];
    CGFloat adjmidrange = [ROIValues midRangeForMin:adjmin andMax:adjmax];
    
    //midrange node moves with range
    SKSpriteNode *rangenode = (SKSpriteNode *)[self.skScene childNodeWithName:[name stringByAppendingString:kSpriteName_Range]];
    if (rangenode != nil) {
        rangenode.position = CGPointMake(adjmidrange, rangenode.position.y);
        rangenode.size = CGSizeMake(adjrange, rangenode.size.height);
    }
    //mean node moves with SD
    SKSpriteNode *sdnode = (SKSpriteNode *)[self.skScene childNodeWithName:[name stringByAppendingString:kSpriteName_SDEV]];
    if (sdnode != nil) {
        sdnode.position = CGPointMake(adjmean, rangenode.position.y);
        sdnode.size = CGSizeMake(adjsdev*2.0, sdnode.size.height);
        [self colourNode:sdnode forName:name];
    }
    //median is alone
    SKSpriteNode *mediannode = (SKSpriteNode *)[self.skScene childNodeWithName:[name stringByAppendingString:kSpriteName_Median]];
    if (mediannode != nil) {
        mediannode.position = CGPointMake(adjmedian, rangenode.position.y);
    }
    
    //update, text is alone too
    NSString *text = [self summaryStringOfSpriteNamed:name forROI:roi];
    [(SKLabelNode *)[self.skScene childNodeWithName:[name stringByAppendingString:kSpriteName_Text]] setText:text];
    
}
-(void)hideNodeNamed:(NSString *)name hidden:(BOOL)hidden {
    [(SKSpriteNode *)[self.skScene childNodeWithName:[name stringByAppendingString:kSpriteName_Range]] setHidden:hidden];
    [(SKSpriteNode *)[self.skScene childNodeWithName:[name stringByAppendingString:kSpriteName_SDEV]] setHidden:hidden];
    [(SKLabelNode *)[self.skScene childNodeWithName:[name stringByAppendingString:kSpriteName_Text]] setHidden:hidden];
    [(SKLabelNode *)[self.skScene childNodeWithName:[name stringByAppendingString:kSpriteName_Median]] setHidden:hidden];
    
}

-(NSString *)summaryStringForActiveRoiInCurrentSliceInViewer:(ViewerController *)viewer {
    NSString *ss = @"Not Found";
    NSString *name = [self roiNameForType:Active_ROI];
    ROI *roi = [self ROIfromCurrentSliceInViewer:viewer withName:name];//growingRegionROIName
    if (roi != nil) {
        ss = [NSString stringWithFormat:@"%@: %@",name,[self summaryStringOfSpriteNamed:name forROI:roi]];
    }
    return ss;
}

-(NSString *)summaryStringOfSpriteNamed:(NSString *)name forROI:(ROI *)roi {
    CGFloat midrange = [ROIValues midRangeForMin:roi.min andMax:roi.max];
    CGFloat median = [ROIValues medianForROI:roi];
    NSString *distanceString = @"";
    NSString *rankString = @"";
    if ([name isEqualToString:kSpriteName_Jiggle]) {
        NSInteger index = [self indexOfJiggleForROI:roi];
        if (index != NSNotFound && index<[self jiggleROIValuesArrayCountInCurrentSlice]) {
            distanceString = [NSString stringWithFormat:@" ∆%li", (long)[[[[self jiggleROIValuesArrayForCurrentSlice] objectAtIndex:index] distance] integerValue]];
            if ([MirrorROIPluginFilterOC userDefaultBooleanForKey:kRankJiggleDefault])
            {
                rankString = [NSString stringWithFormat:@" #%li", (long)[[[[self jiggleROIValuesArrayForCurrentSlice] objectAtIndex:index] rank] integerValue]];
            }
        }
    }
    NSString *text = [NSString stringWithFormat:@"%.0f ± %.0f %.0f (%.0f—%.0f—%.0f)%@%@", roi.mean, roi.dev, median, roi.min, midrange, roi.max, distanceString,rankString];
    return text;
}

#pragma mark - Jiggle
-(NSMutableArray *)jiggleROIValuesArrayForCurrentSlice {
    return [self jiggleROIvaluesArrayForSlice:[[self.viewerCT imageView] curImage]];
}
-(NSMutableArray *)jiggleROIvaluesArrayForSlice:(NSUInteger)slice {
    if (slice<self.arrayJiggleROIvalues.count)
    {
        return [self.arrayJiggleROIvalues objectAtIndex:slice];
    }
    return nil;
}
-(NSUInteger)jiggleROIvaluesArrayCountForSlice:(NSUInteger)slice {
    if (slice<self.arrayJiggleROIvalues.count)
    {
        NSMutableArray *vals = [self.arrayJiggleROIvalues objectAtIndex:slice];
        NSUInteger count = [vals count];
        return count;
    }
    return 0;
}
-(NSUInteger)jiggleROIValuesArrayCountInCurrentSlice {
    return [self jiggleROIvaluesArrayCountForSlice:[[self.viewerCT imageView] curImage]];
}

-(void)clearJiggleROIsAndValuesFromViewer:(ViewerController *)viewer inSlice:(NSInteger)slice {
    if ([self valid2DViewer:viewer])
    {
        if (slice == kAllSlices) {
            [self deleteROIsFromViewerController:viewer withName:kJiggleROIName];
            [self deleteROIsFromViewerController:viewer withName:kJiggleSelectedROIName];
            [self clearJiggleROIvaluesArrayAllSlices];
        }
        else {
            [self deleteROIsInSlice:slice inViewerController:viewer withName:kJiggleROIName];
            [self deleteROIsInSlice:slice inViewerController:viewer withName:kJiggleSelectedROIName];
            [self clearJiggleROIvaluesArrayAtSlice:slice];
        }
        [viewer needsDisplayUpdate];
        [self resetJiggleControlsAndRefresh];
    }
}
-(void)clearJiggleROIsAndValuesFromAllSlices {
    [self clearJiggleROIsAndValuesFromViewer:self.viewerCT inSlice:kAllSlices];
}
-(void)clearJiggleROIsAndValuesFromSlice:(NSInteger)slice {
    [self clearJiggleROIsAndValuesFromViewer:self.viewerCT inSlice:slice];
}
-(void)clearJiggleROIsAndValuesAndResetDisplayed {
    [self clearJiggleROIsAndValuesFromAllSlices];
    [self resetJiggleControlsAndRefresh];
    
}
-(void)clearJiggleROIArrayForTable {
    [[NSUserDefaults standardUserDefaults] setObject:[NSMutableArray array] forKey: kJiggleROIsArrayName];
}

-(void)rebuildJiggleROIArrayForTableOfSummaryStrings:(BOOL)addIndexNumber {
    NSMutableArray *arrayOFStrings = [self jiggleROIArrayForTableOfSummaryStrings:addIndexNumber];
    [[NSUserDefaults standardUserDefaults] setObject:arrayOFStrings forKey: kJiggleROIsArrayName];
}

-(NSMutableArray *)jiggleROIArrayForTableOfSummaryStrings:(BOOL)addIndexNumber {
    NSMutableArray *arrayOfRV = [self jiggleROIValuesArrayForCurrentSlice];
    NSMutableArray *arrayOFStrings = [NSMutableArray arrayWithCapacity:arrayOfRV.count];
    for (int i=0; i<arrayOfRV.count; i++) {
        ROIValues *rv = [arrayOfRV objectAtIndex:i];
        NSString *string = [self summaryStringOfSpriteNamed:kSpriteName_Jiggle forROI:rv.roi];
        if (addIndexNumber) {
            string = [NSString stringWithFormat:@"%li: %@",(long)i,string];
        }
        [arrayOFStrings addObject:@{kJiggleROIsArrayKey : string}];
    }
    return arrayOFStrings;
}
-(NSString *)jiggleROIArrayFinalSummaryString {
    NSMutableArray *arrayOFDicts = [self jiggleROIArrayForTableOfSummaryStrings:YES];
    //arrayofstrings is array of dicts
    NSMutableArray *arrayOFStrings = [NSMutableArray arrayWithCapacity:arrayOFDicts.count];
    for (int i=0; i<arrayOFDicts.count; i++) {
        [arrayOFStrings addObject:[(NSMutableDictionary*)[arrayOFDicts objectAtIndex:i] objectForKey:kJiggleROIsArrayKey]];
    }
    return [arrayOFStrings componentsJoinedByString:@"\n"];
}

-(void)clearJiggleROIvaluesArrayAllSlices {
    self.arrayJiggleROIvalues = [NSMutableArray arrayWithCapacity:self.viewerCT.roiList.count];
    for (int i=0; i<self.viewerCT.roiList.count; i++) {
        [self.arrayJiggleROIvalues addObject:[NSMutableArray arrayWithCapacity:[[NSUserDefaults standardUserDefaults] integerForKey:kJiggleBoundsPixels]*8]];
    }
    [self clearJiggleROIArrayForTable];
}
-(void)clearJiggleROIvaluesArrayAtSlice:(NSUInteger)slice {
    if (slice<self.arrayJiggleROIvalues.count)
    {
        [self.arrayJiggleROIvalues replaceObjectAtIndex:slice withObject:[NSMutableArray arrayWithCapacity:[[NSUserDefaults standardUserDefaults] integerForKey:kJiggleBoundsPixels]*8]];
        [self clearJiggleROIArrayForTable];
    }
}
-(void)clearJiggleROIvaluesArrayAtCurrentSlice {
    [self clearJiggleROIvaluesArrayAtSlice:[[self.viewerCT imageView] curImage]];
}

- (IBAction)changeJiggleROItapped:(NSButton *)sender {
    //deselect and select
    NSInteger index4ROI = [self indexOfJiggleForROI: [self ROIfromCurrentSliceInViewer:self.viewerCT withName:kJiggleSelectedROIName]];
    [self selectJiggleROIinCurrentSlicewithIndex:index4ROI deselect:YES];
    NSInteger newVal = MIN(MAX(self.levelJiggleIndex.integerValue+sender.tag,self.levelJiggleIndex.minValue),self.levelJiggleIndex.maxValue);
    self.levelJiggleIndex.integerValue = newVal;
    self.textJiggleRank.stringValue = [NSString stringWithFormat:@"%li",(long)newVal+1];
    [self selectJiggleROIinCurrentSlicewithIndex:newVal deselect:NO];
    [self refreshDisplayedDataForCT];
}
-(void)resetLevelJiggleWithCount {
    //NSLog(@"count: %li",(long)[self jiggleROIValuesArrayCountInCurrentSlice]);
    self.levelJiggleIndex.maxValue = [self jiggleROIValuesArrayCountInCurrentSlice]-1;
    self.levelJiggleIndex.integerValue = 0;
    self.textJiggleRank.stringValue = @"1";
    self.levelJiggleIndex.warningValue = self.levelJiggleIndex.maxValue+1;//*2/3;//8 in d1, 16 in d2 just inactivates
    self.levelJiggleIndex.criticalValue = self.levelJiggleIndex.maxValue+1;//just inactivates;
    [self hideJiggleControlsOnCount];
}
-(void)hideJiggleControlsOnCount {
    BOOL hide = ([self jiggleROIValuesArrayCountInCurrentSlice]<=0 || ![self valid2DViewer:self.viewerCT]);
    self.levelJiggleIndex.hidden = hide;
    self.buttonJiggleWorse.hidden = hide;
    self.buttonJiggleBetter.hidden = hide;
    self.buttonJiggleSetNew.hidden = hide;
    self.textJiggleRank.hidden = hide;
    
}
- (IBAction)generateJiggleROIsTapped:(NSButton *)sender {
    if ([self valid2DViewer:self.viewerCT])
    {
        switch (sender.tag) {
            case 0:
                [self clearJiggleROIsAndValuesFromSlice:[[self.viewerCT imageView] curImage]];
                [self generateJiggleROIsInSlice:[[self.viewerCT imageView] curImage]];
                break;
            case 1:
                [self replaceMirrorWithJiggleROI];
                break;
            case 2:
                [self clearJiggleROIsAndValuesFromAllSlices];
                for (NSUInteger i=0; i<self.viewerCT.roiList.count; i++) {
                    [self generateJiggleROIsInSlice:i];
                }
                break;
            default:
                break;
        }
        [self resetJiggleControlsAndRefresh];
        [self rebuildJiggleROIArrayForTableOfSummaryStrings:NO];
    }
}
-(void)generateJiggleROIsInSlice:(NSInteger)currentSlice {
    ROI *roi2ClonePET = [self ROIfromSlice:currentSlice inViewer:self.viewerPET withName:[self roiNameForType:Mirrored_ROI]];//we take the position of the MIRROR
    ROI *roi2CloneCT = [self ROIfromSlice:currentSlice inViewer:self.viewerCT withName:[self roiNameForType:Active_ROI]];//take VALUES of the ACTIVE
    if (roi2ClonePET != nil && roi2CloneCT != nil) {
        //make the ROIS grid, dont add the zero ROI as its the already mirror unless specifically requested
        BOOL excludeOriginal = ![MirrorROIPluginFilterOC userDefaultBooleanForKey:kIncludeOriginalInJiggleDefault];
        int minBounds = -1*(int)[[NSUserDefaults standardUserDefaults] integerForKey:kJiggleBoundsPixels];
        int maxBounds = (int)[[NSUserDefaults standardUserDefaults] integerForKey:kJiggleBoundsPixels];
        for (int moveX = minBounds; moveX<=maxBounds; moveX++) {
            for (int moveY = minBounds; moveY <= maxBounds; moveY++) {
                if (excludeOriginal && moveX == 0 && moveY == 0) {continue;}
                
                ROI *createdROI = [[ROI alloc]
                                   initWithTexture:roi2ClonePET.textureBuffer
                                   textWidth:roi2ClonePET.textureWidth
                                   textHeight:roi2ClonePET.textureHeight
                                   textName:roi2ClonePET.name
                                   positionX:roi2ClonePET.textureUpLeftCornerX+moveX
                                   positionY:roi2ClonePET.textureUpLeftCornerY+moveY
                                   spacingX:roi2ClonePET.pixelSpacingX
                                   spacingY:roi2ClonePET.pixelSpacingY
                                   imageOrigin:roi2ClonePET.imageOrigin];
                createdROI.name = kJiggleROIName;
                createdROI.locked = NO;
                [MirrorROIPluginFilterOC setROIcolour:createdROI forType:Jiggle_ROI];
                [self addROI2Pix:createdROI atSlice:currentSlice inViewer:self.viewerCT hidden:YES];
                //createdROI is now in CT, so we can use its pixels straight, alongside its mirror in CT
                [[self jiggleROIvaluesArrayForSlice:currentSlice] addObject:[ROIValues roiValuesWithComparatorROI:roi2CloneCT andJiggleROI:createdROI location:NSMakePoint(moveX, moveY)]];
            }
        }
        //SORT the ROIS by the criteria
        [self sortJiggleROIsInSlice:currentSlice];
        //update
        [self selectJiggleROIinSlice:currentSlice withIndex:0 deselect:NO];
        [self resetJiggleControlsAndRefresh];
    }
}
-(void)resetJiggleControlsAndRefresh {
    [self resetLevelJiggleWithCount];
    [self refreshDisplayedDataForCT];
}
-(void)selectJiggleROIinCurrentSlicewithIndex:(NSUInteger)index deselect:(BOOL)deselect{
    [self selectJiggleROIinSlice:[[self.viewerCT imageView] curImage] withIndex:index deselect:deselect];
}
-(void)selectJiggleROIinSlice:(NSUInteger)slice withIndex:(NSUInteger)index deselect:(BOOL)deselect{
    if (index<[self jiggleROIvaluesArrayCountForSlice:slice]) {
        [[(ROIValues *)[[self jiggleROIvaluesArrayForSlice:slice] objectAtIndex:index] roi] setHidden:deselect];
        if (deselect) {
            [[(ROIValues *)[[self jiggleROIvaluesArrayForSlice:slice] objectAtIndex:index] roi] setName:kJiggleROIName];
        }
        else {
            [[(ROIValues *)[[self jiggleROIvaluesArrayForSlice:slice] objectAtIndex:index] roi] setName:kJiggleSelectedROIName];
        }
    }
    
}
-(void)sortJiggleROIsInSlice:(NSUInteger)slice {
    //get the sort descriptors
    NSArray *sortDescriptors = [self sortDescriptorsForJiggle];
    if (sortDescriptors.count>0) {
        if ([MirrorROIPluginFilterOC userDefaultBooleanForKey:kRankJiggleDefault]) {
            // zero the ranks
            for (ROIValues *rv in [self jiggleROIvaluesArrayForSlice:slice]) {
                rv.rank = [NSNumber numberWithInteger:0];
            }
            //run thru sort descriptors sorting and updating the ranks one by ones
            for (NSInteger sortIndex = 0; sortIndex<sortDescriptors.count; sortIndex++) {
                //take Nth descriptor out and make into an array to sort
                [[self jiggleROIvaluesArrayForSlice:slice] sortUsingDescriptors:[NSArray arrayWithObject:[sortDescriptors objectAtIndex:sortIndex]]];
                
                //update the ranks now with the new order
                //we start with a rank of 0 and update it to index only when the value changes
                NSInteger rank = 0;
                NSString *currentSortKey = [[sortDescriptors objectAtIndex:sortIndex] key];
                //the index 0 object can be skipped as we just increment its rank by 0, and we cannot compare with the one before. A 1 size array just does not change...
                for (NSInteger index=1; index<[self jiggleROIvaluesArrayCountForSlice:slice]; index++) {
                    NSNumber *prevvalue = [(ROIValues *)[[self jiggleROIvaluesArrayForSlice:slice] objectAtIndex:index-1] valueForKey:currentSortKey];
                    NSNumber *currentvalue = [(ROIValues *)[[self jiggleROIvaluesArrayForSlice:slice] objectAtIndex:index] valueForKey:currentSortKey];
                    //if the value has changed we must change rank, otherwise stay on the rank
                    if (![prevvalue isEqualToNumber:currentvalue]) {
                        rank = index;
                    }
                    [(ROIValues *)[[self jiggleROIvaluesArrayForSlice:slice] objectAtIndex:index] incrementRankWithValue:rank];
                    //NSLog(@"Sort %@ prev %@ curr %@index %li rank %li",currentSortKey,prevvalue,currentvalue,(long)index,(long)rank);
                }
            }
            //now do the final sort by rank
            NSSortDescriptor *sd = [[[NSSortDescriptor alloc] initWithKey:@"rank" ascending:YES] autorelease];
            [[self jiggleROIvaluesArrayForSlice:slice] sortUsingDescriptors:[NSArray arrayWithObject:sd]];
        }
        else {
            [[self jiggleROIvaluesArrayForSlice:slice] sortUsingDescriptors:sortDescriptors];
        }
    }
}
-(NSArray *)sortDescriptorsForJiggle {
    NSArray *usersorts = [[NSUserDefaults standardUserDefaults] arrayForKey:kJiggleSortsArrayName];
    NSMutableArray *sorters = [NSMutableArray arrayWithCapacity:usersorts.count];
    if (usersorts.count>0) {
        for (int i=0; i<usersorts.count; i++) {
            NSMutableDictionary *dict = [usersorts objectAtIndex:i];
            if ([[dict objectForKey:kJiggleCheckKey] boolValue] == YES) {
                NSSortDescriptor *sd = [[[NSSortDescriptor alloc] initWithKey:[dict objectForKey:kJiggleSortKey] ascending:YES] autorelease];
                [sorters addObject:sd];
            }
        }
    }
    //    NSArray *array = @[[[NSSortDescriptor alloc] initWithKey:@"distance" ascending:YES],[[NSSortDescriptor alloc] initWithKey:@"meanfloor" ascending:YES]];
    //NSLog(@"%@",sorters);
    return sorters;
}
-(void)replaceMirrorWithJiggleROI {
    ROI *mirroredROI = [self ROIfromCurrentSliceInViewer:self.viewerPET withName:[self roiNameForType:Mirrored_ROI]];
    ROI *selJiggleROI = [self ROIfromCurrentSliceInViewer:self.viewerCT withName:kJiggleSelectedROIName];
    if (mirroredROI != nil && selJiggleROI != nil) {
        NSInteger index = [self indexOfJiggleForROI:selJiggleROI];
        if (index != NSNotFound) {
            NSPoint delta = [(ROIValues *)[[self jiggleROIValuesArrayForCurrentSlice] objectAtIndex:index] location];
            [self moveMirrorROIByAmount:delta];
            [self clearJiggleROIsAndValuesFromAllSlices];
            [self resetJiggleControlsAndRefresh];
        }
    }
}
-(NSInteger)indexOfJiggleForROI:(ROI *)roi2Test {
    for (int i=0; i<[self jiggleROIValuesArrayCountInCurrentSlice]; i++) {
        ROIValues *rv = [[self jiggleROIValuesArrayForCurrentSlice] objectAtIndex:i];
        if (rv.roi == roi2Test) {
            return i;
        }
    }
    return NSNotFound;
}
-(NSString *)jiggleROIfileName {
    return [MirrorROIPluginFilterOC fileNameWithNoBadCharacters:[NSString stringWithFormat:@"🌸-%@",[self petSeriesNameWithNoBadCharacters:YES]]];
}
-(NSString *)jiggleROIsummaryStringWithActiveROIinSliceString {
    return [NSString stringWithFormat:@"%@\n\n%@",[self summaryStringForActiveRoiInCurrentSliceInViewer:self.viewerCT],[self jiggleROIArrayFinalSummaryString]];
}


- (IBAction)tap:(id)sender {
}

@end
