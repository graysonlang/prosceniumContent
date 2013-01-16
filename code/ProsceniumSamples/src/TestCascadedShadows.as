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
	import flash.display3D.textures.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	/**
	 * TestCascadedShadows demonstrates setting up cascaded shadows.
	 * 
	 * <p>Press 'b' to show the bounding boxes around the objects in the scene.</p>
	 */
	public class TestCascadedShadows extends BasicDemo
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		protected static const AXIS:Vector3D						= new Vector3D(
			1 / Math.sqrt( 3 ),
			1 / Math.sqrt( 3 ),
			1 / Math.sqrt( 3 )
		);
		
		protected static const FILENAMES:Vector.<String>			= new <String>[
			"../res/content/metal011.jpg",
			"../res/content/tile004.jpg",
			"../res/content/asphalt002.jpg"
		];
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _castersSet:SceneNode;
		protected var _donut:SceneMesh;
		protected var _initialized:Boolean;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function TestCascadedShadows()
		{
			super();
			shadowMapEnabled = true;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function initModels():void
		{
			LoadTracker.loadImages( FILENAMES, imageCallback );
		}
		
		override protected function initLights():void
		{
			// This value must be set before the shadow map is created - before the lights are initialized
			SceneLight.cascadedShadowMapCount = 4; // 4 shadow maps in one texture. We support 2 and 4, but only for distant lights.
			SceneLight.shadowMapSamplingDistantLights = RenderSettings.SHADOW_MAP_SAMPLING_3x3;
			SceneLight.shadowMapSamplingDistantLights = RenderSettings.SHADOW_MAP_SAMPLING_3x3;
			SceneLight.oneLayerTransparentShadows = true; // Has the effect of using a 4x4 with edge weighting which improves the appearance of the shadows, making them less jagged
			
			// --------------------------------------------------
			//	Light #1
			// --------------------------------------------------
			lights = new Vector.<SceneLight>();
			var light:SceneLight;
			
			light = new SceneLight( SceneLight.KIND_DISTANT, "distant light" );
			light.color.set( .9, .88, .85 );
			light.shadowMapEnabled = shadowMapEnabled;
			light.setShadowMapSize( shadowMapSize, shadowMapSize );
			light.transform.prependRotation( -95, Vector3D.X_AXIS );
			light.transform.appendTranslation( 0.1, 2, 0.1 );
			lights.push( light );
						
			// --------------------------------------------------
			//	Light #2
			// --------------------------------------------------
			light = new SceneLight( SceneLight.KIND_POINT, "point light" );
			light.color.set( .5, .6, .7 );
			light.appendTranslation( -20, 20, 20 );
			light.shadowMapEnabled = shadowMapEnabled;
			light.setShadowMapSize( shadowMapSize, shadowMapSize );
			
			light.transform.prependRotation( -90, Vector3D.X_AXIS );
			light.transform.prependRotation( 35, Vector3D.Y_AXIS );
			
			//	lights.push( light );
			
			// --------------------------------------------------
			//	Light #3
			// --------------------------------------------------
			light = new SceneLight();
			light.color.set( .25, .22, .20 );
			light.kind = "distant";
			light.appendRotation( -90, Vector3D.Y_AXIS, ORIGIN );
			light.appendRotation( 45, Vector3D.Z_AXIS, ORIGIN );			
			lights.push( light );
			
			// --------------------------------------------------
			
			for each ( light in lights ) {
				scene.addChild( light );
			}
		}
		
		protected function imageCallback( bitmaps:Dictionary ):void
		{
			var metal:TextureMap = new TextureMap( bitmaps[ FILENAMES[ 0 ] ].bitmapData );
			var tile:TextureMap = new TextureMap( bitmaps[ FILENAMES[ 1 ] ].bitmapData );
			var asphalt:TextureMap = new TextureMap( bitmaps[ FILENAMES[ 2 ] ].bitmapData );
			
			var material:MaterialStandard = new MaterialStandard();
			material.diffuseColor.set( 0.35, .35, 0.35 );
			material.ambientColor.set( 1.5, 1.5, 1.5 );
			material.specularColor.set( 0, 0, 0 );
			material.specularExponent = 30;
			
			plane = MeshUtils.createFractalTerrain( 100, 100, 900, 900, .35, 0 * 50, 1, 1, material, "terrain" );
			plane.transform.appendTranslation( 0, -30, 0 );
			scene.addChild( plane );
			
			var material2:MaterialStandard = new MaterialStandard();
			material2.diffuseColor.set( .7, .7, .7 );
			material2.specularColor.set( .0, .0, .0 );
			material2.specularExponent = 10;
			material2.opacity = 0.5;
			var plane2:SceneMesh = MeshUtils.createPlane( 400, 400, 1, 1, material, "plane2" );
			plane2.transform.appendRotation( 60, Vector3D.Z_AXIS, ORIGIN );
			//plane2.transform.appendRotation( -45, Vector3D.Y_AXIS, ORIGIN );
			plane2.transform.appendTranslation( 30, 0, 0 );
			//scene.addChild( plane2 );
			
			var plane3:SceneMesh = MeshUtils.createPlane( 400, 400, 1, 1, material, "plane3" );
			plane3.transform.appendRotation( 70, Vector3D.X_AXIS, ORIGIN );
			plane3.transform.appendRotation( 45, Vector3D.Y_AXIS, ORIGIN );
			plane3.transform.appendTranslation( 30, 0, -60 );
			//scene.addChild( plane3 );
			
			_castersSet = new SceneNode( "castersSet" );
			scene.addChild( _castersSet );
			
			//_castersSet.addChild( plane );
			//_castersSet.addChild( plane2 );
			//_castersSet.addChild( plane3 );
			
			var sphere2Material:MaterialStandard = new MaterialStandard( "sphere 2" );
			sphere2Material.diffuseColor.set( .5, .25, .15 );
			sphere2Material.specularColor.set( .15, .15, .15 );
			sphere2Material.specularExponent = 60;
			sphere2Material.diffuseMap = tile;
			var sphere2:SceneMesh = MeshUtils.createSphere( 6, 32, 32, sphere2Material, "Sphere 2" );
			if (false)
			{
				for (var i:uint = 0; i < 900; i+=20)
				{
					for (var j:uint = 0; j < 900; j+=40)
					{
						var sphereInstanced:SceneMesh = sphere2.instance();
						//sphere2.transform.appendTranslation( 15, 15, 5 );
						sphereInstanced.transform.appendTranslation( -450 + j, 15, -450 + i );
						_castersSet.addChild( sphereInstanced );
					}
				}
			} else {
				for (var i:uint = 0; i < 900; i+=20)
				{
					for (var j:uint = 0; j < 900; j+=40)
					{
						sphere2.createTransformInstanceByPosition( -450 + j, 15, -450 + i );
					}
				}
				_castersSet.addChild( sphere2 );
			}
			
			var donutMaterial:MaterialStandard = new MaterialStandard( "donut" );
			donutMaterial.diffuseColor.set( .5, .5, .5 );
			donutMaterial.specularColor.set( .15, .15, .15 );
			donutMaterial.specularExponent = 60;
			donutMaterial.diffuseMap = asphalt;
			_donut = MeshUtils.createDonut( 1.5, 5.0, 50, 10, donutMaterial, "Donut" );
			_donut.transform.appendTranslation( -15, 5, 5 );
			_castersSet.addChild( _donut );
			
			// define shadow casters
			if ( lights )
			{
				if ( lights[ 0 ] && lights[ 0 ].shadowMapEnabled )
					lights[ 0 ].addToShadowMap( _castersSet );
				
				// Disable the second light because otherwise we won't fit into the fragment program
				if ( lights[ 1 ] && lights[ 1 ].shadowMapEnabled )
					lights[ 1 ].shadowMapEnabled = false;
			}
						
			instance.backgroundColor.set( .2,.7,.8);
			instance.primarySettings.fogMode = RenderSettings.FOG_EXP;
			instance.primarySettings.fogDensity = 500;
			
			scene.ambientColor.set(0.5, 0.5, 0.5, 1.0);

			_initialized = true;
		}
		
		override protected function enterFrameEventHandler( event:Event ):void
		{
			if ( !_initialized )
				return;
			
			callPresentOnRender = false;
			super.enterFrameEventHandler( event );
			
			//var w:Number  = 200;
			//if ( lights && lights[ 0 ] && lights[ 0 ].shadowMap )
			//	lights[ 0 ].shadowMap.showMeTheTexture( instance, instance.width, instance.height, 0, 0, w );
			//
			//if ( lights && lights[ 1 ] && lights[ 1 ].shadowMap )
			//	lights[ 1 ].shadowMap.showMeTheTexture( instance, instance.width, instance.height, w, 0, w );
			
			instance.present();
		}
		
		override protected function onAnimate( t:Number, dt:Number ):void
		{
			if ( !_initialized )
				return;
			
			var x:Number, y:Number, z:Number;
			
			// animate lights
			//if ( lights && lights[ 0 ] )
			//{
			//	x = 10 * Math.sin( t );
			//	y = 40;
			//	z = 10 * Math.cos( t )
			//		
			//	lights[ 0 ].transform.identity();
			//	lights[ 0 ].transform.appendTranslation( x, y, z );
			//	lights[ 0 ].dirtyTransform();
			//}
			//
			//if ( lights && lights[ 1 ] )
			//{
			//	x = 15 * Math.sin( t*2 );
			//	y = -10;
			//	//z = 10 * Math.cos( t )
			//		
			//	lights[ 1 ].setPosition( x, y, z );
			//	lights[ 1 ].dirtyTransform();
			//}
			
			// move casters
			x = 15 * Math.sin( t ) + 5;
			y = 5; 
			z = 15 * Math.cos( t ) + 5;
			_donut.setPosition( x, y, z );
			
			_donut.appendRotation( 2, AXIS );
		}
	}
}
