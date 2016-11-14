//
//  PluginTemplateFilter.m
//  PluginTemplate
//
//  Copyright (c) CURRENT_YEAR YOUR_NAME. All rights reserved.
//

#import "MirrorROIPluginFilterOC.h"
#import "ROIValues.h"
#import <OsiriXAPI/PluginFilter.h>
#import <OsiriXAPI/Notifications.h>


@implementation MirrorROIPluginFilterOC


#pragma mark - Plugin

- (void) initPlugin {
    // Register the preference defaults early.
    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
    [defaults setValue:[NSArchiver archivedDataWithRootObject:[NSColor yellowColor]] forKey:kColor_Active];
    [defaults setValue:[NSArchiver archivedDataWithRootObject:[NSColor blueColor]] forKey:kColor_Mirrored];
    [defaults setValue:[NSArchiver archivedDataWithRootObject:[NSColor greenColor]] forKey:kColor_TransformPlaced];
    [defaults setValue:[NSArchiver archivedDataWithRootObject:[NSColor redColor]] forKey:kColor_TransformIntercalated];
    [defaults setValue:@"Transform" forKey:kTransformROInameDefault];
    [defaults setValue:@"Mirrored" forKey:kMirroredROInameDefault];
    [defaults setValue:[NSNumber numberWithBool:YES] forKey:kTransposeDataDefault];
    
    
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];

}

- (long) filterImage:(NSString*) menuName {
    //Some defaults
    [[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"ROITEXTIFSELECTED"];
    
    //essential use this with OWNER specified so it looks in OUR bundle for resource.
    NSWindowController *windowController = [[NSWindowController alloc] initWithWindowNibName:@"MirrorWindow" owner:self];
    [windowController showWindow:self];
    [self smartAssignCTPETwindows];
    [self loadStatsScene];
    [self refreshDisplayedDataForViewer:self.viewerCT];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:OsirixCloseViewerNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:OsirixViewerControllerDidLoadImagesNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:OsirixDCMUpdateCurrentImageNotification object:nil];

    
    BOOL completedOK = YES;
    
    if(completedOK) return 0; // No Errors
    else return -1;
}

-(void)handleNotification:(NSNotification *)notification {
    if ([notification.name isEqualToString:OsirixViewerControllerDidLoadImagesNotification] ||
        [notification.name isEqualToString:OsirixCloseViewerNotification]) {
        [self smartAssignCTPETwindows];
    }
    if ([notification.name isEqualToString:OsirixDCMUpdateCurrentImageNotification] &&
        notification.object == self.viewerCT.imageView) {
        NSLog(@"%@ -- %@ -- %@",notification.name, notification.object, notification.userInfo);
       [self refreshDisplayedDataForViewer:self.viewerCT];
    }
}

#pragma mark - Windows
-(IBAction)assignWindowClicked:(NSButton *)sender {
    [self assignViewerWindow:[ViewerController frontMostDisplayed2DViewer] forType:sender.tag];
}
-(void)assignViewerWindow:(ViewerController *)viewController forType:(ViewerWindow_Type)type {
    
    if (type == CT_Window || type == CTandPET_Windows)
    {
        self.viewerCT = viewController;
        if (viewController != nil) {
            self.labelCT.stringValue = viewController.window.title;
        }
        else
        {
            self.labelCT.stringValue = @"Not Assigned";
        }
    }
    if (type == PET_Window || type == CTandPET_Windows)
    {
        self.viewerPET = viewController;
        if (viewController != nil) {
            self.labelPET.stringValue = viewController.window.title;
        }
        else
        {
            self.labelPET.stringValue = @"Not Assigned";
        }
    }
    [self showHideControlsIfViewersValid];
    [MirrorROIPluginFilterOC deselectROIforViewer:viewController];

}
+(void)deselectROIforViewer:(ViewerController *)viewController {
    if (viewController != nil) {
        //make a dummy just for the tag == 0 for deselect
        NSMenuItem *dummy = [[NSMenuItem alloc] init];
        dummy.tag = 0;
        [viewController roiSelectDeselectAll:dummy];
        [viewController needsDisplayUpdate];
    }
}
-(void)showHideControlsIfViewersValid {
    self.viewTools.hidden = ![self validCTandPETwindows];
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
    return ([self valid2DViewer:self.viewerCT] && [self valid2DViewer:self.viewerPET]);
}
- (IBAction)fuseDefusetapped:(NSButton *)sender {
    [self.viewerCT blendWindows:[[NSMenuItem alloc] init]];
}


