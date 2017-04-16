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
        self.requestEvent.raise(data:("configure_complete",nil))

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
                    self.requestEvent.raise(data:("upload_complete",nil))

                    return nil
                }
                
                let uploadOutput = task.result
                print("Upload complete for: \(uploadRequest?.key)")
                return nil
            })
        
        
    }
    
    func downloadFile(downloadData:JSON){
        let filepath = downloadData["filepath"].stringValue;
        let transferManager = AWSS3TransferManager.default()
        
        let downloadingFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("tempfile.json")
        
        let downloadRequest = AWSS3TransferManagerDownloadRequest()
        downloadRequest?.bucket = bucketName
        downloadRequest?.key = filepath
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
