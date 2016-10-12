//
//  PluginTemplateFilter.m
//  PluginTemplate
//
//  Copyright (c) CURRENT_YEAR YOUR_NAME. All rights reserved.
//

#import "MirrorROIPluginFilterOC.h"

@implementation MirrorROIPluginFilterOC


#pragma mark Windows

- (IBAction)assignCTwindowClicked:(id)sender {
    [self assignViewerWindow:[ViewerController frontMostDisplayed2DViewer] forType:CT_Window];
}
- (IBAction)assignPETwindowClicked:(id)sender {
    [self assignViewerWindow:[ViewerController frontMostDisplayed2DViewer] forType:PET_Window];
}
- (IBAction)unassignCTwindowClicked:(id)sender {
    [self assignViewerWindow:nil forType:CT_Window];
}
- (IBAction)unassignPETwindowClicked:(id)sender {
    [self assignViewerWindow:nil forType:PET_Window];
}


#pragma mark Mirrored

- (IBAction)deleteMirrorROIs:(NSButton *)sender {
    if (sender.tag == Mirrored_ROI) {
        [self deleteROIsFromActiveViewerControllerOfType:tPlain withOptionalName:self.textMirrorROIname.stringValue];
    }
    else
    {
        [self deleteROIsFromActiveViewerControllerOfType:tPlain withOptionalName:self.textActiveROIname.stringValue];
    }
}
- (IBAction)pasteMirrorROIs:(NSButton *)sender {
    if (sender.tag == Mirrored_ROI) {
        [self pasteROIsForActiveViewerControllerOfType:tPlain withOptionalName:self.textMirrorROIname.stringValue ofROIMirrorType:Mirrored_ROI];
    }
    else
    {
        [self pasteROIsForActiveViewerControllerOfType:tPlain withOptionalName:self.textActiveROIname.stringValue ofROIMirrorType:Active_ROI];
    }
}
- (IBAction)copyMirrorROIs:(NSButton *)sender {
    if (sender.tag == Mirrored_ROI) {
        [self copyROIsFromActiveViewerControllerOfType:tPlain withOptionalName:self.textMirrorROIname.stringValue ofROIMirrorType:Mirrored_ROI];
   }
    else
    {
        [self copyROIsFromActiveViewerControllerOfType:tPlain withOptionalName:self.textActiveROIname.stringValue ofROIMirrorType:Active_ROI];
    }
}

- (IBAction)pasteMirroredAsPolygonsFromPET2CTclicked:(id)sender {
    [self doPasteBrushROIsAsPolygonsFromPET2CT:Mirrored_ROI];
}

- (IBAction)pasteMirroredPolygonsFromCT2PETclicked:(id)sender {
    [self doPasteBrushROIsAsPolygonsFromCT2PET:Mirrored_ROI];
}

#pragma mark Active ROI

-(IBAction)mirrorActiveROI2D:(id)sender
{
    [self mirrorActiveROIUsingLengthROIIn3D:NO];
}
- (IBAction)mirrorActiveROI3D:(id)sender {
    [self mirrorActiveROIUsingLengthROIIn3D:YES];
}

- (IBAction)pasteActiveAsPolygonsFromPET2CTclicked:(id)sender {
    [self doPasteBrushROIsAsPolygonsFromPET2CT:Active_ROI];
}

- (IBAction)pasteActivePolygonsFromCT2PETclicked:(id)sender {
    [self doPasteBrushROIsAsPolygonsFromCT2PET:Active_ROI];
}

- (IBAction)growRegionClicked:(id)sender {
    [[NSApplication sharedApplication] sendAction:@selector(segmentationTest:) to:nil from:nil];
}


#pragma mark Transform markers

- (IBAction)callExtendLengthSeries:(id)sender {
    [self completeLengthROIseries];
}

- (IBAction)showHideTransformMarkers:(id)sender {
    [self doShowHideTransformMarkers:self.segmentShowHideTransformMarkers.selectedSegment];
}

- (IBAction)pasteTransformROIs:(id)sender {
    [self pasteROIsForActiveViewerControllerOfType:tMesure withOptionalName:self.textLengthROIname.stringValue ofROIMirrorType:Transform_ROI];
}
- (IBAction)copyTransformROIs:(id)sender {
    [self copyROIsFromActiveViewerControllerOfType:tMesure withOptionalName:self.textLengthROIname.stringValue ofROIMirrorType:Transform_ROI];
}
- (IBAction)deleteTransformROIs:(id)sender {
    [self deleteROIsFromActiveViewerControllerOfType:tMesure withOptionalName:self.textLengthROIname.stringValue];
    
}


