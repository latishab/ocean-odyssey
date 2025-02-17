import UIKit
import Metal
import QuartzCore
import MetalKit

class OceanView: UIView {
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var metalLayer: CAMetalLayer!
    
    private var vertexBuffer: MTLBuffer!
    private var indexBuffer: MTLBuffer!
    
    private var pipelineState: MTLRenderPipelineState!
    private var depthStencilState: MTLDepthStencilState!
    
    private var time: Float = 0.0
    var depth: Float {
        get { return currentDepth }
        set { currentDepth = newValue }
    }
    
    private var currentDepth: Float = 0.0 {
        didSet {
            updateWaterPhysics()
        }
    }
    
    private var sunAngle: Float = Float.pi / 4  // 45 degrees default
    private var waveHeight: Float = 0.08        // Default wave height
    
    struct TimeUniforms {
        var time: Float
        var depth: Float        // This controls camera position
        var swellDirection: SIMD2<Float>
        var swellHeight: Float
        var swellFrequency: Float
        var sunAngle: Float
        var colorBallDepth: Float
        var pressure: Float  
    }
    
    private var timeUniformsBuffer: MTLBuffer!
    private var depthTexture: MTLTexture?
    
    private var swellDirection: SIMD2<Float> = SIMD2<Float>(1.0, 1.0)
    private var swellHeight: Float = 0.08
    private var swellFrequency: Float = 0.4
    private var swellPhase: Float = 0.0

    private var boatTexture: MTLTexture?
    private var boatPosition: SIMD2<Float> = SIMD2<Float>(0.9, 0.5)   // Changed from (0.5, 0.5) to (0.75, 0.5)
    private var boatSize: SIMD2<Float> = SIMD2<Float>(0.2, 0.1)     // Width is twice the height

    struct BoatUniforms {
        var position: SIMD2<Float>
        var size: SIMD2<Float>
        var rotation: Float
    }

    private var boatUniformsBuffer: MTLBuffer!

    private var boatPipelineState: MTLRenderPipelineState!

    private var displayLink: CADisplayLink?

    private var colorBallDepth: Float = 0.0

    // Calculate pressure in atmospheres (atm) based on depth
    private func calculatePressure(atDepth depth: Float) -> Float {
        // Pressure increases by 1 atm per 10 meters
        // depth is normalized (0-1) where 1.0 = 200m for the pressure experiment
        let depthInMeters = depth * 200.0
        let pressureAtm = 1.0 + (depthInMeters / 10.0)
        return pressureAtm
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // Create metal layer only once during initialization
        metalLayer = CAMetalLayer()
        layer.addSublayer(metalLayer)
        
        setupMetal()
        setupWaterMesh()
        
        displayLink = CADisplayLink(target: self, selector: #selector(gameLoop))
        displayLink?.add(to: .current, forMode: .default)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupMetal() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device.")
        }
        self.device = device
        commandQueue = device.makeCommandQueue()
        
        // Configure metal layer but don't create a new one
        metalLayer.device = device
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
        
        // Load the default library which contains all our .metal files
        guard let library = device.makeDefaultLibrary() else {
            fatalError("""
                Failed to load Metal library. Make sure all .metal files are:
                1. Included in the target
                2. Added to the Metal source build phase
                3. Using proper #include statements
                """)
        }
        
        // Get shader functions from the library
        guard let vertexFunction = library.makeFunction(name: "waterVertexShader"),
              let fragmentFunction = library.makeFunction(name: "waterFragmentShader"),
              let boatVertexFunction = library.makeFunction(name: "boatVertexShader"),
              let boatFragmentFunction = library.makeFunction(name: "boatFragmentShader") else {
            fatalError("Failed to find shader functions in library")
        }
        
        // 4. Define the vertex descriptor
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3 // `float3` matches `position`
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        // 5. Create pipeline state
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalLayer.pixelFormat
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Failed to create pipeline state: \(error)")
        }
        
