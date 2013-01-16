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
	import com.adobe.scenegraph.loaders.collada.*;
	import com.adobe.scenegraph.loaders.obj.*;
	import com.adobe.utils.*;
	
	import flash.display.*;
	import flash.display3D.*;
	import flash.display3D.textures.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class Tutorial04_LoadingModels extends BasicDemo
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		protected static const SKYBOX_DIRECTORY:String				= "../res/content/skybox/";
		protected static const SKYBOX_FILENAMES:Vector.<String>		= new <String>[
			SKYBOX_DIRECTORY + "px.png",
			SKYBOX_DIRECTORY + "nx.png",
			SKYBOX_DIRECTORY + "py.png",
			SKYBOX_DIRECTORY + "ny.png",
			SKYBOX_DIRECTORY + "pz.png",
			SKYBOX_DIRECTORY + "nz.png"
		];
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _sky:SceneSkyBox;
		protected var _modelLoader:OBJLoader;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function Tutorial04_LoadingModels()
		{
			super();
			shadowMapEnabled = true;
			
			// Turns on OIT by default
			// The OIT algorithm renders the nearest two transparent surfaces in order.
			// OIT is useful to render foliages without jaggy boundary
			// Press 'o' to toggle OIT
			SceneGraph.OIT_ENABLED = true;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function initModels():void
		{
			var plane:SceneMesh = MeshUtils.createPlane( 100, 100, 20, 20, null, "plane" );
			scene.addChild( plane );

			LoadTracker.loadImages( SKYBOX_FILENAMES, imageLoadComplete );
		}

		protected function imageLoadComplete( bitmaps:Dictionary ):void
		{
			var bitmapDatas:Vector.<BitmapData> = new Vector.<BitmapData>( 6, true );
			var bitmap:Bitmap;
			for ( var i:uint = 0; i < 6; i++ )
				bitmapDatas[ i ] = bitmaps[ SKYBOX_FILENAMES[ i ] ].bitmapData;
			
			// sky
			_sky = new SceneSkyBox( bitmapDatas, false );
			scene.addChild( _sky );	// skybox must be an immediate child of scene root
			_sky.name = "Sky"
			
			_modelLoader = new OBJLoader( "../res/content/PalmTrees/PalmTrees.obj" );
			_modelLoader.addEventListener( Event.COMPLETE, loadComplete);
		}
		
		protected function loadComplete( event:Event ):void
		{
			var tree:SceneNode = new SceneNode( "PalmTrees" );
			var manifest:ModelManifest = _modelLoader.model.addTo( tree );
			scene.addChild( tree );

			lights[0].addToShadowMap( scene );
			
			trace( scene );
		}
	}
}