import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let imagePicker = UIImagePickerController()
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let userPickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.image = userPickedImage
            
            guard let ciimage = CIImage(image: userPickedImage) else {
                fatalError("Could not convert to CIImage")
            }
            detect(image: ciimage)
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
        
    }
    
    func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Loading coreML model failed")
        }
        
        let request = VNCoreMLRequest(model: model) {
            (request, error) in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Model failed to process image")
            }
            if let firstResult = results.first {
                print("confidence: \(firstResult.confidence)")
                let flowerName = firstResult.identifier.capitalized
                self.navigationItem.title = flowerName
                self.getWikipediaText(flowerName: flowerName)
//                if firstResult.identifier.contains("hotdog") {
//                    self.navigationItem.title = "HotDog!"
//                } else {
//                    self.navigationItem.title = "Not Hotdog!"
//                }
                
            }
            print(results)
            
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
        
    }
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    func getWikipediaText(flowerName: String) -> Void {
        let wikipediaUrl = "https://en.wikipedia.org/w/api.php"
        
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "1",
            "redirects" : "1",
            ]
        
        Alamofire.request(wikipediaUrl, method: .get, parameters: parameters).responseJSON {
            (response) in
            if response.result.isSuccess {
                print("Success! Got the wikipedia data!")
                print("json1: \(response.result.value!)")
                let json = JSON(response.result.value!)
                print("json2: \(json)")
                let pageId = json["query"]["pageids"][0].stringValue
                print("pageId: \(pageId)")
                let extract = json["query"]["pages"][pageId]["title"].stringValue
                print("extract: \(extract)")
                
            } else {
                print("Error \(response.result.error)")
                print("Connection Issues")
                
            }
        }
    }
    
}

