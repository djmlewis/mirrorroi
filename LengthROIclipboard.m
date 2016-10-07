//
//  LengthROIclipboard.m
//  MirrorROIPlugin
//
//  Created by David Lewis on 06/10/2016.
//
//

#import "LengthROIclipboard.h"

@implementation LengthROIclipboard
-(LengthROIclipboard *)init {
    self = [super init];
    if (self != nil) {
        self.numberOfSlices = 0;
        self.roiPoints = [NSMutableArray array];
        self.roiSliceIndices = [NSMutableArray array];
        self.roiNames = [NSMutableArray array];
    }
    return self;
}

-(void)setupForNumberOfSlices:(NSUInteger)numberOfSlices {
    self.numberOfSlices = numberOfSlices;
    self.roiSliceIndices = [NSMutableArray arrayWithCapacity:numberOfSlices];
    self.roiPoints = [NSMutableArray arrayWithCapacity:numberOfSlices];
    self.roiNames = [NSMutableArray arrayWithCapacity:numberOfSlices];
}

-(void)addLengthROI:(ROI *)roi atIndex:(NSUInteger)index {
    if (roi != nil) {
        [self.roiPoints addObject:roi.points];
        [self.roiSliceIndices addObject:[NSNumber numberWithUnsignedInteger:index]];
        [self.roiNames addObject:roi.name];
    }
}

-(void)addROIstoViewerController:(ViewerController *)active2Dview{
    //if the array size is unequal weve strayed from our windows fused
    NSMutableArray *roisInViewer = [active2Dview roiList];
    if (self.numberOfSlices == [[active2Dview roiList] count]) {
        for (NSUInteger index = 0; index<self.roiSliceIndices.count; index++) {
            ROI *newRoi = [active2Dview newROI:tMesure];
            newRoi.points = [self.roiPoints objectAtIndex:index];
            newRoi.name = [self.roiNames objectAtIndex:index];
            [newRoi recompute ];
            NSUInteger viewerSliceIndex = [[self.roiSliceIndices objectAtIndex:index] unsignedIntegerValue];
            [[[active2Dview roiList] objectAtIndex:viewerSliceIndex] addObject:newRoi];
        }
    }
}

@end
