//
//  ROIValues.h
//  MirrorROIPlugin
//
//  Created by David Lewis on 14/11/2016.
//
//

#import <Foundation/Foundation.h>

@interface ROIValues : NSObject

@property (retain) NSNumber *mean;
@property (retain) NSNumber *sdev;
@property (retain) NSNumber *min;
@property (retain) NSNumber *max;
@property (retain) NSNumber *range;
@property (retain) NSNumber *median;
@property (retain) NSValue *location;

-(id)initWithMean:(float)mean sdev:(float)sdev max:(float)max min:(float)min range:(float)range median:(float)median location:(NSPoint)location;
+(id)roiValuesWithMean:(float)mean sdev:(float)sdev max:(float)max min:(float)min range:(float)range median:(float)median location:(NSPoint)location;


@end
