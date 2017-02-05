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
    self.arrayBookmarkedSites = [NSMutableArray array];
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

-(void)handleNotification:(NSNotification *)notification {
    //NSLog(@"%@ -- %@ -- %@ << %li",notification.name, notification.object, notification.userInfo,(long)[[self.viewerCT imageView] curImage]);
    if ([notification.name isEqualToString:OsirixViewerControllerDidLoadImagesNotification] ||
        [notification.name isEqualToString:OsirixCloseViewerNotification]) {
        [self smartAssignCTPETwindows];
    }
    if ([notification.name isEqualToString:OsirixDCMUpdateCurrentImageNotification] &&
        notification.object == self.viewerCT.imageView) {
        [self resetJiggleControlsAndRefresh];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath containsString:kColor_Stem]) {
        [self refreshDisplayedDataForCT];
    }
}
#pragma mark - Initialisations
-(void)initDefaults {
    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
    [defaults setValue:[NSArchiver archivedDataWithRootObject:[NSColor yellowColor]] forKey:kColor_Active];
    [defaults setValue:[NSArchiver archivedDataWithRootObject:[NSColor blueColor]] forKey:kColor_Mirrored];
    [defaults setValue:[NSArchiver archivedDataWithRootObject:[NSColor greenColor]] forKey:kColor_TransformPlaced];
    [defaults setValue:[NSArchiver archivedDataWithRootObject:[NSColor redColor]] forKey:kColor_TransformIntercalated];
    [defaults setValue:[NSArchiver archivedDataWithRootObject:[NSColor purpleColor]] forKey:kColor_Jiggle];
    [defaults setValue:@"Transform" forKey:kTransformROInameDefault];
    [defaults setValue:@"Mirrored" forKey:kMirroredROInameDefault];
    
    [defaults setValue:[NSNumber numberWithInteger:0] forKey:kExportMenuSelectedIndexDefault];
    [defaults setValue:[NSNumber numberWithInteger:0] forKey:kSegmentFusedOrPETSegmentDefault];
    [defaults setValue:[NSNumber numberWithInteger:1] forKey:kMirrorMoveByPixels];
    [defaults setValue:[NSNumber numberWithInteger:1] forKey:kJiggleBoundsPixels];
    [defaults setValue:[NSNumber numberWithInteger:2] forKey:kExtendSingleTransformDefault];
    
    [defaults setValue:[NSNumber numberWithBool:YES] forKey:kCombineExportsOneFileDefault];
    [defaults setValue:[NSNumber numberWithBool:YES] forKey:kTransposeExportedDataDefault];
    [defaults setValue:[NSNumber numberWithBool:YES] forKey:kAddReportWhenSaveBookmarkedDataDefault];
    [defaults setValue:[NSNumber numberWithBool:NO] forKey:kIncludeOriginalInJiggleDefault];
    [defaults setValue:[NSNumber numberWithBool:YES] forKey:kRankJiggleDefault];
    [defaults setValue:[NSNumber numberWithBool:YES] forKey:kExportKeyImagesWhenSetting];
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
    [defaults setObject:[NSMutableArray arrayWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"treamentsites" ofType:@"plist"]] forKey:kDefaultArrayTreatmentSites];
    [defaults setObject:[NSMutableArray arrayWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"vaccines" ofType:@"plist"]] forKey:kDefaultArrayTreatmentVaccines];
    [defaults setObject:[NSMutableArray arrayWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"anatomicalsites" ofType:@"plist"]] forKey:kDefaultArrayAnatomicalSites];
    [defaults setObject:[NSMutableArray arrayWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"placebos" ofType:@"plist"]] forKey:kDefaultArrayPlacebos];

    
    //override Osirix Defaults
    [[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"ROITEXTIFSELECTED"];
    
    //register the defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    
    //add observers for defaults changes so app can respond
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kColor_Active options:NSKeyValueObservingOptionNew context:nil];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kColor_Mirrored options:NSKeyValueObservingOptionNew context:nil];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kColor_TransformPlaced options:NSKeyValueObservingOptionNew context:nil];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kColor_TransformIntercalated options:NSKeyValueObservingOptionNew context:nil];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kColor_Jiggle options:NSKeyValueObservingOptionNew context:nil];
}

-(BOOL)userDefaultBoolForKey:(NSString *)key {
    return [[NSUserDefaults standardUserDefaults] boolForKey:key];
}

-(void)initNotfications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:OsirixCloseViewerNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:OsirixViewerControllerDidLoadImagesNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:OsirixDCMUpdateCurrentImageNotification object:nil];
}

#pragma mark - Windows
+(void)alertWithMessage:(NSString *)message andTitle:(NSString *)title
{
    NSRunCriticalAlertPanel(NSLocalizedString(title,nil), NSLocalizedString(message,nil) , NSLocalizedString(@"Close",nil), nil, nil);
}
+(void)alertSound {
    [[NSSound soundNamed:@"Basso"] play];
}
-(IBAction)assignWindowClicked:(NSButton *)sender {
    [self assignViewerWindow:[ViewerController frontMostDisplayed2DViewer] forType:sender.tag];
}
-(void)assignViewerWindow:(ViewerController *)viewController forType:(ViewerWindow_Type)type {
    [self clearTreatmentFields];
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
            [self populateTreatmentFieldsFromComments];
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
        [MirrorROIPluginFilterOC alertWithMessage:@"PET and CT windows have mismatched number of slices" andTitle:@"Unable To Proceed"];
        return NO;
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
        savePanel.nameFieldStringValue = [[MirrorROIPluginFilterOC fileNameForComboBox:comboBox] stringByAppendingPathExtension:@"txt"];
        if ([savePanel runModal] == NSFileHandlingPanelOKButton) {
            NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:nil];
            [[array componentsJoinedByString:@"\n"] writeToURL:savePanel.URL atomically:YES encoding:NSUnicodeStringEncoding error:&error];
        }
    }
    else {
        [MirrorROIPluginFilterOC alertWithMessage:@"There are no items in the list" andTitle:[NSString stringWithFormat:@"Export Items for %@",[MirrorROIPluginFilterOC fileNameForComboBox:comboBox]]];
    }
}

