import UIKit

enum PhotoRecordState {

    case new, downloaded, filtered, failed

}

final class PhotoRecord {
    
    let name: String
    let url: URL
    var state: PhotoRecordState = .new
    var image: UIImage = #imageLiteral(resourceName: "Placeholder")
    
    init(name: String, url: URL) {
        self.name = name
        self.url = url
    }

}

final class PendingOperations {
    
    private lazy var downloadsInProgress: [IndexPath: Operation] = [:]
    private lazy var downloadQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "Download queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    private lazy var filtrationsInProgress: [IndexPath: Operation] = [:]
    private lazy var filtrationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "Image filtration queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    func suspendAllOperations() {
        downloadQueue.isSuspended = true
        filtrationQueue.isSuspended = true
    }

    func resumeAllOperations() {
        downloadQueue.isSuspended = false
        filtrationQueue.isSuspended = false
    }

    
    func startOperation(for record: PhotoRecord,
                        at indexPath: IndexPath,
                        completion: @escaping ()->()) {
        switch record.state {
        case .new:
            startDownload(for: record, at: indexPath, completion: completion)
            
        case .downloaded:
            startFiltration(for: record, at: indexPath, completion: completion)
            
        default:
            print("Do nothing")
        }
    }

    func getActive(for screenCells: [IndexPath]) -> [IndexPath] {
        var allOperations = Set(downloadsInProgress.keys)
        allOperations.formUnion(filtrationsInProgress.keys)
        
        var toBeCancelled = allOperations
        let visible = Set(screenCells)
        toBeCancelled.subtract(visible)
        
        var toBeStarted = visible
        toBeStarted.subtract(allOperations)

        for index in toBeCancelled {
            downloadsInProgress[index]?.cancel()
            downloadsInProgress.removeValue(forKey: index)
            
            filtrationsInProgress[index]?.cancel()
            filtrationsInProgress.removeValue(forKey: index)
        }
        
        return Array(toBeStarted)
    }

    private func startDownload(for record: PhotoRecord,
                               at indexPath: IndexPath,
                               completion: @escaping ()->()) {
        guard downloadsInProgress[indexPath] == nil else { return }
        
        let downloader = ImageDownloader(photoRecord: record)
        let completion = {
            if downloader.isCancelled {
                return
            }
            
            DispatchQueue.main.async {
                self.downloadsInProgress.removeValue(forKey: indexPath)
                completion()
            }
        }
        downloader.completionBlock = completion
        
        downloadsInProgress[indexPath] = downloader
        downloadQueue.addOperation(downloader)
    }
    
    private func startFiltration(for record: PhotoRecord,
                                 at indexPath: IndexPath,
                                 completion: @escaping ()->()) {
        guard filtrationsInProgress[indexPath] == nil else { return }
        
        let filter = ImageFiltration(photoRecord: record)
        let completion = {
            if filter.isCancelled {
                return
            }
            
            DispatchQueue.main.async {
                self.filtrationsInProgress.removeValue(forKey: indexPath)
                completion()
            }
        }
        filter.completionBlock = completion
        
        filtrationsInProgress[indexPath] = filter
        filtrationQueue.addOperation(filter)
    }

}

final class ImageDownloader: Operation {

    private let photoRecord: PhotoRecord
    
    init(photoRecord: PhotoRecord) {
        self.photoRecord = photoRecord
    }

    override func main() {
        if isCancelled {
            return
        }
        
        guard let imageData = try? Data(contentsOf: photoRecord.url) else { return }

        if isCancelled {
            return
        }
        
        guard let image = UIImage(data: imageData) else {
            photoRecord.state = .failed
            photoRecord.image = #imageLiteral(resourceName: "Failed")
            return
        }

        photoRecord.image = image
        photoRecord.state = .downloaded
    }
    
}

final class ImageFiltration: Operation {
    
    private let photoRecord: PhotoRecord
    
    init(photoRecord: PhotoRecord) {
        self.photoRecord = photoRecord
    }

    override func main() {
        if isCancelled {
            return
        }

        guard photoRecord.state == .downloaded else { return }

        if isCancelled {
            return
        }

        guard let filtered = applySepiaFilter(to: photoRecord.image) else { return }

        photoRecord.image = filtered
        photoRecord.state = .filtered
    }

    private func applySepiaFilter(to image: UIImage) -> UIImage? {
        guard let data = UIImagePNGRepresentation(image) else { return nil }
        let inputImage = CIImage(data: data)

        if isCancelled {
            return nil
        }

        let context = CIContext(options: nil)
        guard let filter = CIFilter(name: "CISepiaTone") else { return nil }
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(0.8, forKey: "inputIntensity")
        
        if isCancelled {
            return nil
        }

        guard
            let outputImage = filter.outputImage,
            let outImage = context.createCGImage(outputImage, from: outputImage.extent)
        else {
            return nil
        }
        return UIImage(cgImage: outImage)
    }

}
