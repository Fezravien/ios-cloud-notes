//
//  CloudNotes - ListViewController.swift
//  Created by yagom.
//  Copyright © yagom. All rights reserved.
//

import UIKit

protocol MemoSelectionDelegate: class {
    func memoSelected(_ memo: Memo)
}

final class ListViewController: UITableViewController {
    private var memoList: [Memo] = []
    weak var delegate: MemoSelectionDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(MemoTableViewCell.self, forCellReuseIdentifier: "MemoTableViewCell")
        decodeMemoData()
        setUpNavigationBar()
    }
    
    private func decodeMemoData() {
        guard let dataAsset: NSDataAsset = NSDataAsset(name: "sample") else {
            return
        }
        do {
            self.memoList = try JSONDecoder().decode([Memo].self, from: dataAsset.data)
        } catch {
            print(error)
        }
    }
    
    private func setUpNavigationBar() {
        navigationItem.title = "메모"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "+", style: .plain, target: self, action: #selector(moveToPostViewController))
        navigationItem.rightBarButtonItem?.tintColor = UIColor.systemBlue
    }
    
    @objc private func moveToPostViewController() {
        //📍 CRUD Create 부분
    }
}

// MARK: - extension TableView
extension ListViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return memoList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let memoCell = tableView.dequeueReusableCell(withIdentifier: "MemoTableViewCell", for: indexPath) as? MemoTableViewCell else {
            return UITableViewCell()
        }
        memoCell.accessoryType = .disclosureIndicator
        memoCell.setUpMemoCell(memoList[indexPath.row])
        return memoCell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedMemo = memoList[indexPath.row]
        delegate?.memoSelected(selectedMemo)
        
        if let detailViewController = delegate as? DetailViewController {
          splitViewController?.showDetailViewController(detailViewController, sender: nil)
        }
    }
}

