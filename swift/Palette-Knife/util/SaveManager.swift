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
        
        self.requestEvent.raise(data:("configure_complete",nil))
        
    }
    
    func accessFileList(targetFolder:String, uploadData:JSON?){
             let listRequest: AWSS3ListObjectsRequest = AWSS3ListObjectsRequest()
        listRequest.bucket = bucketName
        listRequest.prefix = targetFolder+"/"
        let s3 = AWSS3.s3(forKey: "defaultKey")
        s3.listObjects(listRequest).continueWith { (task) -> AnyObject? in
            var listArray = [String:String]()

            let listObjectsOutput = task.result;
            for object in (listObjectsOutput?.contents)! {
                let key = object.key
                let nameArray = key!.components(separatedBy: "/")
                let name = nameArray[1]
                print("list=\(object.key,object.eTag)");
                listArray[key!] = name
            }
            
            let listJSON = JSON(listArray)
            print("listJSON=\(listJSON,listArray)")
            if(uploadData != nil){
            var revisedUploadData = uploadData;
            revisedUploadData!["filelist"] = listJSON;
            self.requestEvent.raise(data:("upload_complete",revisedUploadData))
            }
            else{
                var filelist_data:JSON = [:];
                filelist_data["filelist"] = listJSON;
                filelist_data["targetFolder"] = JSON(targetFolder)
                filelist_data["type"] = "filelist"
                self.requestEvent.raise(data:("filelist_complete",filelist_data))
            }

            return nil
        }
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
            self.accessFileList(targetFolder: uploadData["targetFolder"].stringValue, uploadData: uploadData)
                        return nil
        })
        
        
    }
    
    func downloadFile(downloadData:JSON){
        
        let filename = downloadData["filename"].stringValue;
        print("filename = \(filename)")
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
                self.requestEvent.raise(data:("download_complete",downloadJSON))
            }
            catch{
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
