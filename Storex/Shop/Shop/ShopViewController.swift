//
//  ShopViewController.swift
//  Storex
//
//  Created by Kerolles Roshdi on 5/19/19.
//  Copyright © 2019 KerollesRoshdi. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SideMenu

class ShopViewController: UIViewController {
    @IBOutlet weak var tableview: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var retryView: UIView!
    @IBOutlet weak var retryButton: UIButton!
    
    lazy var viewModel: ShopViewModel = {
        return ShopViewModel()
    }()
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setNavigationTitleImage()
        
        // register nibs:
        tableview.registerCellNib(cellClass: DepartmentCell.self)
        

        initView()
        initVM()
    }
    
    private func initView() {
        tableview.rx.modelSelected(DepartmentCellViewModel.self)
            .subscribe(onNext: { [weak self] model in
                guard let self = self else { return }
                guard let categoryVC = self.storyboard?.instantiateViewController(withIdentifier: "DepartmentViewController") as? DepartmentViewController else { return }
                categoryVC.departmentCellViewModel = model
                self.navigationController?.pushViewController(categoryVC, animated: true)
            })
            .disposed(by: disposeBag)
        
        menuButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                let menu = self.storyboard?.instantiateViewController(withIdentifier: "LeftSideMenu") as! UISideMenuNavigationController
                menu.setNavigationBarHidden(true, animated: false)
                SideMenuManager.default.menuPresentMode = .viewSlideInOut
                SideMenuManager.default.menuAnimationBackgroundColor = UIColor.clear
                self.present(menu, animated: true)
            })
            .disposed(by: disposeBag)
        
        retryButton.rx.tap
            .throttle(.seconds(5), scheduler: MainScheduler.instance)
            .subscribe(onNext:{ [weak self] _ in
                guard let self = self else { return }
                self.viewModel.initFetch()
            })
            .disposed(by: disposeBag)
    }
    
    private func initVM() {
        viewModel.errorMessage
            .observeOn(MainScheduler.instance)
            .subscribe(onNext:{ message in
                NotificationBannerManager.show(title: "Network Error!", message: message, style: .warning)
            })
            .disposed(by: disposeBag)
        
        viewModel.state
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] state in
                guard let self = self else { return }
                switch state {
                case .loading:
                    // tableview loading ...
                    self.retryView.isHidden = true
                    self.activityIndicator.startAnimating()
                    UIView.animate(withDuration: 0.2) {
                        self.tableview.alpha = 0.0
                    }
                case .error:
                    self.retryView.isHidden = false
                    self.activityIndicator.stopAnimating()
                    UIView.animate(withDuration: 0.2) {
                        self.tableview.alpha = 0.0
                    }
                case .success:
                    // tableview loaded
                    self.retryView.isHidden = true
                    self.activityIndicator.stopAnimating()
                    UIView.animate(withDuration: 0.2) {
                        self.tableview.alpha = 1.0
                    }
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.departmentCellViewModels
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.tableview.reloadData()
            })
            .disposed(by: disposeBag)
        
        viewModel.departmentCellViewModels
            .bind(to: tableview.rx.items(cellIdentifier: "DepartmentCell")) {
                (row, cellViewModel, cell: DepartmentCell) in
                cell.departmentCellViewModel = cellViewModel
        }.disposed(by: disposeBag)
        
        viewModel.initFetch()
        
    }

}
