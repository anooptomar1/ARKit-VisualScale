//
//  Plane.swift
//  PlotGraph
//
//  Created by Birapuram Kumar Reddy on 9/8/17.
//  Copyright © 2017 Myntra Design Pvt Ltd. All rights reserved.
//

import Foundation
import ARKit

class Plane: SCNNode {

    // MARK: - Properties

    var anchor: ARPlaneAnchor

    // MARK: - Initialization

    init(_ anchor: ARPlaneAnchor) {
        self.anchor = anchor
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - ARKit

    func update(_ anchor: ARPlaneAnchor) {
        self.anchor = anchor
    }

}
