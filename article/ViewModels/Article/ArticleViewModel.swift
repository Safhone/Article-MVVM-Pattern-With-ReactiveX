//
//  ArticleListViewModel.swift
//  article
//
//  Created by Safhone on 3/5/18.
//  Copyright © 2018 Safhone. All rights reserved.
//

import Foundation
import UIKit
import RxSwift


internal typealias completionHandler = () -> ()

struct ArticleViewModel {
    
    var id          : Int?
    var title       : String?
    var description : String?
    var created_date: String?
    var image       : String?
    
    init() {}

    init(article: Article) {
        self.id             = article.id
        self.title          = article.title
        self.description    = article.description
        self.created_date   = (article.created_date?.formatDate(getTime: true))!
        self.image          = article.image
    }
    
}

class ArticleListViewModel {
    
    var title       : Variable<String> = Variable<String>("")
    var description : Variable<String> = Variable<String>("")
    
    private(set) var imageName: String = ""
    private(set) var articleViewModel: Variable<[ArticleViewModel]> = Variable<[ArticleViewModel]>([])

    var isValid: Observable<Bool> {
        return Observable.combineLatest(title.asObservable(), description.asObservable()) { title, description in
            title.trimmingCharacters(in: .whitespaces).count > 0 && description.trimmingCharacters(in: .whitespaces).count > 0
        }
    }
    
    func getArticle(atPage: Int, withLimitation: Int, completion: @escaping completionHandler) {
        DataAccess.manager.fetchData(urlApi: ShareManager.APIKEY.ARTICLE, atPage: atPage, withLimitation: withLimitation, type: Article.self) { [weak self] articles in
            if atPage != 1 {
                let articles = articles?.map(ArticleViewModel.init)
                self?.articleViewModel.value += articles!
            } else {
                self?.articleViewModel.value = []
                self?.articleViewModel.value = (articles?.map(ArticleViewModel.init))!
            }
            completion()
        }
    }
    
    func saveArticle(image: Data, completion: @escaping completionHandler) {
        uploadArticleImage(image: image) { [weak self] in
            let article = Article(id: 0, title: (self?.title.value)!, description: (self?.description.value)!, created_date: "", image: (self?.imageName)!)
            DataAccess.manager.saveData(urlApi: ShareManager.APIKEY.ARTICLE, object: article)
            completion()
        }
    }
    
    func updateArticle(image: Data, id: Int, completion: @escaping completionHandler) {
        uploadArticleImage(image: image) { [weak self] in
            let article = Article(id: 0, title: (self?.title.value)!, description: (self?.description.value)!, created_date: "", image: (self?.imageName)!)
            DataAccess.manager.updateArticle(urlApi: ShareManager.APIKEY.ARTICLE, object: article, id: id)
            completion()
        }
    }
    
    private func uploadArticleImage(image: Data, completion: @escaping completionHandler) {
        DataAccess.manager.uploadImage(urlApi: ShareManager.APIKEY.UPLOAD_IMAGE, image: image) { [weak self] imageName in
            self?.imageName = imageName
            completion()
        }
    }
    
    func deleteArticle(id: Int) {
        DataAccess.manager.deleteData(urlApi: ShareManager.APIKEY.ARTICLE, id: id)
    }
    
    func articleAt(index :Int) -> ArticleViewModel {
        return self.articleViewModel.value[index]
    }
    
    func articleRemoveAt(index: Int) {
        self.articleViewModel.value.remove(at: index)
    }
    
}
