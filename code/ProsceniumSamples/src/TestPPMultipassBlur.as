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
	 * This sample configures a simple blur post-processing pipeline using 
	 * Proscenium's built-in filters and RenderGraph architecture which 
	 * automatically schedules graphics jobs based on their dependencies.
	 * </p>
	 * The steps for the blur pipeline built in this sample are:
	 * <ul>
	 *   <li>Create color render target.</li>
	 *   <li>Create additional buffer.</li>
	 *   <li>Apply the blur kernel back and forth.</li>
	 *   <li>The final blur kernel output is set to primary buffer.</li>
	 * </ul>
	 */
	public class TestPPMultipassBlur extends BasicDemo
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _cubeInstanced:SceneMesh;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function TestPPMultipassBlur()
		{
			super();
			
			shadowMapEnabled = true;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
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
				lights[ 0 ].setPosition( 10, 20, 10 );
				if ( lights[ 0 ].shadowMapEnabled )
				{
					lights[ 0 ].addToShadowMap( _cubeInstanced );
					lights[ 0 ].addToShadowMap( cube );
					lights[ 0 ].addToShadowMap( torus );
					lights[ 0 ].addToShadowMap( sphere );
				}
				
				if ( lights[ 1 ].shadowMapEnabled )
				{
					lights[ 1 ].addToShadowMap( _cubeInstanced );
					lights[ 1 ].addToShadowMap( cube );
					lights[ 1 ].addToShadowMap( torus );
					lights[ 1 ].addToShadowMap( sphere );
				}
			}
			
			// break direct rendering to primary and create a new color render target/texture (HDR target, etc)
			instance.createPostProcessingColorBuffer();
			var color:RenderTexture = instance.colorBuffer;
			
			// create a temporary render target/texture
			var tempo:RenderTexture = new RenderTexture( instance.width, instance.height, "ColorBuffer0" );
			
			var colorToTempo1:RenderGraphNode = new RenderGraphNodePPElement( color, tempo, RenderGraphNodePPElement.BLUR_3x3, "Blur_ColorToTempo1" );
			var tempoToColor2:RenderGraphNode = new RenderGraphNodePPElement( tempo, color, RenderGraphNodePPElement.BLUR_3x3, "Blur_TempoToColor2" );
			var colorToTempo3:RenderGraphNode = new RenderGraphNodePPElement( color, tempo, RenderGraphNodePPElement.BLUR_3x3, "Blur_ColorToTempo3" );
			var tempoToColor4:RenderGraphNode = new RenderGraphNodePPElement( tempo, color, RenderGraphNodePPElement.BLUR_3x3, "Blur_TempoToColor4" );
			var colorToPrimry:RenderGraphNode = new RenderGraphNodePPElement( color, null,  RenderGraphNodePPElement.BLUR_3x3, "Blur_ColorToPrimary" );
			
			colorToTempo1.addStaticPrerequisite( color.renderGraphNode );// blurpass1: color buffer should be ready, i.e., the scene should be rendered
			tempoToColor2.addStaticPrerequisite( colorToTempo1 );		 // blurpass2: blurpass1 should be done before
			colorToTempo3.addStaticPrerequisite( tempoToColor2 );		 // blurpass3: blurpass2 should be done before
			tempoToColor4.addStaticPrerequisite( colorToTempo3 );		 // blurpass4: blurpass3 should be done before
			colorToPrimry.addStaticPrerequisite( tempoToColor4 );		 // final blur

			instance.renderGraphRoot.clearAllPrerequisite();
			instance.renderGraphRoot.addStaticPrerequisite( colorToPrimry );
		}
		
		override protected function enterFrameEventHandler( event:Event ):void
		{
			callPresentOnRender = false;
			super.enterFrameEventHandler( event );

			//instance.renderGraphRoot.dumpRenderGraph();
			//instance.renderGraphRoot.dumpOrderedRenderGraphNodess();
			
			if ( instance.colorBuffer )
				instance.colorBuffer.showMeTheTexture( instance, instance.width, instance.height, 0, 0, 256 );

			instance.present();
		}
	}
}
