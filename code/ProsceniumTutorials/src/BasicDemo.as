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
	
	/**
	 * BasicDemo provides default lighting and keyboard navigation features in addition to BasicScene features.
	 * BasicScene is a part of Proscenium, and is designed to provide some convenience features that Sprite does not have.
	 * BasicDemo is used for most of Proscenium samples. 
	 * Proscenium can also be used for applications that directly extend Sprite. See Tutorial_SpriteBased.as.
	 */
	public class BasicDemo extends BasicScene
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		protected static const CAMERA_ORIGIN:Vector3D				= new Vector3D( 0, 0, 20 );
		protected static const ORIGIN:Vector3D						= new Vector3D();
		protected static const PAN_AMOUNT:Number					= .25;
		protected static const ROTATE_AMOUNT:Number					= 4;
		
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
			
			light = new SceneLight( SceneLight.KIND_DISTANT, "distant light" );
			light.color.set( .9, .88, .85 );
			light.shadowMapEnabled = shadowMapEnabled;
			light.setShadowMapSize( shadowMapSize, shadowMapSize );
			light.transform.prependRotation( -95, Vector3D.X_AXIS );
			light.transform.appendTranslation( 0.1, 2, 0.1 );
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
			light = new SceneLight( SceneLight.KIND_POINT, "point light" );
			light.color.set( .5, .6, .7 );
			light.appendTranslation( -20, 20, 20 );
			light.shadowMapEnabled = shadowMapEnabled;
			light.setShadowMapSize( shadowMapSize, shadowMapSize );
			
			light.transform.prependRotation( -90, Vector3D.X_AXIS );
			light.transform.prependRotation( 35, Vector3D.Y_AXIS );
			
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
						case 13:	// Enter
							animate = !animate;
							break;
						
						case 16:	// Shift
						case 17:	// Ctrl
						case 18:	// Alt
							dirty = false;
							break;
						
						case 32:	// Spacebar
//							resetCamera();
							break;
						
						case 38:	// Up
							if ( event.ctrlKey )		_camera.interactiveRotateFirstPerson( 0, ROTATE_AMOUNT );
							else if ( event.shiftKey )	_camera.interactivePan( 0, -PAN_AMOUNT );
							else						_camera.interactiveForwardFirstPerson( PAN_AMOUNT );
							break;
						
						case 40:	// Down
							if ( event.ctrlKey )		_camera.interactiveRotateFirstPerson( 0, -ROTATE_AMOUNT );
							else if ( event.shiftKey )	_camera.interactivePan( 0, PAN_AMOUNT );
							else						_camera.interactiveForwardFirstPerson( -PAN_AMOUNT );
							break;
						
						case 37:	// Left
							if ( event.shiftKey )		_camera.interactivePan( -PAN_AMOUNT, 0 );
							else						_camera.interactiveRotateFirstPerson( ROTATE_AMOUNT, 0 );							
							break;
						
						case 39:	// Right
							if ( event.shiftKey )		_camera.interactivePan( PAN_AMOUNT, 0 );
							else						_camera.interactiveRotateFirstPerson( -ROTATE_AMOUNT, 0 );
							break;
						
						case 219:	_camera.fov -= 1;				break;	// "["						
						case 221:	_camera.fov += 1;				break;	// "]"						
						
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
							//trace( event.keyCode );
							dirty = false;
					}	
				}
			}
			
			if ( dirty )
				_dirty = true;
		}
		
		override protected function mouseEventHandler( event:MouseEvent, target:InteractiveObject, offset:Point, data:* = undefined ):void
		{
			if ( offset.x == 0 && offset.y == 0 )
				return;
			
			_camera = scene.activeCamera;
			
			if ( event.ctrlKey )
			{
				if ( event.shiftKey )
					_camera.interactivePan( offset.x / 5, offset.y / 5 );
				else
					_camera.interactiveRotateFirstPerson( -offset.x, -offset.y );
			}
			else
			{
				if ( event.shiftKey )
					_camera.interactivePan( offset.x / 5, offset.y / 5 );
				else
				{
					_camera.interactiveRotateFirstPerson( -offset.x, 0 );
					_camera.interactiveForwardFirstPerson( -offset.y / 5 );
				}
			}
		}
	}
}