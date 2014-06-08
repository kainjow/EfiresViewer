//
//  Created by Kevin Wojniak on 6/7/14.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate, NSTableViewDataSource {

    @IBOutlet var filesPopUp : NSPopUpButton
    @IBOutlet var tableView : NSTableView
    @IBOutlet var imageView : NSImageView
    
    var path: String? = nil
    var entries: EfiresEntry[]? = nil

    override func awakeFromNib() {
        filesPopUp.removeAllItems()
        for path in EfiresFile.systemFilePaths() {
            var menuItem = NSMenuItem(title: path.lastPathComponent.stringByDeletingPathExtension, action: nil, keyEquivalent: "")
            menuItem.representedObject = path
            filesPopUp.menu.addItem(menuItem)
        }
        filesPopUp.selectItemAtIndex(-1)
    }
    
    @IBAction func selectedFile(sender: AnyObject!) {
        path = filesPopUp.selectedItem.representedObject as? String
        entries = EfiresFile.entriesAtPath(path!)
        tableView.selectRowIndexes(NSIndexSet(), byExtendingSelection: false)
        tableView.reloadData()
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
            imageView.image = EfiresFile.imageForEntry(entry, path: path!)
        }
    }
}
