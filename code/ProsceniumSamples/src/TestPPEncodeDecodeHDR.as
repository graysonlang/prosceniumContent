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
	 * TestPPEncodeDecodeHDR is a simple test application that
	 * <ul>
	 *   <li>Creates a color render target with HDR mapping enabled.</li>
	 *   <li>Renders from the color render target to the primary buffer with the inverse HDR mapping. </li>
	 * </ul>
	 * <p> HDR mapping is             COLOR = 1 - 2^(-K * HDR_COLOR) </p>
	 * <p> Inverse HDR mapping is     HDR_COLOR =  max( -1/K log2( 1 - COLOR ), HDR_MAX) </p>
	 * <p> HDR_MAX = -1/K log2(1-254/255). Note that we do not use the largest COLOR value not to have inf.</p>
	 * <p> The parameter K is set in the RenderTargetSettings, for example, color.targetSettings.kHDRMapping = 1.2. </p>
	 * 
	 * HDR_COLOR range is [0, ..., HDR_MAX]. 
	 * Therefore, the HDR_COLOR value should not exceed -1/K log2(1-254/255).
	 */
	public class TestPPEncodeDecodeHDR extends BasicDemo
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _cubeInstanced:SceneMesh;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function TestPPEncodeDecodeHDR()
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
		
		override protected function enterFrameEventHandler( event:Event ):void
		{
			callPresentOnRender = false;
			super.enterFrameEventHandler( event );
			
			//instance.renderGraphRoot.dumpRenderGraph();
			//instance.renderGraphRoot.dumpOrderedRenderGraphNodess();
			
			if ( instance.colorBuffer )
				instance.colorBuffer.showMeTheTexture( instance, instance.width, instance.height, 0,0, 256);
			
			instance.present();
		}

		override protected function initModels():void
		{
			var plane:SceneMesh = MeshUtils.createPlane( 50, 50, 20, 20, null, "plane" );
			plane.transform.appendTranslation( 0, -2, 0 );
			scene.addChild( plane );
			
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
			
			//
			if ( lights )
			{
				lights[0].color.set( .9, .88, .85 );
				lights[0].setPosition( 10, 15, 10 );
				if ( lights[0].shadowMapEnabled )
				{
					lights[0].addToShadowMap( _cubeInstanced );
					lights[0].addToShadowMap( cube );
					lights[0].addToShadowMap( torus );
					lights[0].addToShadowMap( sphere );
				}
				
				lights[1].color.set( .0, 0.1, 0.02 );
				lights[1].setPosition( -10, 15, 10 );
				if ( lights[1].shadowMapEnabled )
				{
					lights[1].addToShadowMap( _cubeInstanced );
					lights[1].addToShadowMap( cube );
					lights[1].addToShadowMap( torus );
					lights[1].addToShadowMap( sphere );
				}

				var light0mtrl:MaterialStandard = new MaterialStandard( "light0Mtrl" );
				light0mtrl.emissiveColor.set(
					lights[ 0 ].color.r * 100,
					lights[ 0 ].color.g * 100,
					lights[ 0 ].color.b * 100
				);
				var sphere0:SceneMesh = MeshUtils.createSphere( .5, 30, 30, light0mtrl, "light0Sphere" );
				lights[0].addChild( sphere0 );

				var light1mtrl:MaterialStandard = new MaterialStandard( "light0Mtrl" );
				light1mtrl.emissiveColor.set(
					lights[ 1 ].color.r * 100,
					lights[ 1 ].color.g * 100,
					lights[ 1 ].color.b * 100
				);
				var sphere1:SceneMesh = MeshUtils.createSphere( .5, 30, 30, light1mtrl, "light0Sphere" );
				lights[ 1 ].addChild( sphere1 );
			}
			
			// break direct rendering to primary and create a new color render target/texture (HDR target, etc)
			instance.createPostProcessingColorBuffer();
			var color:RenderTexture = instance.colorBuffer;
			color.targetSettings.useHDRMapping = true;
			color.targetSettings.kHDRMapping = 4;

			var colorToPrimary:RenderGraphNode = new RenderGraphNodePPElement( color, null, RenderGraphNodePPElement.HDR_DECODE, "Decode HDR" );
			colorToPrimary.addStaticPrerequisite( color.renderGraphNode );

			instance.renderGraphRoot.clearAllPrerequisite();
			instance.renderGraphRoot.addStaticPrerequisite( colorToPrimary );
		}
	}
}
