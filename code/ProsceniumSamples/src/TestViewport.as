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
	import com.adobe.utils.LoadTracker;
	
	import flash.display.*;
	import flash.display3D.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	/**
	 * <p>This sample demonstrates viewport implemented inside Proscenium. 
	 * Note that, unlike OpenGL or DirectX, the graphics API does not provide a viewport API. 
	 * Therefore, a viewport transformation matrix must be multiplied to the perspective matrix,
	 * and a scissor rectangle must be set. Proscenium performs these two tasks automatically 
	 * when viewport is set to a camera through SceneCamera.setViewport(...).</p>  
	 * 
	 * <p>In this sample, viewport is animated by using _camera.setViewport( true, L,R,B,T ) 
	 * in each frame to demonstrate the viewport feature.
	 * </p>
	 */
	public class TestViewport extends BasicDemo
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		protected static const IMAGE_FILENAMES:Vector.<String>		= new <String>[
			"../res/content/skybox/px.png",
			"../res/content/skybox/nx.png",
			"../res/content/skybox/py.png",
			"../res/content/skybox/ny.png",
			"../res/content/skybox/pz.png",
			"../res/content/skybox/nz.png"
		];

		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _cubeInstanced:SceneMesh;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function TestViewport()
		{
			super();
			shadowMapEnabled = true;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function initModels():void
		{
			LoadTracker.loadImages( IMAGE_FILENAMES, imageLoadComplete );
		}
		
		protected function imageLoadComplete( bitmaps:Dictionary ):void
		{
			var i:uint;

			var bitmapDatas:Vector.<BitmapData> = new Vector.<BitmapData>( 6, true );
			var bitmap:Bitmap;
			for ( i = 0; i < 6; i++ )
				bitmapDatas[ i ] = bitmaps[ IMAGE_FILENAMES[ i ] ].bitmapData;

			var sky:SceneSkyBox = new SceneSkyBox( bitmapDatas, false );
			scene.addChild( sky );
			
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
			
			var torus:SceneMesh = MeshUtils.createDonut( .25, 1.5, 50, 10, null, "torus" );
			torus.appendTranslation( 10, 2, 0 );
			var rotAxis:Vector3D = new Vector3D( 1, 1, 1 );
			rotAxis.normalize();
			torus.appendRotation( 45, rotAxis );
			scene.addChild( torus );
			
			var sphere:SceneMesh = MeshUtils.createSphere( 3, 50, 50, null, "superSphere" );
			sphere.setPosition( -10, 2, 0 );
			scene.addChild( sphere );	

			if ( lights )
			{
				lights[0].setPosition( 10, 20, 10);
				if ( lights[0].shadowMapEnabled )
				{
					lights[0].addToShadowMap( _cubeInstanced );
					lights[0].addToShadowMap( cube );
					lights[0].addToShadowMap( torus );
					lights[0].addToShadowMap( sphere );
				}
				if ( lights[1].shadowMapEnabled )
				{
					lights[1].addToShadowMap( _cubeInstanced );
					lights[1].addToShadowMap( cube );
					lights[1].addToShadowMap( torus );
					lights[1].addToShadowMap( sphere );
				}
			}
		}

		// animation is performed in onAnimate
		protected var _viewportSizeX:Number = 1;
		protected var _viewportSizeY:Number = 1;
		protected var _viewportCenterX:Number = 0;
		protected var _viewportCenterY:Number = 0;
		override protected function onAnimate( t:Number, dt:Number ):void
		{
			_viewportSizeX = .5 + Math.sin( t ) * .2;
			_viewportSizeY = .5 + Math.sin( t * .8 ) * .2;
			_viewportCenterX = Math.sin( t * .5 ) * .5;
			_viewportCenterY = Math.cos( t * .5 ) * .5;
			
			var L:Number = _viewportCenterX - _viewportSizeX; 
			var R:Number = _viewportCenterX + _viewportSizeX; 
			var B:Number = _viewportCenterY - _viewportSizeY; 
			var T:Number = _viewportCenterY + _viewportSizeY; 

			_camera.aspect = _viewportSizeX / _viewportSizeY;
			_camera.setViewport( true, L, R, B, T );
			//_camera.setViewport( true, -.5, .5, -.5, .5 );
			//_camera.setViewport( true,   0,  1, 0, 1 );

			if ( _cubeInstanced )
				_cubeInstanced.setPosition( Math.cos( t * 2 ) * 3, 6, Math.sin( t * 2 ) * 3 );
		}

		override protected function enterFrameEventHandler( event:Event ):void
		{
			callPresentOnRender = false;
			super.enterFrameEventHandler( event );
			instance.present();
		}
	}
}