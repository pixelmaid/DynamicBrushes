//
//  Event.swift
//  DrawPad
//
//  Created by JENNIFER MARY JACOBS on 2/1/16.
//


public protocol Disposable {
    func dispose()
}


/// An event provides a mechanism for raising notifications, together with some
/// associated data. Multiple function handlers can be added, with each being invoked,
/// with the event data, when the event is raised.
public class Event<T> {
    
    public typealias EventHandler = (T,String) -> ()
    
    var eventHandlers = [Invocable]()
    
    public init() {
        
    }
    
    /// Raises the event, invoking all handlers
    public func raise(data: T) {
        for handler in self.eventHandlers {
            handler.invoke(data: data)
        }
    }
    
    /// Adds the given handler
    public func addHandler<U: AnyObject>(target: U, handler: @escaping (U) -> EventHandler, key:String) -> Disposable {
        let wrapper = EventHandlerWrapper(target: target, handler: handler, event: self, key:key)
        eventHandlers.append(wrapper)
        return wrapper
    }
    
    /// removes the given handler that matches the key
    //TODO: UNTESTED!!!!
    public func removeHandler(key:String){
       for i in 0..<eventHandlers.count{
        let e = eventHandlers[i]
            let eW = e as! EventHandlerWrapper<Brush,(String, Float, Float)>
            if eW.key == key{
                print("found event handler for key to remove\(key)")
                eventHandlers.remove(at: i);
                return;
            }
        }
    }
    
}

class StylusEvent:Event<(Observable<(Float,Float)>,Float,Float)>{
    
}

class BrushEvent:Event<(Brush)>{
    
}




// MARK:- Private

// A protocol for a type that can be invoked
protocol Invocable: class {
    func invoke(data: Any)
}

// takes a reference to a handler, as a class method, allowing
// a weak reference to the owning type.
// see: http://oleb.net/blog/2014/07/swift-instance-methods-curried-functions/
class EventHandlerWrapper<T: AnyObject, U> : Invocable, Disposable {
    weak var target: T?
    let handler: (T) -> (U,String) -> ()
    let event: Event<U>
    let key:String
    init(target: T?, handler: @escaping (T) -> (U,String) -> (), event: Event<U>, key:String){
        self.target = target
        self.handler = handler
        self.event = event
        self.key = key
    }
    
    func invoke(data: Any) -> () {
        if let t = target {
            handler(t)(data as! U, self.key)
        }
    }
    
    func dispose() {
        event.eventHandlers = event.eventHandlers.filter { $0 !== self }
    }
}
