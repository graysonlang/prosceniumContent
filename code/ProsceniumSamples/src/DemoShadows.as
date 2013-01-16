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
	 * DemoShadow demonstrates setting up shadows.
	 * 
	 * Proscenium supports three light types : point, spot, directional
	 * <ul>
	 *   <li> Point light's shadow map is a cube map. </li>
	 *   <li> Directional and spot lights' shadow map is a 2D texture map. </li>
	 * </ul>
	 * 
	 * <p>In BasicDemo applications, setting "shadowMapEnabled = true" will turn on shadows to the default lights.
	 * Shadow casters should be defined by lights[ 0 ].addToShadowMap( ... );
	 * For application not based on BasicDemo, but directly extends Sprite, shadow can be enabled per light.
	 * See Totorial_SpriteBased.as.</p>
	 * 
	 * <p>Press 'b' to show the bounding boxes around the objects in the scene.</p>
	 */
	public class DemoShadows extends BasicDemo
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
		public function DemoShadows()
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
		
		protected function imageCallback( bitmaps:Dictionary ):void
		{
			var metal:TextureMap = new TextureMap( bitmaps[ FILENAMES[ 0 ] ].bitmapData );
			var tile:TextureMap = new TextureMap( bitmaps[ FILENAMES[ 1 ] ].bitmapData );
			var asphalt:TextureMap = new TextureMap( bitmaps[ FILENAMES[ 2 ] ].bitmapData );
			
			var material:MaterialStandard = new MaterialStandard();
			material.diffuseColor.set( .5, .5, .5 );
			material.specularColor.set( .0, .0, .0 );
			material.specularExponent = 30;
			
			plane = MeshUtils.createFractalTerrain( 400, 400, 400, 400, 40, .2, 1, 1, material, "terrain" );

			plane.transform.appendTranslation( 0, -30, 0 );
			scene.addChild( plane );
			
			_castersSet = new SceneNode( "castersSet" );
			scene.addChild( _castersSet );
			
			var sphere1Material:MaterialStandard = new MaterialStandard( "sphere 1" );
			sphere1Material.diffuseColor.set( .5, .5, .5 );
			sphere1Material.specularColor.set( 1, .87, .65 );
			sphere1Material.specularExponent = 25;
			sphere1Material.diffuseMap = metal;
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
			_donut = MeshUtils.createDonut( 1.5, 5.0, 50, 10, donutMaterial, "Donut" );
			_donut.transform.appendTranslation( 5, 5, 5 );
			_castersSet.addChild( _donut );
			
			// define shadow casters
			if ( lights )
			{
				if ( lights.length > 0 && lights[ 0 ] && lights[ 0 ].shadowMapEnabled ) lights[ 0 ].addToShadowMap( scene );			
				if ( lights.length > 1 && lights[ 1 ] && lights[ 1 ].shadowMapEnabled ) lights[ 1 ].addToShadowMap( scene );
			}
			
			// shadow acne control
			SceneLight.shadowMapZBiasFactor		  			= 0;//2;
			SceneLight.shadowMapVertexOffsetFactor			= 0;//3;
			SceneLight.shadowMapSamplerNormalOffsetFactor	= 3;
			SceneLight.shadowMapSamplingDistantLights = RenderSettings.SHADOW_MAP_SAMPLING_3x3;
			SceneLight.oneLayerTransparentShadows = true;

			instance.backgroundColor.set( .2, .7, .8 );
			instance.primarySettings.fogMode = RenderSettings.FOG_EXP;
			instance.primarySettings.fogDensity = 500;

			_initialized = true;
		}
		
		override protected function enterFrameEventHandler( event:Event ):void
		{
			if ( !_initialized )
				return;
			
			callPresentOnRender = false;
			super.enterFrameEventHandler( event );
			
			var w:Number  = 200;
			if ( lights && lights.length > 0 && lights[ 0 ] && lights[ 0 ].shadowMap )
				lights[ 0 ].shadowMap.showMeTheTexture( instance, instance.width, instance.height, 0, 0, w );

			if ( lights && lights.length > 1 && lights[ 1 ] && lights[ 1 ].shadowMap )
				lights[ 1 ].shadowMap.showMeTheTexture( instance, instance.width, instance.height, w, 0, w );
			
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