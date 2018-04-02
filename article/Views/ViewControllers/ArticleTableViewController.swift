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


class ArticleTableViewController: UITableViewController {

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

        articleListViewModel?.articleViewModel.asDriver().drive(tableView.rx.items(cellIdentifier: "Cell", cellType: ArticleTableViewCell.self)) { index, item, cell in
            DispatchQueue.main.async {
                cell.configureCell(articleViewModel: item)
            }

        }.disposed(by: self.disposeBag)

        tableView.rx.itemSelected.subscribe(onNext: { [weak self] indexPath in
            let newsStoryBoard = self?.storyboard?.instantiateViewController(withIdentifier: "newsVC") as! NewsViewController
            newsStoryBoard.newsImage        = self?.getArticleViewModelAt(index: indexPath.row).image
            newsStoryBoard.newsTitle        = self?.getArticleViewModelAt(index: indexPath.row).title
            newsStoryBoard.newsDescription  = self?.getArticleViewModelAt(index: indexPath.row).description
            newsStoryBoard.newsDate         = self?.getArticleViewModelAt(index: indexPath.row).created_date
            
            self?.navigationController?.pushViewController(newsStoryBoard, animated: true)
        }).disposed(by: self.disposeBag)
        
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
        
        refreshControl?.rx.controlEvent(.valueChanged).subscribe({ [weak self] _ in
            self?.fetchData(atPage: 1, withLimitation: 15)
            self?.increasePage = 1
        }).disposed(by: disposeBag)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.title = "News"
        
        NotificationCenter.default.rx.notification(Notification.Name("reloadData"), object: nil).bind { [weak self] notification in
            self?.fetchData(atPage: 1, withLimitation: 15)
            self?.increasePage = 1
        }.disposed(by: self.disposeBag)
    }
    
    private func fetchData(atPage: Int, withLimitation: Int) {
        articleListViewModel?.getArticle(atPage: atPage, withLimitation: withLimitation) { [weak self] in
            DispatchQueue.main.async {
                self?.refreshControl?.endRefreshing()
                self?.loadingIndicatorView.stopAnimating()
                self?.paginationIndicatorView.stopAnimating()
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                    self?.tableView.setContentOffset(.init(x: 0, y: -116), animated: true)
                }
            }
        }
    }
    
    private func getArticleViewModelAt(index: Int) -> ArticleViewModel {
        return (articleListViewModel?.articleAt(index: index))!
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        newFetchBool = 0
    }

    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        newFetchBool += 1
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { [weak self] (action, index) in
            let alert = UIAlertController(title: "Are you sure to delete?", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { (action) in
                DispatchQueue.main.async {
                    self?.articleListViewModel?.deleteArticle(id: (self?.getArticleViewModelAt(index: indexPath.row).id!)!)
                    self?.articleListViewModel?.articleRemoveAt(index: indexPath.row)
                    self?.tableView.reloadData()
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
            self?.present(alert, animated: true, completion: nil)
        }

        let edit = UITableViewRowAction(style: .normal, title: "Edit") { [weak self] (action, index) in
            if let addViewController = self?.storyboard?.instantiateViewController(withIdentifier: "addVC") as? AddArticleViewController {
                addViewController.newsID            = self?.getArticleViewModelAt(index: indexPath.row).id
                addViewController.newsTitle         = self?.getArticleViewModelAt(index: indexPath.row).title
                addViewController.newsDescription   = self?.getArticleViewModelAt(index: indexPath.row).description
                addViewController.newsImage         = self?.getArticleViewModelAt(index: indexPath.row).image
                addViewController.isUpdate          = true
                self?.navigationController?.pushViewController(addViewController, animated: true)
            }
        }
        return [delete, edit]
    }
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let bottomEdge = scrollView.contentOffset.y + scrollView.frame.size.height
        if (bottomEdge >= scrollView.contentSize.height) {
            if decelerate && newFetchBool >= 1 {
                self.increasePage += 1
                self.tableView.layoutIfNeeded()
                self.tableView.tableFooterView              = paginationIndicatorView
                self.tableView.tableFooterView?.isHidden    = false
                self.tableView.tableFooterView?.center      = paginationIndicatorView.center
                self.paginationIndicatorView.startAnimating()
                fetchData(atPage: increasePage, withLimitation: 15)
                self.newFetchBool = 0
            }
        } else if !decelerate {
            newFetchBool = 0
        }
    }

}
