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
        let listRequest: AWSS3ListObjectsRequest = AWSS3ListObjectsRequest()
        listRequest.bucket = bucketName
        listRequest.prefix = targetFolder;
        let s3 = AWSS3.s3(forKey: "defaultKey")
        s3.listObjects(listRequest).continueWith { (task) -> AnyObject? in
            var listArray = [String:String]()
            print("list objects output",task.result?.contents)
            let listObjectsOutput = task.result;
            for object in (listObjectsOutput?.contents)! {
                let key = object.key
                let nameArray = key!.components(separatedBy: "/")
                
                let name:String
                if nameArray.count>3{
                    name = nameArray[3]
                }
                else if nameArray.count>2{
                    name = nameArray[2]

                }
                else if nameArray.count>1{
                    name = nameArray[1]
                    
                }
                else{
                    name = nameArray[0]
                }
                listArray[key!] = name
            }
            
            let listJSON = JSON(listArray)
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
        let fileUrl = NSURL(fileURLWithPath: path)
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        uploadRequest?.bucket = bucketName
        uploadRequest?.key = filename
        uploadRequest?.contentType = uploadData["content_type"].stringValue;
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
                #if DEBUG
                    print("Error uploading image: \(String(describing: uploadRequest?.key)) Error: \(String(describing: taskk.error))")
                #endif
                
            } else {
                self.dataEvent.raise(data: ("upload_image_complete",uploadData))
                self.requestEvent.raise(data:("upload_image_complete",uploadData));
                
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
            #if DEBUG
                print("file write fail")
            #endif
            
        }
        
        
        let transferManager = AWSS3TransferManager.default()
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        uploadRequest?.bucket = bucketName
        uploadRequest?.key = filename
        uploadRequest?.body = path!
        transferManager.upload(uploadRequest!).continueWith(executor: AWSExecutor.mainThread(), block: { (task:AWSTask<AnyObject>) -> Any? in
            
            if let error = task.error as NSError? {
                if error.domain == AWSS3TransferManagerErrorDomain, let code = AWSS3TransferManagerErrorType(rawValue: error.code) {
                    switch code {
                    case .cancelled, .paused:
                        break
                    default:
                        #if DEBUG
                            print("Error uploading: \(String(describing: uploadRequest?.key)) Error: \(error)")
                        #endif
                        
                    }
                } else {
                    #if DEBUG
                        print("Error uploading: \(String(describing: uploadRequest?.key)) Error: \(error)")
                    #endif
                }
                
                return nil
            }
            
            
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
                        #if DEBUG
                            print("Error downloading: \(String(describing: downloadRequest?.key)) Error: \(error)")
                        #endif
                    }
                } else {
                    #if DEBUG
                        print("Error downloading: \(String(describing: downloadRequest?.key)) Error: \(error)")
                    #endif
                }
            }
            #if DEBUG
                print("Download complete for: \(String(describing: downloadRequest?.key))")
            #endif
            _ = task.result
            var downloadJSON:JSON = [:]
            do{
                downloadJSON["data"] = try self.convertFileToJSON(url: downloadingFileURL)!;
                downloadJSON["short_filename"] = downloadData["short_filename"];
                downloadJSON["filename"] = downloadData["filename"];
                
                if(downloadData["type"] == "load"){
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
    
    
    func downloadProjectFile(downloadData:JSON){
        
        let filename = downloadData["filename"].stringValue;
        let id = downloadData["id"].stringValue;
        let transferManager = AWSS3TransferManager.default()
        let url =  URL(fileURLWithPath: downloadData["url"].stringValue)
        let content_type = downloadData["content_type"].stringValue
       // let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(id+".png")
        
        let downloadRequest = AWSS3TransferManagerDownloadRequest()
        downloadRequest?.bucket = bucketName
        downloadRequest?.key = filename
        downloadRequest?.downloadingFileURL = url
        downloadRequest?.downloadProgress = {(bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) -> Void in
            DispatchQueue.main.async(execute: {() -> Void in
                let progress = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
                //self.progressView.progress = progress
                //   self.statusLabel.text = "Downloading..."
                #if DEBUG
                print("Progress for \(content_type) is: %f",progress)
                #endif
            })
        }
        transferManager.download(downloadRequest!).continueWith(executor: AWSExecutor.mainThread(), block: { (task:AWSTask<AnyObject>) -> Any? in
            
            if let error = task.error as NSError? {
                if error.domain == AWSS3TransferManagerErrorDomain, let code = AWSS3TransferManagerErrorType(rawValue: error.code) {
                    switch code {
                    case .cancelled, .paused:
                        break
                    default:
                        #if DEBUG
                        print("Error downloading: \(String(describing: downloadRequest?.key)) Error: \(error)")
                        #endif
                    }
                } else {
                    #if DEBUG
                    print("Error downloading: \(String(describing: downloadRequest?.key)) Error: \(error)")
                    #endif
                }
            }
            #if DEBUG
            print("Download complete for: \(url.absoluteString)")
            #endif
            _ = task.result
            var downloadJSON:JSON = [:]
            
            downloadJSON["path"] = JSON(url.path);
            downloadJSON["id"] = JSON(id);
            downloadJSON["content_type"] = JSON(content_type)
            downloadJSON["isLast"] = downloadData["isLast"]
            self.dataEvent.raise(data: ("download_project_complete",downloadJSON))
            self.requestEvent.raise(data:("download_project_complete",downloadJSON))
            
            
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
