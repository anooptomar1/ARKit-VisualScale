//
//  ViewController.swift
//  KnowYourShoeSizeAR
//
//  Created by Birapuram Kumar Reddy on 7/19/17.
//  Copyright © 2017 Myntra Design Pvt Ltd. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import AVFoundation

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var infoTitle: UILabel!
    @IBOutlet weak var infoDesc: UILabel!

    var planes:[UUID:Plane]!
    var detectedPlanes=[Plane]()
    var isScaleDrawn=false
    var x,y,z:Float!
    private let cell: Float = 0.05

    private var bandSizeInMeters=[CGFloat]() // will store the distance for the specific bands, 23.5 cm to 24.1 is UK 6
    private var bandNames=[String]() // will store the names of the bands UK5,UK6,UK7
    private let rootScaleNode=SCNNode()

    //used for pinch zoom
    let captureSession = AVCaptureSession()
    var captureDevice:AVCaptureDevice!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        planes=[UUID:Plane]()
        // Set the view's delegate
        sceneView.delegate = self
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        // Make things look pretty :)
        self.sceneView.antialiasingMode = SCNAntialiasingMode.multisampling4X;
        // This is the object that we add all of our geometry to, if you want to render something you need to add it here
        self.sceneView.scene = SCNScene();
        // as of now we use auto lighting
        sceneView.autoenablesDefaultLighting=false
        sceneView.automaticallyUpdatesLighting=false
        prepareBandsData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Create a session configuration
        let configuration = ARWorldTrackingSessionConfiguration()
        configuration.planeDetection = .horizontal
        // Run the view's session
        sceneView.debugOptions=[ARSCNDebugOptions.showFeaturePoints,.showCameras]
        sceneView.session.run(configuration)
        
        startAVCaprtureSession()
        //add pinch gesture
        let pinchGesture=UIPinchGestureRecognizer(target: self, action: #selector(ViewController.pinchRecognizer(pinchRec:)))
        view.addGestureRecognizer(pinchGesture)
    }

    @objc func pinchRecognizer(pinchRec:UIPinchGestureRecognizer) -> Void {
        let pinchVelocityDividerFactor:Float = 5.0
        if pinchRec.state == .changed {
            do{
                try captureDevice.lockForConfiguration()
                let desiredZoomFactor=Float(captureDevice.videoZoomFactor) + atan2f(Float(pinchRec.velocity),pinchVelocityDividerFactor)
                captureDevice.videoZoomFactor=CGFloat(max(Float(1.0), min(desiredZoomFactor, Float(captureDevice.activeFormat.videoMaxZoomFactor))))
                captureDevice.unlockForConfiguration()
            }catch{
                print("exception in lock/unlock configurations")
            }
        }
    }

    private func prepareBandsData(){
        /* this is the original band data for men in meters. as you can see the difference between UK 8 to UK 12 is in matter of few centimeters, it is very hard for the user to identifiy the exact band*/
        //bandSizeInMeters=[0.235,0.006,0.007,0.009,0.01,0.006,0.01,0.011]
        //for now, we will use some dummy data for POC.
        bandSizeInMeters=[0.06,0.08,0.05,0.07,0.08]
        bandNames=["UK 5","UK 6","UK 7","UK 8","UK 9","UK 10","UK 11","UK 12"]
    }
    
    func startAVCaprtureSession() {
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        let availableDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back).devices
        captureDevice = availableDevices.first
        beginSession()
    }
    
    func beginSession () {
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(captureDeviceInput)
        }catch {
            print(error.localizedDescription)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the view's session
        sceneView.session.pause()
    }
}


extension ViewController{
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard  let planeAnchor=anchor as? ARPlaneAnchor else {
            return
        }
        let plane=Plane(planeAnchor)
        detectedPlanes.append(plane)
        node.addChildNode(Plane(planeAnchor))
        DispatchQueue.main.async {
            self.infoTitle.text = "Great, we see a plane surface. Now touch anywhere on screen to place a marker"
            self.infoDesc.text = " "
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let anchor=anchor as? ARPlaneAnchor else {
            return
        }
        if let existingPlane=detectedPlanes.filter({
            (plane) in plane.anchor.identifier == anchor.identifier
        }).first {
            print("plane extents updated")
            existingPlane.update(anchor)
        }
    }
}

extension ViewController{
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let results = sceneView.hitTest(touch.location(in: sceneView), types: [ARHitTestResult.ResultType.existingPlaneUsingExtent])
        guard let hitFeature = results.last else { return }
        let hitTransform = SCNMatrix4.init(hitFeature.worldTransform)
        let hitPosition = SCNVector3Make(hitTransform.m41,hitTransform.m42,hitTransform.m43)
        if !isScaleDrawn{
            drawScale(hitPosition: hitPosition)
            isScaleDrawn=true
        }
    }
}

