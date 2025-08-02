//
//  Renderer+ComputeShaders.swift
//  PaintingLandscape
//
//  Compute shader management extension
//

import Metal
import MetalKit

extension Renderer {
    
    // MARK: - Compute Pipeline Management
    
    func setupComputePipelines() {
        let pipelineNames = ["compute"]
        
        for name in pipelineNames {
            if let pipeline = createComputePipeline(functionName: name) {
                computePipelines[name] = pipeline
            }
        }
    }
    
    private func createComputePipeline(functionName: String) -> MTLComputePipelineState? {
        guard let library = device.makeDefaultLibrary(),
              let function = library.makeFunction(name: functionName) else {
            print("Failed to load function: \(functionName)")
            return nil
        }
        
        do {
            return try device.makeComputePipelineState(function: function)
        } catch {
            print("Failed to create compute pipeline for \(functionName): \(error)")
            return nil
        }
    }
    
    // MARK: - Compute Texture Management
    
    func setupComputeTextures() {
        computeOutputTexture = createTexture(width: 1280, height: 720)
    }
    
    private func createTexture(width: Int, height: Int, pixelFormat: MTLPixelFormat = .rgba8Unorm, usage: MTLTextureUsage = [.shaderRead, .shaderWrite]) -> MTLTexture? {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: pixelFormat,
            width: width,
            height: height,
            mipmapped: false
        )
        descriptor.usage = usage
        return device.makeTexture(descriptor: descriptor)
    }
    
    // MARK: - Compute Dispatch
    
    func dispatchComputePass(commandBuffer: MTLCommandBuffer) {
        guard let computePipeline = computePipelines["compute"],
              let outputTexture = computeOutputTexture else {
            print("Compute pipeline or texture not available")
            return
        }
        
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            print("Failed to create compute encoder")
            return
        }
        
        computeEncoder.setComputePipelineState(computePipeline)
        computeEncoder.setTexture(outputTexture, index: 0)
        computeEncoder.setBuffer(dynamicUniformBuffer, offset: uniformBufferOffset, index: BufferIndex.uniforms.rawValue)
        
        // Calculate thread groups
        let threadsPerGroup = MTLSize(width: 16, height: 16, depth: 1)
        let groupCount = MTLSize(
            width: (outputTexture.width + threadsPerGroup.width - 1) / threadsPerGroup.width,
            height: (outputTexture.height + threadsPerGroup.height - 1) / threadsPerGroup.height,
            depth: 1
        )
        
        computeEncoder.dispatchThreadgroups(groupCount, threadsPerThreadgroup: threadsPerGroup)
        computeEncoder.endEncoding()
    }
}