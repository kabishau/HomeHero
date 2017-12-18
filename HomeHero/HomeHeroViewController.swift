

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
      return
    } else if let hit = sceneView.hitTest(viewCenter, types: [.featurePoint]).last {
      sceneView.session.add(anchor: ARAnchor(transform: hit.worldTransform))
      return
    }
  }
  
  // calculation logic of the distance between two measuring nodes
  func measure(fromNode: SCNNode, toNode: SCNNode) {
    let measuringLineNode = createLineNode(fromNode: fromNode, toNode: toNode)
    measuringLineNode.name = "MeasureingLine"
    sceneView.scene.rootNode.addChildNode(measuringLineNode)
    objects.append(measuringLineNode)
    let dist = fromNode.position.distanceTo(toNode.position)
    let measurementValue = String(format: "%.2f", dist)
    distanceLabel.text = "Distance: \(measurementValue) m"
  }
  
  // logic that will update measurement state depending on the number of spheres
  func updateMeasuringNodes() {
    guard measuringNodes.count > 1 else { return }
    let firstNode = measuringNodes[0]
    let secondNode = measuringNodes[1]
    
    let showMeasuring = self.measuringNodes.count == 2
    distanceLabel.isHidden = !showMeasuring
    if showMeasuring {
      measure(fromNode: firstNode, toNode: secondNode)
    } else if measuringNodes.count > 2 {
      firstNode.removeFromParentNode()
      secondNode.removeFromParentNode()
      measuringNodes.removeFirst(2)
      
      for node in sceneView.scene.rootNode.childNodes {
        if node.name == "MeasureingLine" {
          node.removeFromParentNode()
        }
      }
    }
  }
  
  // using the state information provided in ARFrame to let the user know when there are tracking problems
  func updateTrackingInfo() {
    guard let frame = sceneView.session.currentFrame else { return }
    
    switch frame.camera.trackingState {
    case .limited(let reason):
      switch reason {
      case .excessiveMotion:
        trackingInfo.text = "Limited Tracking: Excessive Motion"
      case .insufficientFeatures:
        trackingInfo.text = "Limited Tracking: Insufficient Details"
      default:
        trackingInfo.text = "Limited Tracking"
      }
    default:
      trackingInfo.text = ""
    }
    
    guard let lightEstimate = frame.lightEstimate?.ambientIntensity else { return }
    if lightEstimate < 100 {
      trackingInfo.text = "Limited Tracking: Too Dark"
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
          // node argument is an empty SCNNode that is automatically added to the scene by ARSCNView at a coordinate that corresponds to the anchor argument - attaching child planeNode to this empty node
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
          let sphereNode = createSphereNode(radius: 0.02)
          self.objects.append(sphereNode)
          node.addChildNode(sphereNode)
          self.measuringNodes.append(node)
        }
      }
    }
  }
  
  // called when a corresponding ARAnchor is updated
  func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
    DispatchQueue.main.async {
      if let planeAnchor = anchor as? ARPlaneAnchor {
        updatePlaneNode(node.childNodes[0], center: planeAnchor.center, extent: planeAnchor.extent)
      } else {
        self.updateMeasuringNodes()
      }
    }
  }
  
  // called when ARAnchor is removed
  func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
    guard anchor is ARPlaneAnchor else { return }
    removeChildren(inNode: node)
  }
  
  // updates tracking label for each rendered frame
  func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
    DispatchQueue.main.async {
      self.updateTrackingInfo()
      if let _ = self.sceneView.hitTest(self.viewCenter, types: [.existingPlaneUsingExtent]).first {
        self.crosshair.backgroundColor = UIColor.green
      } else {
        self.crosshair.backgroundColor = UIColor(white: 0.34, alpha: 1)
      }
    }
  }








}
















