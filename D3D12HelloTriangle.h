//*********************************************************
//
// Copyright (c) Microsoft. All rights reserved.
// This code is licensed under the MIT License (MIT).
// THIS CODE IS PROVIDED *AS IS* WITHOUT WARRANTY OF
// ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY
// IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR
// PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.
//
//*********************************************************

#pragma once

#include "DXSample.h"
#include <stdexcept>
#include <dxcapi.h>
#include <vector>
#include "imgui.h"
#include "imgui_impl_dx12.h"
#include "imgui_impl_win32.h"
#include "nv_helpers_dx12/TopLevelASGenerator.h"
#include "nv_helpers_dx12/ShaderBindingTableGenerator.h"
#include "UIConstructor.h"
#include "OBJ_FileManager.h"
#include "chrono"
#include "thread"

using namespace DirectX;
using namespace std::chrono;

// Note that while ComPtr is used to manage the lifetime of resources on the CPU,
// it has no understanding of the lifetime of resources on the GPU. Apps must account
// for the GPU lifetime of resources to avoid destroying objects that may still be
// referenced by the GPU.
// An example of this can be found in the class method: OnDestroy().
using Microsoft::WRL::ComPtr;

class D3D12HelloTriangle : public DXSample
{
public:
	D3D12HelloTriangle(UINT width, UINT height, std::wstring name);

	virtual void OnInit();
	virtual void OnUpdate();
	virtual void OnRender();
	virtual void OnDestroy();

private:
	static const UINT FrameCount = 2;

	struct Vertex
	{
		XMFLOAT3 position;
		XMFLOAT3 normal;
		Vertex(XMFLOAT3 position = XMFLOAT3(0.0f, 0.0f, 0.0f)) : position(position) {}
		//The constructors below are unused. They are only for providing compatibility
		//with DXRHelpers.h which is used when generating the randomized Menger Sponge fractal.
		Vertex(XMFLOAT4 position, XMFLOAT4 n, XMFLOAT4 color) : position(position.x, position.y, position.z) {}
		Vertex(XMFLOAT3 position, XMFLOAT4 color) : position(position) {}
	};

	void ComputeVertexNormals(std::vector<Vertex>& vertices, const std::vector<uint32_t>& indices);

	// Pipeline objects.
	CD3DX12_VIEWPORT m_viewport;
	CD3DX12_RECT m_scissorRect;
	ComPtr<IDXGISwapChain3> m_swapChain;
	ComPtr<ID3D12Device5> m_device;
	ComPtr<ID3D12Resource> m_renderTargets[FrameCount];
	ComPtr<ID3D12CommandAllocator> m_commandAllocator;
	ComPtr<ID3D12CommandQueue> m_commandQueue;
	ComPtr<ID3D12RootSignature> m_rootSignature;
	ComPtr<ID3D12DescriptorHeap> m_rtvHeap;
	ComPtr<ID3D12PipelineState> m_pipelineState;
	ComPtr<ID3D12GraphicsCommandList4> m_commandList;
	UINT m_rtvDescriptorSize;

	// App resources.
	ComPtr<ID3D12Resource> m_modelVertexBuffer;
	D3D12_VERTEX_BUFFER_VIEW m_modelVertexBufferView;
	UINT m_modelVertexCount;

	// Synchronization objects.
	UINT m_frameIndex;
	HANDLE m_fenceEvent;
	ComPtr<ID3D12Fence> m_fence;
	UINT64 m_fenceValue;

	//Rendering mode flag
	bool m_raster = false;

	void LoadPipeline();
	void LoadAssets();
	void PopulateCommandList();
	void WaitForPreviousFrame();
	void CheckRaytracingSupport();

	virtual void OnKeyUp(UINT8 key);
	virtual void OnKeyDown(UINT8 key);

	struct Material
	{
		XMFLOAT3 albedo;
		float roughness;
		float metallic;
		float reflectivity;

		Material(XMFLOAT3 albedo = XMFLOAT3(1.0f, 1.0f, 1.0f), float roughness = 0.5f, float metallic = 1.0f, float reflectivity = 0.5f)
			: albedo(albedo), roughness(roughness), metallic(metallic), reflectivity(reflectivity)
		{

		}
	};

