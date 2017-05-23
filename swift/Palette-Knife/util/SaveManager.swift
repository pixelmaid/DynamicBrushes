//
//  SaveManager.swift
//  PaletteKnife
//
//  Created by JENNIFER MARY JACOBS on 4/11/17.
//  Copyright © 2017 pixelmaid. All rights reserved.
//

import Foundation
import AWSS3
import SwiftyJSON

enum SaveError: Error {
    case jsonConversionFailed
    
}

class SaveManager{
    
    let bucketName = "dynabtest"
    let dataEvent = Event<(String,JSON?)>();
    let requestEvent = Event<(String,JSON?)>();
    
    func configure(){
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: .USEast1, identityPoolId: "us-east-1:ae662e85-94d0-4dcf-81b5-9e27df28af8f")
        let configuration = AWSServiceConfiguration(region: .USEast1, credentialsProvider: credentialsProvider)
        
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        AWSS3.register(with: configuration!, forKey: "defaultKey")
        self.dataEvent.raise(data: ("configure_complete",nil))
        self.requestEvent.raise(data:("configure_complete",nil))

        
    }
    
    func accessFileList(targetFolder:String, list_type:String, uploadData:JSON?){
        print("target folder",targetFolder, list_type)
             let listRequest: AWSS3ListObjectsRequest = AWSS3ListObjectsRequest()
        listRequest.bucket = bucketName
        listRequest.prefix = targetFolder;
        let s3 = AWSS3.s3(forKey: "defaultKey")
        s3.listObjects(listRequest).continueWith { (task) -> AnyObject? in
            var listArray = [String:String]()

            let listObjectsOutput = task.result;
            print("list objects output",listObjectsOutput?.contents);
            for object in (listObjectsOutput?.contents)! {
                print("key = ",object.key)
                let key = object.key
                let nameArray = key!.components(separatedBy: "/")
                print("name key",nameArray,key);
                let name = nameArray[3]
                print("list=\(object.key,object.eTag)");
                listArray[key!] = name
            }
            
            let listJSON = JSON(listArray)
            print("listJSON=\(listJSON,listArray)")
            if(uploadData != nil){
            var revisedUploadData = uploadData;
            revisedUploadData!["filelist"] = listJSON;
            revisedUploadData!["list_type"] = JSON(list_type)
           
            self.dataEvent.raise(data: ("upload_complete",revisedUploadData))
            self.requestEvent.raise(data:("upload_complete",revisedUploadData))
            }
            else{
                var filelist_data:JSON = [:];
                filelist_data["filelist"] = listJSON;
                filelist_data["targetFolder"] = JSON(targetFolder)
                filelist_data["type"] = "filelist"
                filelist_data["list_type"] = JSON(list_type)
                self.dataEvent.raise(data: ("filelist_complete",filelist_data))
                self.requestEvent.raise(data:("filelist_complete",filelist_data))

            }

            return nil
        }
    }
    
    
    func uploadImage(uploadData:JSON){
        
        
                let path = uploadData["path"].stringValue
                let filename = uploadData["filename"].stringValue
                print("filename:",filename)
                let fileUrl = NSURL(fileURLWithPath: path)
                let uploadRequest = AWSS3TransferManagerUploadRequest()
                uploadRequest?.bucket = bucketName
                uploadRequest?.key = filename
                uploadRequest?.contentType = "image/png"
                uploadRequest?.body = fileUrl as URL!
                uploadRequest?.serverSideEncryption = AWSS3ServerSideEncryption.awsKms
                uploadRequest?.uploadProgress = { (bytesSent, totalBytesSent, totalBytesExpectedToSend) -> Void in
                    DispatchQueue.main.async(execute: {
                        //self.amountUploaded = totalBytesSent // To show the updating data status in label.
                        //self.fileSize = totalBytesExpectedToSend
                    })
                }
                
                let transferManager = AWSS3TransferManager.default()
                transferManager.upload(uploadRequest!).continueOnSuccessWith(executor: AWSExecutor.mainThread(), block: { (taskk: AWSTask) -> Any? in
                    if taskk.error != nil {
                        print("Error uploading image: \(String(describing: uploadRequest?.key)) Error: \(String(describing: taskk.error))")

                    } else {
                        self.dataEvent.raise(data: ("upload_image_complete",nil))
                        self.requestEvent.raise(data:("upload_image_complete",nil));

                    }
                    return nil
                })
        
        
    }
    
   
    func uploadFile(uploadData:JSON){
        let filename = uploadData["filename"].stringValue;
        let filedata = uploadData["data"];
        // create a local image that we can use to upload to s3
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("tempfile.json")
        let data: Data = (filedata.rawString())!.data(using:.utf8)!
        do{
            try data.write(to: path!)
        }
        catch{
            print("file write fail")
        }
        
        
        let transferManager = AWSS3TransferManager.default()
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        uploadRequest?.bucket = bucketName
        uploadRequest?.key = filename
        uploadRequest?.body = path!
        transferManager.upload(uploadRequest!).continueWith(executor: AWSExecutor.mainThread(), block: { (task:AWSTask<AnyObject>) -> Any? in
            
            if let error = task.error as? NSError {
                if error.domain == AWSS3TransferManagerErrorDomain, let code = AWSS3TransferManagerErrorType(rawValue: error.code) {
                    switch code {
                    case .cancelled, .paused:
                        break
                    default:
                        print("Error uploading: \(uploadRequest?.key) Error: \(error)")
                    }
                } else {
                    print("Error uploading: \(uploadRequest?.key) Error: \(error)")
                }
                
                return nil
            }
            
            let uploadOutput = task.result
            print("upload data",uploadData);
            let type = uploadData["type"].stringValue
            if(type == "backup"){
                self.dataEvent.raise(data: ("backup_complete",uploadData))
                self.requestEvent.raise(data: ("backup_complete",nil))

            }
            else if(type == "project_save"){
                self.dataEvent.raise(data: ("project_save_json_complete",uploadData))
                self.requestEvent.raise(data: ("project_save_json_complete",nil))
                
                }
            else if(type == "save"){
                self.accessFileList(targetFolder: uploadData["targetFolder"].stringValue, list_type:"behavior_list", uploadData: uploadData)
            }
            
            return nil
            
        })
        
        
    }
    
    func downloadFile(downloadData:JSON){
        
        let filename = downloadData["filename"].stringValue;
        print("filename = \(filename)")
        print("projectName = \(downloadData["projectName"])")

        let transferManager = AWSS3TransferManager.default()
        
        let downloadingFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("tempfile.json")
        
        let downloadRequest = AWSS3TransferManagerDownloadRequest()
        downloadRequest?.bucket = bucketName
        downloadRequest?.key = filename
        downloadRequest?.downloadingFileURL = downloadingFileURL
        
        transferManager.download(downloadRequest!).continueWith(executor: AWSExecutor.mainThread(), block: { (task:AWSTask<AnyObject>) -> Any? in
            
            if let error = task.error as? NSError {
                if error.domain == AWSS3TransferManagerErrorDomain, let code = AWSS3TransferManagerErrorType(rawValue: error.code) {
                    switch code {
                    case .cancelled, .paused:
                        break
                    default:
                        print("Error downloading: \(downloadRequest?.key) Error: \(error)")
                    }
                } else {
                    print("Error downloading: \(downloadRequest?.key) Error: \(error)")
                }
            }
            
            print("Download complete for: \(downloadRequest?.key)")
            _ = task.result
            var downloadJSON:JSON = [:]
            do{
                downloadJSON["data"] = try self.convertFileToJSON(url: downloadingFileURL)!;
                if(downloadData["type"] == "load"){
                    print("load download complete");
                    self.dataEvent.raise(data:("download_complete",downloadJSON))
                    self.requestEvent.raise(data:("download_complete",downloadJSON))
                }
                else if(downloadData["type"] == "project_data_load"){
                    downloadJSON["projectName"] = downloadData["projectName"]
                    self.dataEvent.raise(data: ("project_data_download_complete",downloadJSON))
                    self.requestEvent.raise(data:("project_data_download_complete",downloadJSON))
 
                }
            }
            catch{
                self.dataEvent.raise(data: ("download_failed",JSON([])))
                self.requestEvent.raise(data:("download_failed",JSON([])))
                
            }
            return nil
            
            
        })
        
    }
    
    
    func downloadImage(downloadData:JSON){
        
        let filename = downloadData["filename"].stringValue;
        let id = downloadData["id"].stringValue;
        print("filename, id = \(filename,id)")
        let transferManager = AWSS3TransferManager.default()
        
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(id+".png")
        
        let downloadRequest = AWSS3TransferManagerDownloadRequest()
        downloadRequest?.bucket = bucketName
        downloadRequest?.key = filename
        downloadRequest?.downloadingFileURL = url
        downloadRequest?.downloadProgress = {(bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) -> Void in
            DispatchQueue.main.async(execute: {() -> Void in
                let progress = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
                //self.progressView.progress = progress
                //   self.statusLabel.text = "Downloading..."
                print("Progress is: %f",progress)
            })
        }
        transferManager.download(downloadRequest!).continueWith(executor: AWSExecutor.mainThread(), block: { (task:AWSTask<AnyObject>) -> Any? in
            
            if let error = task.error as NSError? {
                if error.domain == AWSS3TransferManagerErrorDomain, let code = AWSS3TransferManagerErrorType(rawValue: error.code) {
                    switch code {
                    case .cancelled, .paused:
                        break
                    default:
                        print("Error downloading: \(String(describing: downloadRequest?.key)) Error: \(error)")
                    }
                } else {
                    print("Error downloading: \(String(describing: downloadRequest?.key)) Error: \(error)")
                }
            }
            
            print("Download complete for: \(String(describing: downloadRequest?.key))")
            _ = task.result
            var downloadJSON:JSON = [:]
            do{
                downloadJSON["path"] = JSON(url.path);
                downloadJSON["id"] = JSON(id);
                
                let image = UIImage(contentsOfFile: url.path)
                self.dataEvent.raise(data: ("download_image_complete",downloadJSON))
                self.requestEvent.raise(data:("download_image_complete",downloadJSON))
            }
            catch{
                print("download failed")
                self.dataEvent.raise(data: ("download_image_failed",JSON([])))
                self.requestEvent.raise(data:("download_failed",JSON([])))
                
            }
            return nil
            
            
        })
        
    }
    
    
    func convertFileToJSON(url:URL) throws-> JSON?{
        do {
            let fileText = try String(contentsOf: url, encoding: String.Encoding.utf8)
            
            let dataFromString = fileText.data(using: .utf8, allowLossyConversion: false)
            let json = JSON(data: dataFromString!)
            return json;
        }
        catch{
            throw SaveError.jsonConversionFailed;
        }
        
    }
    
}
