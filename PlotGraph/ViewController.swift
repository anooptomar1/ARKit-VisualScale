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

let Inches:CGFloat=39.3701

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    var planes:[UUID:Plane]!
    var vector1,vector2:SCNVector3!
    var vectorArray:[SCNVector3]?
    var isScalePlaced=false
    var x,y,z:Float!
    private let cell: Float = 0.05
    private var lengthArray=[CGFloat]()
    private var sizetextArray=[String]()
    private let scaleNode=SCNNode()
    
    
    let captureSession = AVCaptureSession()
    var captureDevice:AVCaptureDevice!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        planes=[UUID:Plane]()
        vectorArray=[SCNVector3]()
        // Set the view's delegate
        sceneView.delegate = self
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        // Make things look pretty :)
        self.sceneView.antialiasingMode = SCNAntialiasingMode.multisampling4X;
        // This is the object that we add all of our geometry to, if you want to render something you need to add it here
        self.sceneView.scene = SCNScene();
        //        self.sceneView.scene = SCNScene(named: "art.scnassets/ship .scn")!
        // as of now we use auto lighting
        sceneView.autoenablesDefaultLighting=false
        sceneView.automaticallyUpdatesLighting=false
//        lengthArray=[0.235,0.006,0.007,0.009,0.01,0.006,0.01,0.011]
        lengthArray=[0.06,0.08,0.05,0.07,0.08]
        sizetextArray=["UK 5","UK 6","UK 7","UK 8","UK 9","UK 10","UK 11","UK 12"]
//        sizetextArray=["<","6","7","8","9","10","11","12"]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Create a session configuration
        let configuration = ARWorldTrackingSessionConfiguration()
        configuration.planeDetection = .horizontal
        // Run the view's session
        sceneView.debugOptions=[ARSCNDebugOptions.showFeaturePoints,.showCameras]
        sceneView.session.run(configuration)
        
        prepareCamera()
        
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
    
    func prepareCamera() {
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

extension ViewController:ARSessionDelegate{
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Do something with the new transform
        let currentTransform = frame.camera.transform
//        scaleNode.transform=SCNMatrix4FromMat4(currentTransform)
//        scaleNode.eulerAngles=SCNVector3FromFloat3(frame.camera.eulerAngles)
//        doSomething(with: currentTransform)
    }
}

extension ViewController{
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        print("Camera state \(camera.trackingState)")
        // print(sceneView.scene.rootNode.childNodes)
    }
    
    
}

extension ViewController{
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let anchor=anchor as? ARPlaneAnchor else {
            return
        }
        // get center of the plane
        self.x = anchor.center.x + node.position.x
        self.y = anchor.center.y + node.position.y
        self.z = anchor.center.z + node.position.z
        
//        let plane=Plane(with: anchor)
//        planes[anchor.identifier]=plane
//        node.addChildNode(plane)
        
        //        for i in 0...10 {
        //            addLine(to: node, cell * Float(5), 0.01, 0.01, 1, 0, Float(i))
        //        }
        
        guard let config=sceneView.session.configuration as? ARWorldTrackingSessionConfiguration else{
            return
        }
        //config.planeDetection=ARWorldTrackingSessionConfiguration.PlaneDetection(rawValue: 0)
        //sceneView.session.run(config)
        let alert=UIAlertController(title: "Plane Detected", message: "", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK",
                                         style: .cancel, handler: nil)
        
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
//        guard let anchor=anchor as? ARPlaneAnchor else {
//            return
//        }
//        if let plane=planes[anchor.identifier]{
//            plane.updatePlane(anchor: anchor)
//        }
    }
}


extension ViewController{
    private func addLine(to node: SCNNode, _ w: Float, _ h: Float, _ l: Float, _ x: Float, _ y: Float, _ z: Float) {
        let line = SCNBox(width: CGFloat(w), height: CGFloat(h), length: CGFloat(l), chamferRadius: 0)
        let matrix = SCNMatrix4Translate(translate(x - 0.5, y, z - 0.5), w / 2, h / 2, -l / 2)
        //        let matrix = SCNMatrix4Translate(translate(0.5-x, y, 0.5-z), w / 2, h / 2, -l / 2)
        node.addChildNode(createNode(line, matrix, UIColor.random()))
    }
    