	// #DXR
	struct AccelerationStructureBuffers
	{
		ComPtr<ID3D12Resource> pScratch;      // Scratch memory for AS builder
		ComPtr<ID3D12Resource> pResult;       // Where the AS is
		ComPtr<ID3D12Resource> pInstanceDesc; // Hold the matrices of the instances
	};

	struct TLASParams
	{
		//std::tuple < ComPtr<ID3D12Resource>, DirectX::XMMATRIX, UINT
		ComPtr<ID3D12Resource> blas;
		DirectX::XMMATRIX transformMatrix;
		UINT hitGroupIndex;
		UINT materialIndex;

		TLASParams(const ComPtr<ID3D12Resource>& blas, const DirectX::XMMATRIX& transformMatrix, const UINT& hitGroupIndex, const UINT& materialIndex)
			: blas(blas), transformMatrix(transformMatrix), hitGroupIndex(hitGroupIndex), materialIndex(materialIndex)
		{
		}
	};

	ComPtr<ID3D12Resource> m_bottomLevelAS; // Storage for the bottom Level AS

	AccelerationStructureBuffers m_topLevelASBuffers;
	std::vector<TLASParams> m_instances;

	/// <summary>
	/// Create the acceleration structure of an instance
	/// </summary>
	/// <param name="vVertexBuffers">Pair of vertex buffers and vertex count. The vertex buffers are assumed to contain Vertex structures.</param>
	/// <returns>AccelerationStructureBuffers for TLAS</returns>
	AccelerationStructureBuffers CreateBottomLevelAS(std::vector<std::pair<ComPtr<ID3D12Resource>, uint32_t>> vVertexBuffers, std::vector<std::pair<ComPtr<ID3D12Resource>, uint32_t>> vIndexBuffers = {});

	/// <summary>
	/// Create the main acceleration structure that holds all instances of the scene
	/// </summary>
	/// <param name="instances">Parameters of TLAS</param>
	/// <param name="updateOnly">Whether to build TLAS from scratch or just update the existing one</param>
	void CreateTopLevelAS(const std::vector<TLASParams> &instances, bool updateOnly = false);
	/// <summary>
	/// Updates the TLAS with the given instances. Used for loading new .obj files on the fly.
	/// </summary>
	/// <param name="newInstances"></param>
	void UpdateModelWithPendings();

	/// <summary>
	/// Create all acceleration structures, bottom and top
	/// </summary>
	void CreateAccelerationStructures();

	ComPtr<ID3D12RootSignature> CreateRayGenSignature();
	ComPtr<ID3D12RootSignature> CreateMissSignature();
	ComPtr<ID3D12RootSignature> CreateHitSignature();

	void CreateRaytracingPipeline();

	ComPtr<IDxcBlob> m_rayGenLibrary;
	ComPtr<IDxcBlob> m_hitLibrary;
	ComPtr<IDxcBlob> m_missLibrary;

	ComPtr<ID3D12RootSignature> m_rayGenSignature;
	ComPtr<ID3D12RootSignature> m_hitSignature;
	ComPtr<ID3D12RootSignature> m_missSignature;

	// Ray tracing pipeline state
	ComPtr<ID3D12StateObject> m_rtStateObject;

	//Ray tracing pipeline state properties, retaining the shader identifiers to use in the Shader Binding Table
	ComPtr<ID3D12StateObjectProperties> m_rtStateObjectProperties;

	void CreateRaytracingOutputBuffer();
	void CreateShaderResourceHeap();

	ComPtr<ID3D12Resource> m_outputResource;
	ComPtr<ID3D12DescriptorHeap> m_srvUavHeap;

	void CreateShaderBindingTable();
	nv_helpers_dx12::ShaderBindingTableGenerator m_sbtHelper;
	ComPtr<ID3D12Resource> m_sbtStorage;

