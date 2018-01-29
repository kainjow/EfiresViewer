//
//  Created by Kevin Wojniak on 6/7/14.
//

import Cocoa

@NSApplicationMain class AppDelegate: NSObject, NSApplicationDelegate, NSTableViewDataSource {

    @IBOutlet weak var filesPopUp: NSPopUpButton!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var mainWindow: NSWindow!
    
    private var url: URL? = nil
    private var entries: [EfiresEntry] = []

    override func awakeFromNib() {
        DispatchQueue.global().async {
            let urls = EfiresFile.systemFileURLs()
            DispatchQueue.main.async {
                for url in urls {
                    let title = url.deletingPathExtension().lastPathComponent
                    let menuItem = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                    menuItem.representedObject = url
                    self.filesPopUp.menu?.addItem(menuItem)
                }
                self.filesPopUp.selectItem(at: -1)
                self.filesPopUp.isEnabled = true
            }
        }
    }
    
    @IBAction func selectedFile(_ sender: AnyObject) {
        self.url = filesPopUp.selectedItem?.representedObject as? URL
        DispatchQueue.global().async {
            let newEntries = EfiresFile.entriesAtURL(url: self.url!)
            DispatchQueue.main.async {
                self.entries = newEntries
                self.tableView.selectRowIndexes(IndexSet(), byExtendingSelection: false)
                self.tableView.reloadData()
                self.tableView.scrollToBeginningOfDocument(nil)
            }
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return entries.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return entries[row].name
    }
    
    @objc func tableViewSelectionDidChange(_ aNotification: Notification) {
        if tableView.numberOfSelectedRows != 1 {
            imageView.image = nil
        } else {
            let entry = entries[tableView.selectedRow]
            DispatchQueue.global().async {
                let image = EfiresFile.imageForEntry(entry: entry, url: self.url!)
                DispatchQueue.main.async {
                    if image != nil {
                        self.imageView.image = image
                    } else {
                        self.imageView.image = nil
                        print("Not an image: \(entry.name)")
                    }
                }
            }
        }
    }
    
    @IBAction func export(_ sender: AnyObject) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.beginSheetModal(for: self.mainWindow, completionHandler: { (returnCode) -> Void in
            if returnCode.rawValue == NSFileHandlingPanelOKButton {
                let url = openPanel.url
                for row in self.tableView.selectedRowIndexes {
                    let entry = self.entries[row]
                    if let data = EfiresFile.dataForEntry(entry: entry, url: self.url!) {
                        guard let entryURL = url?.appendingPathComponent(entry.name) else {
                            print("Error with entry url: \(entry.name)")
                            return
                        }
                        do {
                            try data.write(to: entryURL, options: .atomic);
                        } catch {
                            print("Failed to write \(entry.name): \(error)")
                        }
                    }
                }
            }
        })
    }
    
    @objc func exportMenuEnabled() -> Bool {
        return self.tableView.numberOfSelectedRows != 0
    }
}