-(void)importComboArrayFileAtURL:(NSURL *)url forComboBox:(ComboBoxIdentifier)comboBox {
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
    if (array.count>0) {
        switch (comboBox) {
            case Combo_Vaccines_Load:
                [[NSUserDefaults standardUserDefaults] setObject:array forKey:kDefaultArrayTreatmentVaccines];
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
        [MirrorROIPluginFilterOC alertWithMessage:[NSString stringWithFormat:@"The file could not be loaded either because it could not be opened or it did not contain readable text. The file must be text with a single item on each line. Read Error: %@", error.localizedDescription] andTitle:@"Error loading file"];
    }
}

#pragma mark - ComboBox
+(NSString *)fileNameForComboBox:(ComboBoxIdentifier)comboBox {
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
            return [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultArrayTreatmentVaccines];
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
            [self alterArrayForComboBox:self.comboVaccines forIdentifier:kDefaultArrayTreatmentVaccines withAlteration:ComboArrayAdd];
            break;
        case Combo_Vaccines_Delete:
            [self alterArrayForComboBox:self.comboVaccines forIdentifier:kDefaultArrayTreatmentVaccines withAlteration:ComboArrayDelete];
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
- (IBAction)growRegionClicked:(id)sender {
    [self.viewerPET.window makeKeyAndOrderFront:nil];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [[NSApplication sharedApplication] sendAction:@selector(segmentationTest:) to:self.viewerPET from:self.viewerPET];
#pragma clang diagnostic pop
}

#pragma mark - Create Transforms
-(IBAction)addTransformROIs:(NSButton *)sender {
    if ([self validSliceCountInCTandPETwindows])
    {
        [self addBoundingTransformROIS];
    }
}
-(void)addBoundingTransformROIS {
    ViewerController *viewerToAdd = [self viewerForTransformsAccordingToFusedOrPetAloneWindowSetting];
    if (viewerToAdd != nil)
    {
        [viewerToAdd setROIToolTag:tMesure];
        [viewerToAdd deleteSeriesROIwithName:[self ROInameForType:Transform_ROI_Placed]];
        
        //find the first and last pixIndex with an ACTIVE ROI
        NSMutableIndexSet *indexesWithROI= [[NSMutableIndexSet alloc]init];
        NSString *activeROIname = [self ROInameForType:Active_ROI];
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
            [MirrorROIPluginFilterOC alertWithMessage:@"No PET slices have ROIs" andTitle:@"Creating transforms"];
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
        [MirrorROIPluginFilterOC alertWithMessage:@"Unable to add bounding transforms as no valid viewer" andTitle:@"Creating transforms"];
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
    newR.name = [self ROInameForType:type];
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
        NSString *measureROIname;
        measureROIname = [self ROInameForType:Transform_ROI_Placed];
        
        //collect up the ROIs
        for (int index = 0;index<allROIsList.count; index++) {
            ROI *measureROI = [MirrorROIPluginFilterOC roiFromList:[allROIsList objectAtIndex:index] WithType:tMesure];
            if (measureROI != nil) {
                //measureROI.hidden = true;//self.segmentShowHideTransformMarkers.selectedSegment;
                measureROI.offsetTextBox_x = 10000.0;
                //rename the ROIS
                measureROI.name = measureROIname;
                [measureROIs addObject:measureROI];
                [indicesOfDCMPixWithMeasureROI addObject:[NSNumber numberWithInt:index]];
            }
        }
        switch (indicesOfDCMPixWithMeasureROI.count)
        {
            case 0:
                [MirrorROIPluginFilterOC alertWithMessage:@"No bounding transforms detected" andTitle:@"Completing transform series"];
                break;
            case 1:
            {
                ROI *roi = [[measureROIs firstObject] copy];
                roi.locked = NO;
                switch ([[NSUserDefaults standardUserDefaults] integerForKey:kExtendSingleTransformDefault])
                {
                    case ExtendSingleLengthUp:
                        [self extendROI:roi withinSeriesFromStart:[[indicesOfDCMPixWithMeasureROI firstObject] intValue]+1 toEnd:allROIsList.count inViewerController:viewerToAdd];
                        break;
                    case ExtendSingleLengthDown:
                        [self extendROI:roi withinSeriesFromStart:0 toEnd:[[indicesOfDCMPixWithMeasureROI firstObject] intValue] inViewerController:viewerToAdd];
                        break;
                    case ExtendSingleLengthBoth:
                        [self extendROI:roi withinSeriesFromStart:[[indicesOfDCMPixWithMeasureROI firstObject] intValue]+1 toEnd:allROIsList.count inViewerController:viewerToAdd];
                        [self extendROI:roi withinSeriesFromStart:0 toEnd:[[indicesOfDCMPixWithMeasureROI firstObject] intValue] inViewerController:viewerToAdd];
                        break;
                }
            }
            default:
                //-1 as we go in pairs and so skip the last one
                for (int roiNumber=0; roiNumber<indicesOfDCMPixWithMeasureROI.count-1; roiNumber++)
                {
                    [self completeLengthROIseriesForViewerController:viewerToAdd
                    betweenROI1:[measureROIs objectAtIndex:roiNumber]
                    andROI2:[measureROIs objectAtIndex:roiNumber+1]
                    inThisRange:NSMakeRange(
                        //skip the start index it already has aROI
                        [[indicesOfDCMPixWithMeasureROI objectAtIndex:roiNumber] unsignedIntegerValue]+1,
                        //length = difference between end and start minus 1 to skip last one
                        [[indicesOfDCMPixWithMeasureROI objectAtIndex:roiNumber+1] unsignedIntegerValue]-
                        [[indicesOfDCMPixWithMeasureROI objectAtIndex:roiNumber] unsignedIntegerValue]-1)
                     ];
                }
                break;
        }
        [viewerToAdd needsDisplayUpdate];
    }
    else
    {
        [MirrorROIPluginFilterOC alertWithMessage:@"Invalid viewer" andTitle:@"Completing transform series"];
    }
}
-(void)completeLengthROIseriesForViewerController:(ViewerController *)active2Dwindow betweenROI1:(ROI *)roi1 andROI2:(ROI *)roi2 inThisRange:(NSRange)rangeOfIndices{
    //not needed right way NSMutableArray  *allROIsList = [active2Dwindow roiList];
    MyPoint *roi1_Point1 = [roi1.points objectAtIndex:0];
    MyPoint *roi1_Point2 = [roi1.points objectAtIndex:1];
    MyPoint *roi2_Point1 = [roi2.points objectAtIndex:0];
    MyPoint *roi2_Point2 = [roi2.points objectAtIndex:1];
    float numberOfSlices = rangeOfIndices.length;//-rangeOfIndices.location;
    float Xincrement1 = (roi2_Point1.point.x - roi1_Point1.point.x)/numberOfSlices;
    float Xincrement2 = (roi2_Point2.point.x - roi1_Point2.point.x)/numberOfSlices;
    float XincrementCurrent1 = Xincrement1;
    float XincrementCurrent2 = Xincrement2;
    float Yincrement1 = (roi2_Point1.point.y - roi1_Point1.point.y)/numberOfSlices;
    float Yincrement2 = (roi2_Point2.point.y - roi1_Point2.point.y)/numberOfSlices;
    float YincrementCurrent1 = Yincrement1;
    float YincrementCurrent2 = Yincrement2;
    //skip first and last index
    for (NSUInteger nextIndex = rangeOfIndices.location; nextIndex<rangeOfIndices.location+rangeOfIndices.length; nextIndex++)
    {
        ROI *newROI = [roi1 copy];
        newROI.locked = NO;
        [MirrorROIPluginFilterOC  setROIcolour:newROI forType:Transform_Intercalated];
        [[[newROI points] objectAtIndex:0] move:XincrementCurrent1 :YincrementCurrent1];
        [[[newROI points] objectAtIndex:1] move:XincrementCurrent2 :YincrementCurrent2];
        //wrong way[[allROIsList objectAtIndex:nextIndex] addObject:newROI];
        [self addROI2Pix:newROI atSlice:nextIndex inViewer:active2Dwindow hidden:NO];

        newROI.offsetTextBox_x = 10000.0;
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
    [self copyTransformsAndMirrorActivesIn3D:sender.tag];
}
-(void)copyTransformsAndMirrorActivesIn3D:(BOOL)in3D {
    if ([self copyTransformROIsFromCT2PETIn3D:in3D])
    {
        [self mirrorActiveROIUsingLengthROIn3D:in3D];
        [self.viewerPET needsDisplayUpdate];
        [self.viewerCT needsDisplayUpdate];
        [self resetJiggleControlsAndRefresh];
    }
}
-(BOOL)copyTransformROIsFromCT2PETIn3D:(BOOL)in3D {
    if ([MirrorROIPluginFilterOC useFusedOrPetAloneWindow] == UseFusedWindows
        && [self validCTandPETwindows]
        && [self validSliceCountInCTandPETwindows])
    {
        BOOL copiedSomething = NO;
        NSUInteger startSlice = 0;
        NSUInteger endSlice = 0;
        NSString *transformname = [self ROInameForType:Transform_ROI_Placed];
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
                    [self addROI2Pix:roiC atSlice:pixIndex inViewer:self.viewerPET hidden:YES];
                    copiedSomething = YES;
                }
            }
        }
        if (copiedSomething) {
            return YES;
        }
        else
        {
            [MirrorROIPluginFilterOC alertWithMessage:@"Unable to complete as no valid transforms were found" andTitle:@"Copy transforms"];
            return NO;
        }
    }
    else
    {
        [MirrorROIPluginFilterOC alertWithMessage:@"Unable to complete as either the viewer windows are not assigned, or the number of slices in each window do not match" andTitle:@"Copy transforms"];
        return NO;
    }
}