    private func createNode(_ geometry: SCNGeometry, _ matrix: SCNMatrix4, _ color: UIColor) -> SCNNode {
        let material = SCNMaterial()
        material.diffuse.contents = color
        // use the same material for all geometry elements
        geometry.firstMaterial = material
        let node = SCNNode(geometry: geometry)
        node.transform = matrix
        return node
    }
    
    private func translate(_ x: Float, _ y: Float, _ z: Float = 0) -> SCNMatrix4 {
        return SCNMatrix4MakeTranslation(self.x + x * cell, self.y + y * cell, self.z + z * cell)
    }
}

extension CGFloat {
    static func random() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}

extension UIColor {
    static func random() -> UIColor {
        return UIColor(red:CGFloat.random(),green:.random(),blue:.random(),alpha: 1.0)
    }
}


extension ViewController{
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let results = sceneView.hitTest(touch.location(in: sceneView), types: [ARHitTestResult.ResultType.existingPlaneUsingExtent])
        guard let hitFeature = results.last else { return }
        let hitTransform = SCNMatrix4FromMat4(hitFeature.worldTransform)
        let hitPosition = SCNVector3Make(hitTransform.m41,hitTransform.m42,hitTransform.m43)
        if !isScalePlaced{
            createLines(hitPosition: hitPosition)
            let camera = self.sceneView.pointOfView!
//            scaleNode.rotation = camera.rotation
            isScalePlaced=true
        }
        /*      let node=SCNNode()
         node.position=hitPosition
         for i in 0...10 {
         //            addLine(to: node, cell * Float(5), 0.01, 0.01, hitPosition.x, 0,Float(i))
         addLine(to: node, cell * Float(5), 0.01, 0.01, 1, 0, Float(i))
         }
         sceneView.scene.rootNode.addChildNode(node)*/
    }
}

extension ViewController {
    func createLines(hitPosition:SCNVector3) {
//        let node=SCNNode()
        var index=0
        let x=hitPosition.x
        let y=hitPosition.y
        var z=hitPosition.z
        drawStartLines(mainNode: scaleNode, position:SCNVector3(x,y,z),width: 0.1,length: lengthArray[0],dottedLines: 10,text:"Start here")
        while index < lengthArray.count {
            let length=lengthArray[index]
            let box1:SCNBox!
            if index == 0 {
                box1=SCNBox(width: 0.1, height: 0.001, length: length, chamferRadius: 0)
                box1.firstMaterial?.diffuse.contents=UIColor(red: 185/255, green: 78/255, blue: 63/255, alpha: 0.5)
                box1.firstMaterial?.ambientOcclusion.contents=UIColor.red
                box1.firstMaterial?.transparent.contents=UIColor.red
            }else if index % 2 == 0 {
                box1=SCNBox(width: 0.1, height: 0.01, length: length, chamferRadius: 0)
                box1.firstMaterial?.diffuse.contents=UIColor(red: 228/255, green: 184/255, blue: 191/255, alpha: 0.8)
            }else{
                box1=SCNBox(width: 0.1, height: 0.01, length: length, chamferRadius: 0)
                box1.firstMaterial?.diffuse.contents=UIColor(red: 200/255, green: 166/255, blue: 154/255, alpha: 0.9)
            }
            
            box1.firstMaterial?.readsFromDepthBuffer=false
            box1.firstMaterial?.writesToDepthBuffer=false
            let cubeNode1 = SCNNode(geometry: box1)
            cubeNode1.position = SCNVector3(x,y,z)
            print("Position   \(index)    \(cubeNode1.position.x,cubeNode1.position.y,cubeNode1.position.z)")
            scaleNode.addChildNode(cubeNode1)
            var dottedLines=0
            if index == 0 {
                 dottedLines=3
            }else{
                dottedLines=index*2+2
            }
            drawDottedLines(mainNode: scaleNode, position: cubeNode1.position,width: 0.1,length: length,dottedLines: dottedLines,text:sizetextArray[index])
//            createTextNodes(node: node, position: cubeNode1.position,text: sizetextArray[index])
            index=index+1
            if index < lengthArray.count {
                let currentLength=Float(length/2)
                let nextLength=Float(lengthArray[index]/2)
                z=z-currentLength-nextLength
            }
            
        }
        sceneView.scene.rootNode.addChildNode(scaleNode)
    }
    
    
    func drawDottedLines(mainNode:SCNNode,position:SCNVector3,width:CGFloat,length:CGFloat,dottedLines:Int,text:String){
        var index=0
        var x=position.x-Float(width/2)
        let z=position.z-Float(length/2)
        while(index < dottedLines){
            let box=SCNBox(width: 0.01, height: 0.001, length: 0.001, chamferRadius: 0.0)
            box.firstMaterial?.diffuse.contents=UIColor.white
            let node=SCNNode(geometry: box)
            node.position=SCNVector3(x,position.y,z)
            x=x-0.02
            index=index+1
            mainNode.addChildNode(node)
        }
        let newposition=SCNVector3(x, position.y, position.z)
        createTextNodes1(node: mainNode, position: newposition, text: text)
    }
    
