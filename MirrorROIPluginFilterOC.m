//
//  PluginTemplateFilter.m
//  PluginTemplate
//
//  Copyright (c) CURRENT_YEAR YOUR_NAME. All rights reserved.
//

#import "MirrorROIPluginFilterOC.h"

@implementation MirrorROIPluginFilterOC

#pragma mark - *********************

#pragma mark - IBActions
- (IBAction)growRegionClicked:(id)sender {
    [self.viewerPET.window makeKeyAndOrderFront:nil];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [[NSApplication sharedApplication] sendAction:@selector(segmentationTest:) to:self.viewerPET from:self.viewerPET];
#pragma clang diagnostic pop
}
- (IBAction)deleteActiveViewerROIsOfType:(NSButton *)sender {
    
    switch (sender.tag) {
        case Mirrored_ROI:
            [self deleteROIsFromViewerController:self.viewerPET withName:self.textMirrorROIname.stringValue];
            break;
        case Active_ROI:
            [self deleteROIsFromViewerController:self.viewerPET withName:self.textMirrorROIname.stringValue];
            break;
        case Transform_ROI:
            [self deleteROIsFromViewerController:self.viewerPET withName:self.textLengthROIname.stringValue];
            [self deleteROIsFromViewerController:self.viewerCT withName:self.textLengthROIname.stringValue];
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

- (void)deleteROIsFromViewerController:(ViewerController *)active2Dwindow withName:(NSString *)name {
    if (active2Dwindow)
    {
        [active2Dwindow deleteSeriesROIwithName:name];
        [active2Dwindow needsDisplayUpdate];
    }
}

- (void)deleteAllROIsFromViewerController:(ViewerController *)active2Dwindow {
    if (active2Dwindow)
    {
        [active2Dwindow roiDeleteAll:nil];
        [active2Dwindow needsDisplayUpdate];
    }
}


#pragma mark - Plugin

- (void) initPlugin {
    self.arrayTransformROIsCopied = [NSMutableArray array];
}

- (long) filterImage:(NSString*) menuName {
    //essential use this with OWNER specified so it looks in OUR bundle for resource.
    NSWindowController *windowController = [[NSWindowController alloc] initWithWindowNibName:@"MirrorWindow" owner:self];
    [windowController showWindow:self];
    [self smartAssignCTPETwindows];
    NSString *activeName = [[NSUserDefaults standardUserDefaults] stringForKey:@"growingRegionROIName"];
    if (activeName) {
        self.textActiveROIname.stringValue = activeName;
    }

    BOOL completedOK = YES;
    
    if(completedOK) return 0; // No Errors
    else return -1;
}

#pragma mark - Assign CT and PET

-(void)assignViewerWindow:(ViewerController *)viewController forType:(ViewerWindow_Type)type {
    
    if (type == CT_Window || type == CTandPET_Windows)
    {
        self.viewerCT = viewController;
        if (viewController != nil) {
            self.boxCT.title = viewController.window.title;
        }
        else
        {
            self.boxCT.title = @"Not Assigned";
        }
    }
    if (type == PET_Window || type == CTandPET_Windows)
    {
        self.viewerPET = viewController;
        if (viewController != nil) {
            self.boxPET.title = viewController.window.title;
        }
        else
        {
            self.boxPET.title = @"Not Assigned";
        }
    }
    self.boxCT.hidden = self.viewerCT == nil || self.viewerPET == nil;
    self.boxPET.hidden = self.boxCT.hidden;
    self.boxTop.hidden = self.boxCT.hidden;
    
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

#pragma mark Active ROI

- (IBAction)mirrorActiveROI3D:(NSButton *)sender {
    [self copyTransformsAndMirrorActives];
}

#pragma mark - Windows
- (IBAction)smartAssignCTPETwindowsClicked:(id)sender {
    [self smartAssignCTPETwindows];
}

- (IBAction)assignCTwindowClicked:(id)sender {
    [self assignViewerWindow:[ViewerController frontMostDisplayed2DViewer] forType:CT_Window];
}
- (IBAction)assignPETwindowClicked:(id)sender {
    [self assignViewerWindow:[ViewerController frontMostDisplayed2DViewer] forType:PET_Window];
}

-(BOOL)valid2DViewer:(ViewerController *)active2Dviewer
{
    if (active2Dviewer == nil || ([self.viewerControllersList indexOfObjectIdenticalTo:active2Dviewer] == NSNotFound)) return false;
    return true;
}

-(BOOL)validCTandPETwindows {
    return ([self valid2DViewer:self.viewerCT] && [self valid2DViewer:self.viewerPET]);
}

#pragma mark - Transform ROIs

-(void)copyTransformsAndMirrorActives {
    [self copyTransformROIsFromCT2PET];
    [self mirrorActiveROIUsingLengthROIinViewerController:self.viewerPET in3D:YES];
    //create a dummy roi just for the name
    ROI *aROI = [self.viewerPET newROI:tPlain];
    aROI.name = self.textMirrorROIname.stringValue;
    //roiSetPixels:(ROI*)aROI :(short)allRois :(BOOL)propagateIn4D :(BOOL)outside :(float)minValue :(float)maxValue :(float)newValue;
    [self.viewerPET roiSetPixels: aROI :SetPixels_SameName :NO :NO :-FLT_MAX :FLT_MAX :FLT_MAX :YES];
    aROI.name = self.textActiveROIname.stringValue;
    [self.viewerPET roiSetPixels: aROI :SetPixels_SameName :NO :NO :-FLT_MAX :FLT_MAX :FLT_MAX :YES];
    [self.viewerPET needsDisplayUpdate];
    [self.viewerCT needsDisplayUpdate];

}

-(IBAction)addTransformROIs:(NSButton *)sender {
    [self addBoundingTransformROIS];
}
-(void)addBoundingTransformROIS {
    [self.viewerCT setROIToolTag:tMesure];
    [self.viewerCT deleteSeriesROIwithName:self.textLengthROIname.stringValue];
    
    //find the first and last pixIndex with an ACTIVE ROI
    NSMutableIndexSet *indexesWithROI= [[NSMutableIndexSet alloc]init];
    NSString *activeROIname = self.textActiveROIname.stringValue;
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
    if (indexesWithROI.count==1) {
        [self addLengthROIWithStart:[self pointForImageIndex:indexesWithROI.firstIndex inWindow:self.viewerCT start:YES]
                             andEnd:[self pointForImageIndex:indexesWithROI.firstIndex inWindow:self.viewerCT start:NO]
                 toViewerController:self.viewerCT
                            atIndex:indexesWithROI.firstIndex];
        [self displayImageInCTandPETviewersWithIndex:indexesWithROI.firstIndex];
        
    }
    else if(indexesWithROI.count>1) {
        [self addLengthROIWithStart:[self pointForImageIndex:indexesWithROI.firstIndex inWindow:self.viewerCT start:YES]
                             andEnd:[self pointForImageIndex:indexesWithROI.firstIndex inWindow:self.viewerCT start:NO]
                 toViewerController:self.viewerCT
                            atIndex:indexesWithROI.firstIndex];
        
        [self addLengthROIWithStart:[self pointForImageIndex:indexesWithROI.firstIndex inWindow:self.viewerCT start:YES]
                             andEnd:[self pointForImageIndex:indexesWithROI.firstIndex inWindow:self.viewerCT start:NO]
                 toViewerController:self.viewerCT
                            atIndex:indexesWithROI.lastIndex];
        
        [self displayImageInCTandPETviewersWithIndex:indexesWithROI.firstIndex];
    }
}
-(void)addLengthROIWithStart:(NSPoint)startPoint andEnd:(NSPoint)endPoint toViewerController:(ViewerController *)active2Dwindow atIndex:(NSUInteger)index {
    ROI *newR = [active2Dwindow newROI:tMesure];
    [newR.points addObject:[active2Dwindow newPoint:startPoint.x :startPoint.y]];
    [newR.points addObject:[active2Dwindow newPoint:endPoint.x :endPoint.y]];
    [[[active2Dwindow roiList] objectAtIndex:index] addObject:newR];
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

-(void)displayImageInCTandPETviewersWithIndex:(short)index {
    //do it in ImageView for correct order
    [self.viewerPET.imageView setIndexWithReset:index :YES];
    [self.viewerCT.imageView setIndexWithReset:index :YES];
    [self.viewerPET needsDisplayUpdate];
    [self.viewerCT needsDisplayUpdate];
    
}

#pragma mark - *********************
- (IBAction)unassignCTwindowClicked:(id)sender {
    [self assignViewerWindow:nil forType:CT_Window];
}
- (IBAction)unassignPETwindowClicked:(id)sender {
    [self assignViewerWindow:nil forType:PET_Window];
}

-(IBAction)quickPasteCTPET:(NSButton *)sender {
    if (sender.tag >= 0)//PET2CT
    {
        switch (sender.tag) {
            case Mirrored_ROI:
            case Active_ROI:
                [self doPasteBrushROIsAsPolygonsFromPET2CT:sender.tag];
                break;
            case MirroredAndActive_ROI:
                [self doPasteBrushROIsAsPolygonsFromPET2CT:Mirrored_ROI];
                [self doPasteBrushROIsAsPolygonsFromPET2CT:Active_ROI];
               break;
            case Transform_ROI:
                [self copyROIsFromViewerController:self.viewerPET ofType:tMesure withOptionalName:self.textLengthROIname.stringValue ofROIMirrorType:Transform_ROI];
                [self pasteROIsForViewerController:self.viewerCT ofType:tMesure withOptionalName:self.textLengthROIname.stringValue ofROIMirrorType:Transform_ROI];
                break;
            default:
                break;
        }
    }
    else //CT2PET
    {
        switch (labs(sender.tag)) {
            case Mirrored_ROI:
            case Active_ROI:
                [self doPasteBrushROIsAsPolygonsFromCT2PET:sender.tag];
                break;
            case MirroredAndActive_ROI:
                [self doPasteBrushROIsAsPolygonsFromCT2PET:Mirrored_ROI];
                [self doPasteBrushROIsAsPolygonsFromCT2PET:Active_ROI];
                break;
            case Transform_ROI:
                [self copyROIsFromViewerController:self.viewerCT ofType:tMesure withOptionalName:self.textLengthROIname.stringValue ofROIMirrorType:Transform_ROI];
                [self pasteROIsForViewerController:self.viewerPET ofType:tMesure withOptionalName:self.textLengthROIname.stringValue ofROIMirrorType:Transform_ROI];
                break;
            default:
                break;
        }
    }
}



-(void)copyTransformROIsFromCT2PET {
        if ([self validCTandPETwindows]
            && ([[self.viewerCT pixList] count] == [[self.viewerPET pixList] count])
            && ([[self.viewerCT roiList] count] == [[self.viewerCT pixList] count])
            && ([[self.viewerPET roiList] count] == [[self.viewerPET pixList] count]))
        {
            NSString *transformname = self.textLengthROIname.stringValue;
            [self.viewerPET deleteSeriesROIwithName:transformname];
            for (NSUInteger pixIndex = 0; pixIndex<[[self.viewerCT roiList] count]; pixIndex++) {
                DCMPix *curDCM = [[self.viewerPET pixList] objectAtIndex: pixIndex];
                for (ROI *roi in [[self.viewerCT roiList] objectAtIndex:pixIndex]) {
                    if ([roi.name isEqualToString:transformname]) {
                        ROI *unpackedROI = [roi copy];
                        //Correct the origin only if the orientation is the same
                        unpackedROI.pix = curDCM;
                        unpackedROI.hidden = YES;
                        [unpackedROI setOriginAndSpacing: curDCM.pixelSpacingX :curDCM.pixelSpacingY :[DCMPix originCorrectedAccordingToOrientation: curDCM]];
                        [[self.viewerPET.roiList objectAtIndex: pixIndex] addObject: unpackedROI];
                        unpackedROI.curView = self.viewerPET.imageView;
                        [unpackedROI recompute];
                    }
                }
            }
        }
}
-(IBAction)buttonAction:(NSButton *)sender
{
    //Transform Front
    if ([sender.identifier isEqualToString:@"pasteTransformFront"]) {
        [self pasteROIsForViewerController:[ViewerController frontMostDisplayed2DViewer] ofType:tMesure withOptionalName:self.textLengthROIname.stringValue ofROIMirrorType:Transform_ROI];
    }
    else  if ([sender.identifier isEqualToString:@"copyTransformFront"]) {
        [self copyROIsFromViewerController:[ViewerController frontMostDisplayed2DViewer] ofType:tMesure withOptionalName:self.textLengthROIname.stringValue ofROIMirrorType:Transform_ROI];
    }
    else  if ([sender.identifier isEqualToString:@"deleteTransformFront"]) {
        [self deleteROIsFromViewerController:[ViewerController frontMostDisplayed2DViewer] ofType:tMesure withOptionalName:self.textLengthROIname.stringValue];
    }
    else  if ([sender.identifier isEqualToString:@"hideTransformFront"]) {
        [self doShowHideTransformMarkersForViewerController:[ViewerController frontMostDisplayed2DViewer]];
    }
    // Transform CT window
    else  if ([sender.identifier isEqualToString:@"deleteTransformCT"]) {
        [self deleteROIsFromViewerController:self.viewerCT ofType:tMesure withOptionalName:self.textLengthROIname.stringValue];
    }
    else  if ([sender.identifier isEqualToString:@"hideTransformCT"]) {
        [self doShowHideTransformMarkersForViewerController:self.viewerCT];
    }
}

- (IBAction)deleteActiveViewerPolygonROIsOfType:(NSButton *)sender {
    switch (sender.tag) {
        case Mirrored_ROI:
            [self deleteROIsFromViewerController:[ViewerController frontMostDisplayed2DViewer] ofType:tCPolygon withOptionalName:self.textMirrorROIname.stringValue];
            break;
        case Active_ROI:
            [self deleteROIsFromViewerController:[ViewerController frontMostDisplayed2DViewer] ofType:tCPolygon withOptionalName:self.textActiveROIname.stringValue];
            break;
            
        default:
            break;
    }
}
- (IBAction)pasteActiveViewerROIsOfType:(NSButton *)sender {
    switch (sender.tag) {
        case Mirrored_ROI:
            [self pasteROIsForViewerController:[ViewerController frontMostDisplayed2DViewer] ofType:tPlain withOptionalName:self.textMirrorROIname.stringValue ofROIMirrorType:Mirrored_ROI];
            break;
        case Active_ROI:
            [self pasteROIsForViewerController:[ViewerController frontMostDisplayed2DViewer] ofType:tPlain withOptionalName:self.textActiveROIname.stringValue ofROIMirrorType:Active_ROI];
            break;
            
        default:
            break;
    }
}
- (IBAction)copyActiveViewerROIsOfType:(NSButton *)sender {
    switch (sender.tag) {
        case Mirrored_ROI:
            [self copyROIsFromViewerController:[ViewerController frontMostDisplayed2DViewer] ofType:tPlain withOptionalName:self.textMirrorROIname.stringValue ofROIMirrorType:Mirrored_ROI];
            break;
        case Active_ROI:
            [self copyROIsFromViewerController:[ViewerController frontMostDisplayed2DViewer] ofType:tPlain withOptionalName:self.textActiveROIname.stringValue ofROIMirrorType:Active_ROI];
            break;
            
        default:
            break;
    }
}






#pragma mark Transform markers

- (IBAction)callExtendLengthSeries:(NSButton *)sender {
    switch (sender.tag) {
        case Front_Window:
            [self completeLengthROIseriesForViewerController:[ViewerController frontMostDisplayed2DViewer]];
            break;
        case CT_Window:
            [self completeLengthROIseriesForViewerController:self.viewerCT];
            break;
            
        default:
            break;
    }
}


#pragma mark - MirrorROIPluginFilterOC


- (void)deleteROIsFromViewerController:(ViewerController *)active2Dwindow ofType:(int)type withOptionalName:(NSString *)name
{
    for (NSUInteger pixIndex = 0; pixIndex < [[active2Dwindow pixList] count]; pixIndex++)
    {
        for( int roiIndex = 0; roiIndex < [[[active2Dwindow roiList] objectAtIndex: pixIndex] count]; roiIndex++)
        {
            ROI	*curROI = [[[active2Dwindow roiList] objectAtIndex: pixIndex] objectAtIndex: roiIndex];
            if ((type == tAnyROItype || curROI.type == type) && (name == nil || name == curROI.name))
            {
                [[[active2Dwindow roiList] objectAtIndex: pixIndex] removeObjectAtIndex:roiIndex];
            }
        }
    }
    [active2Dwindow needsDisplayUpdate];
}

- (void)copyROIsFromViewerController:(ViewerController *)active2Dwindow ofType:(int)type withOptionalName:(NSString *)name ofROIMirrorType:(ROI_Type)roiMirrorType
{
    NSMutableArray *scratchArray = [self arrayOfROIsFromViewerController:active2Dwindow ofType:type withOptionalName:name ofROIMirrorType:roiMirrorType];
    
    switch (roiMirrorType) {
        case Mirrored_ROI:
            self.arrayMirrorROIsCopied  = [NSMutableArray arrayWithArray:scratchArray];
            break;
        case Transform_ROI:
            self.arrayTransformROIsCopied  = [NSMutableArray arrayWithArray:scratchArray];
            break;
        case Active_ROI:
            self.arrayActiveROIsCopied  = [NSMutableArray arrayWithArray:scratchArray];
            break;
        default:
            break;
    }

    if(scratchArray.count == 0)
    {
        NSRunCriticalAlertPanel(NSLocalizedString(@"ROIs Save Error",nil), NSLocalizedString(@"No ROIs in this series!",nil) , NSLocalizedString(@"OK",nil), nil, nil);
    }
}

-(NSMutableArray *)arrayOfROIsFromViewerController:(ViewerController *)active2Dwindow ofType:(int)type withOptionalName:(NSString *)name ofROIMirrorType:(ROI_Type)roiMirrorType
{
    NSMutableArray *scratchArray = [NSMutableArray  arrayWithCapacity:[[active2Dwindow pixList] count]];
    
    for (NSUInteger pixIndex = 0; pixIndex < [[active2Dwindow pixList] count]; pixIndex++)
    {
        NSMutableArray  *roisPerImages = [NSMutableArray  array];
        NSMutableArray *roiListInVC = [active2Dwindow roiList];
        for( int roiIndex = 0; roiIndex < [[roiListInVC objectAtIndex: pixIndex] count]; roiIndex++)
        {
            ROI	*curROI = [[[roiListInVC objectAtIndex: pixIndex] objectAtIndex: roiIndex] copy];
            if ((curROI.type == type) && (name == nil || name == curROI.name))
            {
                [roisPerImages addObject: curROI];
            }
        }
        
        [scratchArray addObject: roisPerImages];
    }
    return scratchArray;
}


-(void)doPasteBrushROIsAsPolygonsFromCT2PET:(ROI_Type)roiMirrorType {
    NSString *ROIname = nil;
    switch (roiMirrorType) {
        case Mirrored_ROI:
            ROIname = self.textMirrorROIname.stringValue;
            break;
        case Active_ROI:
            ROIname = self.textActiveROIname.stringValue;
            break;
        default:
            break;
    }
    NSMutableArray *scratchArray = [self arrayOfROIsFromViewerController:self.viewerCT ofType:tCPolygon withOptionalName:ROIname ofROIMirrorType:roiMirrorType];
    if (scratchArray.count > 0) {
        [self pasteROIsFromArray:scratchArray ofType:tCPolygon withOptionalName:ROIname ofROIMirrorType:roiMirrorType intoViewerController:self.viewerPET];
    }
}

-(void)doPasteBrushROIsAsPolygonsFromPET2CT:(ROI_Type)roiMirrorType {
    NSString *ROIname = nil;
    switch (roiMirrorType) {
        case Mirrored_ROI:
            ROIname = self.textMirrorROIname.stringValue;
            break;
        case Active_ROI:
            ROIname = self.textActiveROIname.stringValue;
            break;
        default:
            break;
    }
    NSMutableArray *scratchArray = [self arrayOfROIsFromViewerController:self.viewerPET ofType:tPlain withOptionalName:ROIname ofROIMirrorType:roiMirrorType];
    if (scratchArray.count > 0) {
        for(NSUInteger pixIndex = 0; pixIndex < [scratchArray count]; pixIndex++)
        {
            NSMutableArray *roisImages = [scratchArray objectAtIndex: pixIndex];
            for(NSUInteger imIndex = 0; imIndex<roisImages.count; imIndex++)
            {
                ROI *poly = [self.viewerPET convertBrushROItoPolygon:[roisImages objectAtIndex:imIndex] numPoints:200];
                poly.name = ROIname;
                [roisImages replaceObjectAtIndex:imIndex withObject:poly];
                
            }
        }
        [self pasteROIsFromArray:scratchArray ofType:tCPolygon withOptionalName:ROIname ofROIMirrorType:roiMirrorType intoViewerController:self.viewerCT];
    }
    
}

- (void)pasteROIsForViewerController:(ViewerController *)active2Dwindow ofType:(int)type withOptionalName:(NSString *)name ofROIMirrorType:(ROI_Type)roiMirrorType
{
    switch (roiMirrorType) {
        case Mirrored_ROI:
            [self pasteROIsFromArray:[NSMutableArray arrayWithArray:self.arrayMirrorROIsCopied] ofType:type withOptionalName:name ofROIMirrorType:roiMirrorType intoViewerController:active2Dwindow];
            break;
        case Transform_ROI:
            [self pasteROIsFromArray:[NSMutableArray arrayWithArray:self.arrayTransformROIsCopied] ofType:type withOptionalName:name ofROIMirrorType:roiMirrorType intoViewerController:active2Dwindow];
            break;
        case Active_ROI:
            [self pasteROIsFromArray:[NSMutableArray arrayWithArray:self.arrayActiveROIsCopied] ofType:type withOptionalName:name ofROIMirrorType:roiMirrorType intoViewerController:active2Dwindow];
            break;
        default:
            break;
    }
}

-(void)pasteROIsFromArray:(NSMutableArray *)scratchArray ofType:(int)type withOptionalName:(NSString *)name ofROIMirrorType:(ROI_Type)roiMirrorType intoViewerController:(ViewerController *)active2Dwindow
{
    NSMutableArray *pixListInActiveVC = [active2Dwindow pixList];
    for(NSUInteger pixIndex = 0; pixIndex < [pixListInActiveVC count]; pixIndex++)
    {
        DCMPix *curDCM = [pixListInActiveVC objectAtIndex: pixIndex];
        
        if( [scratchArray count] > pixIndex)
        {
            NSArray *roisImages = [scratchArray objectAtIndex: pixIndex];
            for( ROI *unpackedROI in roisImages)
            {
                if ((unpackedROI.type == type) && (name == nil || name == unpackedROI.name))
                {
                    //Correct the origin only if the orientation is the same
                    unpackedROI.pix = curDCM;
                    [unpackedROI setOriginAndSpacing: curDCM.pixelSpacingX :curDCM.pixelSpacingY :[DCMPix originCorrectedAccordingToOrientation: curDCM]];
                    [[active2Dwindow.roiList objectAtIndex: pixIndex] addObject: unpackedROI];
                    unpackedROI.curView = active2Dwindow.imageView;
                    [unpackedROI recompute];
                }
            }
        }
    }
    [active2Dwindow.imageView setIndex: active2Dwindow.imageView.curImage];
    [active2Dwindow needsDisplayUpdate];

}

-(void)pasteAllROIsFromArray:(NSMutableArray *)scratchArray intoViewerController:(ViewerController *)active2Dwindow hidden:(BOOL)hidden
{
    NSMutableArray *pixListInActiveVC = [active2Dwindow pixList];
    for(NSUInteger pixIndex = 0; pixIndex < [pixListInActiveVC count]; pixIndex++)
    {
        DCMPix *curDCM = [pixListInActiveVC objectAtIndex: pixIndex];

        if( [scratchArray count] > pixIndex)
        {
            NSArray *roisImages = [scratchArray objectAtIndex: pixIndex];
            for( ROI *unpackedROI in roisImages)
            {
                //Correct the origin only if the orientation is the same
                unpackedROI.pix = curDCM;
                unpackedROI.hidden = hidden;
                [unpackedROI setOriginAndSpacing: curDCM.pixelSpacingX :curDCM.pixelSpacingY :[DCMPix originCorrectedAccordingToOrientation: curDCM]];
                [[active2Dwindow.roiList objectAtIndex: pixIndex] addObject: unpackedROI];
                unpackedROI.curView = active2Dwindow.imageView;
                [unpackedROI recompute];
           }
        }
    }
    [active2Dwindow.imageView setIndex: active2Dwindow.imageView.curImage];
    [active2Dwindow needsDisplayUpdate];
    
}


+(unsigned char*)flippedBufferHorizontalFromROI:(ROI *)roi2Clone
{
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

-(void)addROI:(ROI *)roi toSeriesFromStart:(NSUInteger)start toEnd:(NSUInteger)end inViewerController:(ViewerController *)active2Dwindow
{
    //ViewerController	*active2Dwindow = [ViewerController frontMostDisplayed2DViewer] /*self->viewerController*/;
    NSMutableArray  *allROIsList = [active2Dwindow roiList];
    for (NSUInteger nextIndex = start; nextIndex<end; nextIndex++) {
        ROI *roi2copy = roi;
        [[allROIsList objectAtIndex:nextIndex] addObject:roi2copy];
    }
}


-(void)completeLengthROIseriesForViewerController:(ViewerController *)active2Dwindow
{
    if ([self valid2DViewer:active2Dwindow])
    {
        NSMutableArray  *allROIsList = [active2Dwindow roiList];
        NSMutableArray *indicesOfDCMPixWithMeasureROI = [NSMutableArray arrayWithCapacity:allROIsList.count];
        NSMutableArray *measureROIs = [NSMutableArray arrayWithCapacity:allROIsList.count];
        NSString *measureROIname;
        measureROIname = self.textLengthROIname.stringValue;
        
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
            case 1:
                switch (self.segmentExtendSingleLengthHow.selectedSegment)
            {
                case ExtendSingleLengthUp:
                    [self addROI:[[measureROIs firstObject] copy] toSeriesFromStart:[[indicesOfDCMPixWithMeasureROI firstObject] intValue]+1 toEnd:allROIsList.count inViewerController:active2Dwindow];
                    break;
                case ExtendSingleLengthDown:
                    [self addROI:[[measureROIs firstObject] copy] toSeriesFromStart:0 toEnd:[[indicesOfDCMPixWithMeasureROI firstObject] intValue] inViewerController:active2Dwindow];
                    break;
                case ExtendSingleLengthBoth:
                    [self addROI:[[measureROIs firstObject] copy] toSeriesFromStart:[[indicesOfDCMPixWithMeasureROI firstObject] intValue]+1 toEnd:allROIsList.count inViewerController:active2Dwindow];
                    [self addROI:[[measureROIs firstObject] copy] toSeriesFromStart:0 toEnd:[[indicesOfDCMPixWithMeasureROI firstObject] intValue] inViewerController:active2Dwindow];
                    break;
            }
            default:
                //-1 as we go in pairs and so skip the last one
                for (int roiNumber=0; roiNumber<indicesOfDCMPixWithMeasureROI.count-1; roiNumber++)
                {
                    [self completeLengthROIseriesForViewerController:active2Dwindow
                                                         betweenROI1:[measureROIs objectAtIndex:roiNumber]
                                                             andROI2:[measureROIs objectAtIndex:roiNumber+1]
                                                         inThisRange:NSMakeRange(
                                                        //skip the start index it already has aROI
                                                        [[indicesOfDCMPixWithMeasureROI objectAtIndex:roiNumber] unsignedIntegerValue]+1,
                                                        //length = difference between end and start minus 1 to skip last one
                                                        [[indicesOfDCMPixWithMeasureROI objectAtIndex:roiNumber+1] unsignedIntegerValue]-
                                                        [[indicesOfDCMPixWithMeasureROI objectAtIndex:roiNumber] unsignedIntegerValue]-1)];
                }
                break;
        }
        [active2Dwindow needsDisplayUpdate];
    }
}

-(void)doShowHideTransformMarkersForViewerController:(ViewerController *)active2Dwindow
{
    //ViewerController	*active2Dwindow = [ViewerController frontMostDisplayed2DViewer] /*self->viewerController*/;
    NSMutableArray  *roisInAllSlices  = [active2Dwindow roiList];
    for (NSUInteger slice=0; slice<roisInAllSlices.count; slice++) {
        NSMutableArray *roisInThisSlice = [roisInAllSlices objectAtIndex:slice];
        ROI *ROI2showHide = [MirrorROIPluginFilterOC roiFromList:roisInThisSlice WithType:tMesure];
        if (ROI2showHide != nil) {
            ROI2showHide.hidden = !ROI2showHide.hidden;
        }
    }
}


-(void)completeLengthROIseriesForViewerController:(ViewerController *)active2Dwindow betweenROI1:(ROI *)roi1 andROI2:(ROI *)roi2 inThisRange:(NSRange)rangeOfIndices// inROISArray:(NSMutableArray *)indicesOfDCMPixWithMeasureROI
{
    //ViewerController	*active2Dwindow = [ViewerController frontMostDisplayed2DViewer] /*self->viewerController*/;
    NSMutableArray  *allROIsList = [active2Dwindow roiList];
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
        //[newROI setNSColor:[NSColor redColor]];
        [[[newROI points] objectAtIndex:0] move:XincrementCurrent1 :YincrementCurrent1];
        [[[newROI points] objectAtIndex:1] move:XincrementCurrent2 :YincrementCurrent2];
        [[allROIsList objectAtIndex:nextIndex] addObject:newROI];
        //newROI.hidden = true;//self.segmentShowHideTransformMarkers.selectedSegment;
        newROI.offsetTextBox_x = 10000.0;
        XincrementCurrent1 += Xincrement1;
        XincrementCurrent2 += Xincrement2;
        YincrementCurrent1 += Yincrement1;
        YincrementCurrent2 += Yincrement2;
    }
}

-(void)mirrorActiveROIUsingLengthROIinViewerController:(ViewerController *)active2Dwindow in3D:(BOOL)in3D
{
    [active2Dwindow deleteSeriesROIwithName:self.textMirrorROIname.stringValue];

    NSMutableArray  *roisInAllSlices  = [active2Dwindow roiList];
    NSUInteger startSlice = 0;
    NSUInteger endSlice = 0;
    if (in3D) {
        startSlice = 0;
        endSlice = roisInAllSlices.count;
    }
    else
    {
        startSlice = [[active2Dwindow imageView] curImage];
        endSlice = startSlice+1;

    }
    
    for (NSUInteger slice=startSlice; slice<endSlice; slice++) {
        NSMutableArray *roisInThisSlice = [roisInAllSlices objectAtIndex:slice];
        ROI *roi2Clone = [MirrorROIPluginFilterOC roiFromList:roisInThisSlice WithType:tPlain];
        //rename to keep in sync
        roi2Clone.name = self.textActiveROIname.stringValue;
        NSPoint deltaXY = [MirrorROIPluginFilterOC deltaXYFromROI:roi2Clone usingLengthROI:[MirrorROIPluginFilterOC roiFromList:roisInThisSlice WithType:tMesure]];
        
        if ([MirrorROIPluginFilterOC validDeltaPoint:deltaXY]) {
            ROI *createdROI = [[ROI alloc]
                               initWithTexture:[MirrorROIPluginFilterOC flippedBufferHorizontalFromROI:roi2Clone]
                               textWidth:roi2Clone.textureWidth
                               textHeight:roi2Clone.textureHeight
                               textName:self.textMirrorROIname.stringValue
                               positionX:roi2Clone.textureUpLeftCornerX+deltaXY.x
                               positionY:roi2Clone.textureUpLeftCornerY+deltaXY.y
                               spacingX:roi2Clone.pixelSpacingX
                               spacingY:roi2Clone.pixelSpacingY
                               imageOrigin:roi2Clone.imageOrigin];
            [roisInThisSlice addObject:createdROI];
            [active2Dwindow needsDisplayUpdate];
        }
    }
}


+(NSPoint)deltaXYFromROI:(ROI*)roi2Clone usingLengthROI:(ROI*)lengthROI
{
    NSPoint deltaPoint = NSMakePoint(CGFLOAT_MAX, CGFLOAT_MAX);
    
    if (roi2Clone && lengthROI) {
        NSPoint ipsi = [(MyPoint *)[lengthROI.points objectAtIndex:0] point];
        NSPoint contra = [(MyPoint *)[lengthROI.points objectAtIndex:1] point];
        /*
         X must be mirrored, so left edge [ must move thus (mirroring is along X axis and within the edges, so left edge stays where it is.
          roi         ipsi            contra    mirrored
         [ABCD]--------I---------------C-------[DCBA]
         width  offset   translation    offset
         |<--------------- delta ------------->|
         
         delta = width+translation+ 2*offset
         offset = (ipsi - ROI leftX)-width
         
                           width                 translation                offset      */
        deltaPoint.x = roi2Clone.textureWidth+(contra.x-ipsi.x)+(2.0*(ipsi.x-roi2Clone.textureUpLeftCornerX-roi2Clone.textureWidth));
        
        
        /*
         Y is not mirrored and must only move by the translation to keep the floor of the texture aligned with the anchor
                         translation             */
        deltaPoint.y = (contra.y-ipsi.y);
    }
    return deltaPoint;
}


+(NSMutableArray *)allROIinFrontDCMPixFromViewerController:(ViewerController *)theVC
{
    NSMutableArray  *roisInAllSlices  = [theVC roiList];
    int indexOfFrontDCMPix =  [[theVC imageView] curImage];
    if (roisInAllSlices.count>indexOfFrontDCMPix) {
        return [roisInAllSlices objectAtIndex: indexOfFrontDCMPix];
    }
    return nil;
}

+(ROI*) roiFromList:(NSMutableArray *)roiList WithName:(NSString*)name2Find
{
    for (ROI *roi in roiList) {
        if ([roi.name isEqualToString:name2Find]){return roi;}
    }
    return nil;
}

+(ROI*) roiFromList:(NSMutableArray *)roiList WithType:(int)type2Find
{
    for (ROI *roi in roiList) {
        if (roi.type == type2Find){
            return roi;}
    }
    return nil;
}

+(BOOL)validDeltaPoint:(NSPoint)delta2test
{
    return delta2test.x != CGFLOAT_MAX && delta2test.y != CGFLOAT_MAX;
}

@end
