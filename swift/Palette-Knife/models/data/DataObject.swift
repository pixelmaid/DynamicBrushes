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



class Table:Emitter {
    var i = 0
    var limit = 0
    var columns = [String:Column]()
    var data:[JSON]?
    var columnizedData = [[Float]]();
    var metadataRowOffset:Int = 0;
    var columnSubscribers = [String:ColumnSynchronizer]()
    init(id:String){
        super.init();
        self.id = id;
    }
    func loadDataFromJSON(data:JSON){
        
        let columns = data["meta"]["view"]["columns"].arrayValue;
        #if DEBUG
            //print("dataset loaded",columns,data)
        #endif
        self.data = data["data"].arrayValue;
        
        for i in 0..<columns.count{
            var columnData = [Float]();
            for j in 0..<self.data!.count{
                let row = self.data![j].arrayValue;
                let v = row[i+metadataRowOffset].floatValue;
                columnData.append(v);
            }
            self.columnizedData.append(columnData);
            
            let fieldName = columns[i]["fieldName"].stringValue;
            let position = columns[i]["position"].intValue;
            let dataTypeName = columns[i]["dataTypeName"].stringValue;
            let description = columns[i]["description"].stringValue;
            //let largest = columns[i]["cachedContents"]["largest"].stringValue;
           // let smallest = columns[i]["cachedContents"]["smallest"].stringValue;
           // let width = columns[i]["width"].intValue;
            let id = columns[i]["id"].stringValue;
            let c:Column?
            if(dataTypeName == "meta_data"){
                metadataRowOffset+=1;
            }
            if(dataTypeName == "number"){
                
                let average = Float(columns[i]["cachedContents"]["average"].stringValue)
                c = NumberColumn(table:self,id:id, fieldName: fieldName, position: position, dataTypeName: dataTypeName, data:columnData)
            }
                
            else if(dataTypeName == "date"){
                c = GeoColumn(table:self,id:id, fieldName: fieldName, position: position, dataTypeName: dataTypeName, data:columnData)
            }
            else{
                c = TextColumn(table:self,id:id, fieldName: fieldName, position: position, dataTypeName: dataTypeName, data:columnData)
                
            }
            #if DEBUG
                //print("dataset fieldname",fieldName);
            #endif
            self.columns[fieldName] = c;
            
        }
        
        for i in 0..<columns.count{
           
        }
        
        #if DEBUG
            print("metadata offset",metadataRowOffset);
        #endif
    }
    
    func resetColumns(){
        for (_,column) in self.columns{
            column.reset();
            
        }
        self.columnSubscribers.removeAll();
    }
    
    func subscribeColumnTo(brushId:String,fieldName:String){
        if(self.columnSubscribers[brushId] == nil){
            self.columnSubscribers[brushId] = ColumnSynchronizer();
            
        }
        self.columnSubscribers[brushId]?.registerColumn(fieldName:fieldName)
    }
    
    func getData(position:Int,row:Int)->Float{
        let row = self.data![row].arrayValue;
        let val = row[position+metadataRowOffset].floatValue;
        return val;
        
    }
    
    func getTargetRow(brushId:String, fieldName:String)->Int{
        return 0;
    }
}
    
    /*func subscribe(fieldName:String,subscriberId:String){
     subscribers[fieldName]?.append(subscriberId);
     }
     
     func unsubscribe(fieldName:String,subscriberId:String){
     var subscriberList = subscribers[fieldName]!
     for i in 0..<subscriberList.count{
     if subscriberList[i] == subscriberId{
     subscribers[fieldName]?.remove(at: i);
     }
     }
     }*/


class ColumnSynchronizer {
    var target:Int = 0;
    var registeredColumns = [String]();
    
    func registerColumn(fieldName:String){
        registeredColumns.append(fieldName);
    }
    func step(){
        target += 1;
    }
    
  
}

class Column:Signal{
        //let fieldName:String
       // let position:Int
      //  let table:Table
      //  let dataTypeName:String
        // let largest:String
      //  let smallest:String
    //    var currentRow = 0;
       // var dataSubscribers = [String:Observable<Float>]();
   //     private var isGenerator = false;
    
    
    init(id:String, fieldName:String,position:Int){
            self.fieldName = fieldName;
            self.position = position;
        
            super.init(id:id)
            print("registering column signal with id:",self.id);
            RequestHandler.registerObservable(observableId: table.id+"_"+self.fieldName, observable: self);

        }
        
        override func subscribe(id: String, brushId:String, brushIndex:Observable<Float>?) {
            #if DEBUG
                print("column subscribing with id,index",id,brushIndex?.get(id: nil));
            #endif
            subscribers[id] = currentRow; //Int(brushIndex!.get(id: nil));
            dataSubscribers[brushId] = brushIndex!
            self.table.subscribeColumnTo(brushId: brushId, fieldName: self.fieldName);
            
        }
        
        
        
        override func get(id:String?)->Float{
            let row:Int;
            if(self.isGenerator){
                row = self.table.getTargetRow(brushId: id!, fieldName:self.fieldName)
            }
            else{
                row = Int(dataSubscribers[id!]!.get(id:nil));
            }
            let val = self.table.getData(position:self.position,row:row)
            self.didChange.raise(data:(name, 0, val) );
            #if DEBUG
                print("column being accessed",id,fieldName,position,row,val)
            #endif
            return val;
        }
    
        
        func reset(){
          //  self.currentRow = 0;
            self.removeAllSubscribers();
        }
        
    }
    
    class CalendarDateColumn:Column{
        
    }
    
    class TextColumn:Column{
        
    }
    
    class GeoColumn:Column{
        
        
        override init(table: Table, id: String, fieldName: String, position: Int, dataTypeName: String, data:[Float] ) {
            
            super.init(table:table,id:id, fieldName: fieldName, position: position, dataTypeName: dataTypeName,data:data);
        }
        
        override func get(id:String?)->Float{
                 let row = Int(dataSubscribers[id!]!.get(id:nil));
            let low,high:Float;
            let mapper:Mapper;
            let val = super.get(id:id);
            if(fieldName == "reclong"){
                low = -180.0
                high = 180.0
                mapper = CanvasXPositionMapper(input:Observable<Float>(val),low:low,high:high)
                
            }
            else{//is latitude
                low = -90
                high = 90
                mapper = CanvasYPositionMapper(input:Observable<Float>(val),low:low,high:high)
            }
            let mappedVal =  mapper.get(id:id);
            #if DEBUG
                print("geodata being accessed",row,mappedVal,val);
            #endif
            return mappedVal;
        }
        
    }
    
    class NumberColumn:Column{
        //let average:Float
        
     
        
        
        
    }