#pragma mark - Create Active
- (IBAction)growRegionClicked:(id)sender {
    [self.viewerPET.window makeKeyAndOrderFront:nil];
    //[defaultValues setObject:NSLocalizedString(@"Growing Region", nil) forKey:@"growingRegionROIName"];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [[NSApplication sharedApplication] sendAction:@selector(segmentationTest:) to:self.viewerPET from:self.viewerPET];
#pragma clang diagnostic pop
}

#pragma mark - Create Transforms
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
                            atIndex:indexesWithROI.firstIndex
                         withType:Transform_ROI_Placed];
        [self displayImageInCTandPETviewersWithIndex:indexesWithROI.firstIndex];
        
    }
    else if(indexesWithROI.count>1) {
        [self addLengthROIWithStart:[self pointForImageIndex:indexesWithROI.firstIndex inWindow:self.viewerCT start:YES]
                             andEnd:[self pointForImageIndex:indexesWithROI.firstIndex inWindow:self.viewerCT start:NO]
                 toViewerController:self.viewerCT
                            atIndex:indexesWithROI.firstIndex
                         withType:Transform_ROI_Placed];
        
        [self addLengthROIWithStart:[self pointForImageIndex:indexesWithROI.firstIndex inWindow:self.viewerCT start:YES]
                             andEnd:[self pointForImageIndex:indexesWithROI.firstIndex inWindow:self.viewerCT start:NO]
                 toViewerController:self.viewerCT
                            atIndex:indexesWithROI.lastIndex
                         withType:Transform_ROI_Placed];
        
        [self displayImageInCTandPETviewersWithIndex:indexesWithROI.firstIndex];
    }
}
-(void)displayImageInCTandPETviewersWithIndex:(short)index {
    //do it in ImageView for correct order
    [self.viewerPET.imageView setIndexWithReset:index :YES];
    //[self.viewerPET adjustSlider];
    [self.viewerPET needsDisplayUpdate];

    [self.viewerCT.imageView setIndexWithReset:index :YES];
    //[self.viewerCT adjustSlider];
    [self.viewerCT needsDisplayUpdate];
    
}
-(void)addLengthROIWithStart:(NSPoint)startPoint andEnd:(NSPoint)endPoint toViewerController:(ViewerController *)active2Dwindow atIndex:(NSUInteger)index withType:(ROI_Type)type {
    ROI *newR = [active2Dwindow newROI:tMesure];
    [MirrorROIPluginFilterOC  setROIcolour:newR forType:type];
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
- (IBAction)completeTransformSeries:(NSButton *)sender {
    [self completeLengthROIseriesInCTWindow];
}
-(void)completeLengthROIseriesInCTWindow {
    if ([self valid2DViewer:self.viewerCT])
    {
        NSMutableArray  *allROIsList = [self.viewerCT roiList];
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
                    [self extendROI:[[measureROIs firstObject] copy] withinSeriesFromStart:[[indicesOfDCMPixWithMeasureROI firstObject] intValue]+1 toEnd:allROIsList.count inViewerController:self.viewerCT];
                    break;
                case ExtendSingleLengthDown:
                    [self extendROI:[[measureROIs firstObject] copy] withinSeriesFromStart:0 toEnd:[[indicesOfDCMPixWithMeasureROI firstObject] intValue] inViewerController:self.viewerCT];
                    break;
                case ExtendSingleLengthBoth:
                    [self extendROI:[[measureROIs firstObject] copy] withinSeriesFromStart:[[indicesOfDCMPixWithMeasureROI firstObject] intValue]+1 toEnd:allROIsList.count inViewerController:self.viewerCT];
                    [self extendROI:[[measureROIs firstObject] copy] withinSeriesFromStart:0 toEnd:[[indicesOfDCMPixWithMeasureROI firstObject] intValue] inViewerController:self.viewerCT];
                    break;
            }
            default:
                //-1 as we go in pairs and so skip the last one
                for (int roiNumber=0; roiNumber<indicesOfDCMPixWithMeasureROI.count-1; roiNumber++)
                {
                    [self completeLengthROIseriesForViewerController:self.viewerCT
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
        [self.viewerCT needsDisplayUpdate];
    }
}
-(void)completeLengthROIseriesForViewerController:(ViewerController *)active2Dwindow betweenROI1:(ROI *)roi1 andROI2:(ROI *)roi2 inThisRange:(NSRange)rangeOfIndices{
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
        [MirrorROIPluginFilterOC  setROIcolour:newROI forType:Transform_Intercalated];
        [[[newROI points] objectAtIndex:0] move:XincrementCurrent1 :YincrementCurrent1];
        [[[newROI points] objectAtIndex:1] move:XincrementCurrent2 :YincrementCurrent2];
        [[allROIsList objectAtIndex:nextIndex] addObject:newROI];

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
            [self addROI2Pix:[roi copy] atSlice:nextIndex inViewer:active2Dwindow hidden:NO];
        }
    }
}
- (IBAction)jumpToFirstLastTransform:(NSButton *)sender {
    NSMutableIndexSet *set = [MirrorROIPluginFilterOC indicesInViewer:self.viewerCT withROIofType:tMesure];
    if (set.count>0) {
        if (sender.tag>1)
        {
            [self displayImageInCTandPETviewersWithIndex:set.firstIndex];
        }
        else
        {
            [self displayImageInCTandPETviewersWithIndex:set.lastIndex];
        }
    }
}

