// ================================================================================
//
//	ADOBE SYSTEMS INCORPORATED
//	Copyright 2011 Adobe Systems Incorporated
//	All Rights Reserved.
//
//	NOTICE: Adobe permits you to use, modify, and distribute this file
//	in accordance with the terms of the license agreement accompanying it.
//
// ================================================================================
package
{
	// ===========================================================================
	//	Imports
	// ---------------------------------------------------------------------------
	import com.adobe.display.*;
	import com.adobe.scenegraph.*;
	
	import flash.display.*;
	import flash.display3D.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;
	
	// ===========================================================================
	//	Class 
	// ---------------------------------------------------------------------------
	/**
	 * <p>
	 * This sample configures a simple bloom post-processing pipeline using 
	 * Proscenium's built-in filters and RenderGraph architecture which 
	 * automatically schedules graphics jobs based on their dependencies.
	 * </p>
	 * The bloom pipeline constructed in this sample has the following steps:
	 * <ul>
	 *   <li>Create color render target. Note that render target's size should be a power-of-two. 
	 *       Therefore, color render target will be bigger if necessary. 
	 *       However, only the original size will be used by applying additional viewport 
	 *       transformation and setting a scissor rectangle.</li>
	 *   <li>Create additional render targets for reduction and multi-pass blur.</li>
	 *   <li>Enable HDR mapping so that intensities greater than 1 can be stored.</li>
	 *   <li>Apply a bright pass in order to zero out low intensity pixels (apply reduction also). 
	 *       This is done by using RGNodePPElement.HDR_BRIGHT_2x2.
	 *       The maximum brightness is set using bloomBrightIntensityMinimum.</li>
	 *   <li>Scaled down the size of the color buffer.
	 *       This is done by RGNodePPElement.REDUCTION_2x2.</li>
	 *   <li>Apply blur kernels in x and y directions.
	 *       This is done by RGNodePPElement.BLURU_5 and RGNodePPElement.BLURV_5.</li>
	 *   <li>Composite the result with original color and output to the primary buffer.
	 *       This is done by using RGNodePPElement.HDR_BLOOM.</li>
	 * </ul>
	 */
	public class TestPPBloom extends BasicDemo
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _cubeInstanced:SceneMesh;

		protected var _renderBuffer2:RenderTexture;
		protected var _renderBuffer4:RenderTexture;
		protected var _renderBufferA:RenderTexture;
		protected var _renderBufferB:RenderTexture;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function TestPPBloom()
		{
			super();
			
			shadowMapEnabled = true;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function resetCamera():void
		{
			_camera = scene.activeCamera;
			_camera.identity();
			_camera.position = new Vector3D(0, 1, 40);
			_camera.appendRotation( -30, Vector3D.X_AXIS );
			_camera.appendRotation( -25, Vector3D.Y_AXIS, ORIGIN );
		}
		
		override protected function onAnimate( t:Number, dt:Number ):void
		{
			if ( lights )
			{
				var angle:Number = t;
				var ca:Number = Math.cos( angle );
				var sa:Number = Math.sin( angle );
				
				lights[0].setPosition(  10 * ca, 15, 10 * sa );
				lights[1].setPosition( -10 * sa, 15, 10 * ca );
			}
		}
		
		override protected function enterFrameEventHandler( event:Event ):void
		{
			callPresentOnRender = false;
			super.enterFrameEventHandler( event );
			
		//if ( instance.colorBuffer )
		//	instance.colorBuffer.showMeTheTexture( instance, instance.width, instance.height, 0,0, 256 );
		//if ( RB2 )
		//	RB2.showMeTheTexture( instance, instance.width, instance.height, 0,0, 256 );
			
			instance.present();
		}
		
		override protected function initLights():void
		{
			var material:MaterialStandard;
			
			// --------------------------------------------------
			//	Light #1
			// --------------------------------------------------
			lights = new Vector.<SceneLight>();
			var light:SceneLight;
			var sphere:SceneMesh;
			
			light = new SceneLight( SceneLight.KIND_POINT, "point light" );
			light.color.set( .8, .8, .8 );
			light.setPosition( 10, 15, 10 );
			light.shadowMapEnabled = shadowMapEnabled;
			light.setShadowMapSize( shadowMapSize, shadowMapSize );
			lights.push( light );
			
			// --------------------------------------------------
			//	Light #2
			// --------------------------------------------------
			light = new SceneLight( SceneLight.KIND_POINT, "point light" );
			light.color.set( 0, .5, 0 );
			light.setPosition( -10, 15, 10 );
			light.shadowMapEnabled = shadowMapEnabled;
			light.setShadowMapSize( shadowMapSize, shadowMapSize );
			lights.push( light );
			
			// --------------------------------------------------
			
			var light0mtrl:MaterialStandard = new MaterialStandard( "light0Mtrl" );
			light0mtrl.emissiveColor.set(
				lights[ 0 ].color.r * 5,
				lights[ 0 ].color.g * 5,
				lights[ 0 ].color.b * 5
			);
			var sphere0:SceneMesh = MeshUtils.createSphere( .5, 30, 30, light0mtrl, "light0Sphere" );
			sphere0.neverCastShadow = true;
			lights[ 0 ].addChild( sphere0 );
			
			var light1mtrl:MaterialStandard = new MaterialStandard( "light0Mtrl" );
			light1mtrl.emissiveColor.set(
				lights[ 1 ].color.r * 20,
				lights[ 1 ].color.g * 20,
				lights[ 1 ].color.b * 20
			);
			light1mtrl.specularColor.set(
				lights[ 1 ].color.r,
				lights[ 1 ].color.g,
				lights[ 1 ].color.b
			);
			var sphere1:SceneMesh = MeshUtils.createSphere( .5, 30, 30, light1mtrl, "light0Sphere" );
			sphere1.neverCastShadow = true;
			lights[ 1 ].addChild( sphere1 );
			// --------------------------------------------------
			
			SceneLight.shadowMapSamplingPointLights = RenderSettings.SHADOW_MAP_SAMPLING_1x1;

			for each ( light in lights ) {
				scene.addChild( light );
			}
		}

		override protected function initModels():void
		{
			var outMtrl:MaterialStandard = new MaterialStandard( "bright" );
			outMtrl.emissiveColor.set( 2, 2, 2 );
			var extBox:SceneMesh = MeshUtils.createBox( 5000, 5000, 5000, outMtrl, "exterior" );
			scene.addChild( extBox );
			
			// create walls
			var wallMtrl:MaterialStandard = new MaterialStandard( "wallMtrl" );
			wallMtrl.diffuseColor.set( .2, .3, .9 );
			wallMtrl.specularColor.set( .2, .3, .9 );

			var wallPos:Number = 100;
			var wallSizeA:Number = 150;
			var wallSizeB:Number = 350;
			var wall1:SceneMesh = MeshUtils.createPlane( wallSizeA, wallSizeB, 20, 20, wallMtrl, "wall1" );
			wall1.transform.appendRotation( -90, Vector3D.X_AXIS );
			wall1.appendTranslation( 0, 0, wallPos );
			scene.addChild( wall1 );
			
			var wall2:SceneMesh = MeshUtils.createPlane( wallSizeA, wallSizeB, 20, 20, wallMtrl, "wall1" );
			wall2.transform.appendRotation( 90, Vector3D.X_AXIS );
			wall2.appendTranslation( 0, 0, -wallPos );
			scene.addChild( wall2 );
			
			var wall3:SceneMesh = MeshUtils.createPlane( wallSizeB, wallSizeA, 20, 20, wallMtrl, "wall1" );
			wall3.transform.appendRotation( -90, Vector3D.Z_AXIS );
			wall3.appendTranslation( -wallPos, 0, 0 );
			scene.addChild( wall3 );
			
			var wall4:SceneMesh = MeshUtils.createPlane( wallSizeB, wallSizeA, 20, 20, wallMtrl, "wall1" );
			wall4.appendRotation( 90, Vector3D.Z_AXIS );
			wall4.appendTranslation( wallPos, 0, 0 );
			scene.addChild( wall4 );
			
			// create ground plane
			var groundMtrl:MaterialStandard = new MaterialStandard( "groundMtrl" );
			groundMtrl.diffuseColor.set( .5, .5, .5 );
			groundMtrl.specularColor.set( .2, .2, .2 );
			var ground:SceneMesh = MeshUtils.createPlane( wallSizeA, wallSizeA, 20, 20, groundMtrl, "ground" );
			ground.transform.appendTranslation( 0, -2, 0 );
			scene.addChild( ground );
			
			var material:MaterialStandard = new MaterialStandard( "cubeMtrl" );	// material name is used
			material.diffuseColor.set( 0, 1, 0 );
			var cube:SceneMesh = MeshUtils.createCube( 5, material, "cube" );
			cube.appendTranslation( 0, 6, -10 );
			scene.addChild( cube );
			
			// create an instance of the cube (mesh data is shared)
			_cubeInstanced = cube.instance( "cube-instanced" );
			_cubeInstanced.appendTranslation( 0, 6, 0 );
			scene.addChild( _cubeInstanced );
			
			//
			var torus:SceneMesh = MeshUtils.createDonut( .25, 1.5, 50, 10, null, "torus" );
			torus.appendTranslation( 10, 2, 0 );
			var rotAxis:Vector3D = new Vector3D( 1, 1, 1 );
			rotAxis.normalize();
			torus.appendRotation( 45, rotAxis );
			scene.addChild( torus );
			
			var sphere:SceneMesh = MeshUtils.createSphere( 3, 50, 50, null, "superSphere" );
			sphere.setPosition( -10, 2, 0 );
			scene.addChild( sphere );
			
			if ( true )
			{
				// break direct rendering to primary and create a new color render target/texture (HDR target, etc)
				instance.createPostProcessingColorBuffer();
				var color:RenderTexture = instance.colorBuffer;
				
				// enable HDR scaling for the color RT
				color.targetSettings.useHDRMapping = true;
				color.targetSettings.kHDRMapping = 4;
				
				// create temporary render targets/textures
				_renderBuffer2 = new RenderTexture( instance.width/2, instance.height/2, "Buf/2",   true, false, true );
				_renderBuffer4 = new RenderTexture( instance.width/4, instance.height/4, "Buf/4",   true, false, true );
				_renderBufferA = new RenderTexture( instance.width/8, instance.height/8, "Buf/8-A", true, false, true );
				_renderBufferB = new RenderTexture( instance.width/8, instance.height/8, "Buf/8-B", true, false, true );
				
				// define rendering jobs = nodes
				var toRB2:RenderGraphNodePPElement = new RenderGraphNodePPElement( color, _renderBuffer2, RenderGraphNodePPElement.HDR_BRIGHT_2x2, "Reduction color->2" );
				toRB2.bloomBrightIntensityMinimum = 0.9;
				var toRB4:RenderGraphNodePPElement = new RenderGraphNodePPElement( _renderBuffer2, _renderBuffer4, RenderGraphNodePPElement.REDUCTION_2x2, "Reduction 2->4" );
				var toRBA:RenderGraphNodePPElement = new RenderGraphNodePPElement( _renderBuffer4, _renderBufferA, RenderGraphNodePPElement.REDUCTION_2x2, "Reduction 4->8" );
				
				var blur0:RenderGraphNodePPElement = new RenderGraphNodePPElement( _renderBufferA, _renderBufferB, RenderGraphNodePPElement.BLURU_5, "Blur0 AB" );
				var blur1:RenderGraphNodePPElement = new RenderGraphNodePPElement( _renderBufferB, _renderBufferA, RenderGraphNodePPElement.BLURV_5, "Blur1 BA" );
				var blur2:RenderGraphNodePPElement = new RenderGraphNodePPElement( _renderBufferA, _renderBufferB, RenderGraphNodePPElement.BLURU_5, "Blur2 AB" );
				var blur3:RenderGraphNodePPElement = new RenderGraphNodePPElement( _renderBufferB, _renderBufferA, RenderGraphNodePPElement.BLURV_5, "Blur3 BA" );
				var blur4:RenderGraphNodePPElement = new RenderGraphNodePPElement( _renderBufferA, _renderBufferB, RenderGraphNodePPElement.BLURU_5, "Blur4 AB" );
				var blur5:RenderGraphNodePPElement = new RenderGraphNodePPElement( _renderBufferB, _renderBufferA, RenderGraphNodePPElement.BLURV_5, "Blur5 BA" );
				
				var toPrimary:RenderGraphNodePPElement = new RenderGraphNodePPElement( color, null, RenderGraphNodePPElement.HDR_BLOOM, "Bloom" );
				toPrimary.bloomTexture = _renderBufferA; 
				
				// configure the graph
				instance.renderGraphRoot.clearAllPrerequisite( );
				
				RenderGraphNode.addStaticGraphEdge( color.renderGraphNode, toRB2 ); 
				RenderGraphNode.addStaticGraphEdge(                 toRB2, toRB4 ); 
				RenderGraphNode.addStaticGraphEdge(                 toRB4, toRBA ); 
				RenderGraphNode.addStaticGraphEdge(                 toRBA, blur0 );
				RenderGraphNode.addStaticGraphEdge(                 blur0, blur1 );
				RenderGraphNode.addStaticGraphEdge(                 blur1, blur2 );
				RenderGraphNode.addStaticGraphEdge(                 blur2, blur3 );
				RenderGraphNode.addStaticGraphEdge(                 blur3, blur4 );
				RenderGraphNode.addStaticGraphEdge(                 blur4, blur5 );
				RenderGraphNode.addStaticGraphEdge(                 blur5, toPrimary );
				RenderGraphNode.addStaticGraphEdge(             toPrimary, instance.renderGraphRoot );
			}

			if ( lights[ 0 ].shadowMapEnabled )
				lights[ 0 ].addToShadowMap( _cubeInstanced, cube, torus, sphere, ground );
			if ( lights[ 1 ].shadowMapEnabled )
				lights[ 1 ].addToShadowMap( _cubeInstanced, cube, torus, sphere, ground );
		}
	}
}