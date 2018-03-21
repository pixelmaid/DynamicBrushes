//
//  ViewController.swift
//  Palette-Knife
//
//  Created by JENNIFER MARY JACOBS on 5/4/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//

import UIKit
import SwiftyJSON


let behaviorMapper = BehaviorMapper()
let uiInput = UIInput();
//CONSTANTS:

let kBrightness =       1.0
let kSaturation =       0.45

let kPaletteHeight =	30
let kPaletteSize =	5
let kMinEraseInterval =	0.5

// Padding for margins
let kLeftMargin =	10.0
let kTopMargin =	10.0
let kRightMargin =      10.0
let pX = Float(1366)
let pY = Float(1024)
class DrawingViewController: UIViewController, UIGestureRecognizerDelegate,Requester{
    
    
    
    // MARK: Properties
    
    
    var layerContainerView:LayerContainerView!
    
    
    var behaviorManager: BehaviorManager?
    var currentCanvas: Canvas?
    
    let drawKey = NSUUID().uuidString
    let toolbarKey = NSUUID().uuidString
    let layerEventKey = NSUUID().uuidString
    let colorPickerKey = NSUUID().uuidString
    let fileEventKey = NSUUID().uuidString
    let behaviorEventKey = NSUUID().uuidString
    let programmingEventKey = NSUUID().uuidString
    let stylusManagerKey = NSUUID().uuidString

    let brushEventKey = NSUUID().uuidString
    let dataEventKey = NSUUID().uuidString
    let strokeGeneratedKey = NSUUID().uuidString
    let strokeRemovedKey = NSUUID().uuidString
    let exportKey = NSUUID().uuidString
    let backupKey = NSUUID().uuidString
    let saveEventKey = NSUUID().uuidString
    let loopEventKey = NSUUID().uuidString
    
    var toolbarController: ToolbarViewController?
    var layerPanelController: LayerPanelViewController?
    var behaviorPanelController: BehaviorPanelViewController?
    var recordingToolbarVC: RecordingToolbarVC?
    var recordingViewController:RecordingViewController?
    
    //TODO: properly initialize stylus
    var stylus:Stylus?
    
    var fileListController: SavedFilesPanelViewController?
    let targetSize = CGSize(width:CGFloat(pX),height:CGFloat(pY))
    var blockAlert:UIAlertController!
    private var loggedIn = false;
    //for checking if person is drawing
    var touchesDown:Bool = false;

    var colorPickerView: SwiftHSVColorPicker?
    override var prefersStatusBarHidden: Bool {
        return true
    }
    var drawInterval:Timer!
    
    //variables for setting backups
    var backupTimer:Timer!
    //var cancelBackupTimer:Timer!
    var backupInterval = 60*3; //set to backup every 5 min
    var cancelBackupInterval = 60*2; //set to cancel after 2 min

    var backupNeeded:Bool = false;
    
    var currentBehaviorName = ""
    var currentBehaviorFile = ""
    var startup = true;
    var router:Router?
    @IBOutlet weak var layerPanelContainerView: UIView!
    
    @IBOutlet weak var colorPickerContainerView: UIView!
    @IBOutlet weak var fileListContainerView: UIView!
    
    @IBOutlet weak var behaviorPanelContainerView: UIView!
    required init?(coder: NSCoder) {
        layerContainerView = LayerContainerView(width:pX,height:pY);
        recordingViewController = RecordingViewController();
        super.init(coder: coder);
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "toolbarSegue"){
            toolbarController = segue.destination as? ToolbarViewController;
            _ = toolbarController?.toolEvent.addHandler(target: self, handler: DrawingViewController.toolEventHandler, key: toolbarKey)
            
        }
        else if(segue.identifier == "layerPanelSegue"){
            layerPanelController = segue.destination as? LayerPanelViewController;
            _ = layerPanelController?.layerEvent.addHandler(target: self, handler: DrawingViewController.layerEventHandler, key: layerEventKey)
            
        }
        else if(segue.identifier == "colorPickerSegue"){
            colorPickerView = SwiftHSVColorPicker(frame: CGRect(x:10, y:20, width:300, height:400))
            segue.destination.view.addSubview(colorPickerView!)
            colorPickerView?.setViewColor(UIColor.red)
            _ = colorPickerView?.colorEvent.addHandler(target: self, handler: DrawingViewController.colorPickerEventHandler, key: colorPickerKey)
        }
            
        else if(segue.identifier == "fileListSegue"){
            fileListController = segue.destination as? SavedFilesPanelViewController;
            _ = fileListController?.fileEvent.addHandler(target: self, handler: DrawingViewController.fileEventHandler, key: fileEventKey)
        }
        
