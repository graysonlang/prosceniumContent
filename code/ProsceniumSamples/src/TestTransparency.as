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
	import com.adobe.scenegraph.*;
	import com.adobe.scenegraph.loaders.*;
	import com.adobe.scenegraph.loaders.collada.*;
	
	import flash.display.Bitmap;
	import flash.display3D.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class TestTransparency extends BasicDemo
	{
		// ======================================================================
		//	Embedded Resources
		// ----------------------------------------------------------------------
		[ Embed( source="/../res/content/tile004.jpg" ) ]
		protected static const BITMAP:Class;
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _colladaLoader:ColladaLoader;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function TestTransparency()
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
		override protected function resetCamera():void
		{
			_camera = scene.activeCamera;
			_camera.identity();
			_camera.appendTranslation( 0, 5, 30 );
			_camera.appendRotation( -35, Vector3D.X_AXIS, ORIGIN );
			_camera.appendRotation( -145, Vector3D.Y_AXIS, ORIGIN );
		}
		
		override protected function initModels():void
		{
			//instance.setCulling( Context3DTriangleFace.FRONT );
			
			_colladaLoader = new ColladaLoader( "../res/content/Transparency.dae" );
			_colladaLoader.addEventListener( Event.COMPLETE, completeEventHandler, false, 0, true );
		}
		
		protected function completeEventHandler( event:Event ):void
		{
			SceneLight.oneLayerTransparentShadows = true;
			SceneLight.shadowMapSamplingDistantLights = RenderSettings.SHADOW_MAP_SAMPLING_3x3;
			SceneLight.shadowMapSamplingSpotLights = RenderSettings.SHADOW_MAP_SAMPLING_3x3;
			SceneLight.shadowMapZBiasFactor		  			= 1;//2;
			SceneLight.shadowMapVertexOffsetFactor			= 0;//3;
			SceneLight.shadowMapSamplerNormalOffsetFactor	= 2;

			var node:SceneNode = new SceneNode( "root" );
			
			var manifest:ModelManifest = _colladaLoader.model.addTo( node );
			node.appendScale( 10, 10, 10 );
			scene.addChild( node );
			trace( scene );
			
			var bitmap:Bitmap = new BITMAP() as Bitmap;
			var tile:TextureMap = new TextureMap( bitmap.bitmapData );

			var opaqueMaterial:MaterialStandard;
			
			opaqueMaterial = new MaterialStandard();
			opaqueMaterial.diffuseColor.set( .2, .4, .2 );
			opaqueMaterial.specularColor.set( 1, 1, 1 );
			opaqueMaterial.specularExponent = 20;

			var knot:SceneMesh = node.getDescendantByName( "Torus_Knot" ) as SceneMesh;
			knot.applyMaterial( opaqueMaterial );
			
			// ------------------------------
		
			var transparentMaterial:MaterialStandard = new MaterialStandard();
			transparentMaterial.ambientColor.set( .35, .35, .35 );
			transparentMaterial.diffuseColor.set( .75, .75, .75 );
			transparentMaterial.specularColor.set( .15, .15, .15 );
			transparentMaterial.specularExponent = 60;
			transparentMaterial.opacity = .5
			transparentMaterial.diffuseMap = tile;
			
			//transparentMaterial = new MaterialStandard();
			//transparentMaterial.diffuseColor.set( .4, .6, .8 );
			//transparentMaterial.specularColor.set( .6, .8, 1 );
			//transparentMaterial.specularExponent = 60;
			//transparentMaterial.opacity = 0.5;

			var wall:SceneMesh = node.getDescendantByName( "Box" ) as SceneMesh;
			wall.applyMaterial( transparentMaterial );
			
			//transparentMaterial = new MaterialStandard();
			//transparentMaterial.diffuseColor.set( 1, 0, 0 );
			//transparentMaterial.specularColor.set( 1, 1, 1 );
			//transparentMaterial.specularExponent = 30;
			//transparentMaterial.opacity = 0.5;
			var teapot:SceneMesh = node.getDescendantByName( "Teapot" ) as SceneMesh;
			teapot.applyMaterial( transparentMaterial );
			
			trace( "elements Count", wall.elementCount );

			//transparentMaterial = new MaterialStandard();
			//transparentMaterial.diffuseColor.set( .5, .25, .15 );
			//transparentMaterial.specularColor.set( .15, .15, .15 );
			//transparentMaterial.specularExponent = 60;
			//transparentMaterial.opacity = .5

			var sphere:SceneMesh = MeshUtils.createSphere( 6, 32, 32, transparentMaterial, "Sphere" );
			sphere.transform.appendTranslation( 15, 15, 5 );
			scene.addChild( sphere );
			
			scene.ambientColor.set(1.0, 1.0, 1.0);
			
			// define shadow casters
			if ( lights )
			{
				if ( lights[0] && lights[0].shadowMapEnabled ) lights[ 0 ].addToShadowMap( knot );			
				if ( lights[0] && lights[0].shadowMapEnabled ) lights[ 0 ].addToShadowMap( teapot );			
				if ( lights[0] && lights[0].shadowMapEnabled ) lights[ 0 ].addToShadowMap( wall );			
				if ( lights[1] && lights[1].shadowMapEnabled ) lights[ 1 ].addToShadowMap( knot );
				if ( lights[1] && lights[1].shadowMapEnabled ) lights[ 1 ].addToShadowMap( teapot );			
			}

		}
		
		override protected function enterFrameEventHandler( event:Event ):void
		{			
			callPresentOnRender = false;
			super.enterFrameEventHandler( event );
			
			if ( false ) // Set to true to show the shadow map
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
	}
}