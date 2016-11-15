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
@property (retain) NSNumber *sdev;
@property (retain) NSNumber *min;
@property (retain) NSNumber *max;
@property (retain) NSNumber *range;
@property (retain) NSNumber *median;
@property (retain) ROI *roi;

-(NSComparisonResult)compare:(ROIValues *)otherROIValues;
-(id)initWithMean:(float)mean sdev:(float)sdev max:(float)max min:(float)min range:(float)range median:(float)median roi:(ROI *)roi;
//+(id)roiValuesWithMean:(float)mean sdev:(float)sdev max:(float)max min:(float)min range:(float)range median:(float)median location:(NSPoint)location comparator:(ROI *)comparator;
+(id)roiValuesWithComparatorROI:(ROI *)comparator andJiggleROI:(ROI *)jiggleROI;



@end
