//
//  LengthROIclipboard.h
//  MirrorROIPlugin
//
//  Created by David Lewis on 06/10/2016.
//
//

#import <Foundation/Foundation.h>
#import <OsiriXAPI/PluginFilter.h>

@interface LengthROIclipboard : NSObject
@property NSUInteger numberOfSlices;
@property (nonatomic, retain) NSMutableArray *roiPoints;
@property (nonatomic, retain) NSMutableArray *roiSliceIndices;
@property (nonatomic, retain) NSMutableArray *roiNames;


-(void)setupForNumberOfSlices:(NSUInteger)numberOfSlices;
-(void)addLengthROI:(ROI *)roi atIndex:(NSUInteger)index;
-(void)addROIstoViewerController:(ViewerController *)active2Dview;


@end
