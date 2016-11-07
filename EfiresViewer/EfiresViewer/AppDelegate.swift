//
//  Created by Kevin Wojniak on 6/7/14.
//

import Cocoa

@NSApplicationMain class AppDelegate: NSObject, NSApplicationDelegate, NSTableViewDataSource {

    @IBOutlet weak var filesPopUp: NSPopUpButton!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var mainWindow: NSWindow!
    
    var url: NSURL? = nil
    var entries: [EfiresEntry]? = nil

    override func awakeFromNib() {
        dispatch_async(dispatch_get_global_queue(0, 0), {
            let urls = EfiresFile.systemFileURLs()
            dispatch_async(dispatch_get_main_queue(), {
                for url in urls {
                    let title = url.URLByDeletingPathExtension?.lastPathComponent
                    let menuItem = NSMenuItem(title: title!, action: nil, keyEquivalent: "")
                    menuItem.representedObject = url
                    self.filesPopUp.menu?.addItem(menuItem)
                }
                self.filesPopUp.selectItemAtIndex(-1)
                self.filesPopUp.enabled = true
            })
        })
    }
    
    @IBAction func selectedFile(sender: AnyObject!) {
        self.url = filesPopUp.selectedItem?.representedObject as? NSURL
        dispatch_async(dispatch_get_global_queue(0, 0), {
            let newEntries = EfiresFile.entriesAtURL(self.url!)
            dispatch_async(dispatch_get_main_queue(), {
                self.entries = newEntries
                self.tableView.selectRowIndexes(NSIndexSet(), byExtendingSelection: false)
                self.tableView.reloadData()
                self.tableView.scrollToBeginningOfDocument(nil)
            })
        })
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(theApp: NSApplication) -> Bool {
        return true;
    }
    
    func numberOfRowsInTableView(aTableView: NSTableView) -> Int {
        return entries == nil ? 0 : entries!.count
    }
    
    func tableView(aTableView: NSTableView, objectValueForTableColumn aTableColumn: NSTableColumn?, row rowIndex: Int) -> AnyObject? {
        return entries![rowIndex].name
    }
    
    func tableViewSelectionDidChange(aNotification: NSNotification?) {
        if tableView.numberOfSelectedRows != 1 {
            imageView.image = nil
        } else {
            let entry = entries![tableView.selectedRow]
            dispatch_async(dispatch_get_global_queue(0, 0), {
                let image = EfiresFile.imageForEntry(entry, url: self.url!)
                dispatch_async(dispatch_get_main_queue(), {
                    if image != nil {
                        self.imageView.image = image
                    } else {
                        self.imageView.image = nil
                        print("Not an image: \(entry.name)")
                    }
                })
            })
        }
    }
    
    @IBAction func export(sender: AnyObject!) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.beginSheetModalForWindow(self.mainWindow, completionHandler: { (returnCode) -> Void in
            if returnCode == NSFileHandlingPanelOKButton {
                let url = openPanel.URL
                for row in self.tableView.selectedRowIndexes {
                    let entry = self.entries![row]
                    if let data = EfiresFile.dataForEntry(entry, url: self.url!) {
                        let entryURL = url?.URLByAppendingPathComponent(entry.name)
                        if data.writeToURL(entryURL!, atomically:true) == false {
                            print("Failed to write \(entry.name)")
                        }
                    }
                }
            }
        })
    }
    
    func exportMenuEnabled() -> Bool {
        return self.tableView.numberOfSelectedRows != 0
    }
}
