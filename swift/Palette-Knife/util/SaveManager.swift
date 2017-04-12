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

class SaveManager{
    
    let bucketName = "dynabtest"
    
    func connect(){
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: .USEast1, identityPoolId: "us-east-1:ae662e85-94d0-4dcf-81b5-9e27df28af8f")
        let configuration = AWSServiceConfiguration(region: .USEast1, credentialsProvider: credentialsProvider)
        
        AWSServiceManager.default().defaultServiceConfiguration = configuration
    }
    
    
      
    func uploadFile(filename:String, data:JSON){
        
        // create a local image that we can use to upload to s3
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("tempfile.json")
        let data: Data = (data.rawString())!.data(using:.utf8)!
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
                print("Upload complete for: \(uploadRequest?.key)")
                return nil
            })
        
        
    }
    
    func downloadFile(filePath:String)->URL?{
        let transferManager = AWSS3TransferManager.default()
        
        let downloadingFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("tempfile.json")
        
        let downloadRequest = AWSS3TransferManagerDownloadRequest()
        downloadRequest?.bucket = bucketName
        downloadRequest?.key = filePath
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
            let downloadOutput = task.result
            return nil

        })
        return downloadingFileURL
    }
    
}
