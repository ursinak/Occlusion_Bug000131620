//
//  ViewController.swift
//  Occlusion_Bug000131620
//
//  Created by Ursina Boos on 22.06.20.
//  Copyright © 2020 Ursina Boos. All rights reserved.
//

import ARKit
import SceneKit
import UIKit
import ArcGISToolkit
import ArcGIS

class ViewController: UIViewController, ARSCNViewDelegate {
    @IBOutlet var sceneView: ARSCNView!
    private let arView = ArcGISARView()
    var scene: AGSScene!
    var occlusionLayer: AGSArcGISSceneLayer!
    var newBuildingLayer: AGSArcGISSceneLayer!
    
    var cameraViewpoint = AGSPoint(x: 8.5198291, y: 47.34000863, spatialReference: AGSSpatialReference.wgs84())

    
    // add IBOutlet (Stepper) to change transparency of occlusion layer
    @IBOutlet weak var transpSrepper: UIStepper!
    @IBOutlet weak var uiToolbar: UIToolbar!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        arView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(arView)
        view.addSubview(uiToolbar)

        // Set the view's delegate
        sceneView.delegate = self
        
        NSLayoutConstraint.activate([
        arView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        arView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        arView.topAnchor.constraint(equalTo: view.topAnchor),
        arView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Show statistics such as fps and timing information
//        sceneView.showsStatistics = true
        // Create a new scene
//        let scene = SCNScene(named: "art.scnassets/ship.scn")!
//        // Set the scene to the view
//        sceneView.scene = scene
        arView.locationDataSource = AGSCLLocationDataSource()
        configureScene()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        arView.startTracking(.ignore) // set viewpoint for trackings
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        arView.stopTracking()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate

    /*
     // Override to create and configure nodes for anchors added to the view's session.
     func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
         let node = SCNNode()

         return node
     }
     */

    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }

    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }

    private func configureScene() {
        //  Create scene with imagery basemap
        scene = AGSScene(basemap: .imagery())
        scene.addElevationSource()

        // add layer to the scene
        occlusionLayer = AGSArcGISSceneLayer(url: URL(string: "https://services.arcgis.com/0hCDCNyUhaUExjpm/arcgis/rest/services/Occlusion_in_Manegg_WSL2/SceneServer/layers/0")!)
        newBuildingLayer = AGSArcGISSceneLayer(url: URL(string: "https://services.arcgis.com/0hCDCNyUhaUExjpm/arcgis/rest/services/Occlusion_in_Manegg_WSL1/SceneServer/layers/0")!)
        scene.operationalLayers.add(occlusionLayer)
        scene.operationalLayers.add(newBuildingLayer)

        // load the scene and set the camera
        scene.load { [weak self, weak scene] (error) -> Void in
            guard error == nil else {
                print(error!.localizedDescription)
                return
            }
            scene?.baseSurface?.elevationSources.first?.load { (error) -> Void in guard error == nil else {
                print(error!.localizedDescription)
                return
            }
            scene?.baseSurface?.elevation(for: self!.cameraViewpoint) { (elevation, error) -> Void in guard error == nil else {
                print(error!.localizedDescription)
                return
            }
            let camera = AGSCamera(latitude: (self?.cameraViewpoint.y)!, longitude: self!.cameraViewpoint.x, altitude: elevation, heading: 0, pitch: 90, roll: 0)
            self?.arView.originCamera = camera
            self?.arView.translationFactor = 1
            }
            }
        }
        // display the scene
        arView.sceneView.scene = scene
        arView.sceneView.spaceEffect = .transparent
        arView.sceneView.atmosphereEffect = .none
        
    }
    
    func changeZHBuildingsTransparency(_ transp: Double) {
        let opacity = (transp / 100.0)
        occlusionLayer.opacity = Float(opacity)
    }
    
    
    @IBAction func setTransparency(_ sender: UIStepper) {
        changeZHBuildingsTransparency(sender.value)
    }
    
}

extension AGSScene {
    /// Adds an elevation source to the given scene.
    func addElevationSource() {
        let elevationSource = AGSArcGISTiledElevationSource(url: URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!)
        let surface = AGSSurface()
        surface.elevationSources = [elevationSource]
        surface.name = "baseSurface"
        surface.isEnabled = true
        surface.backgroundGrid.isVisible = false
        surface.navigationConstraint = .none
        baseSurface = surface
        baseSurface?.opacity = 1
        baseSurface?.opacity = 0.8
    }
}
