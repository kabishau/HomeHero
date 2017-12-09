

import UIKit
import ARKit

enum FunctionMode {
  case none
  case placeObject(String)
  case measure
}

class HomeHeroViewController: UIViewController {
  
  @IBOutlet var sceneView: ARSCNView!
  @IBOutlet weak var chairButton: UIButton!
  @IBOutlet weak var candleButton: UIButton!
  @IBOutlet weak var measureButton: UIButton!
  @IBOutlet weak var vaseButton: UIButton!
  @IBOutlet weak var distanceLabel: UILabel!
  @IBOutlet weak var crosshair: UIView!
  @IBOutlet weak var messageLabel: UILabel!
  @IBOutlet weak var trackingInfo: UILabel!
  
  var currentMode: FunctionMode = .none
  var objects: [SCNNode] = []
  var measuringNodes: [SCNNode] = []
  
  override func viewDidLoad() {
    super.viewDidLoad()
    trackingInfo.text = ""
    messageLabel.text = ""
    distanceLabel.isHidden = true
    selectVase()
  }
  
  @IBAction func didTapChair(_ sender: Any) {
    currentMode = .placeObject("Models.scnassets/chair/chair.scn")
    selectButton(chairButton)
  }
  
  @IBAction func didTapCandle(_ sender: Any) {
    currentMode = .placeObject("Models.scnassets/candle/candle.scn")
    selectButton(candleButton)
  }
  
  @IBAction func didTapMeasure(_ sender: Any) {
    currentMode = .measure
    selectButton(measureButton)
  }
  
  @IBAction func didTapVase(_ sender: Any) {
    selectVase()
  }
  
  @IBAction func didTapReset(_ sender: Any) {
    removeAllObjects()
    distanceLabel.text = ""
  }
  
  func selectVase() {
    currentMode = .placeObject("Models.scnassets/vase/vase.scn")
    selectButton(vaseButton)
  }
  
  func selectButton(_ button: UIButton) {
    unselectAllButtons()
    button.isSelected = true
  }
  
  func unselectAllButtons() {
    [chairButton, candleButton, measureButton, vaseButton].forEach {
      $0?.isSelected = false
    }
  }
  
  func removeAllObjects() {
    for object in objects {
      object.removeFromParentNode()
    }
    
    objects = []
  }
}
