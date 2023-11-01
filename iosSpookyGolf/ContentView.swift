//
// ContentView.swift
// iosSpookyGolf
//
// Created by Aiden Shanks on 10/16/23.
//

import SwiftUI
import RealityKit
import ARKit

struct ContentView: View {
    @State private var resetARSession = false
    @State private var courseCompleted = false

    var body: some View {
        ZStack {
            ARViewContainer(resetSession: $resetARSession,  courseCompleted: $courseCompleted).edgesIgnoringSafeArea(.all)

            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        self.courseCompleted = false
                        self.resetARSession.toggle()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .padding()
                            .background(Color.white.opacity(0.75))
                            .clipShape(Circle())
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 44)
                    .padding(.trailing)
                }
                Spacer()
            }
            if courseCompleted {
                Text("Course Completed!")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                    .background(Color.white.opacity(0.85))
                    .cornerRadius(10)
                    .padding()
                    .transition(.scale)
            }
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    @Binding var resetSession: Bool
    @Binding var courseCompleted: Bool
    
    let thresholdValue: Float = 0.6
    let targetPosition = SIMD3<Float>(-1.2, -0.5, 0.175)
    
    
    func loadRealityComposerScene(filename: String, fileExtension: String, sceneName: String) -> (Entity & HasAnchoring)? {
        guard let realitySceneURL = Bundle.main.url(forResource: filename, withExtension: fileExtension) else {
            return nil
        }
        let loadedAnchor = try? Entity.loadAnchor(contentsOf: realitySceneURL)
        return loadedAnchor
    }
    
    func createSphereEntity() -> ModelEntity {
        let sphereRadius: Float = 0.05
        let sphere = ModelEntity(mesh: .generateSphere(radius: sphereRadius))

        
        let sphereShape = ShapeResource.generateSphere(radius: sphereRadius)
        let sphereCollision = CollisionComponent(shapes: [sphereShape])
        sphere.components[CollisionComponent.self] = sphereCollision

        let spherePhysics = PhysicsBodyComponent(shapes: [sphereShape], mass: 1, material: .default, mode: .dynamic)
        sphere.components[PhysicsBodyComponent.self] = spherePhysics
        
        //start = 1.0, 1.1, 0.825
        sphere.position = SIMD3<Float>(1.0, 1.1, 0.825)
        
        sphere.name = "Sphere"

        return sphere
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.session.delegate = context.coordinator
        context.coordinator.arView = arView

        guard let anchor = loadRealityComposerScene(filename: "SGACT3", fileExtension: "reality", sceneName: "Scene1") else {
            print("Failed to load the anchor from SGACT3.reality")
            return arView
        }

        arView.scene.addAnchor(anchor)

        let sphere = createSphereEntity()

        anchor.addChild(sphere)
        

        //arView.debugOptions.insert(.showPhysics)

    
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        if resetSession {
            uiView.session.pause()
            
            uiView.scene.anchors.removeAll()

            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = [.horizontal]
            uiView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

            if let anchor = loadRealityComposerScene(filename: "SGACT3", fileExtension: "reality", sceneName: "Scene1") {
                uiView.scene.addAnchor(anchor)
                
                let sphere = createSphereEntity()
                anchor.addChild(sphere)
            }

            DispatchQueue.main.async {
                self.resetSession = false
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, ARSessionDelegate {
        weak var arView: ARView?
        var parent: ARViewContainer

        init(_ parent: ARViewContainer) {
            self.parent = parent
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            DispatchQueue.main.async {
                self.checkSpherePosition()
            }
        }

        private func checkSpherePosition() {
            guard let arView = self.arView else { return }
            guard let sphere = arView.scene.findEntity(named: "Sphere") as? ModelEntity else { return }

            let spherePosition = sphere.position
            //print(spherePosition)
            let targetPosition = self.parent.targetPosition
            //print(targetPosition)
            let thresholdValue = self.parent.thresholdValue
            //print(thresholdValue)
            let distance = simd_length(spherePosition - targetPosition)
            
            //print(distance)

            if distance < thresholdValue && !self.parent.courseCompleted {
                self.parent.courseCompleted = true
            }
        }

        
        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            guard let arView = sender.view as? ARView else { return }

            let location = sender.location(in: arView)
            let hitResults = arView.hitTest(location)

            for hitResult in hitResults {
                if let hitEntity = hitResult.entity as? ModelEntity {
                    //print("Sphere was tapped!")
                    
                    guard let frame = arView.session.currentFrame else { return }

    
                    let column = frame.camera.transform.columns.2
                    let cameraForwardDirection = SIMD3<Float>(column.x, column.y, column.z)
                    //print(cameraForwardDirection)
              
                    let impulseMagnitude: Float = 0.5
                    let impulseDirection = -cameraForwardDirection
                    let impulse = impulseDirection * impulseMagnitude
                    
                    let hitPosition = SIMD3<Float>(hitResult.position.x, hitResult.position.y, hitResult.position.z)

                    hitEntity.applyImpulse(impulse, at: hitPosition, relativeTo: nil)
                }
            }

        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
