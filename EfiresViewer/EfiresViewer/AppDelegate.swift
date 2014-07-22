//
//  Created by Kevin Wojniak on 6/7/14.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate, NSTableViewDataSource {

    @IBOutlet var filesPopUp : NSPopUpButton!
    @IBOutlet var tableView : NSTableView!
    @IBOutlet var imageView : NSImageView!
    
    var path: String? = nil
    var entries: [EfiresEntry]? = nil

    override func awakeFromNib() {
        dispatch_async(dispatch_get_global_queue(0, 0), {
            var paths = EfiresFile.systemFilePaths()
            dispatch_async(dispatch_get_main_queue(), {
                for path in paths {
                    var menuItem = NSMenuItem(title: path.lastPathComponent.stringByDeletingPathExtension, action: nil, keyEquivalent: "")
                    menuItem.representedObject = path
                    self.filesPopUp.menu.addItem(menuItem)
                }
                self.filesPopUp.selectItemAtIndex(-1)
                self.filesPopUp.enabled = true
            })
        })
    }
    
    @IBAction func selectedFile(sender: AnyObject!) {
        path = filesPopUp.selectedItem.representedObject as? String
        dispatch_async(dispatch_get_global_queue(0, 0), {
            var newEntries = EfiresFile.entriesAtPath(self.path!)
            dispatch_async(dispatch_get_main_queue(), {
                self.entries = newEntries
                self.tableView.selectRowIndexes(NSIndexSet(), byExtendingSelection: false)
                self.tableView.reloadData()
                self.tableView.scrollToBeginningOfDocument(nil)
            })
        })
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(theApp: NSApplication!) -> Bool {
        return true;
    }
    
    func numberOfRowsInTableView(aTableView: NSTableView!) -> Int {
        return !entries ? 0 : entries!.count
    }
    
    func tableView(aTableView: NSTableView!, objectValueForTableColumn aTableColumn: NSTableColumn!, row rowIndex: Int) -> AnyObject! {
        return entries![rowIndex].name
    }
    
    func tableViewSelectionDidChange(aNotification: NSNotification?) {
        if tableView.numberOfSelectedRows == 0 {
            imageView.image = nil
        } else {
            var entry = entries![tableView.selectedRow]
            dispatch_async(dispatch_get_global_queue(0, 0), {
                var image = EfiresFile.imageForEntry(entry, path: self.path!)
                dispatch_async(dispatch_get_main_queue(), {
                    if image {
                        self.imageView.image = image
                    } else {
                        self.imageView.image = nil
                        println("Not an image: \(entry.name)")
                    }
                })
            })
        }
    }
}
