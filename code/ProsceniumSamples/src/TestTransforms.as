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
	
	import flash.display3D.*;
	import flash.geom.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class TestTransforms extends BasicDemo
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		private static const NUM_CUBES:uint							= 100;
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _cubes:Vector.<SceneMesh>;
		protected var _initialized:Boolean;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function TestTransforms()
		{
			super();
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function resetCamera():void
		{
			instance.setCulling( Context3DTriangleFace.FRONT );
			
			_camera = scene.activeCamera;
			_camera.identity();
			_camera.appendTranslation( 0, 0, 200 );
			_camera.appendRotation( -70, Vector3D.X_AXIS );
		}
		
		override protected function initLights():void
		{
			var light:SceneLight = new SceneLight( "light" ); 
			light.color.set( 1, .98, .95 );
			light.appendTranslation( -20, 20, 20 );
			light.kind = "distant";
			light.transform.prependRotation( -35, Vector3D.Y_AXIS );
			light.transform.prependRotation( -70, Vector3D.X_AXIS );
			scene.addChild( light );
		}
		
		override protected function initModels():void 
		{
			instance.setCulling( Context3DTriangleFace.FRONT );
			
			var parent:SceneNode;
			var axis:Vector3D = new Vector3D( 0, 0, -1 );
			
			_cubes = new Vector.<SceneMesh>( NUM_CUBES, true );
			for ( var i:uint = 0; i < NUM_CUBES; i++ )
			{
				var j:uint = i + 1;
				
				var cube:SceneMesh = MeshUtils.createCube( i + j );
				
				if ( !parent )
					parent = scene;
				
				parent.addChild( cube );
				parent = cube;
				cube.appendRotation( -10, axis );
				cube.appendTranslation( 0, 0, -j * j );
				
				_cubes[ i ] =  cube;
			}
			
			_initialized = true;
		}
		
		override protected function onAnimate( t:Number, dt:Number ):void
		{
			if ( !_initialized )
				return;
			
			var angle:Number = 5 * dt;
			
			for each ( var cube:SceneMesh in _cubes ) {
				cube.appendRotation( angle, Vector3D.Y_AXIS );
			}
		}
	}
}