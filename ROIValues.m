//
//  ROIValues.m
//  MirrorROIPlugin
//
//  Created by David Lewis on 14/11/2016.
//
//

#import "ROIValues.h"

@implementation ROIValues

-(id)init {
    return [self initWithMean:0.0 sdev:0.0 max:0.0 min:0.0 range:0.0 median:0.0 location:NSZeroPoint roi:nil];
}

-(id)initWithMean:(float)mean sdev:(float)sdev max:(float)max min:(float)min range:(float)range median:(float)median location:(NSPoint)location roi:(ROI *)roi{
    if (self = [super init]) {
        self.mean = [NSNumber numberWithFloat:mean];
        self.meanfloor = [NSNumber numberWithFloat:floorf(mean)];
        self.sdev = [NSNumber numberWithFloat:sdev];
        self.max = [NSNumber numberWithFloat:max];
        self.min = [NSNumber numberWithFloat:min];
        self.range = [NSNumber numberWithFloat:range];
        self.median = [NSNumber numberWithFloat:median];
        self.medianfloor = [NSNumber numberWithFloat:floorf(median)];
        self.distance = [NSNumber numberWithFloat:fabs(location.x)+fabs(location.y)];
        self.location = location;
        self.roi = roi;
    }
    return self;
}

//+(id)roiValuesWithMean:(float)mean sdev:(float)sdev max:(float)max min:(float)min range:(float)range median:(float)median location:(NSPoint)location comparator:(ROI *)comparator {
//    return [[ROIValues alloc] initWithMean:fabsf(comparator.mean-mean)
//                                      sdev:fabsf(comparator.dev-sdev)
//                                       max:fabsf(comparator.max-max)
//                                       min:fabsf(comparator.min-min)
//                                     range:fabsf(comparator.max-comparator.min-max-min)
//                                    median:fabsf(((comparator.max-comparator.min)/2.0f)-((max-min)/2.0f))
//                                  location:location];
//}

+(id)roiValuesWithComparatorROI:(ROI *)comparator andJiggleROI:(ROI *)jiggleROI location:(NSPoint)location{
    return [[ROIValues alloc] initWithMean:fabsf(comparator.mean-jiggleROI.mean)
                                      sdev:fabsf(comparator.dev-jiggleROI.dev)
                                       max:fabsf(comparator.max-jiggleROI.max)
                                       min:fabsf(comparator.min-jiggleROI.min)
                                     range:fabsf(comparator.max-comparator.min-jiggleROI.max-jiggleROI.min)
                                    median:fabsf(((comparator.max-comparator.min)/2.0f)-((jiggleROI.max-jiggleROI.min)/2.0f))
                                  location:location
                                       roi:jiggleROI];
}



-(NSComparisonResult)compare:(ROIValues *)otherROIValues {
    return [self.mean compare:otherROIValues.mean];
}



@end