#pragma mark - Plugin

- (void) initPlugin
{
    self.arrayTransformROIsCopied = [NSMutableArray array];
}

- (long) filterImage:(NSString*) menuName
{
    //essential use this with OWNER specified so it looks in OUR bundle for resource.
    NSWindowController *windowController = [[NSWindowController alloc] initWithWindowNibName:@"MirrorWindow" owner:self];
    [windowController showWindow:self];
    [self assignViewerWindow:nil forType:CTandPET_Windows];

    BOOL completedOK = YES;//[self mirrorActiveROIUsingLengthROI];
    
    if(completedOK) return 0; // No Errors
    else return -1;
}

#pragma mark - MirrorROIPluginFilterOC
-(void)assignViewerWindow:(ViewerController *)viewController forType:(ViewerWindow_Type)type
{
    if (type == CT_Window || type == CTandPET_Windows)
    {
        self.viewerCT = viewController;
        if (viewController != nil) {
            self.labelCTviewerName.stringValue = viewController.window.title;
        }
        else
        {
            self.labelCTviewerName.stringValue = @"Not Assigned";
        }
    }
    if (type == PET_Window || type == CTandPET_Windows)
    {
        self.viewerPET = viewController;
        if (viewController != nil) {
            self.labelPETviewerName.stringValue = viewController.window.title;
        }
        else
        {
            self.labelPETviewerName.stringValue = @"Not Assigned";
        }
    }
    self.boxQuickCopyButtons.hidden = self.viewerCT == nil || self.viewerPET == nil;
}

- (void)deleteROIsFromActiveViewerControllerOfType:(int)type withOptionalName:(NSString *)name
{
    ViewerController	*active2Dwindow = [ViewerController frontMostDisplayed2DViewer];
    for (NSUInteger pixIndex = 0; pixIndex < [[active2Dwindow pixList] count]; pixIndex++)
    {
        for( int roiIndex = 0; roiIndex < [[[active2Dwindow roiList] objectAtIndex: pixIndex] count]; roiIndex++)
        {
            ROI	*curROI = [[[active2Dwindow roiList] objectAtIndex: pixIndex] objectAtIndex: roiIndex];
            if ((curROI.type == type) && (name == nil || name == curROI.name))
            {
                [[[active2Dwindow roiList] objectAtIndex: pixIndex] removeObjectAtIndex:roiIndex];
            }
        }
    }
    [active2Dwindow needsDisplayUpdate];
}

