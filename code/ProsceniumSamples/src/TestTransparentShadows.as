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
	public class TestTransparentShadows extends BasicDemo
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		protected static const AXIS:Vector3D						= new Vector3D(
			1 / Math.sqrt( 3 ),
			1 / Math.sqrt( 3 ),
			1 / Math.sqrt( 3 )
		);
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _castersSet:SceneNode;
		protected var _donut:SceneMesh;
		protected var _initialized:Boolean;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function TestTransparentShadows()
		{
			super();
			shadowMapEnabled = true;
			SceneGraph.OIT_ENABLED = true;
			SceneGraph.OIT_LAYERS = 2;				// Set to two to see the first two layers of transparency properly ordered. Valid range is 1 to 2
			SceneGraph.OIT_HYBRID_ENABLED = false;	// We leave false, since there are no particles
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function initModels():void
		{
			var filenames:Vector.<String> = new Vector.<String>();
			
			filenames.push( "../res/content/metal011.jpg" );
			filenames.push( "../res/content/tile004.jpg" );
			filenames.push( "../res/content/asphalt002.jpg" );
			
			LoadTracker.loadImages( filenames, imageCallback );
		}
		
		protected function imageCallback( bitmaps:Dictionary ):void
		{
			var metal:TextureMap = new TextureMap( bitmaps[ "../res/content/metal011.jpg" ].bitmapData );
			var tile:TextureMap = new TextureMap( bitmaps[ "../res/content/tile004.jpg" ].bitmapData );
			var asphalt:TextureMap = new TextureMap( bitmaps[ "../res/content/asphalt002.jpg" ].bitmapData );
			
			var material:MaterialStandard = new MaterialStandard();
			material.diffuseColor.set( .5, .5, .5 );
			material.specularColor.set( .0, .0, .0 );
			material.specularExponent = 30;
			
			plane = MeshUtils.createFractalTerrain( 100, 100, 300, 300, 0*50, 0.35, 1, 1, material, "terrain" );
			plane.transform.appendTranslation( 0, -30, 0 );
			scene.addChild( plane );
			
			_castersSet = new SceneNode( "castersSet" );
			scene.addChild( _castersSet );
			
			var sphere1Material:MaterialStandard = new MaterialStandard( "sphere 1" );
			sphere1Material.diffuseColor.set( .5, .5, .5 );
			sphere1Material.specularColor.set( 1, .87, .65 );
			sphere1Material.specularExponent = 25;
			sphere1Material.diffuseMap = metal;
			
			// set opacity here
			sphere1Material.opacity = 3/9 + 0/18;
			
			// Transparent shadows need to use 3x3 sampling
			SceneLight.oneLayerTransparentShadows = true;
			SceneLight.shadowMapSamplingDistantLights = RenderSettings.SHADOW_MAP_SAMPLING_2x2; // For transparent shadows needs to be 3x3 but for now, two lights with transparent shadows and 3x3 exceeds the shader limits
			SceneLight.shadowMapSamplingSpotLights = RenderSettings.SHADOW_MAP_SAMPLING_3x3;
			// UNFORTUNATELY, forced mipmapping of cube maps reduces the dithering of the level 0
			// map and the transparent shadows do not work for point light sources.
			// Thus add a spot light as light 2 and remove the point light 1 from the scene
			if ( lights && lights.length > 1)
			{
				lights[1].removeFromScene();
				
				var light:SceneLight = new SceneLight();
				light.color.set( .5, .6, .7 );
				light.appendTranslation( -0, 45, 0 );
				light.kind = "spot";
				light.shadowMapEnabled = shadowMapEnabled;
				light.setShadowMapSize( shadowMapSize, shadowMapSize );
				
				light.transform.prependRotation( -90, Vector3D.X_AXIS );
				lights[1] = light;
				
				scene.addChild( light );
			}
			
			var sphere1:SceneMesh = MeshUtils.createSphere( 6, 32, 32, sphere1Material, "Sphere 1" );
			sphere1.transform.appendTranslation( 0, 15, 0 );
			_castersSet.addChild( sphere1 );
			
			var sphere2Material:MaterialStandard = new MaterialStandard( "sphere 2" );
			sphere2Material.diffuseColor.set( .5, .25, .15 );
			sphere2Material.specularColor.set( .15, .15, .15 );
			sphere2Material.specularExponent = 60;
			sphere2Material.diffuseMap = tile;
			var sphere2:SceneMesh = MeshUtils.createSphere( 6, 32, 32, sphere2Material, "Sphere 2" );
			sphere2.transform.appendTranslation( 15, 15, 5 );
			_castersSet.addChild( sphere2 );
			
			var donutMaterial:MaterialStandard = new MaterialStandard( "donut" );
			donutMaterial.diffuseColor.set( .5, .5, .5 );
			donutMaterial.specularColor.set( .15, .15, .15 );
			donutMaterial.specularExponent = 60;
			donutMaterial.diffuseMap = asphalt;
			_donut = MeshUtils.createDonut( 1.5, 5.0, 50,10, donutMaterial, "Donut" );
			_donut.transform.appendTranslation( 5, 5, 5 );
			_castersSet.addChild( _donut );
			
			// define shadow casters
			if ( lights )
			{
				if ( lights[0] && lights[0].shadowMapEnabled ) lights[ 0 ].addToShadowMap( _castersSet );			
				if ( lights[1] && lights[1].shadowMapEnabled ) lights[ 1 ].addToShadowMap( _castersSet );
			}
			
			instance.backgroundColor.set( .2,.7,.8);
			instance.primarySettings.fogMode = RenderSettings.FOG_DISABLED; //FOG_EXP;
			instance.primarySettings.fogDensity = 50;
			
			_initialized = true;
		}
		
		override protected function enterFrameEventHandler( event:Event ):void
		{
			if ( !_initialized )
				return;
			
			callPresentOnRender = false;
			super.enterFrameEventHandler( event );
			
			if ( false )
			{
				var w:Number    = 512;
				var xpos:Number = 0;
				for each ( var lt:SceneLight in lights )
				{
					if ( lt.shadowMap )
					{
						lt.shadowMap.showMeTheTexture( instance, instance.width, instance.height, xpos, 0, w );
					}
					xpos += w;
				}
			}
	
			instance.present();
		}
		
		override protected function onAnimate( t:Number, dt:Number ):void
		{
			if ( !_initialized )
				return;
			
			var x:Number, y:Number, z:Number;
			
			// animate lights
			//			if ( lights && lights[ 0 ] )
			//			{
			//				x = 10 * Math.sin( t );
			//				y = 40;
			//				z = 10 * Math.cos( t )
			//					
			//				lights[ 0 ].transform.identity();
			//				lights[ 0 ].transform.appendTranslation( x, y, z );
			//				lights[ 0 ].dirtyTransform();
			//			}
			//
			//			if ( lights && lights[ 1 ] )
			//			{
			//				x = 15 * Math.sin( t*2 );
			//				y = -10;
			//				//z = 10 * Math.cos( t )
			//					
			//				lights[ 1 ].setPosition( x, y, z );
			//				lights[ 1 ].dirtyTransform();
			//			}
			
			// move casters
			x = 15 * Math.sin( t ) + 5;
			y = 5; 
			z = 15 * Math.cos( t ) + 5;
			_donut.setPosition( x, y, z );
			
			_donut.appendRotation( 2, AXIS );
		}
	}
}