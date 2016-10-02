//
//  PluginTemplateFilter.m
//  PluginTemplate
//
//  Copyright (c) CURRENT_YEAR YOUR_NAME. All rights reserved.
//

#import "MirrorROIPluginFilterOC.h"

@implementation MirrorROIPluginFilterOC

- (void) initPlugin
{
}

- (long) filterImage:(NSString*) menuName
{
    BOOL completedOK = [self mirrorActiveROIUsingLengthROI];
    
    if(completedOK) return 0; // No Errors
    else return -1;
}

+(unsigned char*)FlippedBufferHorizontalFromROI:(ROI *)roi2Clone
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


-(BOOL)mirrorActiveROIUsingLengthROI
{
    BOOL completedOK = YES;
    
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
                           initWithTexture:[MirrorROIPluginFilterOC FlippedBufferHorizontalFromROI:roi2Clone]
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
    return completedOK;
}


+(NSPoint)deltaXYFromROI:(ROI*)roi2Clone usingLengthROI:(ROI*)lengthROI
{
    NSPoint deltaPoint = NSMakePoint(CGFLOAT_MAX, CGFLOAT_MAX);
    
    if (roi2Clone && lengthROI) {
        NSPoint ipsi = [(MyPoint *)[lengthROI.points objectAtIndex:0] point];
        NSPoint contra = [(MyPoint *)[lengthROI.points objectAtIndex:1] point];
        
        deltaPoint.x = roi2Clone.textureWidth+(2.0*(ipsi.x-roi2Clone.textureUpLeftCornerX-roi2Clone.textureWidth))+(contra.x-ipsi.x);
        deltaPoint.y = roi2Clone.textureHeight+(2.0*(ipsi.y-roi2Clone.textureUpLeftCornerY-roi2Clone.textureHeight))+(contra.y-ipsi.y);
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
