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
var stylus = Stylus(x: 0,y:0,angle:0,force:0)
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
let pX = Float(1024*1)
let pY = Float(768*1)
class ViewController: UIViewController, UIGestureRecognizerDelegate,Requester{
    
    
    
    // MARK: Properties
    
    
    var layerContainerView:LayerContainerView!
    
    var behaviorManager: BehaviorManager?
    var currentCanvas: Canvas?
    
    let drawKey = NSUUID().uuidString
    let toolbarKey = NSUUID().uuidString
    let layerEventKey = NSUUID().uuidString
    let colorPickerKey = NSUUID().uuidString
    let fileEventKey = NSUUID().uuidString
    
    let brushEventKey = NSUUID().uuidString
    let dataEventKey = NSUUID().uuidString
    let strokeGeneratedKey = NSUUID().uuidString
    let strokeRemovedKey = NSUUID().uuidString
    let exportKey = NSUUID().uuidString
    let backupKey = NSUUID().uuidString
    let saveEventKey = NSUUID().uuidString
    
    var toolbarController: ToolbarViewController?
    var layerPanelController: LayerPanelViewController?
    var fileListController: SavedFilesPanelViewController?
    let targetSize = CGSize(width:CGFloat(pX),height:CGFloat(pY))
    var blockAlert:UIAlertController!
    
    var colorPickerView: SwiftHSVColorPicker?
    override var prefersStatusBarHidden: Bool {
        return true
    }
    var drawInterval:Timer!
    
    //variables for setting backups
    var backupTimer:Timer!
    var backupInterval = 60*5.0; //set to backup every 5 min
    var backupNeeded:Bool = false;
    
    var currentBehaviorName = ""
    var currentBehaviorFile = ""
    var startup = true;
    @IBOutlet weak var layerPanelContainerView: UIView!
    
    @IBOutlet weak var colorPickerContainerView: UIView!
    @IBOutlet weak var fileListContainerView: UIView!
    
    required init?(coder: NSCoder) {
        layerContainerView = LayerContainerView(width:pX,height:pY);
        super.init(coder: coder);
        
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "toolbarSegue"){
            toolbarController = segue.destination as? ToolbarViewController;
            _ = toolbarController?.toolEvent.addHandler(target: self, handler: ViewController.toolEventHandler, key: toolbarKey)
            
        }
        else if(segue.identifier == "layerPanelSegue"){
            layerPanelController = segue.destination as? LayerPanelViewController;
            _ = layerPanelController?.layerEvent.addHandler(target: self, handler: ViewController.layerEventHandler, key: layerEventKey)
            
        }
        else if(segue.identifier == "colorPickerSegue"){
            colorPickerView = SwiftHSVColorPicker(frame: CGRect(x:10, y:20, width:300, height:400))
            segue.destination.view.addSubview(colorPickerView!)
            colorPickerView?.setViewColor(UIColor.red)
            _ = colorPickerView?.colorEvent.addHandler(target: self, handler: ViewController.colorPickerEventHandler, key: colorPickerKey)
        }
            