	// #DXR Extra: Perspective Camera
	//It is important to start the camera from the center of the world, that is, from (0.0f, 0.0f, 0.0f). This is because the raygen shader expects the camera to be initially at the origin.
	/// <summary>
	/// The camera buffer is a constant buffer that stores the transform matrices of the camera, for use by both the rasterization and raytracing.
	/// This method allocates the buffer where the matrices will be copied.
	/// For the sake of code clarity, it also creates a heap containing only this buffer, to use in the rasterization path.
	/// </summary>
	void CreateCameraBuffer();
	/// <summary>
	/// Creates and copies the viewmodel and perspective matrices of the camera
	/// </summary>
	void UpdateCameraBuffer();
	ComPtr<ID3D12Resource> m_cameraBuffer;
	ComPtr<ID3D12DescriptorHeap> m_constHeap; //Camera buffer reference for rasterized rendering
	uint32_t m_cameraBufferSize = 0;

	// #DXR Extra - Refitting
	uint32_t m_time = 0;

	struct InstanceProperties
	{
		XMMATRIX objectToWorld;
		//#DXR Extra - Simple Lighting
		XMMATRIX objectToWorldNormal;
	};

	ComPtr<ID3D12Resource> m_instancePropertiesBuffer;
	void CreateInstancePropertiesBuffer();
	void UpdateInstancePropertiesBuffer();

	// #DXR Extra: Perspective Camera++
	void OnButtonDown(UINT32) override;
	void OnMouseMove(UINT8, UINT32) override;

	// #DXR Extra: Per-Instance Data
	ComPtr<ID3D12Resource> m_planeBuffer;
	D3D12_VERTEX_BUFFER_VIEW m_planeBufferView;
	/// <summary>
	/// Creates a vertex buffer for the plane.
	/// </summary>
	void CreatePlaneVB();
	
	// #DXR Extra: Per-Instance Data
	ComPtr<ID3D12Resource>m_globalConstantBuffer;
	void CreateGlobalConstantBuffer();

	// #DXR Extra: Per-Instance Data
	/// <summary>
	/// Creates a different buffer for each of the 3 triangles.
	/// </summary>
	void CreatePerInstanceConstantBuffers();
	std::vector<ComPtr<ID3D12Resource>> m_perInstanceConstantBuffers;

	ComPtr<ID3D12Resource> m_modelIndexBuffer;
	D3D12_INDEX_BUFFER_VIEW m_modelIndexBufferView;
	UINT m_modelIndexCount;

	void CreateMengerSpongeVB();
	ComPtr<ID3D12Resource> m_mengerVB;
	ComPtr<ID3D12Resource> m_mengerIB;
	D3D12_VERTEX_BUFFER_VIEW m_mengerVBView;
	D3D12_INDEX_BUFFER_VIEW m_mengerIBView;
	UINT m_mengerVertexCount, m_mengerIndexCount;

	// #DXR Extra: Depth Buffering
	void CreateDepthBuffer();
	ComPtr<ID3D12DescriptorHeap> m_dsvHeap;
	ComPtr<ID3D12Resource> m_depthStencil;

	// #DXR Extra - Another ray type
	ComPtr<IDxcBlob> m_shadowLibrary;
	ComPtr<ID3D12RootSignature> m_shadowSignature;

	//UI
	void InitializeImGuiContext(bool darkTheme = true);
	void CreateImGuiFontDescriptorHeap();
	ComPtr<ID3D12DescriptorHeap> m_imguiFontDescriptorHeap;
	UIConstructor uiConstructor;
	bool renderUI;

	//Material system
	//A default material is added in the constructor. New materials start from index 1 unless the default material is removed.
	std::vector<Material> materials;
	ComPtr<ID3D12Resource> materialsBuffer;
	void CreateMaterialsBuffer();
	void UpdateMaterialsBuffer();

	//Frame time measurement
	high_resolution_clock::time_point frameStart;
	high_resolution_clock::time_point frameEnd;
	float frameTime; //Frame time in milliseconds

	//Model updating
	void QueueModelVertexAndIndexBufferUpdates(std::vector<XMFLOAT3>& vertexPoints, std::vector<UINT>& indices);
	std::vector<Vertex> pendingVertices;
	std::vector<UINT> pendingIndices;
	bool pendingModelUpdate = false;
};