let bandWidth:CGFloat = 0.1
let bandHeight:CGFloat = 0.001
let dottedBoxWidth:CGFloat = 0.01
let dottedBoxHeight: CGFloat = 0.001
let dottedBoxLength: CGFloat = 0.001
extension ViewController {
    func drawScale(hitPosition:SCNVector3) {
        var index=0
        let x=hitPosition.x
        let y=hitPosition.y
        var z=hitPosition.z
        drawStartLines(mainNode: rootScaleNode, position:SCNVector3(x,y,z),width: 0.1,length: bandSizeInMeters[0],dottedLines: 10,text:"Start here")
        while index < bandSizeInMeters.count {
            let length=bandSizeInMeters[index]
            let bandBox:SCNBox!
            if index == 0 {
                bandBox=SCNBox(width: bandWidth, height: bandHeight, length: length, chamferRadius: 0)
                bandBox.firstMaterial?.diffuse.contents=UIColor(red: 185/255, green: 78/255, blue: 63/255, alpha: 0.5)
                bandBox.firstMaterial?.ambientOcclusion.contents=UIColor.red
                bandBox.firstMaterial?.transparent.contents=UIColor.red
            }else if index % 2 == 0 {
                bandBox=SCNBox(width: bandWidth, height: bandHeight, length: length, chamferRadius: 0)
                bandBox.firstMaterial?.diffuse.contents=UIColor(red: 228/255, green: 184/255, blue: 191/255, alpha: 0.8)
            }else{
                bandBox=SCNBox(width: bandWidth, height: bandHeight, length: length, chamferRadius: 0)
                bandBox.firstMaterial?.diffuse.contents=UIColor(red: 200/255, green: 166/255, blue: 154/255, alpha: 0.9)
            }
            bandBox.firstMaterial?.readsFromDepthBuffer=false
            bandBox.firstMaterial?.writesToDepthBuffer=false

            let bandNode = SCNNode(geometry: bandBox)
            bandNode.position = SCNVector3(x,y,z)
            rootScaleNode.addChildNode(bandNode)
            var dottedLines=0
            if index == 0 {
                 dottedLines=3
            }else{
                dottedLines=index*2+2
            }
            drawDottedLines(mainNode: rootScaleNode, position: bandNode.position,width: 0.1,length: length,dottedLines: dottedLines,text:bandNames[index])
            index=index+1
            if index < bandSizeInMeters.count {
                let currentLength=Float(length/2)
                let nextLength=Float(bandSizeInMeters[index]/2)
                z=z-currentLength-nextLength
            }
        }
        sceneView.scene.rootNode.addChildNode(rootScaleNode)
    }

    func drawDottedLines(mainNode:SCNNode,position:SCNVector3,width:CGFloat,length:CGFloat,dottedLines:Int,text:String){
        var index=0
        var x=position.x-Float(width/2)
        let z=position.z-Float(length/2)
        while(index < dottedLines){
            let box=SCNBox(width: dottedBoxWidth, height: dottedBoxHeight, length: dottedBoxLength, chamferRadius: 0.0)
            box.firstMaterial?.diffuse.contents=UIColor.white
            let node=SCNNode(geometry: box)
            node.position=SCNVector3(x,position.y,z)
            x=x-0.02 // gap between the dots
            index=index+1
            mainNode.addChildNode(node)
        }
        let newposition=SCNVector3(x, position.y, position.z)
        createTextNodes(node: mainNode, position: newposition, text: text)
    }
    
    func drawStartLines(mainNode:SCNNode,position:SCNVector3,width:CGFloat,length:CGFloat,dottedLines:Int,text:String){
        var index=0
        var x=position.x-Float(width/2)
        let z=position.z+Float(length/2)
        while(index < dottedLines){
            let box=SCNBox(width: dottedBoxWidth, height: dottedBoxHeight, length: dottedBoxLength, chamferRadius: 0.0)
            box.firstMaterial?.diffuse.contents=UIColor.white
            let node=SCNNode(geometry: box)
            node.position=SCNVector3(x,position.y,z)
            x=x-0.02 // gap between the dots
            index=index+1
            mainNode.addChildNode(node)
        }
        let newposition=SCNVector3(x, position.y, z)
        createTextNodes(node: mainNode, position: newposition, text: text)
    }
    
    func createTextNodes(node:SCNNode,position:SCNVector3,text:String,width:CGFloat=0.1,height:CGFloat=0.01,length:CGFloat=0.2){
        let textGeo = SCNText(string: text, extrusionDepth: 1.0)
        textGeo.firstMaterial?.diffuse.contents = UIColor.white
        textGeo.firstMaterial?.ambientOcclusion.contents=UIColor.white
        textGeo.firstMaterial?.transparent.contents=UIColor.white
        textGeo.font = UIFont.systemFont(ofSize: 6.0)
        textGeo.flatness=1.0
        
        let textNode = SCNNode(geometry: textGeo)
        textNode.position = SCNVector3(position.x, position.y,position.z+(0.03*position.z))
        textNode.eulerAngles = SCNVector3(-0.5*Double.pi,0.0,0.0)
        textNode.scale = SCNVector3(0.003,0.003,0.003)
        node.addChildNode(textNode)
    }
}

extension ViewController{
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .notAvailable:
            infoTitle.text = "Tracking status: Not available."
            infoDesc.text = "Tracking status has been unavailable for an extended time. Try resetting the session."
        case .limited(let reason):
             infoTitle.text="Tracking status: Limited."
             var message = "Tracking status has been limited for an extended time. "
            switch reason {
            case .excessiveMotion: message += "Try slowing down your movement, or reset the session."
            case .insufficientFeatures: message += "Try pointing at a flat surface, or reset the session."
            case .initializing:
                message += "initializing..."
             }
            infoDesc.text=message
        case .normal:
            infoTitle.text = "Tracking Status : Normal"
            infoDesc.text = "Tracking is normal"
        }
    }
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }

    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }
}
