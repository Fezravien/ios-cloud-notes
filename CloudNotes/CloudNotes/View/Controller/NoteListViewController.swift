//
//  NoteList.swift
//  CloudNotes
//
//  Created by 윤재웅 on 2021/06/03.
//

import UIKit
import CoreData

class NoteListViewController: UIViewController {
    private lazy var noteManager = NoteManager()
    private var cellView: UIView?
    weak var noteDelegate: NoteDelegate?
    private var specifyNote: Note?
    
    private let tableView: UITableView = {
        let tableview = UITableView(frame: .zero, style: .insetGrouped)
        tableview.showsVerticalScrollIndicator = false
        tableview.translatesAutoresizingMaskIntoConstraints = false
        return tableview
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setConfiguration()
        setConstraint()
        setCellView()
        fetchList()
        noteManager.fetchedResultsController.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: animated)
        }
    }
    
    @objc private func addNote() {
        let newNote = Note(context: noteManager.context)
        newNote.title = ""
        newNote.body = ""
        newNote.lastModify = Date()
        noteManager.insert(newNote)
        noteDelegate?.deliverToDetail(nil, first: true, index: IndexPath(item: 0, section: 0))
    }
    
    func textViewIsEmpty(_ first: Bool) {
        if first == false { return }
        let data = noteManager.specify(IndexPath(row: 0, section: 0))
        self.noteManager.delete(data)
    }
    
    func updateTextToCell(_ data: String, isTitle: Bool, index: IndexPath?) {
        self.noteManager.update(data, isTitle, notedata: specifyNote!)
    }
    
    private func fetchList() {
        switch noteManager.fetch() {
        case .success(_):
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        case .failure(let error):
            alterError(CoreDataError.fetch(error).errorDescription)
        }
    }
    
    private func setCellView() {
        self.cellView = UIView()
        self.cellView?.layer.cornerRadius = 15
    }
    
    private func setConfiguration() {
        self.navigationItem.title = "메모"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNote))
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(NoteListCell.self, forCellReuseIdentifier: "NoteCell")
    }
    
    private func setConstraint() {
        self.view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
    }
}

extension NoteListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return noteManager.count()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NoteCell", for: indexPath) as? NoteListCell else { return UITableViewCell() }
        let data = noteManager.specify(indexPath)
        cell.displayData(data)

        return cell
    }
}

extension NoteListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        specifyNote = noteManager.specify(indexPath)
        noteDelegate?.deliverToDetail(specifyNote, first: false, index: indexPath)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        let deleteAction = UIContextualAction(style: .destructive, title:  "🗑", handler: { [self] (ac: UIContextualAction, view:UIView, success:(Bool) -> Void) in
            let removeData = self.noteManager.specify(indexPath)
            let alertViewController = UIAlertController(title: "Really?", message: "삭제하시겠어요?", preferredStyle: .alert)
            let delete = UIAlertAction(title: "삭제", style: .destructive) { _ in
                noteManager.delete(removeData)
            }
            let cancel = UIAlertAction(title: "취소", style: .cancel, handler: nil)
            
            alertViewController.addAction(delete)
            alertViewController.addAction(cancel)
            
            self.present(alertViewController, animated: true, completion: nil)
            success(true)
            
        })
        
        let shareAction = UIContextualAction(style: .normal, title:  "공유", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            let shardNote = "\(self.noteManager.specify(indexPath).title ?? "") \n\n \(self.noteManager.specify(indexPath).body ?? "")"
            let activityViewController = UIActivityViewController(activityItems: [shardNote], applicationActivities: nil)
            self.present(activityViewController, animated: true, completion: nil)
            success(true)
        })
        shareAction.backgroundColor = .systemTeal
        return UISwipeActionsConfiguration(actions:[deleteAction,shareAction])
    }
}

extension NoteListViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            self.tableView.insertRows(at: [newIndexPath ?? IndexPath(row: 0, section: 0)], with: .none)
        case .delete:
            self.tableView.deleteRows(at: [indexPath!], with: .none)
        case .move:
            self.tableView.deleteRows(at: [indexPath!], with: .none)
            self.tableView.insertRows(at: [newIndexPath!], with: .none)
        case .update:
            guard let cell = self.tableView.cellForRow(at: indexPath!) as? NoteListCell else { return }
            cell.displayData(noteManager.specify(indexPath!))
        @unknown default:
            alterError(CoreDataError.fetch("Unexpected NSFetchedResultsChangeType" as? Error).errorDescription)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
