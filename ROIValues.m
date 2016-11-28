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
    return [self initWithMean:0.0 sdev:0.0 max:0.0 min:0.0 range:0.0 midrange:0.0 median:0.0 location:NSZeroPoint roi:nil];
}

-(id)initWithMean:(float)mean sdev:(float)sdev max:(float)max min:(float)min range:(float)range midrange:(float)midrange median:(float)median location:(NSPoint)location roi:(ROI *)roi{
    if (self = [super init]) {
        self.mean = [NSNumber numberWithFloat:mean];
        self.meanfloor = [NSNumber numberWithFloat:floorf(mean)];
        self.sdev = [NSNumber numberWithFloat:sdev];
        self.sdevfloor = [NSNumber numberWithFloat:floorf(sdev)];
        self.max = [NSNumber numberWithFloat:max];
        self.min = [NSNumber numberWithFloat:min];
        self.range = [NSNumber numberWithFloat:range];
        self.midrange = [NSNumber numberWithFloat:midrange];
        self.median = [NSNumber numberWithFloat:median];
        self.distance = [NSNumber numberWithFloat:(fabs(location.x)+fabs(location.y))];//fmaxf
        self.location = location;
        self.rank = [NSNumber numberWithInteger:0];

        //NSLog(@"%f -- %f - %f",[self.distance floatValue], self.location.x, self.location.y);
        self.roi = roi;
    }
    return self;
}

+(id)roiValuesWithComparatorROI:(ROI *)comparator andJiggleROI:(ROI *)jiggleROI location:(NSPoint)location{
    return [[ROIValues alloc] initWithMean:fabsf(comparator.mean-jiggleROI.mean)
                                      sdev:fabsf(comparator.dev-jiggleROI.dev)
                                       max:fabsf(comparator.max-jiggleROI.max)
                                       min:fabsf(comparator.min-jiggleROI.min)
                                     range:fabsf(comparator.max-comparator.min-jiggleROI.max-jiggleROI.min)
                                     midrange:fabsf([ROIValues midRangeForMin:comparator.min andMax:comparator.max]-[ROIValues midRangeForMin:jiggleROI.min andMax:jiggleROI.max])
                                    median:fabsf([ROIValues medianForROI:comparator]-[ROIValues medianForROI:jiggleROI])
                                  location:location
                                       roi:jiggleROI];
}

-(void)incrementRankWithValue:(NSInteger)index {
    self.rank = [NSNumber numberWithInteger:index+[self.rank integerValue]];
}

+(float)midRangeForMin:(float)min andMax:(float)max {
    return min+((max-min)/2.0f);
}

+(float)medianForROI:(ROI *)roi {
    float median = 0;
    NSArray *roivals = [[roi dataValues] sortedArrayUsingSelector:@selector(compare:)];
    if (roivals.count==0) {
        median = 0;
    }
    else if (roivals.count == 1){
        median = [[roivals firstObject] floatValue];
    }
    else if (roivals.count % 2) {
        //odd
        median =  [[roivals objectAtIndex:(roivals.count-1)/2] floatValue];
    }
    else {
        //even
        NSUInteger upper = roivals.count/2;
        NSUInteger lower = (roivals.count/2)-1;
        float upV = [[roivals objectAtIndex:upper] floatValue];
        float loV = [[roivals objectAtIndex:lower] floatValue];
        median = (upV+loV)/2.0f;
    }
    //NSLog(@"%@",roivals);
    //NSLog(@"%f",median);
    return median;
}

//-(NSComparisonResult)compare:(ROIValues *)otherROIValues {
//    return [self.mean compare:otherROIValues.mean];
//}



@end
