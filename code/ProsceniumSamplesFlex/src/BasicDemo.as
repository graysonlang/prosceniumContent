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
	
	import flash.display.*;
	import flash.display3D.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class BasicDemo extends BasicScene
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		protected static const CAMERA_ORIGIN:Vector3D				= new Vector3D( 0, 0, 20 );
		protected static const ORIGIN:Vector3D						= new Vector3D();
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var plane:SceneMesh;
		public var lights:Vector.<SceneLight>;
		public var shadowMapEnabled:Boolean = false;
		public var shadowMapSize:uint = 1024;
		public var enableLightSpheres:Boolean = false;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function BasicDemo( renderMode:String = Context3DRenderMode.AUTO )
		{
			super( renderMode );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function initLights():void
		{
			var material:MaterialStandard;
			
			// --------------------------------------------------
			//	Light #1
			// --------------------------------------------------
			lights = new Vector.<SceneLight>();
			var light:SceneLight;
			var sphere:SceneMesh;
			
			light = new SceneLight();
			light.kind = "point";
			light.color.set( 1, .98, .95 );
			light.move( 20, 15, -20 );
			//light.shadowMapEnabled = shadowMapEnabled;
			light.setShadowMapSize( shadowMapSize, shadowMapSize );
			lights.push( light );
			
			if ( enableLightSpheres )
			{
				material = new MaterialStandard( "light1" );
				material.emissiveColor = light.color;
				sphere = MeshUtils.createSphere( .5, undefined, undefined, material, "light sphere1"  );
				light.addChild( sphere );
			}
			
			// --------------------------------------------------
			//	Light #2
			// --------------------------------------------------
			light = new SceneLight();
			light.color.set( .5, .6, .7 );
			light.appendTranslation( -20, 20, 20 );
			//light.kind = "spot";
			light.kind = "distant";
			light.shadowMapEnabled = shadowMapEnabled;
			light.setShadowMapSize( shadowMapSize, shadowMapSize );
			light.transform.prependRotation( -45, Vector3D.Y_AXIS );
			light.transform.prependRotation( -70, Vector3D.X_AXIS );
			
			if ( enableLightSpheres )
			{
				material = new MaterialStandard( "light2" );
				material.emissiveColor = light.color;
				sphere = MeshUtils.createSphere( .5, undefined, undefined, material, "light sphere2"  );
				light.addChild( sphere );
			}
			lights.push( light );
			
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
			
			for each ( light in lights )
			{
				scene.addChild( light );
				
				if ( light.shadowMapEnabled )
				{
					light.createShadowMap();
				}
			}
		}
		
		override protected function initModels():void
		{
			var material:MaterialStandard = new MaterialStandard();
			material.specularColor.set( .5, .5, .5 );
			material.specularExponent = 25;
			
			plane = MeshUtils.createPlane( 50, 50, 20, 20, material, "plane" );
			plane.transform.appendTranslation( 0, -2, 0 );
			scene.addChild( plane );
		}
		
		override protected function resetCamera():void
		{
			_camera = scene.activeCamera;
			_camera.identity();
			_camera.position = CAMERA_ORIGIN;
			_camera.appendRotation( -15, Vector3D.X_AXIS );
			_camera.appendRotation( -25, Vector3D.Y_AXIS, ORIGIN );
		}
		
		// ======================================================================
		//	Event Handler Related
		// ----------------------------------------------------------------------
		override protected function onAnimate( t:Number, dt:Number ):void
		{
			
		}
		
		override protected function keyboardEventHandler( event:KeyboardEvent ):void
		{
			var dirty:Boolean = false;
			_camera = scene.activeCamera;
			
			switch( event.type )
			{
				case KeyboardEvent.KEY_DOWN:
				{
					dirty = true;
					
					switch( event.keyCode )
					{
						case 79:	// o
							SceneGraph.OIT_ENABLED = !SceneGraph.OIT_ENABLED;
							trace( "Stenciled Layer Peeling:", SceneGraph.OIT_ENABLED ? "enabled" : "disabled" );
							break;
						
						case 66:	// b
							instance.drawBoundingBox = !instance.drawBoundingBox;
							break;
						
						case 84:	// t
							instance.toneMappingEnabled = !instance.toneMappingEnabled;
							trace( "Tone mapping:", instance.toneMappingEnabled ? "enabled" : "disabled" );
							break;
						
						case 48:	// 0
						case 49:	// 1
						case 50:	// 2
						case 51:	// 3
						case 52:	// 4
						case 53:	// 5
						case 54:	// 6
						case 55:	// 7
						case 56:	// 8
						case 57:	// 9
							instance.toneMapScheme = event.keyCode - 48;
							trace( "Tone map scheme:", instance.toneMapScheme );
							break;
						
						default:
							super.keyboardEventHandler( event );
							dirty = false;
					}	
				}
			}
			
			if ( dirty )
				_dirty = true;
		}
	}
}