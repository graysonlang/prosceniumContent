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
	import com.adobe.transforms.*;
	import com.adobe.utils.*;
	import com.adobe.wiring.*;
	
	import flash.display3D.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	/**
	 * TestFog deomonstrates fogging feature.
	 * 
	 * To enable fog to the primary use instance.primarySettings, and 
	 * to enable fog to render target textures, use RenderTextureBase.targetSettings instead 
	 * 
	 * OpenGL GL_LINEAR - equivalent fog to primary
	 * <pre>
	 *   instance.primarySettings.fogMode = RenderSettings.FOG_LINEAR;
	 *   instance.primarySettings.fogStart = 0;
	 *   instance.primarySettings.fogEnd   = .01;
	 * </pre>
	 *
 	 * OpenGL GL_EXP - equivalent fog to primary
	 * <pre>
	 *   instance.primarySettings.fogMode = RenderSettings.FOG_EXP;
	 *   instance.primarySettings.fogDensity = 50;
	 * </pre>
	 * 
 	 * OpenGL GL_EXP2 - equivalent fog to primary
	 * <pre>
	 *   instance.primarySettings.fogMode = RenderSettings.FOG_EXP2;
	 *   instance.primarySettings.fogDensity = 50;
	 * </pre>
	 */
	public class TestFog extends BasicDemo
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _modelName:String;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function TestFog()
		{
			super();
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function resetCamera():void
		{
			_camera = scene.activeCamera;
			_camera.identity();
			_camera.setPosition( 0, 8, 30 );
			_camera.appendRotation( -20, Vector3D.X_AXIS );
			_camera.appendRotation( -35, Vector3D.Y_AXIS );
		}
		
		override protected function initModels():void
		{
			instance.backgroundColor.set( .5,.5,.8);
			instance.primarySettings.fogMode = RenderSettings.FOG_LINEAR;
			instance.primarySettings.fogStart = 0;
			instance.primarySettings.fogEnd   = .01;
			instance.primarySettings.fogDensity = 50;
			
			var cube:SceneMesh = MeshUtils.createCube( 5 );
			cube.appendTranslation( 0, 6, -10 );
			scene.addChild( cube );
			
			cube = MeshUtils.createCube( 200 );
			cube.appendTranslation( 20000, 6, -20000 );
			scene.addChild( cube );
			
			cube = MeshUtils.createCube( 200 );
			cube.appendTranslation( -200, 6, -1000 );
			scene.addChild( cube );
			
			var plane:SceneMesh = MeshUtils.createPlane( 50000, 50000, 20, 20, null, "plane" );
			plane.transform.appendTranslation( 0, -50, 0 );
			scene.addChild( plane );
		}
	}
}