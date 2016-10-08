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


+(LengthROIclipboard *)lengthROIclipboardForSlices:(NSUInteger)numberOfSlices;
-(void)setupForNumberOfSlices:(NSUInteger)numberOfSlices;
-(void)addLengthROI:(ROI *)roi atIndex:(NSUInteger)index;
-(void)pasteROIsInViewerController:(ViewerController *)active2Dview;
-(void)copyLengthROIsForViewerController:(ViewerController *)active2DView;


@end
