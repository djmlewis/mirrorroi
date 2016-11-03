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
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification), name: NSNotification.Name.OsirixCloseViewer, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification), name: NSNotification.Name.OsirixViewerControllerDidLoadImages, object: nil)

        
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
            if let vc = self.viewerControllersList()[i] as? ViewerController {
                //modality is a function
                if let mode = vc.modality() {
                    switch mode {
                    case "CT":
                        notfoundCT = false
                        self.assignViewerWindow(viewController: vc, type: .CT_Window)
                    case "PT":
                        notfoundPET = false
                        self.assignViewerWindow(viewController: vc, type: .PET_Window)
                    default:
                        break
                    }
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
        print(sender);
    }

     @IBAction func smartAssignCTPETwindowsClicked(_ sender: NSButton) {
        print(sender);

    }

     @IBAction func growRegionClicked(_ sender: NSButton) {
        print(sender);

    }
    
     @IBAction func addTransformROIs(_ sender: NSButton) {
        print(sender);

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



