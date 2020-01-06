// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Foundation

class FileReader {
    enum Error: Swift.Error {
        case urlNotFileSystemRepresentable
        case openFailure(errno: Int32)
        case seekFailure(errno: Int32)
        case readFailure(errno: Int32)
        case closed
    }

    private var _fileDescriptor: Int32?

    init(fileURL: URL) throws {
        let openResult: Int32 = try fileURL.withUnsafeFileSystemRepresentation { filePathPtr in
            guard let filePathPtr = filePathPtr else { throw Error.urlNotFileSystemRepresentable }
            // man open -s2
            return Darwin.open(filePathPtr, Darwin.O_RDONLY)
        }
        guard openResult >= 0 else {
            throw Error.openFailure(errno: errno)
        }
        _fileDescriptor = openResult
    }

    deinit {
        close()
    }

    func seekToEndOfFile() throws -> Int64 {
        guard let fileDescriptor = _fileDescriptor else { throw Error.closed }
        // man lseek -s2
        let seekResult = Darwin.lseek(fileDescriptor, 0, Darwin.SEEK_END)
        guard seekResult >= 0 else { throw Error.seekFailure(errno: errno) }
        return seekResult
    }

    func seek(toFileOffset offset: Int64) throws -> Int64 {
        guard let fileDescriptor = _fileDescriptor else { throw Error.closed }
        // man lseek -s2
        let seekResult = Darwin.lseek(fileDescriptor, offset, Darwin.SEEK_SET)
        guard seekResult >= 0 else { throw Error.seekFailure(errno: errno) }
        return seekResult
    }

    func read(into buffer: UnsafeMutableRawBufferPointer) throws -> UnsafeRawBufferPointer? {
        guard let fileDescriptor = _fileDescriptor else { throw Error.closed }
        var readResult: Int
        repeat {
            // man read -s2
            readResult = Darwin.read(fileDescriptor, buffer.baseAddress, buffer.count)
            // swiftformat:disable:next andOperator
        } while readResult < 0 && EINTR == errno
        guard readResult >= 0 else { throw Error.readFailure(errno: errno) }
        if readResult == 0 {
            return nil
        }
        return UnsafeRawBufferPointer(rebasing: buffer[0 ..< readResult])
    }

    func read(count: Int) throws -> Data? {
        guard let fileDescriptor = _fileDescriptor else { throw Error.closed }
        var data = Data(count: count)
        let readResult: Int = data.withUnsafeMutableBytes {
            var readResult: Int
            repeat {
                // man read -s2
                readResult = Darwin.read(fileDescriptor, $0.baseAddress, $0.count)
            } while readResult < 0 && EINTR == errno
            return readResult
        }
        guard readResult >= 0 else { throw Error.readFailure(errno: errno) }
        if readResult == 0 {
            return nil
        }
        data.count = readResult
        return data
    }

    func close() {
        if let fileDescriptor = _fileDescriptor {
            // man close -s2
            Darwin.close(fileDescriptor)
            _fileDescriptor = nil
        }
    }
}

class FileWriter {
    enum Error: Swift.Error {
        case urlNotFileSystemRepresentable
        case openFailure(errno: Int32)
        case writeFailure(errno: Int32)
        case closed
    }

    private var _fileDescriptor: Int32?

    init(fileURL: URL) throws {
        let openResult: Int32 = try fileURL.withUnsafeFileSystemRepresentation { filePathPtr in
            guard let filePathPtr = filePathPtr else { throw Error.urlNotFileSystemRepresentable }
            // man open -s2
            return Darwin.open(filePathPtr, Darwin.O_WRONLY | Darwin.O_CREAT | Darwin.O_EXCL)
        }
        guard openResult >= 0 else { throw Error.openFailure(errno: errno) }
        let fileDescriptor = openResult
        guard Darwin.fchmod(fileDescriptor, Darwin.S_IRUSR | Darwin.S_IWUSR) == 0 else {
            let fchmodErrno = errno
            // man close -s2
            Darwin.close(fileDescriptor)
            throw Error.openFailure(errno: fchmodErrno)
        }
        _fileDescriptor = fileDescriptor
    }

    deinit {
        close()
    }

    func write(buffer: UnsafeRawBufferPointer) throws {
        guard let fileDescriptor = _fileDescriptor else { throw Error.closed }
        var writeResult: Int
        repeat {
            // man write -s2
            writeResult = Darwin.write(fileDescriptor, buffer.baseAddress, buffer.count)
            // swiftformat:disable:next andOperator
        } while writeResult < 0 && EINTR == errno
        guard writeResult >= 0 else { throw Error.writeFailure(errno: errno) }
    }

    func write(buffer: UnsafeMutableRawBufferPointer) throws {
        try buffer.withUnsafeBytes {
            try write(buffer: $0)
        }
    }

    func write(data: Data) throws {
        try data.withUnsafeBytes {
            try write(buffer: $0)
        }
    }

    func close() {
        if let fileDescriptor = _fileDescriptor {
            // man close -s2
            Darwin.close(fileDescriptor)
            _fileDescriptor = nil
        }
    }
}
