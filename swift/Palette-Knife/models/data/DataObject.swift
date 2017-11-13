//
//  DataObject.swift
//  DynamicBrushes
//
//  Created by JENNIFER MARY JACOBS on 10/10/17.
//  Copyright © 2017 pixelmaid. All rights reserved.
//

import Foundation
import SwiftKVC
import SwiftyJSON


enum FloatParsingError: Error {
    case overflow
    case invalidInput(String)
}

class DataObject:Observable<Float>{
    
    
}

class Table {
    var i = 0
    var limit = 0
    var columns = [String:Column]()
    var data:[JSON]?
    var subscribers = [String:[String]]()
    let id:String
    
    init(id:String){
        self.id = id;
    }
    func loadDataFromJSON(data:JSON){
        
        let columns = data["meta"]["view"]["columns"].arrayValue;
        #if DEBUG
        print("dataset loaded",columns,data)
        #endif
        for i in 0..<columns.count{
            let fieldName = columns[i]["fieldName"].stringValue;
            let position = columns[i]["position"].intValue;
            let dataTypeName = columns[i]["dataTypeName"].stringValue;
            let description = columns[i]["description"].stringValue;
            let largest = columns[i]["cachedContents"]["largest"].stringValue;
            let smallest = columns[i]["cachedContents"]["smallest"].stringValue;
            let width = columns[i]["width"].intValue + 7;
            let id = String(columns[i]["id"].intValue);
            let c:Column?
            if(dataTypeName == "number"){
                
                let average = Float(columns[i]["cachedContents"]["average"].stringValue)
                c = NumberColumn(table:self,id:id, fieldName: fieldName, position: position, dataTypeName: dataTypeName, largest:largest,smallest:smallest,average:average!)
                
                
            }
           
            else if(dataTypeName == "calendar_data"){
                c = CalendarDateColumn(table:self,id:id, fieldName: fieldName, position: position, dataTypeName: dataTypeName, largest:largest,smallest:smallest)
            }
                
            else if(dataTypeName == "location"){
                c = GeoColumn(table:self,id:id, fieldName: fieldName, position: position, dataTypeName: dataTypeName, largest:largest,smallest:smallest)
            }
            else{
                c = TextColumn(table:self,id:id, fieldName: fieldName, position: position, dataTypeName: dataTypeName, largest:largest,smallest:smallest)
                
            }
            #if DEBUG
                print("dataset fieldname",fieldName);
            #endif
            self.columns[fieldName] = c;
            
        }
        self.data = data["data"].arrayValue;
    }
    
    func getData(fieldName:String,type:String,id:String?)->Float{
        
        return 0.0;
    }
    
    func subscribe(fieldName:String,subscriberId:String){
        subscribers[fieldName]?.append(subscriberId);
    }
    
    func unsubscribe(fieldName:String,subscriberId:String){
       var subscriberList = subscribers[fieldName]!
        for i in 0..<subscriberList.count{
            if subscriberList[i] == subscriberId{
            subscribers[fieldName]?.remove(at: i);
            }
        }
    }
    
 
class Column:DataObject{
    let fieldName:String
    let position:Int
    let table:Table
    let dataTypeName:String
    let id:String
    let largest:String
    let smallest:String
    
    init(table:Table,id:String, fieldName:String,position:Int,dataTypeName:String,largest:String,smallest:String){
        self.fieldName = fieldName
        self.position = position
        self.dataTypeName = dataTypeName
        self.table = table
        self.id = id
        self.largest = largest
        self.smallest = smallest
        super.init(0)
    }
    
    override func subscribe(id: String) {
        super.subscribe(id: id)
        self.table.subscribe(fieldName:self.fieldName,subscriberId:id)
    }
    
    override func unsubscribe(id: String) {
        super.unsubscribe(id: id)
        self.table.unsubscribe(fieldName:self.fieldName,subscriberId:id)
    }
    
    override func get(id:String?)->Float{
        #if DEBUG
        #endif
        
        return self.table.getData(fieldName:self.fieldName,type:self.dataTypeName,id:id)
    }
    
}
    
class CalendarDateColumn:Column{
        
}
class TextColumn:Column{
        
}
    
class GeoColumn:Column{
        
}


class NumberColumn:Column{
    let average:Float
    
    init(table:Table,id:String,fieldName:String,position:Int,dataTypeName:String,largest:String,smallest:String,average:Float){

        self.average = average
        super.init(table:table,id:id, fieldName: fieldName, position: position, dataTypeName: dataTypeName, largest:largest, smallest:smallest);
    }
        
        
        
        
    }
}