-(void)mirrorActiveROIUsingLengthROIn3D:(BOOL)in3D {
    BOOL mirroredSomething = NO;
    
    NSMutableArray  *roisInAllSlices  = [self.viewerPET roiList];
    NSUInteger startSlice = 0;
    NSUInteger endSlice = 0;
    if (in3D) {
        [self deleteROIsFromViewerController:self.viewerPET withName:[self ROInameForType:Mirrored_ROI]];
        [self deleteROIsFromViewerController:self.viewerCT withName:[self ROInameForType:Active_ROI]];
        [self deleteROIsFromViewerController:self.viewerCT withName:[self ROInameForType:Mirrored_ROI]];
        [self clearJiggleROIsAndValuesFromAllSlices];
        startSlice = 0;
        endSlice = roisInAllSlices.count;
    }
    else
    {
        startSlice = [[self.viewerPET imageView] curImage];
        endSlice = startSlice+1;
        [self deleteROIsInSlice:startSlice inViewerController:self.viewerPET withName:[self ROInameForType:Mirrored_ROI]];
        [self deleteROIsInSlice:startSlice inViewerController:self.viewerCT withName:[self ROInameForType:Active_ROI]];
        [self deleteROIsInSlice:startSlice inViewerController:self.viewerCT withName:[self ROInameForType:Mirrored_ROI]];
        [self clearJiggleROIsAndValuesFromSlice:startSlice];
    }
    
    for (NSUInteger slice=startSlice; slice<endSlice; slice++) {
        NSMutableArray *roisInThisSlice = [roisInAllSlices objectAtIndex:slice];
        ROI *roi2Clone = [MirrorROIPluginFilterOC roiFromList:roisInThisSlice WithType:tPlain];
        if (roi2Clone != nil) {
            //rename to keep in sync
            roi2Clone.name = [self ROInameForType:Active_ROI];
            [MirrorROIPluginFilterOC  setROIcolour:roi2Clone forType:Active_ROI];
            
            NSPoint deltaXY = [MirrorROIPluginFilterOC deltaXYFromROI:roi2Clone usingLengthROI:[MirrorROIPluginFilterOC roiFromList:roisInThisSlice WithType:tMesure]];
            
            if ([MirrorROIPluginFilterOC validDeltaPoint:deltaXY]) {
                ROI *createdROI = [[ROI alloc]
                                   initWithTexture:[MirrorROIPluginFilterOC flippedBufferHorizontalFromROI:roi2Clone]
                                   textWidth:roi2Clone.textureWidth
                                   textHeight:roi2Clone.textureHeight
                                   textName:[self ROInameForType:Mirrored_ROI]
                                   positionX:roi2Clone.textureUpLeftCornerX+deltaXY.x
                                   positionY:roi2Clone.textureUpLeftCornerY-deltaXY.y
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
    }
    [MirrorROIPluginFilterOC deselectROIforViewer:self.viewerPET];
    [MirrorROIPluginFilterOC deselectROIforViewer:self.viewerCT];
    [self.viewerPET needsDisplayUpdate];
    [self.viewerCT needsDisplayUpdate];
    if (!mirroredSomething) {
        [MirrorROIPluginFilterOC alertWithMessage:@"Unable to mirror anything" andTitle:@"Mirror Active ROI"];
    }
}

#pragma mark - Delta point

+(NSPoint)deltaXYFromROI:(ROI*)roi2Clone usingLengthROI:(ROI*)lengthROI {
    NSPoint deltaPoint = [self anInvalidDeltaPoint];
    
    if (roi2Clone && lengthROI) {
        NSPoint ipsi = [(MyPoint *)[lengthROI.points objectAtIndex:0] point];
        NSPoint contra = [(MyPoint *)[lengthROI.points objectAtIndex:1] point];
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
         Y is not mirrored and must only move by the translation to keep the floor of the texture aligned with the anchor
                        translation             */
        deltaPoint.y = ceilf(contra.y-ipsi.y);
        
    }
    return deltaPoint;
}
+(BOOL)validDeltaPoint:(NSPoint)delta2test{
    return delta2test.x != CGFLOAT_MAX && delta2test.y != CGFLOAT_MAX;
}
+(NSPoint)anInvalidDeltaPoint{
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
        if ([roi2Clone.name isEqualToString:[self ROInameForType:Mirrored_ROI]]) {
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
            //[roisInThisSlice replaceObjectAtIndex:i withObject:createdROI];
            //[MirrorROIPluginFilterOC forceRecomputeDataForROI:createdROI];
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
    [self deleteROIsFromViewerController:viewer withName:text];
    ROI *roi = [viewer newROI:tText];
    [roi setThickness:8.0 globally:NO];//number of points above/below 12 the value is multiplied by 2
    [roi setNSColor:colour globally:NO];
    [roi setName:text];
    [self addROI2Pix:roi atSlice:slice inViewer:viewer hidden:NO];
    NSRect rect= roi.rect;
    rect.origin = NSMakePoint(roi.pix.pwidth*0.5, roi.pix.pheight*[[NSUserDefaults standardUserDefaults] floatForKey:kKeyImageHeightFractionDefault]);
    [roi setROIRect:rect];
    
}
-(void)addROI2Pix:(ROI *)roi2add atSlice:(NSUInteger)slice inViewer:(ViewerController *)viewer hidden:(BOOL)hidden {
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
- (IBAction)deleteActiveViewerROIsOfType:(NSButton *)sender {
    
    switch (sender.tag) {
        case Mirrored_ROI:
            [self deleteROIsFromViewerController:self.viewerPET withName:[self ROInameForType:Mirrored_ROI]];
            break;
        case Active_ROI:
            [self deleteROIsFromViewerController:self.viewerPET withName:[self ROInameForType:Mirrored_ROI]];
            break;
        case Jiggle_ROI:
            [self clearJiggleROIsAndValuesAndResetDisplayed];
            break;
        case Transform_ROI_Placed:
            [self deleteROIsFromViewerController:self.viewerPET withName:[self ROInameForType:Transform_ROI_Placed]];
            [self deleteROIsFromViewerController:self.viewerCT withName:[self ROInameForType:Transform_ROI_Placed]];
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
-(void)unlockROIsIn2DViewer:(ViewerController *)viewer withSeriesName:(NSString *)name{
    for (NSUInteger roiIndex =0; roiIndex<viewer.roiList.count;roiIndex++) {
        for (ROI *roi in [viewer.roiList objectAtIndex:roiIndex]) {
            if (name == nil || [roi.name isEqualToString:name]) {
                roi.locked = NO;
            }
        }
    }
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
        NSMutableIndexSet *set = [NSMutableIndexSet indexSet];
        for (NSUInteger i = 0; i<[roisInSlice count];i++) {
            ROI *roi = [roisInSlice objectAtIndex:i];
            if ([roi.name isEqualToString:name]) {
                [set addIndex:i];
            }
        }
        if (set.count>0) {
            [roisInSlice removeObjectsAtIndexes:set];
        }
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
        [active2Dwindow roiDeleteAll:nil];
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
-(NSString *)ROInameForType:(ROI_Type)type {
    switch (type) {
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
            return [NSString stringWithFormat:@"%@_%@",[self ROInameForType:Active_ROI],[self ROInameForType:Mirrored_ROI]];
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
    return [self.comboAnatomicalSite.stringValue stringByAppendingString:@" "];
}
-(BOOL)anatomicalSiteDefined {
    if (self.comboAnatomicalSite.stringValue.length > 0)
    {
        return YES;
    }
    else
    {
        [MirrorROIPluginFilterOC alertWithMessage:@"No anatomical site is entered - please enter a description and try again." andTitle:@"Anatomical Site Undefined"];
        return NO;
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
        case BookmarkQuickLook:
            [self exportBookmarkedData:ViewInWindow];
            break;

        default:
            break;
    }
}


-(void)subtractBookmarkDataForSelectedSite {
    NSInteger index = self.arrayControllerBookmarks.selectionIndex;
    if (index>=0 && index <self.arrayBookmarkedSites.count) {
        NSString *selectedSite = [self.arrayBookmarkedSites objectAtIndex:index];
        [self.arrayControllerBookmarks removeObjectAtArrangedObjectIndex:index];
        [self.dictBookmarks removeObjectForKey:selectedSite];
    }
}

-(void)trashAllBookmarks {
    //easier to use this method to clear the array
    [self willChangeValueForKey:@"arrayBookmarkedSites"];
    [self.arrayBookmarkedSites removeAllObjects];
    [self didChangeValueForKey:@"arrayBookmarkedSites"];
    [self.dictBookmarks removeAllObjects];
}
-(void)addBookmarkDataForCurrentSite {
    if ([self anatomicalSiteDefined]) {
        NSString *anatSite = [self anatomicalSiteName];
        [self.arrayControllerBookmarks removeObject:anatSite];//erase to replace
        [self.arrayControllerBookmarks addObject:anatSite];
        
        NSMutableDictionary *dictForSite = [self.dictBookmarks objectForKey:anatSite];
        if (dictForSite == nil) {
            dictForSite = [NSMutableDictionary dictionary];
        }
        [dictForSite setObject:[self bookmarkStringForSite:anatSite] forKey:kBookmarkStringKey];
        [self.dictBookmarks setObject:dictForSite forKey:anatSite];
    }
}

-(NSString *)bookmarkStringForSite:(NSString *)anatSite {
    return [NSString stringWithFormat:@"***********\n%@\n***********\n%@\n\n%@\n\n%@\n\n",anatSite,[self pixelStatsStringForType:PixelsGridAllData],[self combinedAandMstringsForExportROIdata_A:[self exportAllROIdataStringForType:Active_ROI] M:[self exportAllROIdataStringForType:Mirrored_ROI]],[self jiggleROIsummaryStringWithActiveROIinSliceString]];
}

-(NSString *)bookMarkStringsConjoined {
    NSMutableArray *rows = [NSMutableArray arrayWithCapacity:self.dictBookmarks.count];
    for (NSString *key in self.dictBookmarks) {
        NSMutableDictionary *dictForSite = [self.dictBookmarks objectForKey:key];
        NSString *bookmarkStringForSite = [dictForSite objectForKey:kBookmarkStringKey];
        [rows addObject:bookmarkStringForSite];
    }
    return [NSString stringWithFormat:@"%@\n%@",[self participantDetailsString],[rows componentsJoinedByString:@"\n\n"]];
}
-(NSString *)bookmarkedDataFilename {
    NSString *fileTypeName = [self exportTypeStringForExportType:BookmarkedData withAnatomicalSite:NO];
    NSString *fileName = [NSString stringWithFormat:@"%@-%@",fileTypeName,self.viewerPET.window.title];
    return fileName;
}
- (void)attachBookmarkedDataFileAsReport:(NSURL*)url {
    DicomStudy *study = [self.viewerPET currentStudy];
    [[BrowserController currentBrowser] importReport:url.path UID:study.studyInstanceUID];
}

- (void)exportBookmarkedData:(ExportDataHow)exportHow {
    NSURL *savedLocation = nil;
    switch (exportHow) {
        case ExportAsFile:
            savedLocation = [self saveData:[self bookMarkStringsConjoined]
                  withName:[self bookmarkedDataFilename]];
            break;
        case ViewInWindow:
            [MirrorROIPluginFilterOC showStringInWindow:[self bookMarkStringsConjoined]
                                              withTitle:[self bookmarkedDataFilename]];
            break;
        default:
            break;
    }
    
    if (savedLocation != nil && [self userDefaultBoolForKey:kAddReportWhenSaveBookmarkedDataDefault])
    {
        [self attachBookmarkedDataFileAsReport:savedLocation];
    }
}

#pragma mark - Comments
-(NSString *)participantDetailsString {
    DicomStudy *study = [self.viewerPET currentStudy];
    return [NSString stringWithFormat:@"%@\t%@\nVaccine\tScan Day\tInjection Location\n%@\nSeries Analysed: %@",study.name,study.patientID,study.comment,self.viewerPET.window.title];
}
-(IBAction)clearTreatmentFieldsTapped:(id)sender {
    [self clearTreatmentFields];
}
-(void)clearTreatmentFields {
    self.comboVaccines.stringValue = @"";
    self.comboTreatmentSite.stringValue = @"";
    self.textFieldVaccineDayOffset.stringValue = @"";
    self.comboPlaceboUsed.stringValue = @"";

}
-(void)populateTreatmentFieldsFromComments {
    NSArray *commentsArray = [[[self.viewerPET currentStudy] comment] componentsSeparatedByString:@"\t"];
    if (commentsArray.count >= 4) {
        self.comboVaccines.stringValue = [commentsArray objectAtIndex:0];
        self.comboTreatmentSite.stringValue = [commentsArray objectAtIndex:1];
        self.textFieldVaccineDayOffset.stringValue = [commentsArray objectAtIndex:2];
        self.comboPlaceboUsed.stringValue = [commentsArray objectAtIndex:3];
    }
}

-(NSString *)correctedStringForNullString:(NSString *)string {
    if (string == nil) {return @"-";}
    return string;
}

-(IBAction)readWriteCommentsFromFieldsTapped:(NSButton *)sender {
    switch (sender.tag) {
        case WriteComments:
            [[self.viewerPET currentStudy] setComment:[NSString stringWithFormat:@"%@\t%@\t+%@\t%@",
                                                       [self correctedStringForNullString:self.comboVaccines.stringValue],
                                                       [self correctedStringForNullString:self.comboTreatmentSite.stringValue],
                                                       [self correctedStringForNullString:self.textFieldVaccineDayOffset.stringValue],
                                                       [self correctedStringForNullString:self.comboPlaceboUsed.stringValue]]];
            break;
        case ReadComments:
            [self populateTreatmentFieldsFromComments];
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
                if ([self userDefaultBoolForKey:kExportKeyImagesWhenSetting]) {
                    [self exportKeyImagesFromViewersTypes:CTandPET_Windows];
                }
            }
            break;
        default:
            break;
    }
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
    return [NSString stringWithFormat:@"%@_%04li.png",viewer.window.title,(long)index];
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
                NSString *filename = [[filenameImageDict objectForKey:@"name"] stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
                NSURL *fileURL = [dirUrl URLByAppendingPathComponent:filename];
                [imageData writeToURL:fileURL atomically:YES];
            }
        }
    }
}

#pragma mark - ROI Export
-(NSString *)exportTypeStringForExportType:(ExportDataType)type withAnatomicalSite:(BOOL)withSite {
    NSString *typeString = @"";
    switch (type) {
        case RoiData:
            typeString =  @"_RoiData";
            break;
        case RoiPixelsFlat:
            typeString =  @"_ROIPixelsFlatData";
            break;
        case PixelsGridSummary:
            typeString =  @"_PixelsGridSummaryData";
            break;
        case PixelsGridAllData:
            typeString =  @"_PixelsGridAllData";
            break;
        case RoiSummary:
            typeString =  @"_ROISummaryData";
            break;
        case RoiThreeD:
            typeString =  @"_ROI3DData";
            break;
        case AllROIdata:
            typeString =  @"_ROIAllData";
            break;
        case PETRois:
            typeString =  @"_PETROIs";
            break;
        case BookmarkedData:
            typeString =  @"BookmarkedData";
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
-(void)exportData:(ExportDataHow)exportHow {
    NSInteger exportType = self.popupExportData.indexOfSelectedItem;
    switch (exportType) {
        case RoiData:
        case RoiSummary:
        case RoiThreeD:
        case AllROIdata:
        case RoiPixelsFlat:
            [self exportROIdata:exportHow];
            break;
        case PETRois:
            [self exportAMTroi];
            break;
        case PixelsGridSummary:
        case PixelsGridAllData:
            [self exportDeltaROI:exportHow exportType:exportType];
            break;
        case JiggleRoi:
            [self exportJiggleValues:exportHow];
            break;
        default:
            break;
    }
}
- (void)exportJiggleValues:(ExportDataHow)exportHow {
    switch (exportHow) {
        case ExportAsFile:
                [self saveData:[self jiggleROIsummaryStringWithActiveROIinSliceString]
                      withName:[self jiggleROIfileName]];
            break;
        case ViewInWindow:
            [MirrorROIPluginFilterOC showStringInWindow:[self jiggleROIsummaryStringWithActiveROIinSliceString]
                                              withTitle:[self jiggleROIfileName]];
            break;
        default:
            break;
    }

}

-(NSString *)pixelStatsStringFromDictionary:(NSMutableDictionary*)dict forType:(ExportDataType)type {
    NSString *stats = @"";
    NSArray *keys = [dict.allKeys sortedArrayUsingSelector:@selector(compare:)];
    for (int k=0;k<keys.count;k++) {
        NSString *currkey = keys[k];
        if (![currkey containsString:kDeltaNameGridDataTag]) {
            stats = [stats stringByAppendingString:[NSString stringWithFormat:@"%@\t%@\n",currkey,dict[currkey]]];
        }
    }
    switch (type) {
        case PixelsGridAllData:
            return [NSString stringWithFormat:@"%@\n%@\n%@\n%@\n%@\n%@\n%@\n%@\n%@\n%@\n%@\n%@\n%@\n%@\n",
                    stats,
                    kDeltaNameActivePixFlat,
                    [[self arrayOfIndexesOfSlicesWithROIofType:Active_ROI] componentsJoinedByString:@"\t"],
                    [self stringForDataArray:[dict objectForKey:kDeltaNameActivePixFlat] forceTranspose:NO],
                    kDeltaNameMirroredPixFlat,
                    [self stringForDataArray:[dict objectForKey:kDeltaNameMirroredPixFlat] forceTranspose:NO],
                    kDeltaNameSubtractedPix,
                    [self stringForDataArray:[dict objectForKey:kDeltaNameSubtractedPix] forceTranspose:NO],
                    kDeltaNameDividedPix,
                    [self stringForDataArray:[dict objectForKey:kDeltaNameDividedPix] forceTranspose:NO],
                    kDeltaNameActivePixGrid,
                    [self dataStringFor2DpixelDataForROIType:Active_ROI],
                    kDeltaNameMirroredPixGrid,
                    [self dataStringFor2DpixelDataForROIType:Mirrored_ROI]
                    ];
            break;
        case PixelsGridSummary:
            return stats;
            break;
        default:
            return @"?";
            break;
    }
}

-(NSString *)pixelStatsStringForType:(ExportDataType)type {
    return [self pixelStatsStringFromDictionary:[self pixelStatsDictionary] forType:type];
}

-(void)exportDeltaROI:(ExportDataHow)exportHow exportType:(ExportDataType)exportType {
    NSString *fileTypeName = [self exportTypeStringForExportType:exportType withAnatomicalSite:YES];
    NSString *fileName = [NSString stringWithFormat:@"%@-%@",fileTypeName,self.viewerPET.window.title];
    switch (exportHow) {
        case ExportAsFile:
            [self saveData:[self pixelStatsStringForType:exportType] withName:fileName];
            break;
        case ViewInWindow:
            [MirrorROIPluginFilterOC showStringInWindow:[self pixelStatsStringForType:exportType] withTitle:fileName];
            break;
        default:
            break;
    }
}

-(NSMutableArray *)pixelsForROI:(ROI *)roi{
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

-(NSMutableDictionary *)pixelStatsDictionary {
    NSMutableArray *dataAflat = [NSMutableArray array];//[self pixelDataFromROIasFlatArrayForType:Active_ROI addHeader:NO];
    NSMutableArray *dataMflat = [NSMutableArray array];//[self pixelDataFromROIasFlatArrayForType:Mirrored_ROI addHeader:NO];
    
    NSMutableArray *dataA2D = [self pixelBufferValuesAs2DArrayForType:Active_ROI];
    NSMutableArray *dataM2D = [self pixelBufferValuesAs2DArrayForType:Mirrored_ROI];

    NSMutableArray *subtracted = [NSMutableArray array];
    NSMutableArray *divided = [NSMutableArray array];
    NSUInteger countOfPixels = 0;
    CGFloat sumOfSubtract = 0.0;
    CGFloat sumOfDivide = 0.0;
    CGFloat sumOfA = 0.0;
    CGFloat maxOfA = -INT_MAX;
    CGFloat minOfA = INT_MAX;
    CGFloat sumOfM = 0.0;
    CGFloat maxOfM = -INT_MAX;
    CGFloat minOfM = INT_MAX;
    
    if (dataA2D.count>0 && dataA2D.count == dataM2D.count) {
        //each roiIndex has a 2D array of Y axis rows of pixels for that roi in a 2D grid
        //so we have to unpack those and mirror the final Y rows for the mirrored roi
        for (int roiIndex=0; roiIndex<dataA2D.count; roiIndex++) {
            //these are our 2D arrays of rows with pixels, y = row index on Y axis
            NSMutableArray *pixelsGridA = [dataA2D objectAtIndex:roiIndex];
            NSMutableArray *pixelsGridM = [dataM2D objectAtIndex:roiIndex];
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
                    CGFloat M = [[rowMatY objectAtIndex:rowMatY.count-col-1] floatValue];//reversed
                    sumOfA += A;
                    maxOfA = fmaxf(maxOfA, A);
                    minOfA = fminf(minOfA, A);
                    sumOfM += M;
                    maxOfM = fmaxf(maxOfM, M);
                    minOfM = fminf(minOfM, M);
                    
                    CGFloat subtraction = A-M;
                    CGFloat division = A/M;
                    sumOfSubtract += subtraction;
                    sumOfDivide += division;
                    //add the results to our 1D rows
                    [roiSubtract addObject:[NSNumber numberWithFloat:subtraction]];
                    [roiDivide addObject:[NSNumber numberWithFloat:division]];
                    
                    //add the NSNumbers to our flat 1D row, we note the reversal
                    [dataForROIflatA addObject:[rowAatY objectAtIndex:col]];
                    [dataForROIflatM addObject:[rowMatY objectAtIndex:rowMatY.count-col-1]];//reversed for mirrored ROI
                }//end of row at Y
            }//end of Pixels grid for ROI
            //we finished all the pixels in this grid for this ROI so update the flat arrays
            [subtracted addObject:roiSubtract];
            [divided addObject:roiDivide];
            [dataAflat addObject:dataForROIflatA];
            [dataMflat addObject:dataForROIflatM];
        }//end of all the ROIs
    }
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    CGFloat sd;
    CGFloat countOfPixelsF = [[NSNumber numberWithUnsignedInteger:countOfPixels] floatValue];
    
    [dict setObject:dataAflat forKey:kDeltaNameActivePixFlat];
    [dict setObject:dataA2D forKey:kDeltaNameActivePixGrid];
    [dict setObject:[NSNumber numberWithFloat:sumOfA] forKey:kDeltaNameActiveSum];
    [dict setObject:[NSNumber numberWithFloat:sumOfA/countOfPixelsF] forKey:kDeltaNameActiveMean];
    [dict setObject:[NSNumber numberWithFloat:maxOfA] forKey:kDeltaNameActiveMax];
    [dict setObject:[NSNumber numberWithFloat:minOfA] forKey:kDeltaNameActiveMin];
    sd = [MirrorROIPluginFilterOC stDevForArrayOfRows:dataAflat withMean:sumOfA/countOfPixelsF andCountF:countOfPixelsF startingAtRow:0];
    [dict setObject:[NSNumber numberWithFloat:sd] forKey:kDeltaNameActiveSD];
    [dict setObject:[NSNumber numberWithFloat:sd/sqrtf(countOfPixelsF)] forKey:kDeltaNameActiveSEM];

    [dict setObject:dataMflat forKey:kDeltaNameMirroredPixFlat];
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
    [dict setObject:[NSNumber numberWithUnsignedInteger:countOfPixels] forKey:kDeltaNameCount];
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

    return dict;
}

+(CGFloat)stDevForArrayOfRows:(NSMutableArray *)array withMean:(CGFloat)mean andCountF:(CGFloat)countF startingAtRow:(int)startingRow {
    CGFloat variance = 0.0;
    for (int row=startingRow; row<array.count; row++)
        for (int col = 0; col<[[array objectAtIndex:row] count]; col++ ) {
            variance += powf([[[array objectAtIndex:row] objectAtIndex:col] floatValue] - mean, 2.0);
        }
    return sqrtf(variance/countF);
}

-(NSString *)combinedAandMstringsForExportROIdata_A:(NSString *)dataStringA M:(NSString *)dataStringM {
    return [NSString stringWithFormat:@"%@\n%@\n\n%@\n%@",[self ROInameForType:Active_ROI],dataStringA,[self ROInameForType:Mirrored_ROI],dataStringM];
}
-(void)exportROIdata:(ExportDataHow)exportHow {
    NSInteger exportType = [[NSUserDefaults standardUserDefaults] integerForKey:kExportMenuSelectedIndexDefault];
    NSString *dataStringA = nil;
    NSString *dataStringM = nil;
    NSString *fileTypeName = [self exportTypeStringForExportType:exportType withAnatomicalSite:YES];
    // check its bookmarkable if thats what we request
    if (exportHow == BookmarkString) {
        // only bookmarkable requests here
        switch (exportType) {
            case AllROIdata:
                dataStringA = [self exportAllROIdataStringForType:Active_ROI];
                dataStringM = [self exportAllROIdataStringForType:Mirrored_ROI];
                break;
            default:
                break;
        }
    }
    else
    {
        //offer up everyting
        switch (exportType) {
            case RoiData:
                dataStringA = [self dataStringForROIdataForType:Active_ROI];
                dataStringM = [self dataStringForROIdataForType:Mirrored_ROI];
                break;
            case RoiSummary:
                dataStringA = [self dataStringForSummaryROIdataForType:Active_ROI];
                dataStringM = [self dataStringForSummaryROIdataForType:Mirrored_ROI];
                break;
            case RoiThreeD:
                dataStringA = [self dataStringFor3DROIdataForType:Active_ROI];
                dataStringM = [self dataStringFor3DROIdataForType:Mirrored_ROI];
                break;
            case RoiPixelsFlat:
                dataStringA = [self dataStringForFlatPixelDataForROIType:Active_ROI];
                dataStringM = [self dataStringForFlatPixelDataForROIType:Mirrored_ROI];
                break;
            case AllROIdata:
                dataStringA = [self exportAllROIdataStringForType:Active_ROI];
                dataStringM = [self exportAllROIdataStringForType:Mirrored_ROI];
                break;
            default:
                break;
        }
    }
    switch (exportHow) {
        case ExportAsFile:
            if ([self userDefaultBoolForKey:kCombineExportsOneFileDefault] == YES)
            {
                if (dataStringA.length>0 && dataStringM.length>0) {
                    [self saveData:[self combinedAandMstringsForExportROIdata_A:dataStringA M:dataStringM] withName:[NSString stringWithFormat:@"%@-%@",fileTypeName,self.viewerPET.window.title]];
                }
            }
            else
            {
                if (dataStringA.length>0) {
                    [self saveData:dataStringA withName:[NSString stringWithFormat:@"%@-%@-%@", [self ROInameForType:Active_ROI],fileTypeName,self.viewerPET.window.title]];
                }
                if (dataStringM.length>0) {
                    [self saveData:dataStringM withName:[NSString stringWithFormat:@"%@-%@-%@", [self ROInameForType:Mirrored_ROI],fileTypeName,self.viewerPET.window.title]];
                }
            }
            break;
        case ViewInWindow:
        {
            if ([self userDefaultBoolForKey:kCombineExportsOneFileDefault] == YES)
            {
                if (dataStringA.length>0 && dataStringM.length>0) {
                    [MirrorROIPluginFilterOC showStringInWindow:[self combinedAandMstringsForExportROIdata_A:dataStringA M:dataStringM]
                                                      withTitle:[NSString stringWithFormat:@"%@-%@",fileTypeName,self.viewerPET.window.title]];
                }
            }
            else
            {
                if (dataStringA.length>0) {
                    [MirrorROIPluginFilterOC showStringInWindow:dataStringA withTitle:[NSString stringWithFormat:@"%@-%@-%@", [self ROInameForType:Active_ROI],fileTypeName,self.viewerPET.window.title]];
                }
                if (dataStringM.length>0) {
                    [MirrorROIPluginFilterOC showStringInWindow:dataStringM withTitle:[NSString stringWithFormat:@"%@-%@-%@", [self ROInameForType:Mirrored_ROI],fileTypeName,self.viewerPET.window.title]];
                }
            }
        }
            break;
        default:
            break;
    }
}

-(NSString *)exportAllROIdataStringForType:(ROI_Type)type {
    NSMutableArray *finalString = [NSMutableArray arrayWithCapacity:4];
    NSString *dataString = [self dataStringFor3DROIdataForType:type];
    if (dataString != nil) {[finalString addObject:[@"3D data\n" stringByAppendingString:dataString]];}
    dataString = [self dataStringForSummaryROIdataForType:type];
    if (dataString != nil) {[finalString addObject:[@"Summary data\n" stringByAppendingString:dataString]];}
    dataString = [self dataStringForROIdataForType:type];
    if (dataString != nil) {[finalString addObject:[@"ROI data\n" stringByAppendingString:dataString]];}
    dataString = [self dataStringForFlatPixelDataForROIType:type];
    if (dataString != nil) {[finalString addObject:[@"Flat Pixel data\n" stringByAppendingString:dataString]];}
    if (finalString.count>0) {
        return [finalString componentsJoinedByString:@"\n\n"];
    }
    return @"";
}

-(NSString *)dataStringForSummaryROIdataForType:(ROI_Type)type {
    NSUInteger capacity = self.viewerPET.roiList.count;
    NSMutableDictionary *dictOfRows = [NSMutableDictionary dictionaryWithCapacity:capacity];
    NSString *roiname = [self ROInameForType:type];
    for (int pix = 0; pix<self.viewerPET.roiList.count; pix++) {
        NSMutableArray *roiList = [self.viewerPET.roiList objectAtIndex:pix];
        for (int roiIndex = 0; roiIndex<roiList.count; roiIndex++) {
            ROI *roi = [roiList objectAtIndex:roiIndex];
            if ([roi.name isEqualToString:roiname]) {
                if (dictOfRows[@"index"] == nil) {
                    dictOfRows[@"index"] = [NSMutableArray arrayWithCapacity:capacity];
                    [dictOfRows[@"index"] addObject:[NSNumber numberWithInt:pix]];
                } else {
                    [dictOfRows[@"index"] addObject:[NSNumber numberWithInt:pix]];
                }

                [MirrorROIPluginFilterOC forceRecomputeDataForROI:roi];
                NSMutableDictionary *roidatadict = [roi dataString];
                for (NSString *key in roidatadict) {
                    id value = roidatadict[key];
                    if (dictOfRows[key] == nil) {
                        dictOfRows[key] = [NSMutableArray arrayWithCapacity:capacity];
                        [dictOfRows[key] addObject:value];
                    } else {
                        [dictOfRows[key] addObject:value];
                    }
                }
                break;
            }
        }
    }
    //add the  col data to array
    NSMutableArray *arrayOfRows = [NSMutableArray arrayWithCapacity:capacity];
    //each row has the data for one roi
    for (NSString *key in dictOfRows) {
        if (![key isEqualToString:@"Name"] && ![key isEqualToString:@"Type"]) {
            [dictOfRows[key] insertObject:key atIndex:0];
            [arrayOfRows addObject:dictOfRows[key]];
        }
    }
    if (arrayOfRows.count>0) {
        return [self stringForDataArray:arrayOfRows forceTranspose:YES];
    }
    return nil;
}
-(NSString *)dataStringFor3DROIdataForType:(ROI_Type)type {
    [self.viewerPET roiSelectDeselectAll: nil];
    NSString *roiname = [self ROInameForType:type];
    ROI *roi = [self ROIfromFirstMatchedSliceInViewer:self.viewerPET withName:roiname];
    NSString *error = nil;
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    [self.viewerPET computeVolume:roi points:nil generateMissingROIs:NO generatedROIs:nil computeData:dataDict error:&error];
    if (error == nil) {
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
    return nil;
}
-(NSString *)dataStringForROIdataForType:(ROI_Type)type {
    NSMutableArray *arrayOfRows = [NSMutableArray arrayWithCapacity:self.viewerPET.roiList.count];
    //each row has the data for one roi
    //add the headings
    [arrayOfRows addObject:@"index\tmean\tsdev\tmax\tmin\tcount"];
    NSString *roiname = [self ROInameForType:type];
    for (int pix = 0; pix<self.viewerPET.roiList.count; pix++) {
        NSMutableArray *roiList = [self.viewerPET.roiList objectAtIndex:pix];
        for (int roiIndex = 0; roiIndex<roiList.count; roiIndex++) {
            ROI *roi = [roiList objectAtIndex:roiIndex];
            if ([roi.name isEqualToString:roiname]) {
                //[MirrorROIPluginFilterOC forceRecomputeDataForROI:roi];
                [arrayOfRows addObject:[[NSArray arrayWithObjects:
                                         [NSNumber numberWithInt:pix],
                                         [NSNumber numberWithFloat:roi.mean],
                                         [NSNumber numberWithFloat:roi.dev],
                                         [NSNumber numberWithFloat:roi.max],
                                         [NSNumber numberWithFloat:roi.min],
                                         [NSNumber numberWithFloat:roi.total],
                                         nil] componentsJoinedByString:@"\t"]];
                break;
            }
        }
    }
    if (arrayOfRows.count>0) {
        return [arrayOfRows componentsJoinedByString:@"\n"];
    }
    return nil;
}

-(NSMutableArray *)arrayOfIndexesOfSlicesWithROIofType:(ROI_Type)type{
    NSString *roiname = [self ROInameForType:type];
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

-(NSMutableArray *)pixelDataFromROIasFlatArrayForType:(ROI_Type)type addHeader:(BOOL)addHeader{
    NSString *roiname = [self ROInameForType:type];
    NSMutableArray *arrayOfRows = [NSMutableArray array];
    for (int pix = 0; pix<self.viewerPET.roiList.count; pix++) {
        BOOL foundROI = NO;
        for (ROI *roi in [self.viewerPET.roiList objectAtIndex:pix]) {
            if ([roi.name isEqualToString:roiname]) {
                NSMutableArray *roiData = roi.dataValues;
                if (!foundROI) {
                    if (addHeader) {
                        [roiData insertObject:[NSNumber numberWithInteger:pix] atIndex:0];
                    }
                    [arrayOfRows addObject:roiData];
                }
                foundROI = YES;
            }
        }
    }
    return arrayOfRows;
}


-(NSMutableDictionary *)dictOfPixelBufferValuesAs2DArrayForType:(ROI_Type)type{
    NSString *roiname = [self ROInameForType:type];
    NSMutableDictionary *dictOfROIgrids = [NSMutableDictionary dictionary];
    for (int pix = 0; pix<self.viewerPET.roiList.count; pix++) {
        BOOL foundROI = NO;
        for (ROI *roi in [self.viewerPET.roiList objectAtIndex:pix]) {
            if ([roi.name isEqualToString:roiname]) {
                NSMutableArray *roiData = [self pixelsForROI:roi];
                if (!foundROI) {
                    [dictOfROIgrids setObject:roiData forKey:[NSString stringWithFormat:@"_%03li",(long)pix]];
                }
                foundROI = YES;
            }
        }
    }
    return dictOfROIgrids;
}

-(NSMutableArray *)pixelBufferValuesAs2DArrayForType:(ROI_Type)type{
    NSString *roiname = [self ROInameForType:type];
    NSMutableArray *arrayOfROIgrids = [NSMutableArray array];
    for (int pix = 0; pix<self.viewerPET.roiList.count; pix++) {
        BOOL foundROI = NO;
        for (ROI *roi in [self.viewerPET.roiList objectAtIndex:pix]) {
            if ([roi.name isEqualToString:roiname]) {
                NSMutableArray *roiData = [self pixelsForROI:roi];
                if (!foundROI) {
                    [arrayOfROIgrids addObject:roiData];
                }
                foundROI = YES;
            }
        }
    }
    return arrayOfROIgrids;
}



-(NSString *)dataStringForFlatPixelDataForROIType:(ROI_Type)type {
    NSMutableArray *arrayOfRows = [self pixelDataFromROIasFlatArrayForType:type addHeader:YES];
    if (arrayOfRows.count>0) {
        return [self stringForDataArray:arrayOfRows forceTranspose:NO];
    }
    return nil;
}

-(NSString *)dataStringFor2DpixelDataForROIType:(ROI_Type)type {
    NSMutableDictionary *dictOfRoiGrids = [self dictOfPixelBufferValuesAs2DArrayForType:type];
    NSMutableArray *arrayOfRows = [NSMutableArray array];
    [arrayOfRows addObject:[NSString stringWithFormat:@"2D grids of Pixel Data For %@ without mirroring",[self ROInameForType:type]]];
    if (dictOfRoiGrids.count>0) {
        NSArray *keys = [dictOfRoiGrids.allKeys sortedArrayUsingSelector:@selector(compare:)];
        for (int k=0; k<keys.count; k++) {
            //each key holds a 2D grid of Y rows
            //add the ROI index
            [arrayOfRows addObject:keys[k]];
            //extract the rows from grid
            NSMutableArray *gridForKey = [dictOfRoiGrids objectForKey:keys[k]];
            for (int y=0; y<gridForKey.count; y++) {
                //make a tab delim string for each grid row
                [arrayOfRows addObject:[[gridForKey objectAtIndex:y] componentsJoinedByString:@"\t"]];
            }
            //add a newline
            [arrayOfRows addObject:@"\n"];
        }
    }
    return [arrayOfRows componentsJoinedByString:@"\n"];
}

-(NSString *)stringForDataArray:(NSMutableArray *)arrayOfData forceTranspose:(BOOL)forceTranspose {
    if (arrayOfData.count>0) {
        NSMutableArray *arrayOfRowStrings = [NSMutableArray arrayWithCapacity:arrayOfData.count];
        if (forceTranspose || [self userDefaultBoolForKey:kTransposeExportedDataDefault]) {
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
    return nil;
}
-(NSURL *)saveData:(NSString *)dataString withName:(NSString *)name {
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    savePanel.allowedFileTypes = [NSArray arrayWithObject:@"txt"];
    savePanel.nameFieldStringValue = name;
    if ([savePanel runModal] == NSFileHandlingPanelOKButton) {
        NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:nil];
        [dataString writeToURL:savePanel.URL atomically:YES encoding:NSUnicodeStringEncoding error:&error];
        if (error.code == 0)
        {
            return savePanel.URL;
        }
    }
    return nil;
}

-(void)exportAMTroi {
    if ([self valid2DViewer:self.viewerPET]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        [[NSApplication sharedApplication] sendAction:@selector(roiSaveSeries:) to:self.viewerPET from:self.viewerPET];
#pragma clang diagnostic pop
    }
}

-(BOOL)roiIsActiveMirrorOrTransform:(ROI *)roi {
    return [roi.name isEqualToString:[self ROInameForType:Active_ROI]] || [roi.name isEqualToString:[self ROInameForType:Mirrored_ROI]] || [roi.name isEqualToString:[self ROInameForType:Transform_ROI_Placed]];
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
        ROI *activeRoi = [self ROIfromCurrentSliceInViewer:viewer withName:[self ROInameForType:Active_ROI]];
        ROI *mirroredRoi = [self ROIfromCurrentSliceInViewer:viewer withName:[self ROInameForType:Mirrored_ROI]];
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

-(NSString *)jiggleROIfileName {
    return [NSString stringWithFormat:@"🌸-%@",self.viewerPET.window.title];
}
-(NSString *)jiggleROIsummaryStringWithActiveROIinSliceString {
    return [NSString stringWithFormat:@"%@\n\n%@",[self summaryStringForActiveRoiInCurrentSliceInViewer:self.viewerCT],[self jiggleROIArrayFinalSummaryString]];
    
}
-(NSString *)summaryStringForActiveRoiInCurrentSliceInViewer:(ViewerController *)viewer {
    NSString *ss = @"Not Found";
    NSString *name = [self ROInameForType:Active_ROI];
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
            if ([self userDefaultBoolForKey:kRankJiggleDefault])
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
    ROI *roi2ClonePET = [self ROIfromSlice:currentSlice inViewer:self.viewerPET withName:[self ROInameForType:Mirrored_ROI]];//we take the position of the MIRROR
    ROI *roi2CloneCT = [self ROIfromSlice:currentSlice inViewer:self.viewerCT withName:[self ROInameForType:Active_ROI]];//take VALUES of the ACTIVE
    if (roi2ClonePET != nil && roi2CloneCT != nil) {
        //make the ROIS grid, dont add the zero ROI as its the already mirror unless specifically requested
        BOOL excludeOriginal = ![self userDefaultBoolForKey:kIncludeOriginalInJiggleDefault];
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
        if ([self userDefaultBoolForKey:kRankJiggleDefault]) {
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
    ROI *mirroredROI = [self ROIfromCurrentSliceInViewer:self.viewerPET withName:[self ROInameForType:Mirrored_ROI]];
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


- (IBAction)tap:(id)sender {
}

@end
