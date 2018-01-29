//
//  Created by Kevin Wojniak on 6/7/14.
//

import Cocoa

extension FileHandle {
    private func readBytes(_ count: Int) -> [UInt8]? {
        let dat = readData(ofLength: count) as NSData
        if dat.length != count {
            print("Can't read bytes.")
            return nil
        }
        var bytes = [UInt8](repeating: 0, count: count)
        dat.getBytes(&bytes, length: dat.length)
        return bytes
    }
    
    fileprivate func readASCIIString(_ count: Int) -> String? {
        if let vals = readBytes(count) {
            var s = ""
            for v in vals {
                guard let uni = UnicodeScalar(UInt32(v)) else {
                    break
                }
                if uni.value == 0 {
                    break
                }
                s += String(uni)
            }
            return s
        }
        return nil
    }
    
    fileprivate func readLittle16() -> UInt16? {
        var val: UInt16 = 0
        let size = MemoryLayout.size(ofValue: val)
        let dat = readData(ofLength: size) as NSData
        if dat.length != size {
            return nil
        }
        dat.getBytes(&val, length: size)
        return val.littleEndian
    }
    
    fileprivate func readLittle32() -> UInt32? {
        var val: UInt32 = 0
        let size = MemoryLayout.size(ofValue: val)
        let dat = readData(ofLength: size) as NSData
        if dat.length != size {
            return nil
        }
        dat.getBytes(&val, length: size)
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
    class func entriesAtURL(url: URL) -> [EfiresEntry] {
        guard let file = try? FileHandle(forReadingFrom: url) else {
            print("Can't open file.")
            return []
        }
        
        if file.readLittle16() == nil {
            print("Bad version.")
            return []
        }
        
        let count = file.readLittle16()
        if count == nil || count == 0 {
            print("No files")
            return []
        }
        
        var entries: [EfiresEntry] = []
        for _ in 0 ..< count! {
            let name = file.readASCIIString(64)
            let offset = file.readLittle32()
            let length = file.readLittle32()
            if name == nil || offset == nil || length == nil {
                print("Can't read entry.")
                return []
            }

            entries.append(EfiresEntry(name: name!, offset: offset!, length: length!))
        }
        
        return entries
    }
    
    class func dataForEntry(entry: EfiresEntry, url: URL) -> Data? {
        guard let file = try? FileHandle(forReadingFrom: url) else {
            return nil
        }
        file.seek(toFileOffset: UInt64(entry.offset))
        return file.readData(ofLength: Int(entry.length))
    }
    
    class func imageForEntry(entry: EfiresEntry, url: URL) -> NSImage? {
        guard let data = dataForEntry(entry: entry, url: url) else {
            return nil
        }
        return NSImage(data: data)
    }
    
    class func systemFileURLs() -> [URL] {
        let parentURL = URL(fileURLWithPath: "/usr/standalone/i386/EfiLoginUI")
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(at: parentURL, includingPropertiesForKeys: [], options: FileManager.DirectoryEnumerationOptions.init(rawValue: 0)) else {
            return []
        }
        var urls: [URL] = []
        for fileURL in contents {
            if !entriesAtURL(url: fileURL).isEmpty {
                urls.append(fileURL)
            }
        }
        return urls
    }
}
