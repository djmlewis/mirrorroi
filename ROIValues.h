//
//  ROIValues.h
//  MirrorROIPlugin
//
//  Created by David Lewis on 14/11/2016.
//
//

#import <Foundation/Foundation.h>
#import <OsiriXAPI/ROI.h>

@interface ROIValues : NSObject

@property (retain) NSNumber *mean;
@property (retain) NSNumber *meanfloor;
@property (retain) NSNumber *sdev;
@property (retain) NSNumber *min;
@property (retain) NSNumber *max;
@property (retain) NSNumber *range;
@property (retain) NSNumber *median;
@property (retain) NSNumber *medianfloor;
@property (retain) NSNumber *distance;
@property (retain) NSNumber *rank;
@property (retain) ROI *roi;
@property NSPoint location;

//-(NSComparisonResult)compare:(ROIValues *)otherROIValues;
-(id)initWithMean:(float)mean sdev:(float)sdev max:(float)max min:(float)min range:(float)range median:(float)median location:(NSPoint)location roi:(ROI *)roi;
//+(id)roiValuesWithMean:(float)mean sdev:(float)sdev max:(float)max min:(float)min range:(float)range median:(float)median location:(NSPoint)location comparator:(ROI *)comparator;
-(void)incrementRankWithIndex:(NSInteger)index;

+(id)roiValuesWithComparatorROI:(ROI *)comparator andJiggleROI:(ROI *)jiggleROI location:(NSPoint)location;
+(float)midRangeForMin:(float)min andMax:(float)max;


@end
