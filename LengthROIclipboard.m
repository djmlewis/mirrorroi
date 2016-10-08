//
//  LengthROIclipboard.m
//  MirrorROIPlugin
//
//  Created by David Lewis on 06/10/2016.
//
//
#import "MirrorROIPluginFilterOC.h"
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

+(LengthROIclipboard *)lengthROIclipboardForSlices:(NSUInteger)numberOfSlices
{
    LengthROIclipboard *lengthROIclipboard = [[LengthROIclipboard alloc] init];
    [lengthROIclipboard setupForNumberOfSlices:numberOfSlices];
    return lengthROIclipboard;
}

-(void)setupForNumberOfSlices:(NSUInteger)numberOfSlices {
    self.numberOfSlices = numberOfSlices;
    self.roiSliceIndices = [NSMutableArray arrayWithCapacity:numberOfSlices];
    self.roiPoints = [NSMutableArray arrayWithCapacity:numberOfSlices];
    self.roiNames = [NSMutableArray arrayWithCapacity:numberOfSlices];
}

-(void)addLengthROI:(ROI *)roi atIndex:(NSUInteger)index forOrigin:(NSPoint)origin{
    if (roi != nil) {
        NSMutableArray *copiedPoints = [NSMutableArray arrayWithCapacity:2];
        for (NSUInteger p=0; p<roi.points.count; p++) {
            NSPoint nsp = [(MyPoint *)[roi.points objectAtIndex:p] point];
            nsp.x = nsp.x-origin.x;
            nsp.y = nsp.y-origin.y;
            MyPoint *point = [MyPoint point:nsp];
            [copiedPoints addObject:point];
        }
        [self.roiPoints addObject:copiedPoints];
        [self.roiSliceIndices addObject:[NSNumber numberWithUnsignedInteger:index]];
        [self.roiNames addObject:roi.name];
    }
}

-(void)copyLengthROIsForViewerController:(ViewerController *)active2DView {
    NSMutableArray  *roisInAllSlices  = [active2DView roiList];
    for (NSUInteger slice=0; slice<roisInAllSlices.count; slice++) {
        DCMPix *pix = [[active2DView pixList] objectAtIndex:slice];
        //NSLog(@"oX: %f  oY:%f", pix.originX, pix.originY);

        [self addLengthROI:[MirrorROIPluginFilterOC roiFromList:[roisInAllSlices objectAtIndex:slice] WithType:tMesure] atIndex:slice forOrigin:(NSPoint)NSMakePoint(pix.originX, pix.originY)] ;
    }
}

-(void)pasteROIsInViewerController:(ViewerController *)active2Dview{
    //if the array size is unequal weve strayed from our windows fused
    if (self.numberOfSlices == [[active2Dview roiList] count]) {
        for (NSUInteger index = 0; index<self.roiSliceIndices.count; index++) {
            DCMPix *pix = [[active2Dview pixList] objectAtIndex:index];
            NSPoint origin = (NSPoint)NSMakePoint(pix.originX, pix.originY);
            
            ROI *newRoi = [active2Dview newROI:tMesure];
            newRoi.points = [self.roiPoints objectAtIndex:index];
            for (NSUInteger p=0; p<newRoi.points.count; p++) {
                MyPoint *mpoint = (MyPoint *)[newRoi.points objectAtIndex:p];
                NSPoint nsp = mpoint.point;
                nsp.x = nsp.x+origin.x;
                nsp.y = nsp.y+origin.y;
                [newRoi.points replaceObjectAtIndex:p withObject:[MyPoint point:nsp]];
            }

            newRoi.name = [self.roiNames objectAtIndex:index];
            NSUInteger viewerSliceIndex = [[self.roiSliceIndices objectAtIndex:index] unsignedIntegerValue];
            [[[active2Dview roiList] objectAtIndex:viewerSliceIndex] addObject:newRoi];
        }
    }
    [active2Dview needsDisplayUpdate];
}

@end
