//
//  MirrorROISwift.swift
//  MirrorROIPlugin
//
//  Created by David JM Lewis on 02/11/2016.
//
//

import Cocoa

enum ViewerWindowType: Int {
    case CT_Window = 1
    case PET_Window = 2
    case CTandPET_Windows = 3
    case NoType_Defined = 4
    case Front_Window = 5
}



public class MirrorROISwift: PluginFilter {
    
    @IBOutlet var panelTop: NSPanel! //a strong reference is needed to ensure the window is not dismissed after the call
    @IBOutlet weak var labelPET: NSTextField!
    @IBOutlet weak var labelCT: NSTextField!
    @IBOutlet weak var  viewTools:NSView!
    @IBOutlet weak var  sliderMovevalue:NSSlider!
    @IBOutlet weak var  textLengthROIname:NSTextField!
    @IBOutlet weak var  textMirrorROIname:NSTextField!
    @IBOutlet weak var  textActiveROIname:NSTextField!
    @IBOutlet weak var  segmentExtendSingleLengthHow:NSSegmentedControl!

    var viewerCT:ViewerController? = nil
    var viewerPET:ViewerController? = nil
    
    
    public override func initPlugin() {
        
    }
    
    public override func filterImage(_ menuName: String!) -> Int {
        //essential use this with OWNER specified so it looks in OUR bundle for resource.
        let windowController = NSWindowController(windowNibName: "MirrorWindow", owner: self)
        windowController.showWindow(self)
        self.smartAssignCTPETwindows()
        if let activeName = UserDefaults().string(forKey: "growingRegionROIName") {
            self.textActiveROIname.stringValue = activeName
        }
        NotificationCenter.default.addObserver(self, selector: #selector(MirrorROISwift.handleNotification), name: NSNotification.Name.OsirixCloseViewer, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MirrorROISwift.handleNotification), name: NSNotification.Name.OsirixViewerControllerDidLoadImages, object: nil)

        
        return 0
    }
    
    
    func handleNotification(notification: NSNotification) {
        if (notification.name == NSNotification.Name.OsirixViewerControllerDidLoadImages || notification.name == NSNotification.Name.OsirixCloseViewer) {
            self.smartAssignCTPETwindows()
        }
    }

    
    func smartAssignCTPETwindows() {
        var notfoundCT = true
        var notfoundPET = true
        var i = 0
        //clear the values
        self.assignViewerWindow(viewController: nil, type: .CTandPET_Windows)
        //try to find
        while (i<self.viewerControllersList().count && (notfoundCT || notfoundPET)) {
            if let modeString = (self.viewerControllersList()[i] as? ViewerController)?.modality() {
                //modality is a function
                switch modeString {
                case "CT":
                    notfoundCT = false
                    self.assignViewerWindow(viewController: (self.viewerControllersList()[i] as! ViewerController), type: .CT_Window)
                case "PT":
                    notfoundPET = false
                    self.assignViewerWindow(viewController: (self.viewerControllersList()[i] as! ViewerController), type: .PET_Window)
                default:
                    break
                }
            }
            i += 1;
        }
    }

    func assignViewerWindow(viewController: ViewerController?, type:ViewerWindowType) {
        switch type {
        case .CT_Window:
            self.viewerCT = viewController
            self.labelCT.stringValue = (viewController?.window?.title == nil) ? "Not Assigned" : viewController!.window!.title
        case .PET_Window:
            self.viewerPET = viewController
            self.labelPET.stringValue = (viewController?.window?.title == nil) ? "Not Assigned" : viewController!.window!.title
        case .CTandPET_Windows:
            self.viewerCT = viewController
            self.labelCT.stringValue = (viewController?.window?.title == nil) ? "Not Assigned" : viewController!.window!.title
           self.viewerPET = viewController
            self.labelPET.stringValue = (viewController?.window?.title == nil) ? "Not Assigned" : viewController!.window!.title
        default:
            break
        }
        self.showHideControlsIfViewersValid()
    }

    func showHideControlsIfViewersValid() {
        self.viewTools.isHidden = !self.validCTandPETwindows();
    }
    
    func validCTandPETwindows() -> Bool {
        return (self.valid2DViewer(viewer: self.viewerCT) && self.valid2DViewer(viewer: self.viewerPET))
    }
    func valid2DViewer(viewer:ViewerController?) -> Bool {
        if self.viewerControllersList().index(where: {($0 as! ViewerController) === viewer}) == nil || viewer == nil {return false}
        return true
    }
    

    
    
    
    
    
    
    
    
    
    
    
    public class func okDeltaPoint(delta2test:NSPoint) -> Bool {
        return delta2test.x != CGFloat.greatestFiniteMagnitude && delta2test.y != CGFloat.greatestFiniteMagnitude;
    }
    
    
    
    
     @IBAction func assignWindowClicked(_ sender: NSButton) {
        self.assignViewerWindow(viewController: ViewerController.frontMostDisplayed2DViewer(), type: ViewerWindowType(rawValue: sender.tag)!)
    }

     @IBAction func smartAssignCTPETwindowsClicked(_ sender: NSButton) {
        self.smartAssignCTPETwindows()

    }

     @IBAction func growRegionClicked(_ sender: NSButton) {
        self.viewerPET?.window?.makeKeyAndOrderFront(nil)
        NSApplication.shared().sendAction(Selector(("segmentationTest:")), to: self.viewerPET, from: self.viewerPET)
    }
    
     @IBAction func addTransformROIs(_ sender: NSButton) {
        self.addBoundingTransformROIS()
    }
    
    
    
    func addBoundingTransformROIS() {
        guard let viewCT = self.viewerCT, let viewPET = self.viewerPET else {
                return
        }
        viewCT.setROIToolTag(tMesure)
        viewCT.deleteSeriesROIwithName(self.textLengthROIname.stringValue)
        
        //find the first and last pixIndex with an ACTIVE ROI
        let indexesWithROI = NSMutableIndexSet()
        let activeROIname = self.textActiveROIname.stringValue
        for pixIndex in 0..<viewPET.pixList().count {
            let roiArray = (viewPET.roiList().object(at: pixIndex) as! NSMutableArray)
            for roiIndex in 0..<roiArray.count {
                let curROI = (roiArray.object(at: roiIndex) as! ROI)
                if (curROI.name == activeROIname)
                {
                    indexesWithROI.add(pixIndex)
                    break;
                }
            }
        }
        
        if (indexesWithROI.count==1) {
            self.addLengthROIWithStart(startPoint: self.pointForImageIndex(index: indexesWithROI.firstIndex, viewer: viewCT, start: true), endPoint: self.pointForImageIndex(index: indexesWithROI.firstIndex, viewer: viewCT, start: false), active2Dwindow: viewCT, index: indexesWithROI.firstIndex)
            self.displayImageInCTandPETviewersWithIndex(index: indexesWithROI.firstIndex)
        }
        else if(indexesWithROI.count>1) {
            self.addLengthROIWithStart(startPoint: self.pointForImageIndex(index: indexesWithROI.firstIndex, viewer: viewCT, start: true), endPoint: self.pointForImageIndex(index: indexesWithROI.firstIndex, viewer: viewCT, start: false), active2Dwindow: viewCT, index: indexesWithROI.firstIndex)
            self.addLengthROIWithStart(startPoint: self.pointForImageIndex(index: indexesWithROI.lastIndex, viewer: viewCT, start: true), endPoint: self.pointForImageIndex(index: indexesWithROI.lastIndex, viewer: viewCT, start: false), active2Dwindow: viewCT, index: indexesWithROI.lastIndex)
            self.displayImageInCTandPETviewersWithIndex(index: indexesWithROI.firstIndex)
        }
    }
    
    func displayImageInCTandPETviewersWithIndex(index:Int) {
        //do it in ImageView for correct order
        self.viewerPET?.imageView().setIndexWithReset(Int16(index), true)
        self.viewerCT?.imageView().setIndexWithReset(Int16(index), true)
        self.viewerPET?.needsDisplayUpdate()
        self.viewerCT?.needsDisplayUpdate()
    }

    
    func addLengthROIWithStart(startPoint:NSPoint, endPoint:NSPoint, active2Dwindow:ViewerController, index:Int) {

        guard let newR = active2Dwindow.newROI(Int(tMesure.rawValue)) else {
                return
            }
            newR.points.add(active2Dwindow.newPoint(Float(startPoint.x), Float(startPoint.y)))
            newR.points.add(active2Dwindow.newPoint(Float(endPoint.x), Float(endPoint.y)))
            //(active2Dwindow.roiList().object(at: index) as! NSMutableArray).add(newR)

    }

    
    func pointForImageIndex(index:Int, viewer:ViewerController, start:Bool)->NSPoint {
        var point = NSMakePoint(0.0, 0.0)
        var divisor:CGFloat = 0.3;//end
        if (start) { divisor = 0.6;}//start
        if (index < viewer.pixList().count) {
            let h:CGFloat = CGFloat((viewer.pixList()[index] as! DCMPix).pheight)
            let w:CGFloat = CGFloat((viewer.pixList()[index] as! DCMPix).pwidth)
            point.y = h/2.0
            point.x = w*divisor;
        }
        return point;
    }

    
    
    
    
    
    
    
     @IBAction func completeTransformSeries(_ sender: NSButton) {
        print(sender);

    }

     @IBAction func jumpToFirstLastTransform(_ sender: NSButton) {
        print(sender);

    }

     @IBAction func mirrorActiveROI3D(_ sender: NSButton) {
        print(sender);

    }
    
     @IBAction func moveMirrorROI(_ sender: NSButton) {
        print(sender);

    }

     @IBAction func deleteActiveViewerROIsOfType(_ sender: NSButton) {
        print(sender);

    }

    
    
    
    
    
    
    
}



