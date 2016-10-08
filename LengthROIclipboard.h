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
//rois array is an array of rois per image arrays forA series in a VeiwerController. 4D movies are ignored
@property (nonatomic, retain) NSMutableArray *roisArray;
@property (nonatomic, retain) NSMutableArray *roiSliceIndices;
@property (nonatomic, retain) NSMutableArray *roiNames;


+(LengthROIclipboard *)lengthROIclipboardForSlices:(NSUInteger)numberOfSlices;
-(void)setupForNumberOfSlices:(NSUInteger)numberOfSlices;
-(void)addLengthROI:(ROI *)roi atIndex:(NSUInteger)index;
-(void)pasteROIsInViewerController:(ViewerController *)active2Dview;
-(void)copyLengthROIsForViewerController:(ViewerController *)active2DView;


@end