#pragma mark - Do Mirror
- (IBAction)mirrorActiveROI3D:(NSButton *)sender {
    [self copyTransformsAndMirrorActivesIn3D:sender.tag];
}
-(void)copyTransformsAndMirrorActivesIn3D:(BOOL)in3D {
    [self copyTransformROIsFromCT2PETIn3D:in3D];
    [self mirrorActiveROIUsingLengthROIn3D:in3D];
    [self.viewerPET needsDisplayUpdate];
    [self.viewerCT needsDisplayUpdate];

}
-(void)copyTransformROIsFromCT2PETIn3D:(BOOL)in3D {
    if ([self validCTandPETwindows]
        && ([[self.viewerCT pixList] count] == [[self.viewerPET pixList] count])
        && ([[self.viewerCT roiList] count] == [[self.viewerCT pixList] count])
        && ([[self.viewerPET roiList] count] == [[self.viewerPET pixList] count]))
    {
        NSUInteger startSlice = 0;
        NSUInteger endSlice = 0;
        NSString *transformname = self.textLengthROIname.stringValue;
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
                if ([roi.name isEqualToString:transformname]) {
                    [self addROI2Pix:[roi copy] atSlice:pixIndex inViewer:self.viewerPET hidden:YES];
                }
            }
        }
    }
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
        [roi2add recompute];
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
        [roi2add recompute];
    }
}
-(void)mirrorActiveROIUsingLengthROIn3D:(BOOL)in3D {
    NSMutableArray  *roisInAllSlices  = [self.viewerPET roiList];
    NSUInteger startSlice = 0;
    NSUInteger endSlice = 0;
    if (in3D) {
        [self deleteROIsFromViewerController:self.viewerPET withName:self.textMirrorROIname.stringValue];
        [self deleteROIsFromViewerController:self.viewerCT withName:self.textActiveROIname.stringValue];
        [self deleteROIsFromViewerController:self.viewerCT withName:self.textMirrorROIname.stringValue];
        startSlice = 0;
        endSlice = roisInAllSlices.count;
    }
    else
    {
        startSlice = [[self.viewerPET imageView] curImage];
        endSlice = startSlice+1;
        [self deleteROIsInSlice:startSlice inViewerController:self.viewerPET withName:self.textMirrorROIname.stringValue];
        [self deleteROIsInSlice:startSlice inViewerController:self.viewerCT withName:self.textActiveROIname.stringValue];
        [self deleteROIsInSlice:startSlice inViewerController:self.viewerCT withName:self.textMirrorROIname.stringValue];
   }
    
    for (NSUInteger slice=startSlice; slice<endSlice; slice++) {
        NSMutableArray *roisInThisSlice = [roisInAllSlices objectAtIndex:slice];
        ROI *roi2Clone = [MirrorROIPluginFilterOC roiFromList:roisInThisSlice WithType:tPlain];
        if (roi2Clone != nil) {
            //rename to keep in sync
            roi2Clone.name = self.textActiveROIname.stringValue;
            [MirrorROIPluginFilterOC  setROIcolour:roi2Clone forType:Active_ROI];

            NSPoint deltaXY = [MirrorROIPluginFilterOC deltaXYFromROI:roi2Clone usingLengthROI:[MirrorROIPluginFilterOC roiFromList:roisInThisSlice WithType:tMesure]];
            
            if ([MirrorROIPluginFilterOC validDeltaPoint:deltaXY]) {
                ROI *createdROI = [[ROI alloc]
                                   initWithTexture:[MirrorROIPluginFilterOC flippedBufferHorizontalFromROI:roi2Clone]
                                   textWidth:roi2Clone.textureWidth
                                   textHeight:roi2Clone.textureHeight
                                   textName:self.textMirrorROIname.stringValue
                                   positionX:roi2Clone.textureUpLeftCornerX+deltaXY.x
                                   positionY:roi2Clone.textureUpLeftCornerY-deltaXY.y
                                   spacingX:roi2Clone.pixelSpacingX
                                   spacingY:roi2Clone.pixelSpacingY
                                   imageOrigin:roi2Clone.imageOrigin];
                [MirrorROIPluginFilterOC  setROIcolour:createdROI forType:Mirrored_ROI];
               [roisInThisSlice addObject:createdROI];
                [self addPolygonsToCTAtSlice:slice forActiveROI:roi2Clone mirroredROI:createdROI];
            }
        }
    }
    [MirrorROIPluginFilterOC deselectROIforViewer:self.viewerPET];
    [MirrorROIPluginFilterOC deselectROIforViewer:self.viewerCT];
    [self.viewerPET needsDisplayUpdate];
    [self.viewerCT needsDisplayUpdate];
}
-(void)addPolygonsToCTAtSlice:(NSUInteger)slice forActiveROI:(ROI *)activeROI mirroredROI:(ROI *)mirroredROI {
    if (activeROI) {
        ROI *aP = [activeROI copy];
        //[self.viewerPET convertBrushROItoPolygon:activeROI numPoints:50];
        //aP.name = activeROI.name;
        [self addROI2Pix:aP atSlice:slice inViewer:self.viewerCT hidden:NO];
    }
    if (mirroredROI) {
        ROI *mP = [mirroredROI copy];
        //self.viewerPET convertBrushROItoPolygon:mirroredROI numPoints:50];
        //mP.name = mirroredROI.name;
        [self addROI2Pix:mP atSlice:slice inViewer:self.viewerCT hidden:NO];
    }

}
+(NSPoint)deltaXYFromROI:(ROI*)roi2Clone usingLengthROI:(ROI*)lengthROI {
    NSPoint deltaPoint = [self anInvalidDeltaPoint];
    
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
         
                        width                    translation            offset      */
        deltaPoint.x = (roi2Clone.textureWidth)+(contra.x-ipsi.x)+(2.0*(ipsi.x-roi2Clone.textureUpLeftCornerX-roi2Clone.textureWidth));
        
        
        /*
         Y is not mirrored and must only move by the translation to keep the floor of the texture aligned with the anchor
         translation             */
        deltaPoint.y = (contra.y-ipsi.y);
        
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
            if (roi.type == type2Find){
                [set addIndex:roiIndex];}
            break;
        }
    }
    return set;
}
- (IBAction)moveMirrorROI:(NSButton *)sender {
    int moveX = 0;
    int moveY = 0;
    switch (sender.tag) {
        case MoveROI_Up:
            moveY = -self.sliderMovevalue.intValue;
            break;
        case MoveROI_Down:
            moveY = self.sliderMovevalue.intValue;
            break;
        case MoveROI_Right:
            moveX = self.sliderMovevalue.intValue;
            break;
        case MoveROI_Left:
            moveX = -self.sliderMovevalue.intValue;
            break;
        case MoveROI_NE:
            moveY = -self.sliderMovevalue.intValue;
            moveX = self.sliderMovevalue.intValue;
            break;
        case MoveROI_SE:
            moveY = self.sliderMovevalue.intValue;
            moveX = self.sliderMovevalue.intValue;
            break;
        case MoveROI_SW:
            moveY = self.sliderMovevalue.intValue;
            moveX = -self.sliderMovevalue.intValue;
            break;
        case MoveROI_NW:
            moveY = -self.sliderMovevalue.intValue;
            moveX = -self.sliderMovevalue.intValue;
            break;
        default:
            break;
    }
    short activeSlice = [[self.viewerPET imageView] curImage];
    NSMutableArray  *roisInAllSlices  = [self.viewerPET roiList];
    NSMutableArray *roisInThisSlice = [roisInAllSlices objectAtIndex:activeSlice];
    for (int i=0; i<roisInThisSlice.count;i++) {
        ROI *roi2Clone = [roisInThisSlice objectAtIndex:i];
        if ([roi2Clone.name isEqualToString:self.textMirrorROIname.stringValue]) {
            ROI *createdROI = [[ROI alloc]
                               initWithTexture:roi2Clone.textureBuffer
                               textWidth:roi2Clone.textureWidth
                               textHeight:roi2Clone.textureHeight
                               textName:roi2Clone.name
                               positionX:roi2Clone.textureUpLeftCornerX+moveX
                               positionY:roi2Clone.textureUpLeftCornerY+moveY
                               spacingX:roi2Clone.pixelSpacingX
                               spacingY:roi2Clone.pixelSpacingY
                               imageOrigin:roi2Clone.imageOrigin];
            [createdROI setNSColor:roi2Clone.NSColor globally:NO];
            [roisInThisSlice replaceObjectAtIndex:i withObject:createdROI];
            
            //move the polygon
            [self deleteROIsInSlice:activeSlice inViewerController:self.viewerCT withName:createdROI.name];
            [self addPolygonsToCTAtSlice:activeSlice forActiveROI:nil mirroredROI:createdROI];
            
            
            break;
        }
    }
    [self.viewerPET needsDisplayUpdate];
    [self.viewerCT needsDisplayUpdate];
    [self refreshDisplayedDataForViewer:self.viewerCT];
}