        // 6. Depth stencil state
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .lessEqual
        depthStencilDescriptor.isDepthWriteEnabled = true
        depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)

        // After creating the water pipeline state, create the boat pipeline state
        let boatPipelineDescriptor = MTLRenderPipelineDescriptor()
        boatPipelineDescriptor.vertexFunction = boatVertexFunction
        boatPipelineDescriptor.fragmentFunction = boatFragmentFunction
        boatPipelineDescriptor.vertexDescriptor = vertexDescriptor
        boatPipelineDescriptor.colorAttachments[0].pixelFormat = metalLayer.pixelFormat
        boatPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        boatPipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        boatPipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        boatPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        boatPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        boatPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        boatPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        boatPipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        do {
            boatPipelineState = try device.makeRenderPipelineState(descriptor: boatPipelineDescriptor)
        } catch {
            fatalError("Failed to create boat pipeline state: \(error)")
        }

        loadBoatTexture()
        
        // Create boat uniforms buffer
        boatUniformsBuffer = device.makeBuffer(length: MemoryLayout<BoatUniforms>.stride, options: .storageModeShared)

        // Update the initial uniforms
        if let uniforms = timeUniformsBuffer?.contents().assumingMemoryBound(to: TimeUniforms.self) {
            uniforms.pointee = TimeUniforms(
                time: 0,
                depth: 0,
                swellDirection: SIMD2<Float>(1.0, 1.0),
                swellHeight: waveHeight,
                swellFrequency: 0.4,
                sunAngle: sunAngle,
                colorBallDepth: 0.0,
                pressure: 0.0
            )
        }
    }

    private func loadBoatTexture() {
        guard let device = device,
              let boat = UIImage(named: "boat.png"), // Explicitly specify .png extension
              let cgImage = boat.cgImage else {
            print("Failed to load boat.png image")
            return
        }
        
        let textureLoader = MTKTextureLoader(device: device)
        let textureLoaderOptions = [
            MTKTextureLoader.Option.textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
            MTKTextureLoader.Option.textureStorageMode: NSNumber(value: MTLStorageMode.private.rawValue),
            MTKTextureLoader.Option.SRGB: false // Ensure correct color handling
        ]
        
        do {
            boatTexture = try textureLoader.newTexture(cgImage: cgImage, options: textureLoaderOptions)
        } catch {
            print("Failed to create boat texture: \(error)")
        }
    }

    func setupWaterMesh() {
        // Create a grid of vertices and indices
        let gridSizeX = 2  // Start with a simple quad for debugging
        let gridSizeY = 2
        var vertices: [SIMD3<Float>] = []
        var indices: [UInt32] = []

        // Generate a simple quad that fills the screen
        vertices = [
            SIMD3<Float>(-1.0, -1.0, 0.0),  // Bottom left
            SIMD3<Float>( 1.0, -1.0, 0.0),  // Bottom right
            SIMD3<Float>(-1.0,  1.0, 0.0),  // Top left
            SIMD3<Float>( 1.0,  1.0, 0.0)   // Top right
        ]
        
        // Two triangles to form a quad
        indices = [
            0, 1, 2,  // First triangle
            2, 1, 3   // Second triangle
        ]

        vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: vertices.count * MemoryLayout<SIMD3<Float>>.stride,
            options: .storageModeShared
        )
        indexBuffer = device.makeBuffer(
            bytes: indices,
            length: indices.count * MemoryLayout<UInt32>.stride,
            options: .storageModeShared
        )
        timeUniformsBuffer = device.makeBuffer(
            length: MemoryLayout<TimeUniforms>.stride, 
            options: .storageModeShared
        )
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Only update the frame, don't create new layers
        metalLayer.frame = bounds
        createDepthTexture()
    }
    
    private func createDepthTexture() {
        guard bounds.width > 0, bounds.height > 0 else {
            print("Invalid bounds for depth texture creation.")
            return
        }
        
        let depthTextureDescriptor = MTLTextureDescriptor()
        depthTextureDescriptor.textureType = .type2D
        depthTextureDescriptor.width = Int(bounds.width)
        depthTextureDescriptor.height = Int(bounds.height)
        depthTextureDescriptor.pixelFormat = .depth32Float
        depthTextureDescriptor.usage = [.renderTarget, .shaderRead]
        depthTextureDescriptor.storageMode = .private
        
        guard let texture = device.makeTexture(descriptor: depthTextureDescriptor) else {
            fatalError("Failed to create depth texture")
        }
        
        depthTexture = texture
    }
    
    func updateWaterPhysics() {
        time += 0.01
        swellPhase += 0.003
        
        let swellAngle = sin(swellPhase * 0.08) * 0.4
        swellDirection = SIMD2<Float>(cos(swellAngle), sin(swellAngle))
        
        let heightVariation = sin(swellPhase * 0.05) * 0.02
        let currentSwellHeight = waveHeight + heightVariation
        
        // Calculate pressure based on depth
        let pressure = (currentDepth / 10.0) + 1.0
        
        var timeUniforms = TimeUniforms(
            time: time,
            depth: currentDepth,
            swellDirection: swellDirection,
            swellHeight: currentSwellHeight,
            swellFrequency: swellFrequency,
            sunAngle: sunAngle,
            colorBallDepth: colorBallDepth,
            pressure: pressure  
        )
        
        memcpy(timeUniformsBuffer.contents(), &timeUniforms, MemoryLayout<TimeUniforms>.stride)
    }
    
    override func draw(_ rect: CGRect) {
        print("OceanView: Drawing frame with depth: \(currentDepth)")
        guard let drawable = metalLayer.nextDrawable(),
              let depthTexture = depthTexture else {
            print("Drawable or depth texture is unavailable.")
            return
        }
        
        let passDescriptor = MTLRenderPassDescriptor()
        passDescriptor.colorAttachments[0].texture = drawable.texture
        passDescriptor.colorAttachments[0].loadAction = .clear
        passDescriptor.colorAttachments[0].clearColor = .init(red: 0, green: 0, blue: 0.5, alpha: 1)
        passDescriptor.colorAttachments[0].storeAction = .store
        passDescriptor.depthAttachment.texture = depthTexture
        passDescriptor.depthAttachment.loadAction = .clear
        passDescriptor.depthAttachment.clearDepth = 1.0
        passDescriptor.depthAttachment.storeAction = .dontCare
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor) else {
            print("Failed to create command buffer or render command encoder.")
            return
        }
        
        renderCommandEncoder.setRenderPipelineState(pipelineState)
        renderCommandEncoder.setDepthStencilState(depthStencilState)
        
        // Bind vertex buffer (index 0)
        renderCommandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        // Bind time uniform buffer for both vertex and fragment shaders
        renderCommandEncoder.setVertexBuffer(timeUniformsBuffer, offset: 0, index: 1)
        renderCommandEncoder.setFragmentBuffer(timeUniformsBuffer, offset: 0, index: 1)
        
        // Draw the indexed primitives
        renderCommandEncoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: indexBuffer.length / MemoryLayout<UInt32>.stride,
            indexType: .uint32,
            indexBuffer: indexBuffer,
            indexBufferOffset: 0
        )
        
        // Update boat position and rotation based on waves
        var boatUniforms = BoatUniforms(
            position: boatPosition,
            size: boatSize,
            rotation: 0.0  // Changed from Float.pi to 0.0
        )
        memcpy(boatUniformsBuffer.contents(), &boatUniforms, MemoryLayout<BoatUniforms>.stride)
        
        // Draw boat
        renderCommandEncoder.setRenderPipelineState(boatPipelineState)
        renderCommandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderCommandEncoder.setVertexBuffer(boatUniformsBuffer, offset: 0, index: 1)
        renderCommandEncoder.setVertexBuffer(timeUniformsBuffer, offset: 0, index: 2)
        renderCommandEncoder.setFragmentTexture(boatTexture, index: 0)
        
        renderCommandEncoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: 6,
            indexType: .uint32,
            indexBuffer: indexBuffer,
            indexBufferOffset: 0
        )
        
        renderCommandEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    func setDepth(_ newDepth: Float) {
        currentDepth = newDepth
        if let uniforms = timeUniformsBuffer?.contents().assumingMemoryBound(to: TimeUniforms.self) {
            uniforms.pointee.depth = currentDepth
            setNeedsDisplay()
        }
    }

    @objc func gameLoop() {
        updateWaterPhysics()
        setNeedsDisplay()
    }

    func updateSwellParameters(height: Float, frequency: Float) {
        swellHeight = height
        swellFrequency = frequency
    }

    private func mix(_ x: Float, _ y: Float, _ a: Float) -> Float {
        return x * (1 - a) + y * a
    }

    // Remove the cleanup method and deinit
    func invalidateDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    func releaseResources() {
        // Release Metal resources
        vertexBuffer = nil
        indexBuffer = nil
        timeUniformsBuffer = nil
        boatUniformsBuffer = nil
        pipelineState = nil
        boatPipelineState = nil
        depthStencilState = nil
        commandQueue = nil
        device = nil
    }

    func setColorBallDepth(_ depth: Float) {
        // Clamp the depth to ensure ball stays below waves
        let minDepth: Float = 0.05  // Minimum depth to keep ball below waves
        let clampedDepth = max(minDepth, depth)
        colorBallDepth = clampedDepth
        
        // Calculate and update pressure based on depth
        let pressure = calculatePressure(atDepth: clampedDepth)
        
        // Update uniforms
        updateWaterPhysics()
    }
}
