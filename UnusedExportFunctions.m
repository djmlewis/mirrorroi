//
//  UnusedExportFunctions.m
//  MirrorROIPlugin
//
//  Created by David Lewis on 08/02/2017.
//
//

#import <Foundation/Foundation.h>

#import "MirrorROIPluginFilterOC.h"
#import "ROIValues.h"
#import "TextDisplayWindowController.h"

#import <OsiriXAPI/PluginFilter.h>
#import <OsiriXAPI/Notifications.h>
#import <OsiriXAPI/DicomStudy.h>
#import <OsiriXAPI/DicomSeries.h>
#import <OsiriXAPI/BrowserController.h>

-(BOOL)roiIsActiveMirrorOrTransform:(ROI *)roi {
    return [roi.name isEqualToString:[self roiNameForType:Active_ROI]] || [roi.name isEqualToString:[self roiNameForType:Mirrored_ROI]] || [roi.name isEqualToString:[self roiNameForType:Transform_ROI_Placed]];
}

-(NSString *)dataStringFor2DpixelDataForROIType:(ROI_Type)type {
    !! No longer correct as it does not take into account the fact that dictOfrawPixelsDelta_make2DarrayWithPixelsFromROIsForType is now called makeArrayBySliceOf2DarraysWithPixelsFromROIsInSliceOfType and returns an array of pixel grids for all the rois
    
    NSMutableDictionary *dictOfRoiGrids = [self dictOfrawPixelsDelta_make2DarrayWithPixelsFromROIsForType:type];
    NSMutableArray *arrayOfRows = [NSMutableArray array];
    [arrayOfRows addObject:[NSString stringWithFormat:@"2D grids of Pixel Data For %@ without mirroring",[self roiNameForType:type]]];
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

-(NSString *)rawPixelsDelta_assembleFinalDataString:(ExportDataType)type {
    NSMutableDictionary *dict = [self dataDictForRawPixelsDelta];
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
                    kDeltaNameActivePixFlatAndNotMirrored,
                    [[self arrayOfIndexesOfSlicesWithROIofType:Active_ROI] componentsJoinedByString:@"\t"],
                    [MirrorROIPluginFilterOC stringForDataArray:[dict objectForKey:kDeltaNameActivePixFlatAndNotMirrored] forceTranspose:NO],
                    kDeltaNameMirroredPixFlatAndMirroredInRows,
                    [MirrorROIPluginFilterOC stringForDataArray:[dict objectForKey:kDeltaNameMirroredPixFlatAndMirroredInRows] forceTranspose:NO],
                    kDeltaNameSubtractedPix,
                    [MirrorROIPluginFilterOC stringForDataArray:[dict objectForKey:kDeltaNameSubtractedPix] forceTranspose:NO],
                    kDeltaNameDividedPix,
                    [MirrorROIPluginFilterOC stringForDataArray:[dict objectForKey:kDeltaNameDividedPix] forceTranspose:NO],
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

-(void)exportROIdata:(ExportDataHow)exportHow {
    NSInteger exportType = [[NSUserDefaults standardUserDefaults] integerForKey:kExportMenuSelectedIndexDefault];
    NSString *dataStringA = nil;
    NSString *dataStringM = nil;
    NSString *fileTypeName = [self fileNamePrefixForExportType:exportType withAnatomicalSite:YES];
    
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
            dataStringA = [self dataStringFromDataValuesArrayFromROIsOfType:Active_ROI];
            dataStringM = [self dataStringFromDataValuesArrayFromROIsOfType:Mirrored_ROI];
            break;
        case AllROIdata:
            dataStringA = [self dataStringForAllROdataIForType:Active_ROI];
            dataStringM = [self dataStringForAllROdataIForType:Mirrored_ROI];
            break;
        default:
            break;
    }
    switch (exportHow) {
        case ExportAsFile:
            if ([MirrorROIPluginFilterOC userDefaultBooleanForKey:kCombinePixelsWithStatsInFileDefault] == YES)
            {
                if (dataStringA.length>0 && dataStringM.length>0) {
                    [self saveData:[self combinedAandMstringsForExportROIdata_A:dataStringA M:dataStringM] withName:[NSString stringWithFormat:@"%@-%@",fileTypeName,self.viewerPET.window.title]];
                }
            }
            else
            {
                if (dataStringA.length>0) {
                    [self saveData:dataStringA withName:[NSString stringWithFormat:@"%@-%@-%@", [self roiNameForType:Active_ROI],fileTypeName,self.viewerPET.window.title]];
                }
                if (dataStringM.length>0) {
                    [self saveData:dataStringM withName:[NSString stringWithFormat:@"%@-%@-%@", [self roiNameForType:Mirrored_ROI],fileTypeName,self.viewerPET.window.title]];
                }
            }
            break;
        case ViewInWindow:
        {
            if ([MirrorROIPluginFilterOC userDefaultBooleanForKey:kCombinePixelsWithStatsInFileDefault] == YES)
            {
                if (dataStringA.length>0 && dataStringM.length>0) {
                    [MirrorROIPluginFilterOC showStringInWindow:[self combinedAandMstringsForExportROIdata_A:dataStringA M:dataStringM]
                                                      withTitle:[NSString stringWithFormat:@"%@-%@",fileTypeName,self.viewerPET.window.title]];
                }
            }
            else
            {
                if (dataStringA.length>0) {
                    [MirrorROIPluginFilterOC showStringInWindow:dataStringA withTitle:[NSString stringWithFormat:@"%@-%@-%@", [self roiNameForType:Active_ROI],fileTypeName,self.viewerPET.window.title]];
                }
                if (dataStringM.length>0) {
                    [MirrorROIPluginFilterOC showStringInWindow:dataStringM withTitle:[NSString stringWithFormat:@"%@-%@-%@", [self roiNameForType:Mirrored_ROI],fileTypeName,self.viewerPET.window.title]];
                }
            }
        }
            break;
        default:
            break;
    }
}
-(NSString *)dataStringForAllROdataIForType:(ROI_Type)type {
    NSMutableArray *finalString = [NSMutableArray arrayWithCapacity:4];
    NSString *dataString = [self dataStringFor3DROIdataForType:type];
    if (dataString != nil) {[finalString addObject:[@"3D data\n" stringByAppendingString:dataString]];}
    dataString = [self dataStringForSummaryROIdataForType:type];
    if (dataString != nil) {[finalString addObject:[@"Summary data\n" stringByAppendingString:dataString]];}
    dataString = [self dataStringForROIdataForType:type];
    if (dataString != nil) {[finalString addObject:[@"ROI data\n" stringByAppendingString:dataString]];}
    dataString = [self dataStringFromDataValuesArrayFromROIsOfType:type];
    if (dataString != nil) {[finalString addObject:[@"Flat Pixel data\n" stringByAppendingString:dataString]];}
    if (finalString.count>0) {
        return [finalString componentsJoinedByString:@"\n\n"];
    }
    return @"";
}
-(NSString *)dataStringForSummaryROIdataForType:(ROI_Type)type {
    NSUInteger capacity = self.viewerPET.roiList.count;
    NSMutableDictionary *dictOfRows = [NSMutableDictionary dictionaryWithCapacity:capacity];
    NSString *roiname = [self roiNameForType:type];
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
        return [MirrorROIPluginFilterOC stringForDataArray:arrayOfRows forceTranspose:YES];
    }
    return nil;
}
-(NSString *)dataStringForROIdataForType:(ROI_Type)type {
    NSMutableArray *arrayOfRows = [NSMutableArray arrayWithCapacity:self.viewerPET.roiList.count];
    //each row has the data for one roi
    //add the headings
    [arrayOfRows addObject:@"index\tmean\tsdev\tmax\tmin\tcount"];
    NSString *roiname = [self roiNameForType:type];
    for (int pix = 0; pix<self.viewerPET.roiList.count; pix++) {
        NSMutableArray *roiList = [self.viewerPET.roiList objectAtIndex:pix];
        for (int roiIndex = 0; roiIndex<roiList.count; roiIndex++) {
            ROI *roi = [roiList objectAtIndex:roiIndex];
            if ([roi.name isEqualToString:roiname]) {
                
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

-(NSString *)dataStringFor3DROIdataForType:(ROI_Type)type {
    [self.viewerPET roiSelectDeselectAll: nil];
    NSString *roiname = [self roiNameForType:type];
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

-(void)rawPixelsDelta_export:(ExportDataHow)exportHow exportType:(ExportDataType)exportType {
    NSString *fileTypeName = [self fileNamePrefixForExportType:exportType withAnatomicalSite:YES];
    NSString *fileName = [NSString stringWithFormat:@"%@-%@",fileTypeName,self.viewerPET.window.title];
    switch (exportHow) {
        case ExportAsFile:
            [self saveData:[self rawPixelsDelta_assembleFinalDataString:exportType] withName:fileName];
            break;
        case ViewInWindow:
            [MirrorROIPluginFilterOC showStringInWindow:[self rawPixelsDelta_assembleFinalDataString:exportType] withTitle:fileName];
            break;
        default:
            break;
    }
}

-(NSString *)combinedAandMstringsForExportROIdata_A:(NSString *)dataStringA M:(NSString *)dataStringM {
    return [NSString stringWithFormat:@"%@\n%@\n\n%@\n%@",[self roiNameForType:Active_ROI],dataStringA,[self roiNameForType:Mirrored_ROI],dataStringM];
}

-(NSMutableArray *)dataValuesArrayFromROIsOfType:(ROI_Type)type addHeader:(BOOL)addHeader{
    NSString *roiname = [self roiNameForType:type];
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




-(NSString *)dataStringFromDataValuesArrayFromROIsOfType:(ROI_Type)type {
    NSMutableArray *arrayOfRows = [self dataValuesArrayFromROIsOfType:type addHeader:YES];
    if (arrayOfRows.count>0) {
        return [MirrorROIPluginFilterOC stringForDataArray:arrayOfRows forceTranspose:NO];
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

// OTHER STUFF
#pragma mark - Other Stuff
- (void) exportAMTroiInViewer:(ViewerController *)viewer {
    if ([self valid2DViewer:viewer])
    {
        NSMutableArray  *roisPerSeries = [NSMutableArray  array];
        BOOL rois = NO;
        //retain the structure of the arrays, but pick only AMT
        for( int x = 0; x < [viewer.roiList count]; x++)
        {
            NSMutableArray  *roisPerImages = [NSMutableArray  array];
            for( int i = 0; i < [[viewer.roiList objectAtIndex: x] count]; i++)
            {
                ROI	*curROI = [[viewer.roiList objectAtIndex: x] objectAtIndex: i];
                if ([self roiIsActiveMirrorOrTransform:curROI])
                {
                    [roisPerImages addObject: curROI];
                    rois = YES;
                }
            }
            
            [roisPerSeries addObject: roisPerImages];
        }
        
        if(rois == YES)
        {
            NSSavePanel *panel = [NSSavePanel savePanel];
            [panel setCanSelectHiddenExtension:NO];
            //[panel setRequiredFileType:@"rois_series"];
            panel.allowedFileTypes = [NSArray arrayWithObject:@"rois_series"];
            panel.nameFieldStringValue = viewer.window.title;
            if( [panel runModal] == NSFileHandlingPanelOKButton)
            {
                [NSArchiver archiveRootObject: roisPerSeries toFile :[panel filename]];
            }
        }
    }
}



-(void)setColourWellsToDefaults {
    /*
     self.colorWellActive.color = [MirrorROIPluginFilterOC colourFromData:[[NSUserDefaults standardUserDefaults] dataForKey:kColor_Active]];
     self.colorWellMirrored.color = [MirrorROIPluginFilterOC colourFromData:[[NSUserDefaults standardUserDefaults] dataForKey:kColor_Mirrored]];
     self.colorWellTransformPlaced.color = [MirrorROIPluginFilterOC colourFromData:[[NSUserDefaults standardUserDefaults] dataForKey:kColor_TransformPlaced]];
     self.colorWellTransformIntercalated.color = [MirrorROIPluginFilterOC colourFromData:[[NSUserDefaults standardUserDefaults] dataForKey:kColor_TransformIntercalated]];
     */
}

-(void)setLocationOfSpriteNamed:(NSString *)name mean:(CGFloat)mean min:(CGFloat)min max:(CGFloat)max sdev:(CGFloat)sdev minGrey:(CGFloat)minGrey ratio:(CGFloat)ratio{
    
    CGFloat median = (max-min)/2.0;
    CGFloat adjmean = (mean-minGrey)*ratio+kSceneMargin;
    CGFloat adjmin = (min-minGrey)*ratio+kSceneMargin;
    CGFloat adjmax = (max-minGrey)*ratio+kSceneMargin;
    CGFloat adjsdev = sdev*ratio;
    CGFloat adjrange = (adjmax-adjmin);
    CGFloat adjmedian = (adjmax-adjmin)/2.0;
    SKSpriteNode *rangenode = (SKSpriteNode *)[self.skScene childNodeWithName:[name stringByAppendingString:kSpriteName_Range]];
    if (rangenode != nil) {
        rangenode.position = CGPointMake(adjmin+adjmedian, rangenode.position.y);
        rangenode.size = CGSizeMake(adjrange, rangenode.size.height);
    }
    SKSpriteNode *sdnode = (SKSpriteNode *)[self.skScene childNodeWithName:[name stringByAppendingString:kSpriteName_SDEV]];
    if (sdnode != nil) {
        sdnode.position = CGPointMake(adjmean, rangenode.position.y);
        sdnode.size = CGSizeMake(adjsdev*2.0, sdnode.size.height);
        [self colourNode:sdnode forName:name];
        //mean node moves with SD node
    }
    
    //update text
    [(SKLabelNode *)[self.skScene childNodeWithName:[name stringByAppendingString:kSpriteName_Text]] setText:[NSString stringWithFormat:@"%.0f ± %.0f (%.0f—%.0f—%.0f)", mean, sdev, min, median, max]];
    
}




+(unsigned char*)ClonedBufferFromROI:(ROI *)roi2Clone
{
    int textureBuffer_Length = roi2Clone.textureHeight * roi2Clone.textureWidth;
    int textureBuffer_Width = roi2Clone.textureWidth;
    
    unsigned char   *tempBuffer = (unsigned char*)malloc(textureBuffer_Length*sizeof(unsigned char));
    
    for (int pixelIndex = 0; pixelIndex<textureBuffer_Length; pixelIndex+=textureBuffer_Width) {
        //copy the row mask
        for (int col=0; col<textureBuffer_Width; col++) {
            tempBuffer[pixelIndex+col] = roi2Clone.textureBuffer[pixelIndex+col];
        }
    }
    return tempBuffer;
}





+(NSPoint)deltaXYFromROI:(ROI*)roi2Clone ipsiROI:(ROI*)ipsiROI contraROI:(ROI*)contraROI
{
    NSPoint deltaPoint = NSMakePoint(CGFLOAT_MAX, CGFLOAT_MAX);
    
    if (roi2Clone && ipsiROI && contraROI) {
        deltaPoint.x =
        ([contraROI centroid].x - [ipsiROI centroid].x) + roi2Clone.textureWidth;
        //+ (1.0*([ipsiROI centroid].x - [roi2Clone centroid].x));
        deltaPoint.y =
        [contraROI centroid].y - [ipsiROI centroid].y +
        (1.0*([ipsiROI centroid].y - [roi2Clone centroid].y));
        //2* becaumse we mirror around the contra anchor
        
    }
    return deltaPoint;
}


+(ROI*) roiFromList:(NSMutableArray *)roiList WithName:(NSString*)name2Find
{
    for (ROI *roi in roiList) {
        if ([roi.name isEqualToString:name2Find]){return roi;}
    }
    return nil;
}


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
            case Transform_ROI_Placed:
                [self copyROIsFromViewerController:self.viewerPET ofType:tMesure withOptionalName:[self roiNameForType:Transform_ROI_Placed] ofROIMirrorType:Transform_ROI_Placed];
                [self pasteROIsForViewerController:self.viewerCT ofType:tMesure withOptionalName:[self roiNameForType:Transform_ROI_Placed] ofROIMirrorType:Transform_ROI_Placed];
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
            case Transform_ROI_Placed:
                [self copyROIsFromViewerController:self.viewerCT ofType:tMesure withOptionalName:[self roiNameForType:Transform_ROI_Placed] ofROIMirrorType:Transform_ROI_Placed];
                [self pasteROIsForViewerController:self.viewerPET ofType:tMesure withOptionalName:[self roiNameForType:Transform_ROI_Placed] ofROIMirrorType:Transform_ROI_Placed];
                break;
            default:
                break;
        }
    }
}

-(void)burnActiveAndMirrorROIsIntoCTViewer {
    //create a dummy roi just for the name
    [self.viewerPET revertSeries:nil];
    
    ROI *aROI = [self.viewerPET newROI:tPlain];
    aROI.name = [self roiNameForType:Mirrored_ROI];
    //roiSetPixels:(ROI*)aROI :(short)allRois :(BOOL)propagateIn4D :(BOOL)outside :(float)minValue :(float)maxValue :(float)newValue;
    [self.viewerPET roiSetPixels: aROI :SetPixels_SameName :NO :NO :-FLT_MAX :FLT_MAX :FLT_MAX :YES];
    aROI.name = [self roiNameForType:Active_ROI];
    [self.viewerPET roiSetPixels: aROI :SetPixels_SameName :NO :NO :-FLT_MAX :FLT_MAX :FLT_MAX :YES];
    [self.viewerPET needsDisplayUpdate];
    [self.viewerCT needsDisplayUpdate];
    
}


-(IBAction)buttonAction:(NSButton *)sender {
    //Transform Front
    if ([sender.identifier isEqualToString:@"pasteTransformFront"]) {
        [self pasteROIsForViewerController:[ViewerController frontMostDisplayed2DViewer] ofType:tMesure withOptionalName:[self roiNameForType:Transform_ROI_Placed] ofROIMirrorType:Transform_ROI_Placed];
    }
    else  if ([sender.identifier isEqualToString:@"copyTransformFront"]) {
        [self copyROIsFromViewerController:[ViewerController frontMostDisplayed2DViewer] ofType:tMesure withOptionalName:[self roiNameForType:Transform_ROI_Placed] ofROIMirrorType:Transform_ROI_Placed];
    }
    else  if ([sender.identifier isEqualToString:@"deleteTransformFront"]) {
        [self deleteROIsFromViewerController:[ViewerController frontMostDisplayed2DViewer] ofType:tMesure withOptionalName:[self roiNameForType:Transform_ROI_Placed]];
    }
    else  if ([sender.identifier isEqualToString:@"hideTransformFront"]) {
        [self doShowHideTransformMarkersForViewerController:[ViewerController frontMostDisplayed2DViewer]];
    }
    // Transform CT window
    else  if ([sender.identifier isEqualToString:@"deleteTransformCT"]) {
        [self deleteROIsFromViewerController:self.viewerCT ofType:tMesure withOptionalName:[self roiNameForType:Transform_ROI_Placed]];
    }
    else  if ([sender.identifier isEqualToString:@"hideTransformCT"]) {
        [self doShowHideTransformMarkersForViewerController:self.viewerCT];
    }
}

- (IBAction)deleteActiveViewerPolygonROIsOfType:(NSButton *)sender {
    switch (sender.tag) {
        case Mirrored_ROI:
            [self deleteROIsFromViewerController:[ViewerController frontMostDisplayed2DViewer] ofType:tCPolygon withOptionalName:[self roiNameForType:Mirrored_ROI]];
            break;
        case Active_ROI:
            [self deleteROIsFromViewerController:[ViewerController frontMostDisplayed2DViewer] ofType:tCPolygon withOptionalName:[self roiNameForType:Active_ROI]];
            break;
            
        default:
            break;
    }
}
- (IBAction)pasteActiveViewerROIsOfType:(NSButton *)sender {
    switch (sender.tag) {
        case Mirrored_ROI:
            [self pasteROIsForViewerController:[ViewerController frontMostDisplayed2DViewer] ofType:tPlain withOptionalName:[self roiNameForType:Mirrored_ROI] ofROIMirrorType:Mirrored_ROI];
            break;
        case Active_ROI:
            [self pasteROIsForViewerController:[ViewerController frontMostDisplayed2DViewer] ofType:tPlain withOptionalName:[self roiNameForType:Active_ROI] ofROIMirrorType:Active_ROI];
            break;
            
        default:
            break;
    }
}
- (IBAction)copyActiveViewerROIsOfType:(NSButton *)sender {
    switch (sender.tag) {
        case Mirrored_ROI:
            [self copyROIsFromViewerController:[ViewerController frontMostDisplayed2DViewer] ofType:tPlain withOptionalName:[self roiNameForType:Mirrored_ROI] ofROIMirrorType:Mirrored_ROI];
            break;
        case Active_ROI:
            [self copyROIsFromViewerController:[ViewerController frontMostDisplayed2DViewer] ofType:tPlain withOptionalName:[self roiNameForType:Active_ROI] ofROIMirrorType:Active_ROI];
            break;
            
        default:
            break;
    }
}




- (void)copyROIsFromViewerController:(ViewerController *)active2Dwindow ofType:(int)type withOptionalName:(NSString *)name ofROIMirrorType:(ROI_Type)roiMirrorType
{
    NSMutableArray *scratchArray = [self arrayOfROIsFromViewerController:active2Dwindow ofType:type withOptionalName:name ofROIMirrorType:roiMirrorType];
    
    switch (roiMirrorType) {
        case Mirrored_ROI:
            self.arrayMirrorROIsCopied  = [NSMutableArray arrayWithArray:scratchArray];
            break;
        case Transform_ROI_Placed:
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
            ROIname = [self roiNameForType:Mirrored_ROI];
            break;
        case Active_ROI:
            ROIname = [self roiNameForType:Active_ROI];
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
            ROIname = [self roiNameForType:Mirrored_ROI];
            break;
        case Active_ROI:
            ROIname = [self roiNameForType:Active_ROI];
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
        case Transform_ROI_Placed:
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

-(void)doShowHideTransformMarkersForViewerController:(ViewerController *)active2Dwindow
{
    //ViewerController	*active2Dwindow = [ViewerController frontMostDisplayed2DViewer];
    NSMutableArray  *roisInAllSlices  = [active2Dwindow roiList];
    for (NSUInteger slice=0; slice<roisInAllSlices.count; slice++) {
        NSMutableArray *roisInThisSlice = [roisInAllSlices objectAtIndex:slice];
        ROI *ROI2showHide = [MirrorROIPluginFilterOC roiFromList:roisInThisSlice WithType:tMesure];
        if (ROI2showHide != nil) {
            ROI2showHide.hidden = !ROI2showHide.hidden;
        }
    }
}

+ (NSInteger)indexOfFirstROIInFromViewerController:(ViewerController *)active2Dwindow atSlice:(NSUInteger)slice withName:(NSString *)name {
    if (slice<active2Dwindow.roiList.count) {
        for (NSInteger i=0; i<[[active2Dwindow.roiList objectAtIndex:slice] count];i++) {
            ROI *roi = [[active2Dwindow.roiList objectAtIndex:slice] objectAtIndex:i];
            if ([roi.name isEqualToString:name]) {
                return i;
            }
        }
    }
    return NSNotFound;
}

