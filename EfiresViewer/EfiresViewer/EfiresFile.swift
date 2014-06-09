//
//  Created by Kevin Wojniak on 6/7/14.
//

import Cocoa

extension NSFileHandle {
    func readBytes(count: Int) -> UInt8[]? {
        let dat: NSData? = readDataOfLength(count)
        if dat?.length != count {
            println("Can't read bytes.")
            return nil
        }
        var bytes = UInt8[](count: count, repeatedValue: 0)
        dat!.getBytes(&bytes, length: dat!.length)
        return bytes
    }
    
    func readASCIIString(count: Int) -> String? {
        if let vals = readBytes(count) {
            var s = ""
            for v in vals {
                let uni = UnicodeScalar(UInt32(v))
                if !uni.isPrint() {
                    break
                }
                s += String(uni)
            }
            return s
        }
        return nil
    }
    
    func readLittle16() -> UInt16? {
        if let vals = readBytes(sizeof(UInt16)) {
            var r: UInt16 = 0
            r |= UInt16(vals[1]) << 8
            r |= UInt16(vals[0])
            return r
        }
        return nil
    }
    
    func readLittle32() -> UInt32? {
        if let vals = readBytes(sizeof(UInt32)) {
            var r: UInt32 = 0
            r |= UInt32(vals[3]) << 24
            r |= UInt32(vals[2]) << 16
            r |= UInt32(vals[1]) << 8
            r |= UInt32(vals[0])
            return r
        }
        return nil
    }
}

class EfiresEntry {
    let name: String
    let offset: UInt32
    let length: UInt32
    init(name: String, offset: UInt32, length: UInt32) {
        self.name = name
        self.offset = offset
        self.length = length
    }
}

class EfiresFile {
    class func entriesAtPath(path: String) -> EfiresEntry[]? {
        let url = NSURL.fileURLWithPath(path)
        let file: NSFileHandle? = NSFileHandle.fileHandleForReadingFromURL(url, error: nil)
        if !file {
            println("Can't open file.")
            return nil
        }
        
        if file!.readLittle16() == nil {
            println("Bad version.")
            return nil
        }
        
        let count = file!.readLittle16()
        if !count || count? == 0 {
            println("No files")
            return nil
        }
        
        var entries: EfiresEntry[] = []
        for _ in 0..count! {
            let name = file!.readASCIIString(64)
            let offset = file!.readLittle32()
            let length = file!.readLittle32()
            if !name || !offset || !length {
                println("Can't read entry.")
                return nil
            }

            entries.append(EfiresEntry(name: name!, offset: offset!, length: length!))
        }
        
        return entries
    }
    
    class func imageForEntry(entry: EfiresEntry, path: String) -> NSImage? {
        let url = NSURL.fileURLWithPath(path)
        let file: NSFileHandle? = NSFileHandle.fileHandleForReadingFromURL(url, error: nil)
        if !file {
            return nil
        }
        file!.seekToFileOffset(CUnsignedLongLong(entry.offset))
        return NSImage(data: file!.readDataOfLength(Int(entry.length)))
    }
    
    class func systemFilePaths() -> String[] {
        var parentDir = "/usr/standalone/i386/EfiLoginUI"
        var fm = NSFileManager.defaultManager()
        var contents = fm.contentsOfDirectoryAtPath(parentDir, error: nil) as String[]
        var paths: String[] = []
        for fileName in contents {
            var path = parentDir.stringByAppendingPathComponent(fileName)
            if let entries = entriesAtPath(path) {
                paths.append(path)
            }
        }
        return paths
    }
}
