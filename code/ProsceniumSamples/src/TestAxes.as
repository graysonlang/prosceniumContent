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
	import com.adobe.scenegraph.loaders.obj.*;
	
	import flash.display.*;
	import flash.display3D.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class TestAxes extends BasicDemo
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _objLoader:OBJLoader;
		protected var _colladaLoader:ColladaLoader;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function TestAxes()
		{
			super();
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function initModels():void 
		{
			scene.addChild( new SceneAxes() );
			
			_objLoader = new OBJLoader( "../res/content/teapot.obj" );
			_objLoader.addEventListener( Event.COMPLETE, completeEventHandler, false, 0, true );
		}
		
		override protected function resetCamera():void
		{
			_camera = scene.activeCamera;
			_camera.identity();
			_camera.lookat( new Vector3D( 5, 10, 20 ), new Vector3D( 0, 0, 0 ), new Vector3D( 0, 1, 0 ) );
		}
		
		protected function completeEventHandler( event:Event ):void
		{
			var loader:ModelLoader = event.target as ModelLoader;
			var manifest:ModelManifest = loader.model.addTo( scene );
			trace( scene );
		}
	}
}