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
	import com.adobe.scenegraph.loaders.*;
	import com.adobe.scenegraph.loaders.obj.*;
	import com.adobe.utils.*;
	
	import flash.display.*;
	import flash.display3D.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class TestEnvironmentMap extends BasicDemo
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		protected static const SKYBOX_FILENAMES:Vector.<String>		= new <String>[
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
		protected var _objLoader:OBJLoader;
		protected var _sky:SceneSkyBox;
		protected var _spheres:Vector.<SceneNode>;
		protected var _sphereMaps:Vector.<RenderTextureCube>;
		protected var _mirror:SceneMesh;
		protected var _mirrorRefMap:RenderTextureReflection; 
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function TestEnvironmentMap()
		{
			super();
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function initLights():void
		{
			lights = new Vector.<SceneLight>();
			var light:SceneLight;
			var sphere:SceneMesh;
			
			// --------------------------------------------------
			//	Point Light
			// --------------------------------------------------
			light = new SceneLight();
			light.kind = "point";
			light.color.set( .4, .45, .5 );
			light.move( 0, 1000, -250 );
			lights.push( light );
			
			light = new SceneLight();
			light.kind = "point";
			light.color.set( .25, .25, .25 );
			light.move( 0, -1000, 100 );
			lights.push( light );
			
			// --------------------------------------------------
			//	Distant Light
			// --------------------------------------------------
			light = new SceneLight();
			light.kind = "distant";
			light.color.set( 1, .98, .95 );
			//dir = new Vector3D( -0.1, -1, -1 );
			light.transform.prependRotation( -90, Vector3D.Y_AXIS );
			light.transform.prependRotation( -45, Vector3D.X_AXIS );
			lights.push( light );
			
			// --------------------------------------------------
			
			for each ( light in lights ) {
				scene.addChild( light );
			}
		}

		override protected function initModels():void
		{
			super.initModels();

			LoadTracker.loadImages( SKYBOX_FILENAMES, imageLoadComplete );
		}
		
		protected function imageLoadComplete( bitmaps:Dictionary ):void
		{
			var bitmapDatas:Vector.<BitmapData> = new Vector.<BitmapData>( 6, true );
			var bitmap:Bitmap;
			
			for ( var i:uint = 0; i < 6; i++ )
				bitmapDatas[ i ] = bitmaps[ SKYBOX_FILENAMES[ i ] ].bitmapData;
			
			_sky = new SceneSkyBox( bitmapDatas, false );
			_sky.name = "Sky";
			scene.addChild( _sky );
			
			var modelURI:String = "../res/content/teapot.obj";
			_objLoader = new OBJLoader( modelURI );
			_objLoader.addEventListener( Event.COMPLETE, completeEventHandler, false, 0, true );
		}
		
		protected function completeEventHandler( event:Event ):void
		{
			var loader:OBJLoader = event.target as OBJLoader;
			var manifest:ModelManifest = loader.model.addTo( scene );
			
			var mesh:SceneMesh = manifest.meshes[ 0 ];
			//mesh.appendScale( 2, 2, 2 );
			
			var reflection:TextureMapCube = _sky.cubeMap;
			
			var count:uint = mesh.elementCount;
			for ( var i:uint = 0; i < count; i++ )
			{
				var material:MaterialStandard = mesh.getElementByIndex( i ).material as MaterialStandard;
				
				// Make the material reflective
				material.environmentMap = reflection;
				material.environmentMapStrength = .25;
			}
		}
	}
}