    func drawStartLines(mainNode:SCNNode,position:SCNVector3,width:CGFloat,length:CGFloat,dottedLines:Int,text:String){
        var index=0
        var x=position.x-Float(width/2)
        let z=position.z+Float(length/2)
        while(index < dottedLines){
            let box=SCNBox(width: 0.01, height: 0.001, length: 0.001, chamferRadius: 0.0)
            box.firstMaterial?.diffuse.contents=UIColor.white
            let node=SCNNode(geometry: box)
            node.position=SCNVector3(x,position.y,z)
            x=x-0.02
            index=index+1
            mainNode.addChildNode(node)
        }
        let newposition=SCNVector3(x, position.y, z)
        createTextNodes1(node: mainNode, position: newposition, text: text)
    }
    
    func createTextNodes1(node:SCNNode,position:SCNVector3,text:String,width:CGFloat=0.1,height:CGFloat=0.01,length:CGFloat=0.2){
        let textGeo = SCNText(string: text, extrusionDepth: 1.0)
        textGeo.firstMaterial?.diffuse.contents = UIColor.white
        textGeo.firstMaterial?.ambientOcclusion.contents=UIColor.white
        textGeo.firstMaterial?.transparent.contents=UIColor.white
        textGeo.font = UIFont.systemFont(ofSize: 6.0)
        textGeo.flatness=1.0
        
        let textNode = SCNNode(geometry: textGeo)
        textNode.position = SCNVector3(position.x, position.y,position.z+(0.03*position.z))
        //        textNode.rotation = SCNVector4(1,0,0,Double.pi/(-4))
        textNode.eulerAngles = SCNVector3(-0.5*Double.pi,0.0,0.0)
        textNode.scale = SCNVector3(0.003,0.003,0.003)
        node.addChildNode(textNode)
    }
    
    func createTextNodes(node:SCNNode,position:SCNVector3,text:String,width:CGFloat=0.1,height:CGFloat=0.01,length:CGFloat=0.2){
        let textGeo = SCNText(string: text, extrusionDepth: 1.0)
        textGeo.firstMaterial?.diffuse.contents = UIColor.white
        textGeo.firstMaterial?.ambientOcclusion.contents=UIColor.black
        textGeo.firstMaterial?.transparent.contents=UIColor.black
        textGeo.font = UIFont.systemFont(ofSize: 10.0)
//        textGeo.alignmentMode="center"
        textGeo.flatness=1.0
        
        let textNode = SCNNode(geometry: textGeo)
        textNode.position = SCNVector3(position.x-Float(width/2), position.y,position.z)
//        textNode.rotation = SCNVector4(1,0,0,Double.pi/(-4))
//        textNode.eulerAngles = SCNVector3(0.0, 0.25*Double.pi, 0.5*Double.pi)
        textNode.scale = SCNVector3(0.003,0.003,0.003)
        
        node.addChildNode(textNode)
    }
}



private extension SCNVector3{
    func distance(receiver:SCNVector3) -> Float{
        let xd = receiver.x - self.x
        let yd = receiver.y - self.y
        let zd = receiver.z - self.z
        let distance = Float(sqrt(xd * xd + yd * yd + zd * zd))
        
        if (distance < 0){
            return (distance * -1)
        } else {
            return (distance)
        }
    }
}





