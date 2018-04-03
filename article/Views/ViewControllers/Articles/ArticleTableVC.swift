//
//  ViewController.swift
//  article
//
//  Created by Safhone on 3/5/18.
//  Copyright © 2018 Safhone. All rights reserved.
//

import UIKit
import SDWebImage
import RxCocoa
import RxSwift


class ArticleTableVC: UITableViewController {

    private var articleListViewModel: ArticleListViewModel?
    
    private let paginationIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    private var loadingIndicatorView    = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    private var increasePage            = 1
    private var newFetchBool            = 0
    private let disposeBag              = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        
        tableView.preservesSuperviewLayoutMargins   = false
        tableView.separatorInset                    = UIEdgeInsets.zero
        tableView.layoutMargins                     = UIEdgeInsets.zero
        tableView.tableFooterView                   = UIView()
        tableView.estimatedRowHeight                = 111
        tableView.rowHeight                         = UITableViewAutomaticDimension
        tableView.dataSource                        = nil
        
        articleListViewModel = ArticleListViewModel()
        
        fetchData(atPage: self.increasePage, withLimitation: 15)

        articleListViewModel?.articleViewModel.asDriver()
            .filter({ $0.count > 0 })
            .do(onNext: { [weak self] _ in
                self?.refreshControl?.endRefreshing()
                self?.loadingIndicatorView.stopAnimating()
                self?.paginationIndicatorView.stopAnimating()
            })
            .drive(tableView.rx.items) { tableView, index, item in
                let indexPath = IndexPath(row: index, section: 0)
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ArticleTableViewCell
                
                cell.configureCell(articleViewModel: item)
                
                return cell
            }
            .disposed(by: disposeBag)
    
        tableView.rx.modelSelected(ArticleViewModel.self).asDriver()
            .drive(onNext: { [weak self] article in
                let newsStoryBoard = self?.storyboard?.instantiateViewController(withIdentifier: "newsVC") as! NewsVC
                newsStoryBoard.newsImage        = article.image
                newsStoryBoard.newsTitle        = article.title
                newsStoryBoard.newsDescription  = article.description
                newsStoryBoard.newsDate         = article.created_date
                
                self?.navigationController?.pushViewController(newsStoryBoard, animated: true)
            })
            .disposed(by: disposeBag)
        
        tableView.rx.didEndDecelerating.asDriver()
            .drive(onNext: { [weak self] decelerate in
                if (self?.tableView.contentOffset.y)! >= ((self?.tableView.contentSize.height)! - (self?.tableView.frame.size.height)! - 49) {
                    self?.increasePage += 1
                    self?.tableView.layoutIfNeeded()
                    self?.tableView.tableFooterView             = self?.paginationIndicatorView
                    self?.tableView.tableFooterView?.isHidden   = false
                    self?.tableView.tableFooterView?.center     = (self?.paginationIndicatorView.center)!
                    self?.paginationIndicatorView.startAnimating()
                    self?.fetchData(atPage: (self?.increasePage)!, withLimitation: 15)
                }
            })
            .disposed(by: disposeBag)
        
        pullToRefresh()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.title = "News"
        
        NotificationCenter.default.rx.notification(Notification.Name("reloadData"), object: nil)
            .bind { [weak self] notification in
                self?.fetchData(atPage: 1, withLimitation: 15)
                self?.increasePage = 1
            }
            .disposed(by: self.disposeBag)
    }
    
    private func fetchData(atPage: Int, withLimitation: Int) {
        articleListViewModel?.getArticle(atPage: atPage, withLimitation: withLimitation) {}
    }
    
    private func pullToRefresh() {
        let x = self.view.frame.width / 2
        let y = self.view.frame.height / 2
        loadingIndicatorView.center = CGPoint(x: x, y: y - 100)
        loadingIndicatorView.hidesWhenStopped = true
        view.addSubview(loadingIndicatorView)
        loadingIndicatorView.startAnimating()
        
        refreshControl = UIRefreshControl()
        let attributes = [NSAttributedStringKey.foregroundColor: UIColor.gray]
        refreshControl?.attributedTitle = NSAttributedString(string: "Pull to Refresh", attributes: attributes)
        tableView.addSubview(refreshControl!)
        
        refreshControl?.rx.controlEvent(.valueChanged)
            .subscribe({ [weak self] _ in
                self?.fetchData(atPage: 1, withLimitation: 15)
                self?.increasePage = 1
            })
            .disposed(by: disposeBag)
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { [weak self] action, index in
            let alert = UIAlertController(title: "Are you sure to delete?", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { (action) in
                DispatchQueue.main.async {
                    self?.articleListViewModel?.deleteArticle(id: (self?.articleListViewModel?.articleAt(index: indexPath.row).id!)!)
                    self?.articleListViewModel?.articleRemoveAt(index: indexPath.row)
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
            self?.present(alert, animated: true, completion: nil)
        }
        
        let edit = UITableViewRowAction(style: .normal, title: "Edit") { [weak self] action, index in
            if let addViewController = self?.storyboard?.instantiateViewController(withIdentifier: "addVC") as? AddArticleVC {
                addViewController.newsID            = self?.articleListViewModel?.articleAt(index: indexPath.row).id
                addViewController.newsTitle         = self?.articleListViewModel?.articleAt(index: indexPath.row).title
                addViewController.newsDescription   = self?.articleListViewModel?.articleAt(index: indexPath.row).description
                addViewController.newsImage         = self?.articleListViewModel?.articleAt(index: indexPath.row).image
                addViewController.isUpdate          = true
                self?.navigationController?.pushViewController(addViewController, animated: true)
            }
        }
        
        return [delete, edit]
    }

}
