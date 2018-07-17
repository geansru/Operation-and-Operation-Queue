/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import CoreImage

let dataSourceURL = URL(string:"http://www.raywenderlich.com/downloads/ClassicPhotosDictionary.plist")!

class ListViewController: UITableViewController {
  var photos: [PhotoRecord] = []
  let pendingOperations = PendingOperations()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.title = "Classic Photos"
    fetchPhotoDetails()
  }
  
  // MARK: - Table view data source

  override func tableView(_ tableView: UITableView?, numberOfRowsInSection section: Int) -> Int {
    return photos.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "CellIdentifier", for: indexPath)

    if cell.accessoryView == nil {
      let indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
      cell.accessoryView = indicator
    }
    let indicator = cell.accessoryView as! UIActivityIndicatorView
    
    let record = photos[indexPath.row]
    cell.textLabel?.text = record.name
    cell.imageView?.image = record.image
    
    switch record.state {
    case .filtered:
      indicator.stopAnimating()

    case .failed:
      indicator.stopAnimating()
      cell.textLabel?.text = "Failed to load"
      
    case .new,
         .downloaded:
      indicator.startAnimating()
      if tableView.isDragging && tableView.isDragging {
        break
      }
      pendingOperations.startOperation(for: record, at: indexPath) { [weak self] in
        self?.tableView.reloadRows(at: [indexPath], with: .fade)
      }
    }

    return cell
  }

  private func fetchPhotoDetails() {
    let request = URLRequest(url: dataSourceURL)
    UIApplication.shared.isNetworkActivityIndicatorVisible = true
    let handler: (Data?, URLResponse?, Error?) -> Void = { [weak self] data, response, error in
      let alert = UIAlertController(title: "Ooops",
                                    message: "There was an error fetching photo details",
                                    preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default))

      defer {
        DispatchQueue.main.async {
          UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
      }

      guard let `self` = self else { return }

      guard let data = data else {
        if error != nil {
          DispatchQueue.main.async { self.present(alert, animated: true) }
        }
        return
      }
      
      do {
        let dataSourceDictionary = try PropertyListSerialization
        .propertyList(from: data, options: [], format: nil) as! [String: String]
        
        for (name, value) in dataSourceDictionary {
          guard let url = URL(string: value) else { continue }
          let photoRecord = PhotoRecord(name: name, url: url)
          self.photos.append(photoRecord)
        }
        
        DispatchQueue.main.async { self.tableView.reloadData() }
      } catch {
        DispatchQueue.main.async { self.present(alert, animated: true) }
      } // end of catch
    } // end of completion handler
    
    let task = URLSession(configuration: .default).dataTask(with: request, completionHandler: handler)
    task.resume()
  }
  
  private func loadImagesOnScreenCells() {
    guard let pathsArray = tableView.indexPathsForVisibleRows else { return }
    let toBeStarted = pendingOperations.getActive(for: pathsArray)
    for indexPath in toBeStarted {
      let record = photos[indexPath.row]
      pendingOperations.startOperation(for: record, at: indexPath) { [weak self] in
        self?.tableView.reloadRows(at: [indexPath], with: .fade)
      }
    }
  }

}
