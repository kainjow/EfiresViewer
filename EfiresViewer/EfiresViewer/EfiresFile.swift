//
//  Created by Kevin Wojniak on 6/7/14.
//

import Cocoa

extension NSFileHandle {
    func readBytes(count: Int) -> [UInt8]? {
        let dat: NSData? = readDataOfLength(count)
        if dat?.length != count {
            print("Can't read bytes.")
            return nil
        }
        var bytes = [UInt8](count: count, repeatedValue: 0)
        dat!.getBytes(&bytes, length: dat!.length)
        return bytes
    }
    
    func readASCIIString(count: Int) -> String? {
        if let vals = readBytes(count) {
            var s = ""
            for v in vals {
                let uni = UnicodeScalar(UInt32(v))
                if uni.value == 0 {
                    break
                }
                s += String(uni)
            }
            return s
        }
        return nil
    }
    
    func readLittle16() -> UInt16? {
        let dat: NSData? = readDataOfLength(sizeof(UInt16));
        if dat?.length != sizeof(UInt16) {
            return nil
        }
        var val: UInt16 = 0
        dat!.getBytes(&val, length: sizeof(UInt16))
        return val.littleEndian
    }
    
    func readLittle32() -> UInt32? {
        let dat: NSData? = readDataOfLength(sizeof(UInt32));
        if dat?.length != sizeof(UInt32) {
            return nil
        }
        var val: UInt32 = 0
        dat!.getBytes(&val, length: sizeof(UInt32))
        return val.littleEndian
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
    class func entriesAtURL(url: NSURL) -> [EfiresEntry] {
        let file: NSFileHandle? = try? NSFileHandle(forReadingFromURL: url)
        if file == nil {
            print("Can't open file.")
            return []
        }
        
        if file!.readLittle16() == nil {
            print("Bad version.")
            return []
        }
        
        let count = file!.readLittle16()
        if count == nil || count == 0 {
            print("No files")
            return []
        }
        
        var entries: [EfiresEntry] = []
        for _ in 0 ..< count! {
            let name = file!.readASCIIString(64)
            let offset = file!.readLittle32()
            let length = file!.readLittle32()
            if name == nil || offset == nil || length == nil {
                print("Can't read entry.")
                return []
            }

            entries.append(EfiresEntry(name: name!, offset: offset!, length: length!))
        }
        
        return entries
    }
    
    class func dataForEntry(entry: EfiresEntry, url: NSURL) -> NSData? {
        let file: NSFileHandle? = try? NSFileHandle(forReadingFromURL: url)
        if file == nil {
            return nil
        }
        file!.seekToFileOffset(CUnsignedLongLong(entry.offset))
        return file!.readDataOfLength(Int(entry.length))
    }
    
    class func imageForEntry(entry: EfiresEntry, url: NSURL) -> NSImage? {
        let data = dataForEntry(entry, url: url)
        if data == nil {
            return nil
        }
        return NSImage(data: data!)
    }
    
    class func systemFileURLs() -> [NSURL] {
        let parentURL = NSURL(fileURLWithPath: "/usr/standalone/i386/EfiLoginUI")
        let fm = NSFileManager.defaultManager()
        let contents = (try! fm.contentsOfDirectoryAtURL(parentURL, includingPropertiesForKeys:[], options: NSDirectoryEnumerationOptions(rawValue: 0)))
        var urls: [NSURL] = []
        for fileURL in contents {
            if !entriesAtURL(fileURL).isEmpty {
                urls.append(fileURL)
            }
        }
        return urls
    }
}
