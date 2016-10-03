//
//  PluginTemplateFilter.m
//  PluginTemplate
//
//  Copyright (c) CURRENT_YEAR YOUR_NAME. All rights reserved.
//

#import "MirrorROIPluginFilterOC.h"

@implementation MirrorROIPluginFilterOC


-(IBAction)mirrorActiveROI:(id)sender
{
    [self mirrorActiveROIUsingLengthROI];
}
- (IBAction)callExtendLengthSeries:(id)sender {
    [self completeLengthROIseries];
}

- (void) initPlugin
{
}

- (long) filterImage:(NSString*) menuName
{
    //essential use this with OWNER specified so it looks in OUR bundle for resource.
    NSWindowController *windowController = [[NSWindowController alloc] initWithWindowNibName:@"MirrorWindow" owner:self];
    [windowController showWindow:self];
    
    BOOL completedOK = YES;//[self mirrorActiveROIUsingLengthROI];
    
    if(completedOK) return 0; // No Errors
    else return -1;
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

-(void)completeLengthROIseries
{
    ViewerController	*active2Dwindow = self->viewerController;
    NSMutableArray  *allROIsList = [active2Dwindow roiList];
    NSMutableArray *indicesOfDCMPixWithMeasureROI = [NSMutableArray arrayWithCapacity:allROIsList.count];
    NSMutableArray *measureROIs = [NSMutableArray arrayWithCapacity:allROIsList.count];
    
    for (int index = 0;index<allROIsList.count; index++) {
        ROI *measureROI = [MirrorROIPluginFilterOC roiFromList:[allROIsList objectAtIndex:index] WithType:tMesure];
        if (measureROI != nil) {
            [measureROIs addObject:measureROI];
            [indicesOfDCMPixWithMeasureROI addObject:[NSNumber numberWithInt:index]];
        }
    }
    switch (indicesOfDCMPixWithMeasureROI.count) {
        case 1:
            for (int nextIndex = [[indicesOfDCMPixWithMeasureROI firstObject] intValue]+1; nextIndex<allROIsList.count; nextIndex++) {
                [[allROIsList objectAtIndex:nextIndex] addObject:[[measureROIs firstObject] copy]];
            }
            break;
        case 2:
        {
            ROI * roi1 = [measureROIs firstObject];
            ROI * roi2 = [measureROIs lastObject];
            MyPoint *roi1_Point1 = [roi1.points objectAtIndex:0];
            MyPoint *roi1_Point2 = [roi1.points objectAtIndex:1];
            MyPoint *roi2_Point1 = [roi2.points objectAtIndex:0];
            MyPoint *roi2_Point2 = [roi2.points objectAtIndex:1];
            float numberOfSlices = [[indicesOfDCMPixWithMeasureROI lastObject] floatValue] - [[indicesOfDCMPixWithMeasureROI firstObject] floatValue] - 1.0;
            float Xincrement1 = (roi2_Point1.point.x - roi1_Point1.point.x)/numberOfSlices;
            float Xincrement2 = (roi2_Point2.point.x - roi1_Point2.point.x)/numberOfSlices;
            float XincrementCurrent1 = Xincrement1;
            float XincrementCurrent2 = Xincrement2;
            float Yincrement1 = (roi2_Point1.point.y - roi1_Point1.point.y)/numberOfSlices;
            float Yincrement2 = (roi2_Point2.point.y - roi1_Point2.point.y)/numberOfSlices;
            float YincrementCurrent1 = Yincrement1;
            float YincrementCurrent2 = Yincrement2;
            //skip first and last index
            for (int nextIndex = [[indicesOfDCMPixWithMeasureROI firstObject] intValue]+1; nextIndex<[[indicesOfDCMPixWithMeasureROI lastObject] intValue]; nextIndex++) {
                ROI *newROI = [roi1 copy];
                [[[newROI points] objectAtIndex:0] move:XincrementCurrent1 :YincrementCurrent1];
                [[[newROI points] objectAtIndex:1] move:XincrementCurrent2 :YincrementCurrent2];
                [[allROIsList objectAtIndex:nextIndex] addObject:newROI];
                XincrementCurrent1 += Xincrement1;
                XincrementCurrent2 += Xincrement2;
                YincrementCurrent1 += Yincrement1;
                YincrementCurrent2 += Yincrement2;
            }
        }
            break;
        
        default:
            break;
    }

    [active2Dwindow needsDisplayUpdate];
}

-(void)mirrorActiveROIUsingLengthROI
{
    //BOOL completedOK = YES;
    
    ViewerController	*active2Dwindow = self->viewerController;
    NSMutableArray  *DCMPixList;
    //NSMutableArray  *roiSeriesList;
    //NSMutableArray  *roiImageList;
    //DCMPix *curPix = [DCMPixList objectAtIndex: curImageIndex];
    //short curImageIndex = [theDCMView curImage];
    /**  Return the image pane object - (DCMView*) imageView; */
    //DCMView *theDCMView = [active2Dwindow imageView];
    
    // DCMPix of active window
    DCMPixList = [active2Dwindow pixList];
    
    
    NSMutableArray *roiInThisDCMPix = [MirrorROIPluginFilterOC allROIinFrontDCMPixFromViewerController:active2Dwindow];
    ROI *roi2Clone = [MirrorROIPluginFilterOC roiFromList:roiInThisDCMPix WithName:@"Active"];
    
    NSPoint deltaXY = [MirrorROIPluginFilterOC deltaXYFromROI:roi2Clone usingLengthROI:[MirrorROIPluginFilterOC roiFromList:roiInThisDCMPix WithType:tMesure]];
    
    if ([MirrorROIPluginFilterOC validDeltaPoint:deltaXY]) {
        ROI *createdROI = [[ROI alloc]
                           initWithTexture:[MirrorROIPluginFilterOC flippedBufferHorizontalFromROI:roi2Clone]
                           textWidth:roi2Clone.textureWidth
                           textHeight:roi2Clone.textureHeight
                           textName:@"Created"
                           positionX:roi2Clone.textureUpLeftCornerX+deltaXY.x
                           positionY:roi2Clone.textureUpLeftCornerY+deltaXY.y
                           spacingX:roi2Clone.pixelSpacingX
                           spacingY:roi2Clone.pixelSpacingY
                           imageOrigin:roi2Clone.imageOrigin];
        [roiInThisDCMPix addObject:createdROI];
        [active2Dwindow needsDisplayUpdate];
    }
    //return completedOK;
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
    NSMutableArray  *allROIinAllImagesInSeriesInFrontWindow  = [theVC roiList];
    int indexOfFrontDCMPix =  [[theVC imageView] curImage];
    if (allROIinAllImagesInSeriesInFrontWindow.count>indexOfFrontDCMPix) {
        return [allROIinAllImagesInSeriesInFrontWindow objectAtIndex: indexOfFrontDCMPix];
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
