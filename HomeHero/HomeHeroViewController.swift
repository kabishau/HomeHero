

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
    runSession()
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
  
  func runSession() {
    sceneView.delegate = self
    let configuration = ARWorldTrackingConfiguration()
    configuration.planeDetection = .horizontal
    configuration.isLightEstimationEnabled = true
    sceneView.session.run(configuration)
    
    #if DEBUG
      sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
    #endif
  }
  
  // this will add a new anchor in the hit result point
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    if let hit = sceneView.hitTest(viewCenter, types: [.existingPlaneUsingExtent]).first {
      sceneView.session.add(anchor: ARAnchor(transform: hit.worldTransform))
    }
  }
}

extension HomeHeroViewController: ARSCNViewDelegate {
  
  // rendering new planes
  func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    DispatchQueue.main.async {
      if let planeAnchor = anchor as? ARPlaneAnchor {
        #if DEBUG
          let planeNode = createPlaneNode(center: planeAnchor.center, extent: planeAnchor.extent)
          node.addChildNode(planeNode)
        #endif
      } else {
        switch self.currentMode {
        case .none:
          break
        case .placeObject(let name):
          let modelClone = nodeWithModelName(name)
          self.objects.append(modelClone)
          node.addChildNode(modelClone)
        case .measure:
          break
        }
      }
    }
  }
  
  // called when a corresponding ARAnchor is updated
  func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
    DispatchQueue.main.async {
      if let planeAnchor = anchor as? ARPlaneAnchor {
        updatePlaneNode(node.childNodes[0], center: planeAnchor.center, extent: planeAnchor.extent)
      }
    }
  }
  
  // called when ARAnchor is removed
  func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
    guard anchor is ARPlaneAnchor else { return }
    removeChildren(inNode: node)
  }








}
