        else if(segue.identifier == "fileListSegue"){
            fileListController = segue.destination as? SavedFilesPanelViewController;
            _ = fileListController?.fileEvent.addHandler(target: self, handler: ViewController.fileEventHandler, key: fileEventKey)
        }
        
    }
    
    func colorPickerEventHandler(data:(UIColor), key: String){
        toolbarController?.setColor(color:data);
        uiInput.setColor(color:data);
    }
    
    func toolEventHandler(data: (String), key: String){
        switch(data){
        case "VIEW_LOADED":
            toolbarController?.exportButton.addTarget(self, action: #selector(ViewController.exportImage), for: .touchUpInside)
            toolbarController?.saveButton.addTarget(self, action: #selector(ViewController.saveProject), for: .touchUpInside)
            
            break;
        case "ERASE_MODE":
            layerContainerView.setDrawActive(val: false);
            break;
        case "BRUSH_MODE":
            layerContainerView.setDrawActive(val: true);
            break;
            
        case "TOGGLE_LAYER_PANEL":
            if(layerPanelContainerView?.isHidden == true){
                layerPanelContainerView?.isHidden = false
            }
            else{
                layerPanelContainerView?.isHidden = true
            }
            colorPickerContainerView?.isHidden = true
            
            break;
        case "TOGGLE_BEHAVIOR_PANEL":
            
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
            break;
        case "LAYER_ADDED":
            self.newLayer();
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
    
    func fileEventHandler(data: (String,String,String?), key: String){
        switch(data.0){
        case "FILE_SELECTED":
            let artistName = UserDefaults.standard.string(forKey: "userkey")
            self.loadProject(projectName: data.2!, artistName: artistName!);
            break;
        default:
            break;
        }
    }
    
    func strokeGeneratedHandler(data:(String),key:String){
        self.layerContainerView.addStroke(id:data);
    }
    
    func strokeRemovedHandler(data:([String]),key:String){
        self.layerContainerView.removeStroke(idList:data);
        
    }
    
    
    override func viewDidLoad() {
        
        
        
        super.viewDidLoad()
        
        self.initCanvas()
        
        
        _ = RequestHandler.dataEvent.addHandler(target: self, handler: ViewController.processRequestHandler, key: dataEventKey)
        
        let configureRequest = Request(target: "storage", action: "configure", data:JSON([]), requester: self)
        
        RequestHandler.addRequest(requestData:configureRequest);
        
        layerContainerView.center = CGPoint(x:self.view.frame.size.width/2,y:self.view.frame.size.height/2);
        self.view.addSubview(layerContainerView);
        self.view.sendSubview(toBack: layerContainerView);
        
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(ViewController.handlePinch))
        pinchRecognizer.delegate = self
        layerContainerView.addGestureRecognizer(pinchRecognizer)
        
        let rotateRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(ViewController.handleRotate))
        rotateRecognizer.delegate = self
        layerContainerView.addGestureRecognizer(rotateRecognizer)
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(ViewController.handlePan))
        panRecognizer.delegate = self
        panRecognizer.minimumNumberOfTouches = 2;
        layerContainerView.addGestureRecognizer(panRecognizer)
        
        layerPanelContainerView.layer.cornerRadius = 8.0
        layerPanelContainerView.clipsToBounds = true
        self.newLayer();
        
        layerPanelContainerView.isHidden = true;
        
        colorPickerContainerView.layer.cornerRadius = 8.0
        colorPickerContainerView.clipsToBounds = true
        
        colorPickerContainerView.isHidden = true;
        
        uiInput.setDiameter(val: (toolbarController?.diameterSlider.value)!);
        uiInput.setAlpha(val: (toolbarController?.alphaSlider.value)!);
        uiInput.setColor(color: (colorPickerView?.color)!)
        
        fileListContainerView.layer.cornerRadius = 8.0
        fileListContainerView.clipsToBounds = true
        fileListContainerView.isHidden = true;
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);
        
        self.loginAlert(isIncorrect: false);
        
    }
    
    func addConnectionRequests(){
        let connectRequest = Request(target: "socket", action: "connect", data:JSON([]), requester: self)
        RequestHandler.addRequest(requestData:connectRequest);
    }
    
    func addProjectInitRequests(){
        
        
        var templateJSON:JSON = [:]
        templateJSON["filename"] = "templates/ui_debugging.json"
        templateJSON["type"] = JSON("load")
        let behaviorDownloadRequest = Request(target: "storage", action: "download", data:templateJSON, requester: self)
        RequestHandler.addRequest(requestData:behaviorDownloadRequest);
        
        requestProjectList()
        
        drawInterval  = Timer.scheduledTimer(timeInterval:0.016 , target: self, selector: #selector(ViewController.drawIntervalCallback), userInfo: nil, repeats: true)
        
      //  backupTimer  = Timer.scheduledTimer(timeInterval:TimeInterval(backupInterval), target: self, selector: #selector(ViewController.backupCallback), userInfo: nil, repeats: true)
        
        
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
            if(activeId != nil){
                self.layerPanelController?.setActive(layerId:activeId!);
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    func uploadProject(type:String,filename:String){
        UserDefaults.standard.set(type, forKey: "save_type")
        UserDefaults.standard.set(filename, forKey: "save_filename")
        
        UserDefaults.standard.synchronize()
        
        _ = self.layerContainerView.saveEvent.addHandler(target: self, handler: ViewController.uploadProjectHandler, key: saveEventKey)
        self.behaviorManager?.refreshAllBehaviors();
        //TODO: this is a hack. need to create a delay in case it's saving a stroke to the texture
        let when = DispatchTime.now() + 2;         DispatchQueue.main.asyncAfter(deadline: when) {
            self.layerContainerView.save();
        }

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
            uploadData["filename"] = JSON("saved_files/"+artistName!+prefix+filename+"/"+s+".strokedata")
            let path = documentDirectory.appending("/"+s+".strokedata")
            uploadData["path"] = JSON(path)
                print("stroke data upload path",path);
            uploadData["targetFolder"] = JSON("saved_files/"+artistName!+prefix)
            let uploadRequest = Request(target: "storage", action: "upload_image", data:uploadData, requester: self)
            RequestHandler.addRequest(requestData:uploadRequest);
            }

        }
        
        for (key,val) in save_plists{
            
            var uploadData:JSON = [:]
            uploadData["content_type"] = JSON("text/plist")
            
            uploadData["filename"] = JSON("saved_files/"+artistName!+prefix+filename+"/"+"state_"+key+".plist")
            uploadData["path"] = JSON(val)
            uploadData["targetFolder"] = JSON("saved_files/"+artistName!+prefix)
            let uploadRequest = Request(target: "storage", action: "upload_image", data:uploadData, requester: self)
            RequestHandler.addRequest(requestData:uploadRequest);
            
            
        }
        self.requestProjectList()

    }
    
    func backupProject(filename:String){
        self.uploadProject(type: "backup", filename: filename)
    }
    
    func saveProject(){
        
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
        
        _ = self.layerContainerView.exportEvent.addHandler(target: self, handler: ViewController.backupImageHandler, key: backupKey)
        self.layerContainerView.exportPNG();
    }
    
    func backupImageHandler(data:(String,UIImage?),key:String){
        layerContainerView.exportEvent.removeHandler(key: backupKey);
        if(data.0 == "COMPLETE"){
            let filename =  UserDefaults.standard.string(forKey: "backup_filename")!
            let prefix = "/image_backups/";
            let artistName = UserDefaults.standard.string(forKey:"userkey");
            let png = UIImagePNGRepresentation(data.1!)
            let path = self.layerContainerView.exportPNGAsFile(image: png!)
            
            var uploadData:JSON = [:]
            uploadData["filename"] = JSON("saved_files/"+artistName!+prefix+filename+".png")
            uploadData["path"] = JSON(path)
            uploadData["targetFolder"] = JSON("saved_files/"+artistName!+"/")
            let uploadRequest = Request(target: "storage", action: "upload_image", data:uploadData, requester: self)
            RequestHandler.addRequest(requestData:uploadRequest);
        }
    }
    
    
    func exportImage(){
       _ = self.layerContainerView.exportEvent.addHandler(target: self, handler: ViewController.handleExportRequest, key: exportKey)
        self.behaviorManager?.refreshAllBehaviors();
        //TODO: this is a hack. need to create a delay in case it's saving a stroke to the texture
        DispatchQueue.global(qos: .userInteractive).async {
            
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Saving", message: "Saving Image", preferredStyle: .alert)
        
                self.present(alert, animated: true, completion: { _ in }
                )
            }
        }
        
        let when = DispatchTime.now() + 2;
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.layerContainerView.exportPNG();

        }
    }
    
    func handleExportRequest(data:(String,UIImage?),key:String) {
        let contentToShare = data.1;
        #if DEBUG
            print("handle export request",contentToShare as Any)
        #endif
        layerContainerView.exportEvent.removeHandler(key: exportKey);
        if(contentToShare != nil){
            
            UIImageWriteToSavedPhotosAlbum(contentToShare!, nil, nil, nil)
            self.dismiss(animated: true, completion: nil)

             DispatchQueue.global(qos: .userInteractive).async {
                
                 DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Saved", message: "Your image has been saved to the photo album", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    
                    self.present(alert, animated: true, completion: { _ in }
                    )
                }
            }
            
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
    
    
    @objc func backupCallback(){
        if(backupNeeded){
            let filename = String(Int((NSDate().timeIntervalSince1970)*100000));
            UserDefaults.standard.set(filename, forKey: "backup_filename")
            UserDefaults.standard.synchronize()
            
            self.behaviorManager?.refreshAllBehaviors();
            //TODO: this is a hack. need to create a delay in case it's saving a stroke to the texture
            let when = DispatchTime.now() + 2;
            DispatchQueue.main.asyncAfter(deadline: when) {

                self.backupBehavior(filename:filename)
                self.backupProject(filename:filename)
                self.backupImage()
                self.backupNeeded = false;

            }
        }
    }
    
    
    
    
    
    func newLayer(){
       
        self.behaviorManager?.refreshAllBehaviors();
        //TODO: this is a hack. need to create a delay in case it's saving a stroke to the texture
        let when = DispatchTime.now() + 1;
        DispatchQueue.main.asyncAfter(deadline: when) {
            let id = self.layerContainerView.newLayer(name: (self.layerPanelController?.getNextName())!,id:nil, size:self.targetSize);
        self.layerPanelController?.addLayer(layerId: id);
        }
    }
    
    func onErase(sender: UIButton!) {
        layerContainerView.eraseCurrentLayer();
    }
    
    internal func processRequestHandler(data: (String, JSON?), key: String) {
        self.processRequest(data:data)
    }
    
    
    
    //from Requester protocol. Handles result of request
    internal func processRequest(data: (String, JSON?)) {
        switch(data.0){
        case "disconnected":
            recconnectAlert();
            break;
        case "incorrect_key":
            self.loginAlert(isIncorrect: true)
            break;
        case "correct_key":
            self.keyRecognized()
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
            
            behaviorManager?.loadBehavior(json: data.1!["data"])
            self.synchronizeWithAuthoringClient();
            break;
        case "download_project_complete":
            let id = data.1!["id"].stringValue;
            let path = data.1!["path"].stringValue;
            let content_type = data.1!["content_type"].stringValue;
            
            print("download project complete id:\(id),path:\(path),content_type:\(content_type)")
            if(content_type == "plist"){
                layerContainerView.loadImageIntoLayer(id:id);
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
                    let plist_load_request = Request(target:"storage",action:"download_project_file",data:plistDownloadData,requester:self)
                    RequestHandler.addRequest(requestData: plist_load_request)
                }
            }
            
            
            break;
        case "upload_complete":
            let uploadtype = data.1!["type"];
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
        var behavior:JSON = behaviorManager!.getAllBehaviorJSON();
        let request = Request(target: "socket", action: "synchronize", data: behavior, requester: self)
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
        _ = currentCanvas!.currentDrawing?.strokeGeneratedEvent.addHandler(target: self, handler: ViewController.strokeGeneratedHandler, key: strokeGeneratedKey)
        _ = currentCanvas!.currentDrawing?.strokeRemovedEvent.addHandler(target: self, handler: ViewController.strokeRemovedHandler, key: strokeRemovedKey)
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
           layerContainerView.activeLayer?.layerTouchesEnded(touches, with: event)
        }
        
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if(layerContainerView.activeLayer != nil){
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
            //layerContainerView.activeLayer?.touchesCancelled(touches, with: event)
        }
        
    }
    
    
    
    
    func handlePinch(recognizer : UIPinchGestureRecognizer) {
        if let view = recognizer.view {
            view.transform = view.transform.scaledBy(x: recognizer.scale, y: recognizer.scale)
            recognizer.scale = 1
        }
    }
    
    func handleRotate(recognizer : UIRotationGestureRecognizer) {
        if let view = recognizer.view {
            view.transform = view.transform.rotated(by: recognizer.rotation)
            recognizer.rotation = 0
        }
    }
    
    func handlePan(recognizer:UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self.view)
        if let view = recognizer.view {
            view.center = CGPoint(x:view.center.x + translation.x,
                                  y:view.center.y + translation.y)
        }
        recognizer.setTranslation(CGPoint.zero, in: self.view)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    
    
}


