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
	//	Metadata Tag
	// ---------------------------------------------------------------------------
	[ SWF( width="1280", height="720", backgroundColor="0x333333", frameRate="125" ) ]
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class Tutorial05_SpriteBased  extends Sprite
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		protected static const PAN_AMOUNT:Number					= .25;
		protected static const ROTATE_AMOUNT:Number					= 4;
		protected static const CAMERA_ORIGIN:Vector3D				= new Vector3D( 0, 0, 20 );
		protected static const ORIGIN:Vector3D						= new Vector3D();
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var instance:Instance3D;

		protected var _camera:SceneCamera;
		protected var _mouseHandler:MouseHandler
		protected var _mouseParent:DisplayObjectContainer;
		
		protected var _renderMode:String;
		protected var _box:SceneMesh;
		protected var _light:SceneLight;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function Tutorial05_SpriteBased ( renderMode:String = Context3DRenderMode.AUTO )
		{
			_renderMode = renderMode;
			addEventListener( Event.ADDED_TO_STAGE, addedEventHandler );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		protected function addedEventHandler( event:Event ):void
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			var stage3D:Stage3D = stage.stage3Ds[ 0 ] as Stage3D;
			
			stage3D.addEventListener( Event.CONTEXT3D_CREATE, contextEventHandler );
			stage3D.requestContext3D( _renderMode );			
		}
		
		protected function contextEventHandler( event:Event ):void
		{
			var stage3D:Stage3D = event.target as Stage3D;
			if ( !stage3D )
				return;
			
			instance = new Instance3D( stage3D.context3D );
			
			resize( stage.stageWidth, stage.stageHeight );
			
			// fogging can be enabled.
			instance.backgroundColor.set( .5,.5,.8);
			instance.primarySettings.fogMode = RenderSettings.FOG_EXP2;
			instance.primarySettings.fogDensity = 1000;

			// init camera
			_camera = instance.scene.activeCamera;
			_camera.identity();
			_camera.position = CAMERA_ORIGIN;
			_camera.appendRotation( -15, Vector3D.X_AXIS );
			_camera.appendRotation( -25, Vector3D.Y_AXIS, ORIGIN );

			// init event handlers
			_mouseHandler = new MouseHandler( parent );
			_mouseHandler.register( parent, mouseEventHandler );
			_mouseHandler.register( this, mouseEventHandler );
			
			stage.addEventListener( KeyboardEvent.KEY_DOWN, keyboardEventHandler );
			stage.addEventListener( Event.ENTER_FRAME, enterFrameEventHandler );
			stage.addEventListener( Event.RESIZE, resizeEventHandler );

			// setup light
			_light = new SceneLight();
			_light.color.set( .5, .6, .7 );
			_light.appendTranslation( -20, 20, 20 );
			_light.kind = "distant";
			_light.transform.prependRotation( -45, Vector3D.Y_AXIS );
			_light.transform.prependRotation( -70, Vector3D.X_AXIS );
			_light.shadowMapEnabled = true;
			_light.setShadowMapSize( 256, 256 );
			instance.scene.addChild( _light );
			
			// setup models
			var plane:SceneMesh = MeshUtils.createPlane( 50, 50, 20, 20, null, "plane" );
			plane.transform.appendTranslation( 0, -2, 0 );
			instance.scene.addChild( plane );
			
			_box = MeshUtils.createBox( 8, 2, 12 );
			_box.appendTranslation( 0, 3, 0 );
			instance.scene.addChild( _box );

			var mtrl2:MaterialStandard = new MaterialStandard;
			mtrl2.diffuseColor.set( 0.8, 0.2, 0.3 );
			var sphere:SceneMesh = MeshUtils.createSphere( 4, 32, 32, mtrl2, "sphere" );
			sphere.appendTranslation( 4, 10, 0 );
			instance.scene.addChild( sphere );

			// define shadow casters
			_light.addToShadowMap( _box );
			_light.addToShadowMap( sphere );
			
			//
			dispatchEvent( new Event( Event.COMPLETE, true ) );
		}
		
		// ======================================================================
		//	Event Handler Related
		// ----------------------------------------------------------------------
		protected function resizeEventHandler( event:Event = undefined ):void
		{
			resize( stage.stageWidth, stage.stageHeight );
		}
		
		public function resize( width:int, height:int ):void
		{
			if ( !instance.scene )
				return;
			
			instance.configureBackBuffer( width, height, 2, true );
			instance.scene.activeCamera.aspect = width / height;
			
			var stage3D:Stage3D = stage.stage3Ds[ 0 ] as Stage3D;
			instance.render();
		}
		
		protected function enterFrameEventHandler( event:Event ):void
		{
			if ( instance.scene == null )
				return;
			
			// animation
			_box.setPosition( 5*Math.cos(getTimer()/10000), 3,  5*Math.sin(10*getTimer()/10000) );
			
			instance.render( 0, false );
//			_light.shadowMap.showMeTheTexture( instance, instance.width, instance.height, 0, 0, 200 );
			instance.present();
		}
		
		protected function keyboardEventHandler( event:KeyboardEvent ):void
		{
			_camera = instance.scene.activeCamera;
			
			switch( event.type )
			{
				case KeyboardEvent.KEY_DOWN:
				{
					switch( event.keyCode )
					{
						case 38:	// Up
							if      ( event.ctrlKey  )	_camera.interactiveRotateFirstPerson( 0, ROTATE_AMOUNT );
							else if ( event.shiftKey )	_camera.interactivePan( 0, -PAN_AMOUNT );
							else						_camera.interactiveForwardFirstPerson( PAN_AMOUNT );
							break;
						
						case 40:	// Down
							if      ( event.ctrlKey  )	_camera.interactiveRotateFirstPerson( 0, -ROTATE_AMOUNT );
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
						
						default:
							break;
					}	
				}
			}
		}
		
		protected function mouseEventHandler( event:MouseEvent, target:InteractiveObject, offset:Point, data:* = undefined ):void
		{
			if ( offset.x == 0 && offset.y == 0 )
				return;
			
			_camera = instance.scene.activeCamera;
			
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