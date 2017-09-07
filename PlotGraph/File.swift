//
//  Plane.swift
//  KnowYourShoeSizeAR
//
//  Created by Birapuram Kumar Reddy on 7/19/17.
//  Copyright © 2017 Myntra Design Pvt Ltd. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

class Plane: SCNNode{
    
    var planeGeometry:SCNBox!
    convenience init(with anchor:ARPlaneAnchor) {
        self.init()
        planeGeometry=SCNBox(width: CGFloat(anchor.extent.x), height: 0.05, length: CGFloat(anchor.extent.z), chamferRadius: 0)
        let material=SCNMaterial()
        material.lightingModel = .constant
        /*let image=UIImage(named:"tron-albedo1")
        material.diffuse.contents=image
        material.diffuse.wrapS = .repeat
        material.diffuse.wrapT = .repeat
        material.roughness.wrapT = .repeat
        material.roughness.wrapS = .repeat
        material.normal.wrapT = .repeat
        material.normal.wrapS = .repeat
        material.metalness.wrapT = .repeat
        material.metalness.wrapS = .repeat
        let tMaterial=SCNMaterial()
        tMaterial.diffuse.contents=UIColor.white.withAlphaComponent(0.0)
        planeGeometry.materials=[tMaterial,tMaterial,tMaterial,tMaterial,material,tMaterial]*/
        
        let childNode=SCNNode(geometry: planeGeometry)
        childNode.position=SCNVector3(0, -0.1/2, 0)
        /* let planeG = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
         let childNode=SCNNode(geometry: planeG)
         childNode.position=SCNVector3(anchor.center.x, 0, anchor.center.z)
         childNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)*/
        self.addChildNode(childNode)
        self.setTexture()
    }
    
    func setTexture(){
        /*let material=planeGeometry.materials[4]
        let scnMatrix=SCNMatrix4MakeScale(Float(planeGeometry.width*1), Float(planeGeometry.height*1), 1)
        material.diffuse.contentsTransform=scnMatrix
        material.roughness.contentsTransform=scnMatrix
        material.metalness.contentsTransform=scnMatrix
        material.normal.contentsTransform=scnMatrix*/
    }
    
    func updatePlane(anchor:ARPlaneAnchor) {
        planeGeometry.width=CGFloat(anchor.extent.x)
        planeGeometry.length=CGFloat(anchor.extent.z)
        self.setTexture()
    }
}


