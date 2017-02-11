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
    return [roi.name isEqualToString:[self ROInameForType:Active_ROI]] || [roi.name isEqualToString:[self ROInameForType:Mirrored_ROI]] || [roi.name isEqualToString:[self ROInameForType:Transform_ROI_Placed]];
}

-(NSString *)dataStringFor2DpixelDataForROIType:(ROI_Type)type {
    NSMutableDictionary *dictOfRoiGrids = [self dictOfrawPixelsDelta_make2DarrayWithPixelsFromROIsForType:type];
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
                    [self stringForDataArray:[dict objectForKey:kDeltaNameActivePixFlatAndNotMirrored] forceTranspose:NO],
                    kDeltaNameMirroredPixFlatAndMirroredInRows,
                    [self stringForDataArray:[dict objectForKey:kDeltaNameMirroredPixFlatAndMirroredInRows] forceTranspose:NO],
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
            if ([self userDefaultBoolForKey:kCombinePixelsWithStatsInFileDefault] == YES)
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
            if ([self userDefaultBoolForKey:kCombinePixelsWithStatsInFileDefault] == YES)
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
    return [NSString stringWithFormat:@"%@\n%@\n\n%@\n%@",[self ROInameForType:Active_ROI],dataStringA,[self ROInameForType:Mirrored_ROI],dataStringM];
}

-(NSMutableArray *)dataValuesArrayFromROIsOfType:(ROI_Type)type addHeader:(BOOL)addHeader{
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




-(NSString *)dataStringFromDataValuesArrayFromROIsOfType:(ROI_Type)type {
    NSMutableArray *arrayOfRows = [self dataValuesArrayFromROIsOfType:type addHeader:YES];
    if (arrayOfRows.count>0) {
        return [self stringForDataArray:arrayOfRows forceTranspose:NO];
    }
    return nil;
}