        else if(segue.identifier == "behaviorPanelSegue"){
            behaviorPanelController = segue.destination as? BehaviorPanelViewController;
            _ =  behaviorPanelController?.behaviorEvent.addHandler(target: self, handler: DrawingViewController.behaviorEventHandler, key: behaviorEventKey)
        }
        else if(segue.identifier == "recordingToolbarSegue"){
            recordingToolbarVC = segue.destination as? RecordingToolbarVC;
            _ =  recordingToolbarVC?.loopEvent.addHandler(target: self, handler: DrawingViewController.recordingEventHandler, key: loopEventKey)
        }
        else if(segue.identifier == "recordingViewControllerSegue"){
            recordingViewController = segue.destination as? RecordingViewController;
      }
        
    }
    
    func colorPickerEventHandler(data:(UIColor), key: String){
        toolbarController?.setColor(color:data);
        uiInput.setColor(color:data);
    }
    
    func stylusManagerEventHandler(data:(String,Any),key:String){
       switch(data.0){
            case "ERASE_REQUEST":
               
              //  _ = layerContainerView.activeLayer?.jotView.undo();
                layerContainerView.undoById(layerList:data.1 as! [String:[String]])
            break;
            case "REQUEST_CORRECT_LAYER":
                layerContainerView.selectActiveLayer(id:data.1 as! String);
            break;
            case "VIS_STROKE_DOWN":
            break;
            default:
            break;
        }

    }
    
    func toolEventHandler(data: (String), key: String){
        print("tool event handler",data)
        switch(data){
        case "UNDO":
            //layerContainerView.activeLayer!.undo();
            break;
        case "PROGRAMMING_VIEW_REQUEST":
            _ = Router.createProgrammingModule();
            break;
        case "VIEW_LOADED":
            toolbarController?.exportButton.addTarget(self, action: #selector(DrawingViewController.exportImage), for: .touchUpInside)
            toolbarController?.saveButton.addTarget(self, action: #selector(DrawingViewController.saveProject), for: .touchUpInside)
            break;
        case "ERASE_MODE":
            self.layerContainerView.removeAllStrokes()
            layerContainerView.toggleDrawActive();
            break;
        case "PEN_MODE":
            self.layerContainerView.removeAllStrokes()
            layerContainerView.setPenActive();
            break;
        case "AIRBRUSH_MODE":
            self.layerContainerView.removeAllStrokes()
            layerContainerView.setAirbrushActive();
            break;

            
        case "TOGGLE_LAYER_PANEL":
            if(layerPanelContainerView?.isHidden == true){
                layerPanelContainerView?.isHidden = false
            }
            else{
                layerPanelContainerView?.isHidden = true
            }
            colorPickerContainerView?.isHidden = true
            behaviorPanelContainerView?.isHidden = true

            
            break;
        case "TOGGLE_BEHAVIOR_PANEL":
            if(behaviorPanelContainerView?.isHidden == true){
                behaviorPanelContainerView?.isHidden = false
            }
            else{
                behaviorPanelContainerView?.isHidden = true
            }
            colorPickerContainerView?.isHidden = true
            layerPanelContainerView?.isHidden = true

            
            break;
        case "TOGGLE_FILE_PANEL":
           
            
           if(fileListContainerView?.isHidden == true){
                fileListContainerView?.isHidden = false
            }
            else{
                fileListContainerView?.isHidden = true
            }
           
            break;
        case "TOGGLE_COLOR_PANEL":
            if(colorPickerContainerView?.isHidden == true){
                colorPickerContainerView?.isHidden = false
            }
            else{
                colorPickerContainerView?.isHidden = true
            }
            layerPanelContainerView?.isHidden = true
            behaviorPanelContainerView?.isHidden = true

            
            break
        case "DIAMETER_CHANGED":
            uiInput.setDiameter(val: (toolbarController?.diameterSlider.value)!);
            break;
        case "ALPHA_CHANGED":
            uiInput.setAlpha(val: (toolbarController?.alphaSlider.value)!);
            break;
        default:
            break;
        }
    }
    
    
    
    func layerEventHandler(data: (String,String,String?), key: String){
        switch(data.0){
        case "LAYER_SELECTED":
            layerContainerView.selectActiveLayer(id:data.1);
            StylusManager.setLayerId(layerId: data.1)
            break;
        case "LAYER_ADDED":
            self.userInitLayer();
            break;
        case "SHOW_LAYER":
            layerContainerView.showLayer(id: data.1);
            break;
        case "HIDE_LAYER":
            layerContainerView.hideLayer(id: data.1);
            break;
        case "DELETE_LAYER":
            self.deleteAlert(layerName: data.2!, layerId: data.1)
            break;
        default:
            break;
        }
    }
    
    func behaviorEventHandler(data: (String,String,String?), key: String){
        switch(data.0){
        case "ACTIVATE_BEHAVIOR":
            var authoringData:JSON = [:]
            authoringData["type"] = JSON("set_behavior_active")
            authoringData["behaviorId"] = JSON(data.1)
            authoringData["active_status"] = JSON(true)
            var data:JSON = [:]
            data["data"] = authoringData
            do {
           try _ = behaviorManager?.handleAuthoringRequest(authoring_data: data)
                self.synchronizeWithAuthoringClient();

            }
            catch{
                #if DEBUG
                    print("error in authoring")
                #endif
            }
            break;
        case "DEACTIVATE_BEHAVIOR":
            var authoringData:JSON = [:]
            authoringData["type"] = JSON("set_behavior_active")
            authoringData["behaviorId"] = JSON(data.1)
            authoringData["active_status"] = JSON(false)
            var data:JSON = [:]
            data["data"] = authoringData
            do {
                try _ = behaviorManager?.handleAuthoringRequest(authoring_data: data)
                self.synchronizeWithAuthoringClient();

            }
            catch{
                #if DEBUG
                    print("error in authoring")
                #endif
            }
            
            break;
        case "REFRESH_BEHAVIOR":
            var authoringData:JSON = [:]
            authoringData["type"] = JSON("refresh_behavior")
            authoringData["behaviorId"] = JSON(data.1)
            var data:JSON = [:]
            data["data"] = authoringData
            do {
                try _ = behaviorManager?.handleAuthoringRequest(authoring_data: data)
            }
            catch{
                #if DEBUG
                    print("error in authoring")
                #endif
            }
            break;
        default:
            break;
        }
    }
    
    func fileEventHandler(data: (String,String,String?), key: String){
        switch(data.0){
        case "FILE_SELECTED":
            let artistName = UserDefaults.standard.string(forKey: "userkey")
            
            DispatchQueue.global(qos: .userInteractive).async {
                
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Loading", message: "Loading Project", preferredStyle: .alert)
                    
                    self.present(alert, animated: true, completion: { _ in }
                    )
                }
            }
            self.loadProject(projectName: data.2!, artistName: artistName!);
            break;
        default:
            break;
        }
    }

    
    func recordingEventHandler(data: (String), key: String){
        switch(data){
        case "LOOP":
            recordingViewController?.loopInitialized()
            break;
        default:
            break;
        }
    }
    
    func strokeGeneratedHandler(data:(String),key:String){
        StylusManager.addResultantStroke(layerId: layerContainerView.activeLayer!.id, strokeId: data)
        self.layerContainerView.addStroke(id:data);
    }
    
    func strokeRemovedHandler(data:([String]),key:String){
        self.layerContainerView.removeStroke(idList:data);
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        
        self.initInterface();

    }
    
    
    func initInterface(){
        self.initCanvas()
        
        
        _ = RequestHandler.dataEvent.addHandler(target: self, handler: DrawingViewController.processRequestHandler, key: dataEventKey)
        
        let configureRequest = Request(target: "storage", action: "configure", data:JSON([]), requester: self)
        
        RequestHandler.addRequest(requestData:configureRequest);
        
        layerContainerView.center = CGPoint(x:self.view.frame.size.width/2,y:self.view.frame.size.height/2);
        self.view.addSubview(layerContainerView);
        self.view.sendSubview(toBack: layerContainerView);
        
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(DrawingViewController.handlePinch))
        pinchRecognizer.delegate = self
        layerContainerView.addGestureRecognizer(pinchRecognizer)
        
        let rotateRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(DrawingViewController.handleRotate))
        rotateRecognizer.delegate = self
        layerContainerView.addGestureRecognizer(rotateRecognizer)
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(DrawingViewController.handlePan))
        panRecognizer.delegate = self
        panRecognizer.minimumNumberOfTouches = 2;
        layerContainerView.addGestureRecognizer(panRecognizer)
        
        layerPanelContainerView.layer.cornerRadius = 8.0
        layerPanelContainerView.clipsToBounds = true
        self.newLayer();
        self.newVisualizationLayer();

        layerPanelContainerView.isHidden = true;
        
        
        
        behaviorPanelContainerView.layer.cornerRadius = 8.0
        behaviorPanelContainerView.clipsToBounds = true
        behaviorPanelContainerView.isHidden = true;
        
        colorPickerContainerView.layer.cornerRadius = 8.0
        colorPickerContainerView.clipsToBounds = true
        
        colorPickerContainerView.isHidden = true;
        
        uiInput.setDiameter(val: (toolbarController?.diameterSlider.value)!);
        uiInput.setAlpha(val: (toolbarController?.alphaSlider.value)!);
        uiInput.setColor(color: (colorPickerView?.color)!)
        
        fileListContainerView.layer.cornerRadius = 8.0
        fileListContainerView.clipsToBounds = true
        fileListContainerView.isHidden = true;
        
        do {
            if let file = Bundle.main.url(forResource: "CollectionPresets", withExtension: "json") {
                let data = try Data(contentsOf: file)
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if json is [String: Any] {
                    // json is a dictionary
                    BehaviorManager.loadCollectionsFromJSON(data:JSON(data)["collections"])
                }  else {
                    print("JSON is invalid")
                }
            } else {
                print("no file")
            }
        } catch {
            print(error.localizedDescription)
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);
        print("logged in state",loggedIn)
        if(!loggedIn){
            self.loginAlert(isIncorrect: false);
        }

    }
    
    func addConnectionRequests(){
        let connectRequest = Request(target: "socket", action: "connect", data:JSON([]), requester: self)
        RequestHandler.addRequest(requestData:connectRequest);
       loggedIn = true;
      print("logged in state after connection",loggedIn)
    }
    
    func addProjectInitRequests(){
        
        
        var templateJSON:JSON = [:]
        templateJSON["filename"] = "templates/refactor_template.json"
        templateJSON["type"] = JSON("load")
        let behaviorDownloadRequest = Request(target: "storage", action: "download", data:templateJSON, requester: self)
        RequestHandler.addRequest(requestData:behaviorDownloadRequest);
        
        requestProjectList()
        
        drawInterval  = Timer.scheduledTimer(timeInterval:0.016 , target: self, selector: #selector(DrawingViewController.drawIntervalCallback), userInfo: nil, repeats: true)
        
        self.startBackupTimer(interval:self.backupInterval);
        

    }
    
    
    func requestProjectList(){
        let artistName = UserDefaults.standard.string(forKey: "userkey")
        var projectListJSON:JSON = [:]
        projectListJSON["list_type"] = JSON("project_list")
        projectListJSON["targetFolder"] = JSON("saved_files/"+artistName!+"/drawings/")
        let projectListRequest = Request(target: "storage", action:"filelist", data:projectListJSON, requester: self);
        RequestHandler.addRequest(requestData:projectListRequest);
        
    }
    
    func processProjectList(list:JSON){
        let list_dict = list.dictionaryValue
        var newFiles = [String:String]()
        for(key,value) in list_dict{
            if key.range(of: "data.json") != nil{
                newFiles[key] = value.stringValue;
            }
        }
        
        fileListController?.loadFiles(newFiles: newFiles)
        
    }
    
    func keyRecognized(){
        #if DEBUG
            print("key is recognized")
        #endif
        if(startup == true){
            self.addProjectInitRequests()
            startup = false;
        }
    }
    
    func loginAlert(isIncorrect:Bool) {
        let message:String
        if(!isIncorrect){
            message = "Enter your login key"
        }
        else{
            message = "That key was not recognized, please try again"
        }
        let alertController = UIAlertController(title: "Login", message: message, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { (_) in
            if let field = alertController.textFields?[0] {
                // store your data
                UserDefaults.standard.set(field.text, forKey: "userkey")
                UserDefaults.standard.synchronize()
                self.addConnectionRequests();
                
            } else {
                #if DEBUG
                    print("no login key provided");
                #endif
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addTextField { (textField) in
            textField.placeholder = ""
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func recconnectAlert(){
        print("reconnectAlert logged in",loggedIn)
        loggedIn = false;
        let alertController = UIAlertController(title:"Connection Issue", message: "You were disconnected from the server. Try to reconnect?", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { (_) in
            self.addConnectionRequests();
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    func deleteAlert(layerName:String, layerId:String){
        let alertController = UIAlertController(title:"Delete Layer", message: "Delete the layer \""+layerName+"\"?", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { (_) in
            let activeId = self.layerContainerView.deleteLayer(id: layerId)
            self.layerPanelController?.removeLayer(layerId: layerId)
            StylusManager.handleDeletedLayer(deletedId: layerId);
            if(activeId != nil){
                self.layerPanelController?.setActive(layerId:activeId!);
                StylusManager.setLayerId(layerId: activeId!)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    func saveFileToTempDir(data:NSData,filename:String,ext:String)->String{
        let fileManager = FileManager.default
        let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("\(filename).\(ext)")
       
        fileManager.createFile(atPath: path as String, contents: data as Data, attributes: nil)
        return path;
    }
    
    func uploadProject(type:String,filename:String){
       // if(type != "backup"){
        DispatchQueue.global(qos: .userInteractive).async {
           
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Saving", message: "Saving Project", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
                    self.cancelBackupCallback()
                
                }
                alert.addAction(cancelAction)

                self.present(alert, animated: true, completion: { _ in }
                )
            }
        }
       // }
        
        UserDefaults.standard.set(type, forKey: "save_type")
        UserDefaults.standard.set(filename, forKey: "save_filename")
        
        UserDefaults.standard.synchronize()
        
        _ = self.layerContainerView.saveEvent.addHandler(target: self, handler: DrawingViewController.uploadProjectHandler, key: saveEventKey)
        self.behaviorManager?.refreshAllBehaviors();
        //TODO: this is a hack. need to create a delay in case it's saving a stroke to the texture
        
            self.layerContainerView.save();
        

    }
    
    
    func uploadProjectHandler(data:(JSON,[String:String],[String:String],[String:[String]]),key:String){
        self.layerContainerView.saveEvent.removeAllHandlers();
        let type = UserDefaults.standard.string(forKey: "save_type")!
        let filename = UserDefaults.standard.string(forKey: "save_filename")!
        let prefix:String
        
        if(type == "backup"){
            prefix = "/drawing_backups/"
            
        }
        else{
            prefix = "/drawings/"
        }
        
        let save_json = data.0;
        let save_inks = data.1;
        let save_plists = data.2
        let save_strokes = data.3
        let artistName = UserDefaults.standard.string(forKey:"userkey");
        
        var uploadJSON:JSON = [:]
        uploadJSON["filename"] = JSON("saved_files/"+artistName!+prefix+filename+"/"+"data.json")
        uploadJSON["data"] = save_json
        uploadJSON["type"] = JSON("project_save")
        
        uploadJSON["targetFolder"] = JSON("saved_files/"+artistName!+prefix+filename+"/")
        
        let uploadRequest = Request(target: "storage", action: "upload", data:uploadJSON, requester: self)
        
        RequestHandler.addRequest(requestData:uploadRequest);
        
        for (key,val) in save_inks{
            if(val != "no_image"){
                var uploadData:JSON = [:]
                uploadData["content_type"] = JSON("image/png")
                 uploadData["save_type"] = JSON(type)
                uploadData["filename"] = JSON("saved_files/"+artistName!+prefix+filename+"/"+"ink_"+key+".png")
                uploadData["path"] = JSON(val)
                uploadData["targetFolder"] = JSON("saved_files/"+artistName!+prefix)
                let uploadRequest = Request(target: "storage", action: "upload_image", data:uploadData, requester: self)
                RequestHandler.addRequest(requestData:uploadRequest);
            }
            
        }
        
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        let documentDirectory = paths[0] as! String
        
        for (_, strokes) in save_strokes{
            for s in strokes{
            var uploadData:JSON = [:]
            uploadData["content_type"] = JSON("text/strokedata")
            uploadData["save_type"] = JSON(type)
            uploadData["filename"] = JSON("saved_files/"+artistName!+prefix+filename+"/"+s+".strokedata")
            let path = documentDirectory.appending("/"+s+".strokedata")
            uploadData["path"] = JSON(path)
                print("stroke data upload path",path);
            uploadData["targetFolder"] = JSON("saved_files/"+artistName!+prefix)
            let uploadRequest = Request(target: "storage", action: "upload_image", data:uploadData, requester: self)
            RequestHandler.addRequest(requestData:uploadRequest);
            }

        }
        var count = 0;
        
        for (key,val) in save_plists{
            count += 1
            var uploadData:JSON = [:]
            uploadData["content_type"] = JSON("text/plist")
            uploadData["save_type"] = JSON(type)
            uploadData["filename"] = JSON("saved_files/"+artistName!+prefix+filename+"/"+"state_"+key+".plist")
            uploadData["path"] = JSON(val)
            uploadData["targetFolder"] = JSON("saved_files/"+artistName!+prefix)
            if(count == save_plists.count){
                uploadData["isLast"] = JSON(true);
            }
            
            let uploadRequest = Request(target: "storage", action: "upload_image", data:uploadData, requester: self)
            RequestHandler.addRequest(requestData:uploadRequest);
            
            
        }
        self.requestProjectList()

    }
    
    func startBackupTimer(interval:Int){
        self.endBackupTimer();
        self.toolbarController?.enableSaveLoad();
        self.dismiss(animated: true, completion: nil)
        //self.endCancelTimer();
        backupTimer  = Timer.scheduledTimer(timeInterval:TimeInterval(interval), target: self, selector: #selector(DrawingViewController.backupCallback), userInfo: nil, repeats: true)

    }
    
    
    /*func startCancelBackupTimer(){
        cancelBackupTimer  = Timer.scheduledTimer(timeInterval:TimeInterval(cancelBackupInterval), target: self, selector: #selector(ViewController.cancelBackupCallback), userInfo: nil, repeats: true)
    }*/
    func endBackupTimer(){
        if(backupTimer != nil){
            backupTimer.invalidate();
        }
    }
    
    /*func endCancelTimer(){
        if(cancelBackupTimer != nil){
            cancelBackupTimer.invalidate();
        }
    }*/
    
    func backupProject(filename:String){
        self.uploadProject(type: "backup", filename: filename)
    }
    
    func saveProject(){
        endBackupTimer();
        let alertController = UIAlertController(title: "Save", message: "Enter a name for your project", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Save", style: .default) { (_) in
            if let field = alertController.textFields?[0] {
                self.uploadProject(type:"save", filename: field.text!)
                
                
            } else {
                #if DEBUG
                    print("no name key provided");
                #endif
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addTextField { (textField) in
            textField.placeholder = ""
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
        
        
    }
    
    func backupImage(){
        
        _ = self.layerContainerView.exportEvent.addHandler(target: self, handler: DrawingViewController.backupImageHandler, key: backupKey)
        self.layerContainerView.exportPNG();
    }
    
    func backupImageHandler(data:(String,UIImage?),key:String){
        layerContainerView.exportEvent.removeHandler(key: backupKey);
        if(data.0 == "COMPLETE"){
            let filename =  UserDefaults.standard.string(forKey: "backup_filename")!
            #if DEBUG
                print("backing up image to",filename)
            #endif
            
            let prefix = "/image_backups/";
            let artistName = UserDefaults.standard.string(forKey:"userkey");
            let png = UIImagePNGRepresentation(data.1!)
            let path = self.layerContainerView.exportPNGAsFile(image: png!)
            
            var uploadData:JSON = [:]
            uploadData["filename"] = JSON("saved_files/"+artistName!+prefix+filename+".png")
            uploadData["path"] = JSON(path)
            uploadData["isLast"] = JSON(true)
            uploadData["save_type"] = "backup"
            uploadData["content_type"] = "image/png"

            uploadData["targetFolder"] = JSON("saved_files/"+artistName!+"/")
            let uploadRequest = Request(target: "storage", action: "upload_image", data:uploadData, requester: self)
            RequestHandler.addRequest(requestData:uploadRequest);
        }
    }
    
    
    func exportImage(){
        self.endBackupTimer()
       _ = self.layerContainerView.exportEvent.addHandler(target: self, handler: DrawingViewController.handleExportRequest, key: exportKey)
        self.behaviorManager?.refreshAllBehaviors();
        //TODO: this is a hack. need to create a delay in case it's saving a stroke to the texture
        DispatchQueue.global(qos: .userInteractive).async {
            
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Saving", message: "Saving Image", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
                    self.cancelBackupCallback()
                    
                }
                alert.addAction(cancelAction)

                self.present(alert, animated: true, completion: { _ in }
                )
            }
        }
        
        
        self.layerContainerView.exportPNG();

        
    }
    
    func handleExportRequest(data:(String,UIImage?),key:String) {
        let contentToShare = data.1;
        #if DEBUG
            print("handle export request",contentToShare as Any)
        #endif
        layerContainerView.exportEvent.removeHandler(key: exportKey);
        if(contentToShare != nil){
            
         
            let pngImageData: Data? = UIImagePNGRepresentation(contentToShare!)
            let pngSmallImage = UIImage(data: pngImageData!)
            UIImageWriteToSavedPhotosAlbum(pngSmallImage!, self, nil, nil)
            let svg = (currentCanvas?.currentDrawing?.getSVG())! as NSString;
            print("svg=",svg);
            let svg_data = svg.data(using: String.Encoding.utf8.rawValue)!
            let activityViewController = UIActivityViewController(activityItems: [svg_data], applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
            
            
            // present the view controller
            self.present(activityViewController, animated: true, completion: nil)
            self.dismiss(animated: true, completion: nil)
            self.startBackupTimer(interval:self.backupInterval);
             /*DispatchQueue.global(qos: .userInteractive).async {
                
                 DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Saved", message: "Your image has been saved to the photo album", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    
                    self.present(alert, animated: true, completion: { _ in }
                    )
                }
            }*/
            
            /*let nsContent = NSData(data: contentToShare!)
            let activityViewController = UIActivityViewController(activityItems: [nsContent], applicationActivities: nil)
            // let activityViewController = UIActivityViewController(activityItems: [shareContent as NSString], applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = toolbarController?.exportButton
            present(activityViewController, animated: true, completion: {})*/
        }
        else{
            #if DEBUG
                print("cannot share image because nothing is there")
            #endif
        }
        
        
    }
    
    
    @objc func drawIntervalCallback(){
        DispatchQueue.global(qos: .userInteractive).async {
            #if DEBUG
                //print("draw interval callback called",self.currentCanvas!.dirty)
            #endif
            if(self.currentCanvas!.dirty){
                DispatchQueue.main.async {
                    self.layerContainerView.drawIntoCurrentLayer(currentCanvas:self.currentCanvas!);
                }
                self.backupNeeded = true;
                
            }
        }
    }
    
    
    @objc func cancelBackupCallback(){
        RequestHandler.emptyQueue()
        self.layerContainerView.saveEvent.removeAllHandlers();
        self.layerContainerView.exportEvent.removeAllHandlers();
        self.startBackupTimer(interval: self.backupInterval);
    }
    
    
    @objc func backupCallback(){
        #if DEBUG
            print("ready to export?",layerContainerView.isReadyToExport())
        #endif
        if(backupNeeded && layerContainerView.isReadyToExport() && !self.touchesDown){
            self.endBackupTimer();
           // self.startCancelBackupTimer();
            let alertController = UIAlertController(title:"Backup", message: "Backup project now?", preferredStyle: .alert)
            
            let confirmAction = UIAlertAction(title: "Yes", style: .default) { (_) in
           
            self.endBackupTimer()
            #if DEBUG
                print("begining backup")
            #endif
            self.toolbarController?.disableSaveLoad();
            let filename = String(Int((NSDate().timeIntervalSince1970)*100000));
            UserDefaults.standard.set(filename, forKey: "backup_filename")
            UserDefaults.standard.synchronize()
            
                self.behaviorManager?.refreshAllBehaviors();
            
                self.backupProject(filename:filename)
               
                
                
                self.backupNeeded = false;
            }
            
            let cancelAction = UIAlertAction(title: "Later", style: .cancel) { (_) in
        
                self.startBackupTimer(interval:60*5)
            
            }
            
            alertController.addAction(confirmAction)
            alertController.addAction(cancelAction)
            
            self.present(alertController, animated: true, completion: nil)

            
        }
        else if(backupNeeded){
            self.endBackupTimer();
            self.startBackupTimer(interval:1)
        }
    }
    
    
    
    func userInitLayer(){
        
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Layers", message: "Adding Layer", preferredStyle: .alert)
                
                self.present(alert, animated: true, completion: { _ in }
                )
            }
        

        let when = DispatchTime.now() + 1;
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.dismiss(animated: true, completion: nil)
            self.startBackupTimer(interval:self.backupInterval);
            self.newLayer();
        }
    }
    
    func newLayer(){
        endBackupTimer()
       
        self.behaviorManager?.refreshAllBehaviors();
        //TODO: this is a hack. need to create a delay in case it's saving a stroke to the texture
     
            let id = self.layerContainerView.newLayer(name: (self.layerPanelController?.getNextName())!,id:nil, size:self.targetSize);
        self.layerPanelController?.addLayer(layerId: id);
        StylusManager.setLayerId(layerId:id);
        
    }
    
    func newVisualizationLayer() {
        self.layerContainerView.addVisualizationLayer(name: "Vis layer",id:nil, size:self.targetSize);
    }
    
    func onErase(sender: UIButton!) {
        layerContainerView.eraseCurrentLayer();
    }
    
    internal func processRequestHandler(data: (String, JSON?), key: String) {
        self.processRequest(data:data)
    }
    
    
    
    //from Requester protocol. Handles result of request
    internal func processRequest(data: (String, JSON?)) {
               #if DEBUG
            //print("process request",data.0)
        #endif
        switch(data.0){
        
        case "disconnected":
            recconnectAlert();
            break;
        case "incorrect_key":
            loggedIn = false;

            print("incorrect key logged in",loggedIn)

            self.loginAlert(isIncorrect: true)
            break;
        case "correct_key":
            self.keyRecognized()
            break;
        case "backup_complete":
            self.startBackupTimer(interval: self.backupInterval)
            break;
        case "upload_image_complete":
            let isLast = data.1?["isLast"].boolValue
            let saveType = data.1?["save_type"].stringValue
            let content_type = data.1?["content_type"].stringValue
                if isLast != nil && isLast == true {
                    if(saveType == "backup" && content_type == "text/plist"){
                        #if DEBUG
                        print("backing up image")
                        #endif
                        self.backupImage()
                        
                    }
                    else if(saveType == "backup" && content_type == "image/png"){
                        #if DEBUG
                            print("backing up behavior")
                        #endif

                        let filename = UserDefaults.standard.string(forKey: "backup_filename")!
                        self.backupBehavior(filename: filename)
                    }
                    else{
                        self.requestProjectList()
                        self.dismiss(animated: true, completion: nil)
                        self.startBackupTimer(interval:self.backupInterval);
                    }
            }
            break;
        case "filelist_complete":
            let listType = data.1?["list_type"].stringValue
            if(listType == "project_list"){
                processProjectList(list: (data.1?["filelist"])!);
            }
            else if(listType == "behavior_list"){
                let filelist_complete_request = Request(target:"socket",action:"send_storage_data",data:data.1,requester:self)
                RequestHandler.addRequest(requestData: filelist_complete_request)
            }
            break;
        case "download_complete":
            currentBehaviorName = (data.1?["short_filename"].stringValue)!
            currentBehaviorFile = (data.1?["filename"].stringValue)!
            
            behaviorManager?.loadData(json: data.1!["data"])
            
            self.behaviorPanelController?.loadBehaviors(json: data.1!["data"])
            self.synchronizeWithAuthoringClient();
            self.startBackupTimer(interval:self.backupInterval);
            break;
            
        case "download_project_complete":
            let id = data.1!["id"].stringValue;
            let path = data.1!["path"].stringValue;
            let content_type = data.1!["content_type"].stringValue;
            let isLast = data.1!["isLast"].boolValue
            print("download project complete id:\(id),path:\(path),content_type:\(content_type)")
            if(content_type == "plist"){
                layerContainerView.loadImageIntoLayer(id:id);
            }
            if isLast == true{
                fileListContainerView?.isHidden = true
                self.dismiss(animated: true, completion: nil)
                self.startBackupTimer(interval:self.backupInterval)
 
            }
            
            break;
        case "project_data_download_complete":
            let fileData = data.1!["data"];
            let newLayers = layerContainerView.loadFromData(fileData: fileData,size:targetSize)
            layerPanelController?.loadLayers(newLayers:newLayers);

            let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
            let documentDirectory = paths[0] as! String
            
            var jsonLayerArray = fileData["layers"].arrayValue;
            for i in 0..<jsonLayerArray.count{
                let layerData = jsonLayerArray[i];
                let hasImageData = layerData["hasImageData"].boolValue
                if(hasImageData){
                    let id = layerData["id"].stringValue;
                    let artistName = UserDefaults.standard.string(forKey: "userkey")!
                    let projectName = data.1!["projectName"].stringValue
                    var imageDownloadData:JSON = [:]
                    let imageUrl = documentDirectory.appending("/ink_"+id+".png")
                    imageDownloadData["id"] = JSON(id)
                    imageDownloadData["url"] = JSON(imageUrl)
                     imageDownloadData["content_type"] = JSON("ink")
                    let image_filename = "saved_files/"+artistName+"/drawings/"+projectName+"/ink_"+id+".png"
                    imageDownloadData["filename"] = JSON(image_filename);
                    let image_load_request = Request(target:"storage",action:"download_project_file",data:imageDownloadData,requester:self)
                    RequestHandler.addRequest(requestData: image_load_request)
                    
                    let saved_strokes = layerData["saved_strokes"].arrayValue
                    print("saved strokes list json",saved_strokes);
                    for stroke in saved_strokes{
                        let stroke_id = stroke.stringValue
                        print("stroke id",stroke_id)

                        var strokeDownloadData:JSON = [:]
                        let strokeURL = documentDirectory.appending("/"+stroke_id+".strokedata")
                        strokeDownloadData["id"] = JSON(id)
                        strokeDownloadData["url"] = JSON(strokeURL)
                        strokeDownloadData["content_type"] = JSON("strokedata")
                        
                        let stroke_filename = "saved_files/"+artistName+"/drawings/"+projectName+"/"+stroke_id+".strokedata"
                        strokeDownloadData["filename"] = JSON(stroke_filename);
                        let stroke_load_request = Request(target:"storage",action:"download_project_file",data:strokeDownloadData,requester:self)
                        RequestHandler.addRequest(requestData: stroke_load_request)

                    }
                    
                    
                    
                    var plistDownloadData:JSON = [:]
                    let plistURL = documentDirectory.appending("/state_"+id+".plist")
                    plistDownloadData["id"] = JSON(id)
                    plistDownloadData["url"] = JSON(plistURL)
                    plistDownloadData["content_type"] = JSON("plist")

                    let plist_filename = "saved_files/"+artistName+"/drawings/"+projectName+"/state_"+id+".plist"
                    plistDownloadData["filename"] = JSON(plist_filename);
                    if(i == jsonLayerArray.count-1){
                       plistDownloadData["isLast"]  = JSON(true)
                    }
                    let plist_load_request = Request(target:"storage",action:"download_project_file",data:plistDownloadData,requester:self)
                    RequestHandler.addRequest(requestData: plist_load_request)
                }
            }
            
            
            break;
        case "upload_complete":
            let uploadtype = data.1!["type"].stringValue;
            switch(uploadtype){
            case "backup":
                break;
            case "save":
                let saveCompleteRequest = Request(target:"socket",action:"send_storage_data",data:data.1,requester:self)
                RequestHandler.addRequest(requestData: saveCompleteRequest)
                break;
            default:
                break;
            }
            break;
        case "synchronize_request", "authoring_client_connected":
            self.synchronizeWithAuthoringClient();
            break;
        case "authoring_request":
            do{
                let authoring_data = data.1! as JSON
                let attempt = try behaviorManager?.handleAuthoringRequest(authoring_data: authoring_data);
                let data = authoring_data["data"]
                if(data["type"].stringValue == "behavior_added"){
                    
                    behaviorPanelController?.addBehavior(behaviorId: data["id"].stringValue, behaviorName: data["name"].stringValue, activeStatus: true)
                }
                else if(data["type"].stringValue == "delete_behavior_request"){
                    behaviorPanelController?.removeBehavior(behaviorId: data["behaviorId"].stringValue)
                }
                
                else if(data["type"].stringValue == "set_behavior_active"){
                    let active = data["active_status"].boolValue
                    if(active){
                    behaviorPanelController?.setActive(id: data["behaviorId"].stringValue)
                    }
                    else{
                        behaviorPanelController?.setInactive(id: data["behaviorId"].stringValue)
 
                    }
                }

                let socketRequest = Request(target: "socket", action: "authoring_response", data: attempt, requester: self)
                
                RequestHandler.addRequest(requestData:socketRequest);
                
            }
            catch{
                #if DEBUG
                    print("failed authoring request");
                #endif
                var jsonArg:JSON = [:]
                jsonArg["type"] = "authoring_response"
                jsonArg["result"] = "failed"
                
                let socketRequest = Request(target: "socket", action: "authoring_request_response", data: jsonArg, requester: self)
                
                RequestHandler.addRequest(requestData:socketRequest);
            }
            backupNeeded = true
            
            break;
        case "storage_request":
            let storage_data = data.1!["data"];
            let type = storage_data["type"].stringValue;
            let filename = storage_data["filename"].stringValue;
            let artistName = storage_data["artistName"].stringValue;
            switch(type){
            case "save_request":
                self.saveBehavior(filename: filename, artistName: artistName);
                
                break;
            case "load_request":
                self.loadBehavior(filename: filename, artistName: artistName);
                
                break;
            case "filelist_request":
                var filelist_json:JSON = [:]
                filelist_json["targetFolder"] = storage_data["targetFolder"];
                filelist_json["list_type"] = storage_data["list_type"]
                
                let request = Request(target: "storage", action: "filelist", data: filelist_json, requester: self)
                RequestHandler.addRequest(requestData: request);
                break;
                
            default:
                break;
            }
            
            break;
        default:
            break;
            
        }
    }
    
    func synchronizeWithAuthoringClient(){
        let behavior:JSON = behaviorManager!.getAllBehaviorJSON();
        let collections:JSON = BehaviorManager.getAllCollectionJSON();
        var syncJSON:JSON = [:]
        syncJSON["behaviors"] = behavior;
        syncJSON["collections"] = collections;

        let request = Request(target: "socket", action: "synchronize", data: syncJSON, requester: self)
        RequestHandler.addRequest(requestData: request)
    }
    
    
    
    func loadBehavior(filename:String, artistName:String){
        let long_filename = filename;
        //let long_filename = "saved_files/"+artistName+"/behaviors/"+filename
        var loadJSON:JSON = [:]
        loadJSON["filename"] = JSON(long_filename);
        loadJSON["short_filename"] = JSON(filename);
        
        loadJSON["type"] = JSON("load")
        
        loadJSON["targetFolder"] = JSON("saved_files/"+artistName+"/behaviors/")
        let request = Request(target: "storage", action: "download", data: loadJSON, requester: self)
        RequestHandler.addRequest(requestData: request);
    }
    
    
    func loadProject(projectName:String, artistName:String){
        endBackupTimer();
        let project_filename = "saved_files/"+artistName+"/drawings/"+projectName+"/data.json"
        var loadJSON:JSON = [:]
        loadJSON["filename"] = JSON(project_filename);
        loadJSON["type"] = JSON("project_data_load")
        loadJSON["projectName"] = JSON(projectName)
        loadJSON["targetFolder"] = JSON("saved_files/"+artistName+"/drawings/"+projectName+"/")
        let request = Request(target: "storage", action: "download", data: loadJSON, requester: self)
        RequestHandler.addRequest(requestData: request);
    }
    
    
    func saveBehavior(filename:String,artistName:String){
        endBackupTimer()
        var behavior_json:JSON = [:]
        for (key,val) in BehaviorManager.behaviors{
            behavior_json[key] = val.toJSON();
        }
        let filename = "saved_files/"+artistName+"/behaviors/"+filename
        var saveJSON:JSON = [:]
        saveJSON["filename"] = JSON(filename);
        saveJSON["data"] = behavior_json
        saveJSON["type"] = JSON("save")
        saveJSON["targetFolder"] = JSON("saved_files/"+artistName+"/behaviors/")
        let request = Request(target: "storage", action: "upload", data: saveJSON, requester: self)
        RequestHandler.addRequest(requestData: request);
    }
    
    func backupBehavior(filename:String){
        let artistName = UserDefaults.standard.string(forKey: "userkey")
        var behavior_json:JSON = [:]
        for (key,val) in BehaviorManager.behaviors{
            behavior_json[key] = val.toJSON();
        }
        let filename = "saved_files/"+artistName!+"/behavior_backups/"+filename;
        var backupJSON:JSON = [:]
        backupJSON["filename"] = JSON(filename);
        backupJSON["data"] = behavior_json
        backupJSON["type"] = JSON("backup")
        backupJSON["targetFolder"] = JSON("saved_files/"+artistName!+"/backup_behaviors/")
        
        let request = Request(target: "storage", action: "upload", data: backupJSON, requester: self)
        RequestHandler.addRequest(requestData: request);
    }
    
    
    
    
    //event handler for incoming data
    func dataHandler(data:(String,JSON?), key:String){
        switch(data.0){
        case "data_request":
            let requestJSON:JSON = behaviorManager!.getAllBehaviorJSON();
            
            let socketRequest = Request(target: "socket", action: "data_request_response", data: requestJSON, requester: self)
            
            RequestHandler.addRequest(requestData:socketRequest);
            break
        default:
            break
        }
        
    }
    
    func initCanvas(){
        currentCanvas = Canvas();
        behaviorManager = BehaviorManager(canvas: currentCanvas!);
        currentCanvas!.initDrawing();
        _ = currentCanvas!.currentDrawing?.strokeGeneratedEvent.addHandler(target: self, handler: DrawingViewController.strokeGeneratedHandler, key: strokeGeneratedKey)
        
        _ = currentCanvas!.currentDrawing?.strokeRemovedEvent.addHandler(target: self, handler: DrawingViewController.strokeRemovedHandler, key: strokeRemovedKey)
        
        _ = StylusManager.eraseEvent.addHandler(target: self, handler: DrawingViewController.stylusManagerEventHandler, key: stylusManagerKey)
        
        _ = StylusManager.layerEvent.addHandler(target: self, handler: DrawingViewController.stylusManagerEventHandler, key: stylusManagerKey)

    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        #if DEBUG
            print("did receive memory warning")
        #endif
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if(layerContainerView.activeLayer != nil){
            self.touchesDown = false;
           layerContainerView.activeLayer?.layerTouchesEnded(touches, with: event)
        }
        
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if(layerContainerView.activeLayer != nil){
            self.touchesDown = true;
            layerContainerView.activeLayer?.layerTouchesBegan(touches, with: event)
        }
    }
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if(layerContainerView.activeLayer != nil){
            
            layerContainerView.activeLayer?.layerTouchesMoved(touches, with: event)
        }
    }
    
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if(layerContainerView.activeLayer != nil){
            self.touchesDown = false
            //layerContainerView.activeLayer?.touchesCancelled(touches, with: event)
        }
        
    }
    
    
    
    
    func handlePinch(recognizer : UIPinchGestureRecognizer) {
        if let view = recognizer.view {
            self.layerContainerView.removeAllStrokes()
            view.transform = view.transform.scaledBy(x: recognizer.scale, y: recognizer.scale)
            recognizer.scale = 1
        }
    }
    
    func handleRotate(recognizer : UIRotationGestureRecognizer) {
        if let view = recognizer.view {
            self.layerContainerView.removeAllStrokes()

            view.transform = view.transform.rotated(by: recognizer.rotation)
            recognizer.rotation = 0
        }
    }
    
    func handlePan(recognizer:UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self.view)
        if let view = recognizer.view {
            self.layerContainerView.removeAllStrokes()

            view.center = CGPoint(x:view.center.x + translation.x,
                                  y:view.center.y + translation.y)
        }
        recognizer.setTranslation(CGPoint.zero, in: self.view)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    
    
}


