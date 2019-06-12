//
//  Router.swift
//  DynamicBrushes
//
//  Created by JENNIFER MARY JACOBS on 11/20/17.
//  Copyright © 2017 pixelmaid. All rights reserved.
//


// routes between views
import Foundation

final class Router {
    static let sharedInstance = Router()
    
    
    private init() {}
    
    
    class func createDrawingModule()->UIViewController{
         let navController = mainStoryboard.instantiateViewController(withIdentifier: "NavigationController")
        if let view = navController.children.first as? DrawingViewController{
            view.router = Router();
            /* let presenter: PostListPresenterProtocol & PostListInteractorOutputProtocol = PostListPresenter()
 let interactor: PostListInteractorInputProtocol & PostListRemoteDataManagerOutputProtocol = PostListInteractor()
 let localDataManager: PostListLocalDataManagerInputProtocol = PostListLocalDataManager()
 let remoteDataManager: PostListRemoteDataManagerInputProtocol = PostListRemoteDataManager()
 let wireFrame: PostListWireFrameProtocol = PostListWireFrame()
 
 view.presenter = presenter
 presenter.view = view
 presenter.wireFrame = wireFrame
 presenter.interactor = interactor
 interactor.presenter = presenter
 interactor.localDatamanager = localDataManager
 interactor.remoteDatamanager = remoteDataManager
 remoteDataManager.remoteRequestHandler = interactor*/
            
            return navController;
        }
        return UIViewController()

    }
    
    static var mainStoryboard: UIStoryboard {
        return UIStoryboard(name: "Main", bundle: Bundle.main)
    }
    
    class func createProgrammingModule()->UIViewController{
        let viewController = mainStoryboard.instantiateViewController(withIdentifier: "ProgrammingController")
        if viewController is ProgrammingViewController {
            /*let presenter: PostDetailPresenterProtocol = PostDetailPresenter()
            let wireFrame: PostDetailWireFrameProtocol = PostDetailWireFrame()
            
            view.presenter = presenter
            presenter.view = view
            presenter.post = post
            presenter.wireFrame = wireFrame*/
            
            return viewController
        }
        return UIViewController()
    }
    
    
    
}