#pragma mark - Delete ROIs
- (IBAction)deleteActiveViewerROIsOfType:(NSButton *)sender {
    
    switch (sender.tag) {
        case Mirrored_ROI:
            [self deleteROIsFromViewerController:self.viewerPET withName:self.textMirrorROIname.stringValue];
            break;
        case Active_ROI:
            [self deleteROIsFromViewerController:self.viewerPET withName:self.textMirrorROIname.stringValue];
            break;
        case Transform_ROI_Placed:
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
- (void)deleteROIsInSlice:(NSUInteger)slice inViewerController:(ViewerController *)active2Dwindow withName:(NSString *)name {
    if (active2Dwindow && slice<active2Dwindow.roiList.count)
    {
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
    }
}
- (void)deleteAllROIsFromViewerController:(ViewerController *)active2Dwindow {
    if (active2Dwindow)
    {
        [active2Dwindow roiDeleteAll:nil];
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

-(void)setColourWellsToDefaults {
    /*
    self.colorWellActive.color = [MirrorROIPluginFilterOC colourFromData:[[NSUserDefaults standardUserDefaults] dataForKey:kColor_Active]];
    self.colorWellMirrored.color = [MirrorROIPluginFilterOC colourFromData:[[NSUserDefaults standardUserDefaults] dataForKey:kColor_Mirrored]];
    self.colorWellTransformPlaced.color = [MirrorROIPluginFilterOC colourFromData:[[NSUserDefaults standardUserDefaults] dataForKey:kColor_TransformPlaced]];
    self.colorWellTransformIntercalated.color = [MirrorROIPluginFilterOC colourFromData:[[NSUserDefaults standardUserDefaults] dataForKey:kColor_TransformIntercalated]];
     */
}
+(void)setROIcolour:(ROI *)roi forType:(ROI_Type)type {
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
        default:
            break;
    }
    colour = [colour colorWithAlphaComponent:0.5];
    [roi setNSColor:colour globally:NO];
}


#pragma mark - ROI Data
- (IBAction)refreshDisplayedDataCTTapped:(NSButton *)sender {
    [self refreshDisplayedDataForViewer:self.viewerCT];
}
- (void)refreshDisplayedDataForViewer:(ViewerController *)viewer{
    ROI *activeRoi = [self ROIfromCurrentSliceInViewer:viewer withName:self.textActiveROIname.stringValue];
    ROI *mirroredRoi = [self ROIfromCurrentSliceInViewer:viewer withName:self.textMirrorROIname.stringValue];
    if (activeRoi != nil && mirroredRoi != nil) {
        [activeRoi recompute];
        [mirroredRoi recompute];

        //draw the boxes
        float minGrey = fminf(activeRoi.min, mirroredRoi.min);
        minGrey = fminf(minGrey, mirroredRoi.mean-mirroredRoi.dev);
        minGrey = fminf(minGrey, activeRoi.mean-activeRoi.dev);
        float maxGrey = fmaxf(activeRoi.max, mirroredRoi.max);
        maxGrey = fmaxf(maxGrey, mirroredRoi.mean+mirroredRoi.dev);
        maxGrey = fmaxf(maxGrey, activeRoi.mean+activeRoi.dev);
        float ratio = 0;
        if (minGrey != maxGrey) {
            ratio = (self.skView.frame.size.width-(2.0*kSceneMargin))/(maxGrey-minGrey);
        }
        
        [self setLocationOfSpriteNamed:@"A"
                                  mean:(activeRoi.mean-minGrey)*ratio+kSceneMargin
                                   min:(activeRoi.min-minGrey)*ratio+kSceneMargin
                                   max:(activeRoi.max-minGrey)*ratio+kSceneMargin
                                  sdev:activeRoi.dev*ratio
                                   atY:0.66];
        [self setLocationOfSpriteNamed:@"M"
                                  mean:(mirroredRoi.mean-minGrey)*ratio+kSceneMargin
                                   min:(mirroredRoi.min-minGrey)*ratio+kSceneMargin
                                   max:(mirroredRoi.max-minGrey)*ratio+kSceneMargin
                                  sdev:mirroredRoi.dev*ratio
                                   atY:0.33];
        
        self.skView.hidden = NO;
    }
    else
    {
        self.skView.hidden = YES;
    }
}
-(ROI *)ROIfromCurrentSliceInViewer:(ViewerController *)viewer withName:(NSString *)name {
    if (viewer != nil)
    {
        for (ROI *roi in [[viewer roiList] objectAtIndex:[[viewer imageView] curImage]]) {
            if ([roi.name isEqualToString:name]) {
                return roi;
            }
        }
    }
    return nil;
}
- (IBAction)exportROIdataTapped:(NSButton *)sender {
    [self exportROIdataForType:sender.tag];
}

-(void)exportROIdataForType:(ROI_Type)type {
    NSString *name = @"";
    switch (type) {
        case Active_ROI:
            name = self.textActiveROIname.stringValue;
            break;
        case Mirrored_ROI:
            name = self.textMirrorROIname.stringValue;
            break;
        default:
            break;
    }
    NSMutableArray *arrayOfRows = [NSMutableArray arrayWithCapacity:self.viewerPET.roiList.count];
    for (int pix = 0; pix<self.viewerPET.roiList.count; pix++) {
        NSMutableArray *roiList = [self.viewerPET.roiList objectAtIndex:pix];
        for (int roiIndex = 0; roiIndex<roiList.count; roiIndex++) {
            ROI *roi = [roiList objectAtIndex:roiIndex];
            if ([roi.name isEqualToString:name]) {
                [roi recompute];
                NSMutableArray *roiData = roi.dataValues;
                [roiData insertObject:[NSNumber numberWithInteger:pix] atIndex:0];
                [arrayOfRows addObject:roiData];
                break;
            }
        }
    }
    if (arrayOfRows.count>0) {
        NSSavePanel *savePanel = [NSSavePanel savePanel];
        savePanel.allowedFileTypes = [NSArray arrayWithObject:@"txt"];
        savePanel.nameFieldStringValue = name;
        if ([savePanel runModal] == NSFileHandlingPanelOKButton) {
            NSString *dataString = [self stringForDataArray:arrayOfRows];
            NSError *error = [[NSError alloc] init];
            [dataString writeToURL:savePanel.URL atomically:YES encoding:NSUnicodeStringEncoding error:&error];
        }
    }
}

-(NSString *)stringForDataArray:(NSMutableArray *)arrayOfData {
    if (arrayOfData.count>0) {
        NSMutableArray *arrayOfRowStrings = [NSMutableArray arrayWithCapacity:arrayOfData.count];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kTransposeExportedDataDefault]) {
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

#pragma mark - ROI Data

-(void)loadStatsScene {
    
    // Load the SKScene from 'GameScene.sks'
    self.skScene = [SKScene sceneWithSize:self.skView.frame.size];
    self.skScene.scaleMode = SKSceneScaleModeResizeFill;
    self.skScene.backgroundColor = [NSColor clearColor];
    self.skView.allowsTransparency = YES;
    [self.skView presentScene:self.skScene];
    self.skView.showsFPS = NO;
    self.skView.showsNodeCount = NO;
    [self addStatsMarkersWithName:@"A"];
    [self addStatsMarkersWithName:@"M"];
    SKLabelNode *statsA = [SKLabelNode labelNodeWithFontNamed:@"Helvetica"];
    statsA.text = @"statsA";
    statsA.name = @"AT";
    statsA.fontSize = 13;
    statsA.fontColor = [NSColor blackColor];
    statsA.position = CGPointMake(CGRectGetMidX(self.skView.bounds),self.skView.frame.size.height-statsA.frame.size.height-kSceneMargin);
    [self.skScene addChild:statsA];
    SKLabelNode *statsM = [SKLabelNode labelNodeWithFontNamed:@"Helvetica"];
    statsM.text = @"statsM";
    statsM.name = @"MT";
    statsM.fontSize = 13;
    statsM.fontColor = [NSColor blackColor];
    statsM.position = CGPointMake(CGRectGetMidX(self.skView.bounds),kSceneMargin);
    [self.skScene addChild:statsM];

    
}
-(void)addStatsMarkersWithName:(NSString *)name {
    SKSpriteNode *rangeA = [SKSpriteNode spriteNodeWithColor:[NSColor darkGrayColor] size:CGSizeMake(0.0, 3.0)];
    rangeA.name = [name stringByAppendingString:@"R"];
    SKSpriteNode *median = [SKSpriteNode spriteNodeWithColor:[NSColor darkGrayColor] size:CGSizeMake(2, 25.0)];
    median.name = [name stringByAppendingString:@"MD"];
    [rangeA addChild:median];
    [self.skScene addChild:rangeA];
    SKSpriteNode *sdevA = [SKSpriteNode spriteNodeWithColor:[NSColor blackColor] size:CGSizeMake(0.0, 15.0)];
    sdevA.name = [name stringByAppendingString:@"S"];
    SKSpriteNode *meanA = [SKSpriteNode spriteNodeWithColor:[NSColor blackColor] size:CGSizeMake(2, 31.0)];
    meanA.name = [name stringByAppendingString:@"MN"];
    [self colourNode:sdevA forName:name];
    [sdevA addChild:meanA];
    [self.skScene addChild:sdevA];
    

}
-(void)colourNode:(SKSpriteNode *)node forName:(NSString *)name {
    if (node != nil) {
        if ([name isEqualToString:@"A"]) {
            node.color = self.colorWellActive.color;
        }
        else {
            node.color = self.colorWellMirrored.color;
        }
    }
}
-(void)setLocationOfSpriteNamed:(NSString *)name mean:(CGFloat)mean min:(CGFloat)min max:(CGFloat)max sdev:(CGFloat)sdev atY:(CGFloat)divisorY{
    CGFloat range = (max-min);
    CGFloat median = (max-min)/2.0;
    CGFloat posY = self.skView.frame.size.height*divisorY;
    SKSpriteNode *rangenode = (SKSpriteNode *)[self.skScene childNodeWithName:[name stringByAppendingString:@"R"]];
    if (rangenode != nil) {
        rangenode.position = CGPointMake(min+median, posY);
        rangenode.size = CGSizeMake(range, rangenode.size.height);
    }
    SKSpriteNode *sdnode = (SKSpriteNode *)[self.skScene childNodeWithName:[name stringByAppendingString:@"S"]];
    if (sdnode != nil) {
        sdnode.position = CGPointMake(mean, posY);
        sdnode.size = CGSizeMake(sdev*2.0, sdnode.size.height);
        [self colourNode:sdnode forName:name];
        //mean node moves with SD node
    }
    
    //update text
    [(SKLabelNode *)[self.skScene childNodeWithName:[name stringByAppendingString:@"T"]] setText:[NSString stringWithFormat:@"%.0f ± %.0f (%.0f—%.0f—%.0f)", mean, sdev, min, median, max]];

}
- (IBAction)selectBestMirrorTapped:(NSButton *)sender {
    [self selectBestMirror];
}

- (IBAction)sliderSelectBestROIchanged:(NSSlider *)sender {
}

-(void)selectBestMirror {
    ROI *roi2Clone = [self ROIfromCurrentSliceInViewer:self.viewerPET withName:self.textMirrorROIname.stringValue];
    if (roi2Clone != nil) {
        NSMutableArray *arrayOfvalues = [NSMutableArray arrayWithCapacity:self.viewerPET.roiList.count];
        for (int moveX=-2; moveX<3; moveX++) {
            for (int moveY=-1; moveY<3; moveY++) {
                ROI *createdROI = [[ROI alloc]
                                   initWithTexture:roi2Clone.textureBuffer
                                   textWidth:roi2Clone.textureWidth
                                   textHeight:roi2Clone.textureHeight
                                   textName:roi2Clone.name
                                   positionX:roi2Clone.textureUpLeftCornerX+moveX
                                   positionY:roi2Clone.textureUpLeftCornerY+moveY
                                   spacingX:roi2Clone.pixelSpacingX
                                   spacingY:roi2Clone.pixelSpacingY
                                   imageOrigin:roi2Clone.imageOrigin];
                createdROI.name = @"jiggle";
                [self addROI2Pix:createdROI atSlice:[[self.viewerCT imageView] curImage] inViewer:self.viewerCT hidden:YES];
                [arrayOfvalues addObject:
                 [ROIValues roiValuesWithMean: fabsf(roi2Clone.mean-createdROI.mean)
                                         sdev:fabsf(roi2Clone.dev-createdROI.dev)
                                          max:fabsf(roi2Clone.max-createdROI.max)
                                          min:fabsf(roi2Clone.min-createdROI.min)
                                          range:fabsf(roi2Clone.max-roi2Clone.min-createdROI.max-createdROI.min)
                                          median:fabsf(((roi2Clone.max-roi2Clone.min)/2.0f)-((createdROI.max-createdROI.min)/2.0f))
                                     location:NSMakePoint(roi2Clone.textureUpLeftCornerX+moveX, roi2Clone.textureUpLeftCornerY+moveY)]];
            }
        }
        
        [arrayOfvalues sortUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"mean" ascending:YES],
                                              [[NSSortDescriptor alloc] initWithKey:@"sdev" ascending:YES]]];
        
        NSLog(@"%@",arrayOfvalues);
    }
 
    
}
@end
