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
    return [self initWithMean:0.0 sdev:0.0 max:0.0 min:0.0 range:0.0 median:0.0 location:NSZeroPoint];
}

-(id)initWithMean:(float)mean sdev:(float)sdev max:(float)max min:(float)min range:(float)range median:(float)median location:(NSPoint)location {
    if (self = [super init]) {
        self.mean = [NSNumber numberWithFloat:mean];
        self.sdev = [NSNumber numberWithFloat:sdev];
        self.max = [NSNumber numberWithFloat:max];
        self.min = [NSNumber numberWithFloat:min];
        self.range = [NSNumber numberWithFloat:range];
        self.median = [NSNumber numberWithFloat:median];
        self.location = [NSValue valueWithPoint:location];
    }
    return self;
}

+(id)roiValuesWithMean:(float)mean sdev:(float)sdev max:(float)max min:(float)min range:(float)range median:(float)median location:(NSPoint)location{
    return [[ROIValues alloc] initWithMean:mean sdev:sdev max:max min:min  range:range median:median location:location];
}

@end