- (void)copyROIsFromActiveViewerControllerOfType:(int)type withOptionalName:(NSString *)name ofROIMirrorType:(ROI_Mirror_Type)roiMirrorType
{
    NSMutableArray *scratchArray = [self arrayOfROIsFromActiveViewerControllerOfType:type withOptionalName:name ofROIMirrorType:roiMirrorType];
    
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

-(NSMutableArray *)arrayOfROIsFromViewerController:(ViewerController *)active2Dwindow ofType:(int)type withOptionalName:(NSString *)name ofROIMirrorType:(ROI_Mirror_Type)roiMirrorType
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

-(NSMutableArray *)arrayOfROIsFromActiveViewerControllerOfType:(int)type withOptionalName:(NSString *)name ofROIMirrorType:(ROI_Mirror_Type)roiMirrorType
{
    return [self arrayOfROIsFromViewerController:[ViewerController frontMostDisplayed2DViewer] ofType:type withOptionalName:name ofROIMirrorType:roiMirrorType];
}

-(void)doPasteBrushROIsAsPolygonsFromCT2PET:(ROI_Mirror_Type)roiMirrorType {
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

-(void)doPasteBrushROIsAsPolygonsFromPET2CT:(ROI_Mirror_Type)roiMirrorType {
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

- (void)pasteROIsForActiveViewerControllerOfType:(int)type withOptionalName:(NSString *)name ofROIMirrorType:(ROI_Mirror_Type)roiMirrorType
{
    switch (roiMirrorType) {
        case Mirrored_ROI:
            [self pasteROIsFromArray:[NSMutableArray arrayWithArray:self.arrayMirrorROIsCopied] ofType:type withOptionalName:name ofROIMirrorType:roiMirrorType intoViewerController:[ViewerController frontMostDisplayed2DViewer]];
            break;
        case Transform_ROI:
            [self pasteROIsFromArray:[NSMutableArray arrayWithArray:self.arrayTransformROIsCopied] ofType:type withOptionalName:name ofROIMirrorType:roiMirrorType intoViewerController:[ViewerController frontMostDisplayed2DViewer]];
            break;
        case Active_ROI:
            [self pasteROIsFromArray:[NSMutableArray arrayWithArray:self.arrayActiveROIsCopied] ofType:type withOptionalName:name ofROIMirrorType:roiMirrorType intoViewerController:[ViewerController frontMostDisplayed2DViewer]];
            break;
        default:
            break;
    }
}

-(void)pasteROIsFromArray:(NSMutableArray *)scratchArray ofType:(int)type withOptionalName:(NSString *)name ofROIMirrorType:(ROI_Mirror_Type)roiMirrorType intoViewerController:(ViewerController *)active2Dwindow
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

-(void)addROI:(ROI *)roi toSeriesFromStart:(NSUInteger)start toEnd:(NSUInteger)end
{
    ViewerController	*active2Dwindow = [ViewerController frontMostDisplayed2DViewer] /*self->viewerController*/;
    NSMutableArray  *allROIsList = [active2Dwindow roiList];
    for (NSUInteger nextIndex = start; nextIndex<end; nextIndex++) {
        ROI *roi2copy = roi;
        [[allROIsList objectAtIndex:nextIndex] addObject:roi2copy];
    }
}


-(void)completeLengthROIseries
{
    ViewerController	*active2Dwindow = [ViewerController frontMostDisplayed2DViewer] /*self->viewerController*/;
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
                [self addROI:[[measureROIs firstObject] copy] toSeriesFromStart:[[indicesOfDCMPixWithMeasureROI firstObject] intValue]+1 toEnd:allROIsList.count];
                break;
            case ExtendSingleLengthDown:
                [self addROI:[[measureROIs firstObject] copy] toSeriesFromStart:0 toEnd:[[indicesOfDCMPixWithMeasureROI firstObject] intValue]];
                break;
            case ExtendSingleLengthBoth:
                [self addROI:[[measureROIs firstObject] copy] toSeriesFromStart:[[indicesOfDCMPixWithMeasureROI firstObject] intValue]+1 toEnd:allROIsList.count];
                [self addROI:[[measureROIs firstObject] copy] toSeriesFromStart:0 toEnd:[[indicesOfDCMPixWithMeasureROI firstObject] intValue]];
                break;
            }
        default:
            //-1 as we go in pairs and so skip the last one
            for (int roiNumber=0; roiNumber<indicesOfDCMPixWithMeasureROI.count-1; roiNumber++)
            {
                [self completeLengthROIseriesBetweenROI1:[measureROIs objectAtIndex:roiNumber] andROI2:[measureROIs objectAtIndex:roiNumber+1] inThisRange:NSMakeRange(
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

-(void)doShowHideTransformMarkers:(BOOL)show
{
    ViewerController	*active2Dwindow = [ViewerController frontMostDisplayed2DViewer] /*self->viewerController*/;
    NSMutableArray  *roisInAllSlices  = [active2Dwindow roiList];
    for (NSUInteger slice=0; slice<roisInAllSlices.count; slice++) {
        NSMutableArray *roisInThisSlice = [roisInAllSlices objectAtIndex:slice];//[MirrorROIPluginFilterOC allROIinFrontDCMPixFromViewerController:active2Dwindow];
        ROI *ROI2showHide = [MirrorROIPluginFilterOC roiFromList:roisInThisSlice WithType:tMesure];
        if (ROI2showHide != nil) {
            ROI2showHide.hidden = show;
        }
    }
}


-(void)completeLengthROIseriesBetweenROI1:(ROI *)roi1 andROI2:(ROI *)roi2 inThisRange:(NSRange)rangeOfIndices// inROISArray:(NSMutableArray *)indicesOfDCMPixWithMeasureROI
{
    ViewerController	*active2Dwindow = [ViewerController frontMostDisplayed2DViewer] /*self->viewerController*/;
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

-(void)mirrorActiveROIUsingLengthROIIn3D:(BOOL)in3D
{
    ViewerController	*active2Dwindow = [ViewerController frontMostDisplayed2DViewer] /*self->viewerController*/;
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
        NSMutableArray *roisInThisSlice = [roisInAllSlices objectAtIndex:slice];//[MirrorROIPluginFilterOC allROIinFrontDCMPixFromViewerController:active2Dwindow];
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
