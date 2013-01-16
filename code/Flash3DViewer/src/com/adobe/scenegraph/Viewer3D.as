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
package com.adobe.scenegraph
{
	// ===========================================================================
	//	Imports
	// ---------------------------------------------------------------------------
	import com.adobe.display.*;
	import com.adobe.images.*;
	import com.adobe.math.*;
	import com.adobe.scenegraph.*;
	import com.adobe.scenegraph.loaders.*;
	import com.adobe.scenegraph.loaders.collada.*;
	import com.adobe.scenegraph.loaders.kmz.*;
	import com.adobe.scenegraph.loaders.obj.*;
	import com.adobe.utils.*;
	
	import flash.display.*;
	import flash.display3D.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.text.*;
	import flash.utils.*;
	
	//import flash.system.ApplicationDomain;
	
	// ===========================================================================
	//	Events
	// ---------------------------------------------------------------------------
	[ Event( name = "complete", type = "flash.events.Event" ) ]
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class Viewer3D extends Sprite
	{
		// ======================================================================
		//	Embedded Resources
		// ----------------------------------------------------------------------
		[ Embed( source="/../res/movies/Spinner.swf" ) ]
		private static var Spinner:Class;
		
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const NAV_MODE_ORBIT:String					= "orbit";
		public static const NAV_MODE_SPIN:String					= "spin";
		public static const NAV_MODE_PAN:String						= "pan";
		public static const NAV_MODE_WALK:String					= "walk";

		protected static const RAD2DEG:Number						= 180 / Math.PI;
		protected static const DEG2RAD_2:Number						= Math.PI / 360;
		protected static const ISO_ANGLE:Number						= -Math.atan( Math.sin( Math.PI / 4 ) ) / Math.PI * 180;
		
		protected static const TEXT_FORMAT:TextFormat				= new TextFormat( "Consolas", 12, 0x0, false, false, false, null, null, TextFormatAlign.LEFT );
		protected static const COMPLETE_EVENT:Event					= new Event( Event.COMPLETE, true );

		protected static const ORIGIN:Vector3D						= new Vector3D();
		
		protected static const GROUND_PLANE_SIZE_SMALL:String		= "small";
		protected static const GROUND_PLANE_SIZE_M:String			= "medium";
		protected static const GROUND_PLANE_SIZE_L:String			= "large";
		protected static const GROUND_PLANE_SIZE_XL:String			= "extra large";
		protected static const GROUND_PLANE_SIZE_H:String			= "huge";
		
		protected static const GROUND_PLANE_STYLE_SOLID:String		= "solid";
		protected static const GROUND_PLANE_STYLE_WIRE:String		= "wire";
		protected static const GROUND_PLANE_STYLE_SHADOW:String		= "shadow";
		
		protected static const VECTOR_FRONT:Vector3D				= new Vector3D( 0, 0, 1, 0 );
		
		//Small
		//Medium
		//Large 
		//Extra Large
		//Huge
		
		 
		protected static const WALK_AMOUNT:Number					= 1 / 100;
		protected static const PAN_AMOUNT:Number						= 1 / 250;
		protected static const ROTATE_AMOUNT:Number					= 4;
		
		protected static const CAMERA_ORIGIN:Vector3D				= new Vector3D( 0, 0, 20 );
		
		protected static const PROGRESS_BAR_WIDTH:uint				= 128;
		protected static const PROGRESS_BAR_HEIGHT:uint				= 8;
		protected static const PROGRESS_BAR_BORDER_COLOR:uint		= 0x111111;
		
		protected static const PROGRESS_BAR_COLORS:Array			= [ 0xdddddd, 0x999999 ];
		protected static const PROGRESS_BAR_ALPHAS:Array			= [ 1, 1 ];
		protected static const PROGRESS_BAR_RATIOS:Array			= [ 127, 255 ];
		
		protected static const TWIPS:Number							= 1638.4;
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _startTime:uint								= 0;
		protected var _timer:Timer; 
		
		protected var _bounds:BoundingBox;
		protected var _diag:Number									= 1;
		
		protected var _modelURI:String;
		
		protected var _instance:Instance3D;
		protected var _scene:SceneGraph;
		
		protected var _manifest:ModelManifest;

		public var shadowMapEnabled:Boolean = false;
		public var shadowMapSize:uint = 1024;
		public var enableLightSpheres:Boolean = false;
		
		public var priorTime:uint;
		public var currentTime:int;
		public var t:Number = 0;
		public var dt:Number = 0;
		public var animate:Boolean = true;
		
		public var callPresentOnRender:Boolean = true;
		
		protected var _groundPlaneEnabled:Boolean;
		protected var _groundPlaneSize:String;
		protected var _groundPlaneStyle:String;
		protected var _groundPlaneColor:Color;
		
		protected var _animatingCamera:Boolean						= false;
		protected var _animatingCameraLength:Number					= .35;
		protected var _animatingCameraStart:uint					= 0;
		protected var _animatingCameraCamera:SceneNode;
		protected var _animatingCameraTargetDistance:Number			= 10;
		protected var _animatingCameraInfoStart:CameraInfo;
		protected var _animatingCameraInfoEnd:CameraInfo;
		
		protected var _spinner:Sprite;
		protected var _spinnerComplete:Boolean;
		protected var _loadComplete:Boolean;
		
		// ----------------------------------------------------------------------

		protected var _navMode:String;
		
		protected var _camera:SceneCamera;
		protected var _mouseContainer:DisplayObjectContainer;
		protected var _keyboardContainer:DisplayObjectContainer;
		
		protected var _mouseHandler:MouseHandler;
		protected var _mouseParent:DisplayObjectContainer;		
		
		protected var _dirty:Boolean = true;
		protected var _renderMode:String;
		protected var _stage3D:Stage3D;
		protected var _viewport:DisplayObject;
		
		protected var _text:Vector.<TextField>;
		protected var _textIndex:uint = 0;
		
		protected var _parameters:Object;
		
		protected var _plane:SceneMesh;
		
		protected var _initialized:Boolean;
		protected var _animations:Vector.<AnimationController>;

		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function set mouseParent( parent:DisplayObjectContainer ):void
		{
			_mouseParent = parent;
		}
		
		public function set viewport( viewport:DisplayObject ):void
		{
			_viewport = viewport;
		}
		
		override public function get width():Number		{ return _instance.width; }
		override public function get height():Number	{ return _instance.height; }
		
		public function set navMode( mode:String ):void
		{
			switch( mode )
			{
				case NAV_MODE_ORBIT:
				case NAV_MODE_PAN:
				case NAV_MODE_WALK:
				case NAV_MODE_SPIN:
					_navMode = mode; 
					break;
				
				default:
				trace( "invalid navigation mode" );
			}
		}

		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function Viewer3D( parameters:Object )
		{
			_navMode = NAV_MODE_ORBIT;
			
			_renderMode = Context3DRenderMode.AUTO;
			_parameters = parameters;
			//_parameters = loaderInfo.parameters;
			addEventListener( Event.ADDED_TO_STAGE, addedEventHandler );
			
			//for ( var value:String in _parameters )
			//	trace( value, _parameters[ value ] );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function setView( viewName:String = "front" ):void
		{
			var cx:Number, cy:Number, cz:Number;
			var dx:Number, dy:Number, dz:Number;
			
			if ( !_initialized || !_manifest )
			{
				cx = 0;
				cy = 0;
				cz = 0;
				
				dx = 20;
				dy = 20;
				dz = 20;
			}
			else
			{
				cx = ( _bounds.maxX + _bounds.minX ) / 2;
				cy = ( _bounds.maxY + _bounds.minY ) / 2;
				cz = ( _bounds.maxZ + _bounds.minZ ) / 2;
				
				dx = _bounds.maxX - _bounds.minX;
				dy = _bounds.maxY - _bounds.minY;
				dz = _bounds.maxZ - _bounds.minZ;
			}
			
			_diag = Math.sqrt( dx * dx + dy * dy + dz * dz );
			
			var dist:Number = _diag / ( Math.tan( _scene.activeCamera.fov * DEG2RAD_2 ) * 2 );
			
//			trace( "distance", dist );
//			trace( "center", cx, cy, cz );

			var center:Vector3D = new Vector3D( cx, cy, cz );
			
			_animatingCameraCamera = _scene.activeCamera;
			_animatingCameraInfoStart.transform.copyFrom( _animatingCameraCamera.transform );
			
			_animatingCameraInfoStart.targetDistance = _animatingCameraInfoStart.transform.position.subtract( center ).length;
			
			var transform:Matrix3D =_animatingCameraInfoEnd.transform;
			transform.identity();
			transform.appendTranslation( cx, cy, cz + dist );

			switch( viewName.toLowerCase() )
			{
				case "bottom":
					transform.appendRotation( 90, Vector3D.X_AXIS, center );
					break;
				
				case "back":
					transform.appendRotation( 180, Vector3D.Y_AXIS, center );
					break;
				
				case "back-left":
					transform.appendRotation( -135, Vector3D.Y_AXIS, center );
					break;
				
				case "back-right":
					transform.appendRotation( 135, Vector3D.Y_AXIS, center );
					break;
				
				default:
				case "front":
					break;
				
				case "front-left":
					transform.appendRotation( -45, Vector3D.Y_AXIS, center );
					break;
				
				case "front-right":
					transform.appendRotation( 45, Vector3D.Y_AXIS, center );
					break;
				
				case "isometric":
					transform.appendRotation( ISO_ANGLE, Vector3D.X_AXIS, center );
					transform.appendRotation( 45, Vector3D.Y_AXIS, center );
					break;
				
				case "left":
					transform.appendRotation( -90, Vector3D.Y_AXIS, center );
					break;
				
				case "right":
					transform.appendRotation( 90, Vector3D.Y_AXIS, center );
					break;
				
				case "top":
					transform.appendRotation( -90, Vector3D.X_AXIS, center );
					break;
				
				
				case "top-back":
					transform.appendRotation( -45, Vector3D.X_AXIS, center );
					transform.appendRotation( 180, Vector3D.Y_AXIS, center );
					break;
				
				case "top-back-left":
					transform.appendRotation( -45, Vector3D.X_AXIS, center );
					transform.appendRotation( -135, Vector3D.Y_AXIS, center );
					break;
				
				case "top-back-right":
					transform.appendRotation( -45, Vector3D.X_AXIS, center );
					transform.appendRotation( 135, Vector3D.Y_AXIS, center );
					break;
				
				case "top-front":
					transform.appendRotation( -45, Vector3D.X_AXIS, center );
					break;
				
				case "top-front-left":
					transform.appendRotation( -45, Vector3D.X_AXIS, center );
					transform.appendRotation( -45, Vector3D.Y_AXIS, center );
					break;
				
				case "top-front-right":
					transform.appendRotation( -45, Vector3D.X_AXIS, center );
					transform.appendRotation( 45, Vector3D.Y_AXIS, center );
					break;
				
				case "top-left":
					transform.appendRotation( -45, Vector3D.X_AXIS, center );
					transform.appendRotation( -90, Vector3D.Y_AXIS, center );
					break;
				
				case "top-right":
					transform.appendRotation( -45, Vector3D.X_AXIS, center );
					transform.appendRotation( 90, Vector3D.Y_AXIS, center );
					break;
			}
			
			_animatingCameraInfoEnd.targetDistance = dist;
			
			startCameraAnimation();
		}
		
		public function resetCamera():void
		{
			setView();
		}
		
		protected function initScene():void
		{
			_stage3D = stage.stage3Ds[ 0 ] as Stage3D;
			
			if ( _viewport )
			{
				_stage3D.x = _viewport.x;
				_stage3D.y = _viewport.y;
			}
			else
			{
				_stage3D.x = 0;
				_stage3D.y = 0;
			}
			
			_stage3D.addEventListener( Event.CONTEXT3D_CREATE, contextEventHandler );
			_stage3D.requestContext3D( _renderMode );
		}
		
		protected function initSpinner():void
		{
			_spinner = new Spinner();
			_spinner.width /= 2;
			_spinner.height /= 2;
			addChild( _spinner );
		}
		
		protected function contextEventHandler( event:Event ):void
		{
			var stage3D:Stage3D = event.target as Stage3D;
			
			if ( !stage3D )
				return;
			
			_instance = new Instance3D( stage3D.context3D );
			_scene = _instance.scene;
			//_scene.drawBoundingBox = true;
			
			if ( _parameters )
			{
				if ( _parameters.bgcolor )
				{
					var bgcolor:Color = Color.fromString( _parameters.bgcolor );
					_instance.backgroundColor.set( bgcolor.r, bgcolor.g, bgcolor.b ); 
				}
			}
			
			resize( stage.stageWidth, stage.stageHeight );
			
			initCamera();
			initHandlers();
			initLights();
			initModels();
			
			dispatchEvent( COMPLETE_EVENT );
		}
		
		protected function initText():void
		{
			var text:TextField;
			
			_text = new Vector.<TextField>( 20, true );
			
			for ( var i:uint = 0; i < _text.length; i++ )
			{
				text = new TextField();
				text.x = 10;
				text.y = i * 18 + 10;
				text.width = stage.stageWidth - 20;
				text.mouseEnabled = false;
				
				addChild( text );
				_text[ i ] = text;
			}
		}
		
		protected function initCamera():void
		{
			var target:DisplayObjectContainer = _mouseParent ? _mouseParent : this.parent;
			
			_camera = _scene.activeCamera;
			_mouseContainer = target;
			_keyboardContainer = stage;
			
			_mouseHandler = new MouseHandler( _mouseContainer );
			_mouseHandler.register( _mouseContainer, mouseEventHandler );
			
			_mouseContainer.addEventListener( MouseEvent.MOUSE_WHEEL, mouseWheelEventHandler );
			
			_keyboardContainer.addEventListener( KeyboardEvent.KEY_DOWN, keyboardEventHandler );
			//keyboardContainer.addEventListener( Event.ENTER_FRAME, enterFrameEventHandler );
			
			_animatingCameraInfoStart = new CameraInfo();
			_animatingCameraInfoEnd = new CameraInfo();
			
			resetCamera();
		}

		protected function initLights():void
		{
			//			var material:MaterialStandard;
			//			
						var lights:Vector.<SceneLight> = new Vector.<SceneLight>();
						var light:SceneLight;
						var sphere:SceneMesh;
						
						// --------------------------------------------------
						//	Light #1
						// --------------------------------------------------
						light = new SceneLight();
						light.kind = "point";
						light.color.set( 1, .98, .95 );
						light.move( 20, 15, -20 );
						//light.shadowMapEnabled = shadowMapEnabled;
						light.setShadowMapSize( shadowMapSize, shadowMapSize );
						lights.push( light );
			//			
			//			// --------------------------------------------------
			//			//	Light #2
			//			// --------------------------------------------------
			//			light = new SceneLight();
			//			light.color.set( .5, .6, .7 );
			//			light.appendTranslation( -20, 20, 20 );
			//			//light.kind = "spot";
			//			light.kind = "distant";
			//			light.shadowMapEnabled = shadowMapEnabled;
			//			light.setShadowMapSize( shadowMapSize, shadowMapSize );
			//			light.transform.prependRotation( -45, Vector3D.Y_AXIS );
			//			light.transform.prependRotation( -70, Vector3D.X_AXIS );
			//			lights.push( light );
			//			
			//			// --------------------------------------------------
			//			//	Light #3
			//			// --------------------------------------------------
			//			light = new SceneLight();
			//			light.color.set( .25, .22, .20 );
			//			light.kind = "distant";
			//			light.appendRotation( -90, Vector3D.Y_AXIS, ORIGIN );
			//			light.appendRotation( 45, Vector3D.Z_AXIS, ORIGIN );			
			//			lights.push( light );
			//			
			//			// --------------------------------------------------
			//			
						for each ( light in lights )
						{
							_scene.addChild( light );
							
							if ( light.shadowMapEnabled )
								light.addToShadowMap( _scene );
						}

//				var light:SceneLight = new SceneLight();
//				light.color.set( .75, .735, .675 );
//				light.kind = "distant";				
//				light.transform.appendRotation( -45, Vector3D.X_AXIS );
//				light.transform.appendRotation( 45, Vector3D.Y_AXIS );
//				scene.addChild( light );
//				
//				light = new SceneLight();
//				light.color.set( .25, .3, .35 );
//				light.kind = "distant";
//				light.transform.appendRotation( -45, Vector3D.X_AXIS );
//				light.transform.appendRotation( -135, Vector3D.Y_AXIS );
//				scene.addChild( light );
//				
//				light = new SceneLight();
//				light.color.set( .125, .125, .125 );
//				light.kind = "distant";
//				light.transform.appendRotation( 90, Vector3D.X_AXIS );
//				scene.addChild( light );

		}
		
		protected function initModels():void
		{
			if ( _parameters )
			{
				if ( _parameters.model )
				{
					_modelURI = _parameters.model;
					var modelLoader:ModelLoader = loadModel();
				}
				
				_startTime = getTimer();
				
				_groundPlaneEnabled	= _parameters.groundPlane != null;
				_groundPlaneSize	= _parameters.groundPlaneSize ? _parameters.groundPlaneSize.toLowerCase() : GROUND_PLANE_SIZE_L;
				_groundPlaneStyle	= _parameters.groundPlaneStyle ? _parameters.groundPlaneStyle.toLowerCase() : GROUND_PLANE_STYLE_SOLID;
			}
		}
		
		protected function loadModel():ModelLoader
		{
			var result:ModelLoader;

			var extension:String = URIUtils.getFileExtension( _modelURI.toLowerCase() );
			switch( extension )
			{
				case "obj":
					result = new OBJLoader();
					break;
				
				case "dae":
					result = new ColladaLoader();
					break;
				
				case "kmz":
				case "fl3":
					result = new KMZLoader();
					
					break;
				
				default:
					throw new Error( "Unsupported model type" );
			}
			
			result.addEventListener( ProgressEvent.PROGRESS, progressEventHandler, false, 0, true );
			result.addEventListener( Event.COMPLETE, completeEventHandler, false, 0, true );
//			result.addEventListener( IOErrorEvent.IO_ERROR, ioErrorEventHandler, false, 0, true );
			
			result.load( _modelURI );
			
			return result;
		}
		
//		protected function ioErrorEventHandler( event:IOErrorEvent ):void
//		{
//			trace( event );
//			
//			_timer = new Timer( 500, 1 );
//			_timer.addEventListener( TimerEvent.TIMER, loadModel );
//			_timer.start();
//		}
		
		protected function progressEventHandler( event:ProgressEvent ):void
		{
			trace( event.bytesLoaded );
		}
		
		protected function completeEventHandler( event:Event ):void
		{
			_loadComplete = true;
			
			_instance.setCulling( Context3DTriangleFace.NONE );
			
			var node:SceneNode = new SceneNode();
			_scene.addChild( node );
			
			var loader:ModelLoader = event.target as ModelLoader;
			_manifest = loader.model.addTo( node );
			
			_animations = loader.model.animations;
			for each ( var animation:AnimationController in _animations ) {
				animation.bind( node );
				//trace( "\nAnimation length:", animation.length.toFixed( 2 ) + "s" );
			}
			
			var roots:Vector.<SceneNode> = _manifest.roots;
			
			var groundPlane:SceneMesh = _scene.getDescendantByNameAndType( "Ground_Plane", SceneMesh ) as SceneMesh;

			if ( groundPlane )
			{
				groundPlane.hidden = true;
				
				_bounds = new BoundingBox();
				
				var parentage:Dictionary = new Dictionary();
				parentage[ groundPlane ] = groundPlane;
				
				var parent:SceneNode = groundPlane.parent;
				
				while ( parent )
				{
					var childCount:uint = parent.childCount;
					
					if ( childCount > 1 )
					{
						for ( var i:uint = 0; i < childCount; i++ )
						{
							var child:SceneNode = parent.getChildByIndex( i );
							if ( !parentage[ child ] )
								_bounds.combine( child.boundingBox );
						}
					}
					
					parentage[ parent ] = parent;
					parent = parent.parent;
				}
			}
			else
				_bounds = _manifest.boundingBox;
			
//			trace( "bounds:", _bounds );
			
			//= manifest.rootNode.boundingBox;
			
//			trace( loader.model );
//			trace( _scene );
			
//			for each ( var camera:SceneNode in _manifest.cameras )
//			{
//				var m:Matrix3D = camera.parent.transform;
//				trace( MatrixUtils.matrixToString( m ) );
//				
//				var v:Vector3D = m.transformVector( VECTOR_FRONT );
//				trace( v );
//				
//				var v2:Vector3D = new Vector3D( v.x, 0, v.z );
//				v2.normalize();
//				trace( v2 );
//				
//				var x:Number = Math.acos( -v2.z ) * ( v2.x < 0 ? 1 : -1 );
//				trace( "x", x * RAD2DEG );
//			}
			
			var material:MaterialStandard;
			
			var lights:Vector.<SceneLight> = _manifest.lights;
			i = 0;
			for each ( var light:SceneLight in lights )
			{
				//				light.intensity = .2;
				//				trace( "\nLight:", light, "\n" );
				
				var lc:Color = light.color;
				
				material = new MaterialStandard();
				material.ambientColor.set( 0, 0, 0 );
				material.diffuseColor.set( 0, 0, 0 );
				material.emissiveColor.set( lc.r, lc.g, lc.b );
				material.specularColor.set( 0, 0, 0 );
				
//				var sphere:SceneMesh = MeshUtils.createSphere( .25, 32, 32, material  );
//				
//				var pos:Vector3D = light.worldPosition;
//				//				sphere.$transform.setMatrix3D( light.worldTransform );
//				sphere.appendTranslation( pos.x, pos.y, pos.z );
//				//				trace( MatrixUtils.tidyMatrix( sphere.worldTransform ) );
//				_scene.addChild( sphere );
			}
			
			//			var materials:Vector.<Material> = manifest.materials;
			//			i = 0;
			//			
			//			_scene.ambientColor.set( 0, 0, 0 );
			//			for each ( var mat:Material in materials )
			//			{
			//				material = mat as MaterialStandard;			
			////				material.ambientColor.set( 0, 0, 0 );
			////				material.diffuseColor.set( 0, 0, 0 );
			////				material.specularColor.set( 1, 1, 1 );
			////				material.specularExponent = 50;
			//				
			////				material.specularColor.set( 1, 1, 1 );
			//				
			//				trace( "emissiveColor",  material.emissiveColor );
			//				trace( "specularIntensity",  material.specularIntensity );
			//				trace( "ambientColor", material.ambientColor );
			//				trace( "diffuseColor", material.diffuseColor );
			//				trace( "specularColor", material.specularColor );
			//				trace( "specularExponent", material.specularExponent );
			////				trace( "\nMaterial:", mat, "\n" );
			//			}
			
			material = new MaterialStandard();
			material.specularColor.set( .5, .5, .5 );
			material.specularExponent = 25;
			
//			if ( _groundPlaneEnabled )
//			{
//				var plane:SceneMesh = MeshUtils.createPlane( 1, 1, 1, 1, material, "plane" );
//				_scene.addChild( plane );
//				
//				//				switch( groundPlaneStyle )
//				//				{
//				_plane = MeshUtils.createPlane( 50, 50, 20, 20, material, "plane" );
//				_scene.addChild( _plane );					
//				//				}
//			}
			
			//_scene.addChild( ProceduralGeometry.createSphere( 10 ) );
			
			//			for each ( var light:SceneLight in manifest.li )
			//			{
			//				if ( light.shadowMapEnabled )
			//				{
			//					light.createShadowMap();
			//					_scene.addPrerequisite( light.renderSource );
			//				}
			//			}
			
			_initialized = true;
			
			setView();
		}
		
		public function pick( iX:int, iY:int):SceneNode
		{
			var x:Number =  ( iX - width * .5) / width * 2;
			var y:Number = -( iY - height * .5) / height * 2;
			
			return _scene.pick( x, y );
		}
		
		// ======================================================================
		//	Event Handler Related
		// ----------------------------------------------------------------------
		protected function addedEventHandler( event:Event ):void
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			initText();
			initSpinner();
			initScene();
		}
		
		protected function onAnimate( t:Number, dt:Number ):void
		{
			if ( !_initialized )
				return;
			
			for each ( var animation:AnimationController in _animations ) {
				animation.time = ( t % animation.length ) + animation.start;
			}
		}
		
		protected function initHandlers():void
		{
			var target:DisplayObjectContainer = _mouseParent ? _mouseParent : this.parent;
			
			priorTime = getTimer();
			stage.addEventListener( KeyboardEvent.KEY_DOWN, keyboardEventHandler );
			stage.addEventListener( Event.ENTER_FRAME, enterFrameEventHandler );
			stage.addEventListener( Event.RESIZE, resizeEventHandler );
		}
		
		protected function resizeEventHandler( event:Event = undefined ):void
		{
			if ( !_scene )
				return;
			
			resize( stage.stageWidth, stage.stageHeight );
		}
		
		public function resize( width:int, height:int ):void
		{
			var w:Number, h:Number, x:Number, y:Number;
			if ( _viewport )
			{
				w = _viewport.width;
				h = _viewport.height;
				x = _viewport.x;
				y = _viewport.y;
			}
			else
			{
				w = width;
				h = height;
				x = 0;
				y = 0;
			}
			
			// TODO: Consolidate configureBackBuffer calls
			_instance.configureBackBuffer( w, h, 2, true );
			_scene.activeCamera.aspect = w / h;
			
			if ( stage != null )
			{
				_stage3D.x = x;
				_stage3D.y = y;
			}
			
			_instance.render();
		}
		
		protected function enterFrameEventHandler( event:Event ):void
		{
			if ( _scene == null )
				return;
			
			var currentTime:uint = getTimer();
			dt = ( currentTime - priorTime ) / 1000.0;
			
			if ( !_spinnerComplete && _spinner )
			{
				if ( _loadComplete )
					clearSpinner();
				else
					updateSpinner();
			}

			if ( animate )
			{
				t += dt;
				onAnimate( t, dt );
			}
			
			// TODO: fix Scene3D so it property dirties
			if ( true || _dirty )
			{
				_dirty = false;
				_instance.render( 0, callPresentOnRender );
			}
			
			priorTime = currentTime;
		}
		
		protected function clearSpinner():void
		{
			_spinnerComplete = true;
			removeChild( _spinner )
		}
		
		protected function updateSpinner():void
		{
			_spinner.x = stage.stageWidth / 2 - _spinner.width / 2;
			_spinner.y = stage.stageHeight / 2 - _spinner.height / 2;
		}
		
		protected function keyboardEventHandler( event:KeyboardEvent ):void
		{
			var dirty:Boolean = false;
			_camera = _scene.activeCamera;
			
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
						
						//case 38:	// Up
						//	if ( event.ctrlKey )		_camera.interactiveRotateFirstPerson( 0, ROTATE_AMOUNT );
						//	else if ( event.shiftKey )	_camera.interactivePan( 0, -PAN_AMOUNT * _diag );
						//	else						_camera.interactiveForwardFirstPerson( WALK_AMOUNT * _diag );
						//	break;
						//
						//case 40:	// Down
						//	if ( event.ctrlKey )		_camera.interactiveRotateFirstPerson( 0, -ROTATE_AMOUNT );
						//	else if ( event.shiftKey )	_camera.interactivePan( 0, PAN_AMOUNT * _diag );
						//	else						_camera.interactiveForwardFirstPerson( -WALK_AMOUNT * _diag );
						//	break;
						//
						//case 37:	// Left
						//	if ( event.shiftKey )		_camera.interactivePan( -PAN_AMOUNT * _diag, 0 );
						//	else						_camera.interactiveRotateFirstPerson( ROTATE_AMOUNT, 0 );							
						//	break;
						//
						//case 39:	// Right
						//	if ( event.shiftKey )		_camera.interactivePan( PAN_AMOUNT * _diag, 0 );
						//	else						_camera.interactiveRotateFirstPerson( -ROTATE_AMOUNT, 0 );
						//	break;
						
						case 96:	// Numpad 0
							setView( "bottom" );
							break;
						
						case 97:	// Numpad 1
							setView( event.ctrlKey ? "top-front-left" : "front-left" );
							break;
						
						case 98:	// Numpad 2
							setView( event.ctrlKey ? "top-front" : "front" );
							break;
						
						case 99:	// Numpad 3
							setView( event.ctrlKey ? "top-front-right" : "front-right" );
							break;
						
						case 100:	// Numpad 4
							setView( event.ctrlKey ? "top-left" : "left" );
							break;
						
						case 101:	// Numpad 5
							setView( "top" );
							break;
						
						case 102:	// Numpad 6
							setView( event.ctrlKey ? "top-right" : "right" );
							break;
						
						case 103:	// Numpad 7
							setView( event.ctrlKey ? "top-back-left" : "back-left" );
							break;
						
						case 104:	// Numpad 8
							setView( event.ctrlKey ? "top-back" : "back" );
							break;
						
						case 105:	// Numpad 9
							setView( event.ctrlKey ? "top-back-right" : "back-right" );
							break;
						
						case 106:	// Numpad *
							break;
						
						case 107:	// Numpad +
							break;
						
						case 109:	// Numpad -
							break;
						
						case 110:	// Numpad .
							setView( "isometric" );
							break;
						
						case 111:	// Numpad /
							break;
						
						default:
							dirty = false;
							//super.keyboardEventHandler( event );
					}	
				}
			}
			
			if ( dirty )
				_dirty = true;
		}

		protected function mouseEventHandler( event:MouseEvent, target:InteractiveObject, offset:Point, data:* = undefined ):void
		{
			if ( offset.x == 0 && offset.y == 0 )
				return;
			
			if ( event.ctrlKey )
			{
				if ( event.shiftKey )
					_camera.interactivePan( offset.x * PAN_AMOUNT * _diag, offset.y * PAN_AMOUNT * _diag );
				else
					_camera.interactiveRotateFirstPerson( -offset.x, -offset.y );
			}
			else
			{
				if ( event.shiftKey )
					_camera.interactivePan( offset.x * PAN_AMOUNT * _diag , offset.y * PAN_AMOUNT * _diag );
				else
				{
					switch( _navMode )
					{
						case "orbit":
						{
							var cx:Number, cy:Number, cz:Number;
							var dx:Number, dy:Number, dz:Number;
							
							if ( !_initialized || !_manifest )
							{
								cx = 0;
								cy = 0;
								cz = 0;
								
								dx = 20;
								dy = 20;
								dz = 20;
							}
							else
							{
								cx = ( _bounds.maxX + _bounds.minX ) / 2;
								cy = ( _bounds.maxY + _bounds.minY ) / 2;
								cz = ( _bounds.maxZ + _bounds.minZ ) / 2;
								
								dx = _bounds.maxX - _bounds.minX;
								dy = _bounds.maxY - _bounds.minY;
								dz = _bounds.maxZ - _bounds.minZ;
							}
							
							_diag = Math.sqrt( dx * dx + dy * dy + dz * dz );
							
							var dist:Number = _diag / ( Math.tan( _scene.activeCamera.fov * DEG2RAD_2 ) * 2 );
							
							//			trace( "distance", dist );
							//			trace( "center", cx, cy, cz );
							
							var center:Vector3D = new Vector3D( cx, cy, cz );
							//_camera.interactiveOrbit( offset.x, offset.y, 10 );
							
							var width:Number = target.width;
							var height:Number = target.height;
							
							var x1:Number = ( ( ( event.localX + offset.x ) / width ) - .5 ) * 2
							var y1:Number = ( ( ( event.localY - offset.y ) / height ) - .5 ) * 2
							
							var x2:Number = ( ( event.localX / width ) - .5 ) * 2;
							var y2:Number = ( ( event.localY / height ) - .5 ) * 2;
							
							var pivot:Vector3D = new Vector3D();
							
							_camera.interactiveTrackball( x1, y1, x2, y2, center );
//							_camera.interactiveOrbit( dx, dy, 10 );
						}
							break;
						
						case "walk":
							_camera.interactiveRotateFirstPerson( -offset.x, 0 );
							_camera.interactiveForwardFirstPerson( -offset.y * WALK_AMOUNT * _diag );
							break;
						
						case "pan":
							_camera.interactiveStrafeFirstPerson( -offset.x * PAN_AMOUNT * _diag, offset.y * PAN_AMOUNT * _diag );
							break;
					}
				}
			}
		}
		
		protected function mouseWheelEventHandler( event:MouseEvent ):void
		{
			//trace( event.delta );
		}

		// --------------------------------------------------
		
		protected function print( ...parameters ):void
		{
			var string:String = parameters.join( " " );
			//trace( string ); 
			
			if ( !_text )
				return;
			
			_text[ _textIndex ].text = string;
			_text[ _textIndex ].setTextFormat( TEXT_FORMAT );
			
			if ( ++_textIndex >= _text.length )
				_textIndex = 0;
		}
		
		protected function startCameraAnimation():void
		{
			_animatingCamera = true;
			_animatingCameraStart = getTimer();
			//_animatingCameraCamera = _cameraMesh;
			stage.addEventListener( Event.ENTER_FRAME, cameraAnimationHandler );
		}
		
		protected function cameraAnimationHandler( event:Event ):void
		{
			var t:Number = ( getTimer() - _animatingCameraStart ) / 1000;
			
			if ( _animatingCamera )
			{
				var factor:Number = 1;
				
				if ( t > _animatingCameraLength )
				{
					_animatingCamera = false;
					//mRenderContext->SetCamera( mAnimatingCameraTarget );
					// Notify( V4kCameraTransitionDone );
					stage.removeEventListener( Event.ENTER_FRAME, cameraAnimationHandler );
				}
				else
					factor = 1 - ( ( Math.cos( t / _animatingCameraLength * Math.PI ) + 1 ) * .5 )
				
				blendCamera( _animatingCameraCamera, _animatingCameraInfoStart, _animatingCameraInfoEnd, factor );
			}
		}
		
		
		protected static var _m_:Matrix3D = new Matrix3D();
		protected static var _q_:Quaternion = new Quaternion();
		
		private static var _tempMatrix_:Matrix3D = new Matrix3D();
		public function blendCamera( camera:SceneNode, startCamera:CameraInfo, endCamera:CameraInfo, blendFactor:Number ):void
		{
			//			if ( startCamera.kind == endCamera.kind )
			//			{
			//				switch( startCamera.kind )
			//				{
			//					case SceneCamera.KIND_PERSPECTIVE:
			//						//camera.fov = blend( startCamera.fov, endCamera.fov, blendFactor );
			//						break;
			//					
			//					case SceneCamera.KIND_ORTHOGRAPHIC:
			//					{
			//						//						// correct for absolute binding
			//						//						V4Double startVPS	= ( startCamera.binding == V4kAbsolute ) ? startCamera.viewPlaneSize / endCamera.pointWidth : startCamera.viewPlaneSize;
			//						//						V4Double endVPS		= ( endCamera.binding == V4kAbsolute ) ?  endCamera.viewPlaneSize / endCamera.pointWidth : endCamera.viewPlaneSize;
			//						//						
			//						//						V4Double newVPS = sBlendFunc( startVPS, endVPS, blendFactor );
			//						//						camera->SetZoomFactor((float)(2 * newVPS) );
			//					}						
			//						break;
			//				}
			//			}
			//			else
			//			{
			//				//if ( startCamera.kind == SceneCamera.KIND_ORTHOGRAPHIC && camera.IsOrtho )
			//				//	camera->SetOrtho( false );
			//				
			//				//camera.fov = blend( startCamera.fov, endCamera.fov, blendFactor );
			//			}
			
			// --------------------------------------------------
			
			var tempTarget:Vector3D = new Vector3D();
			
			// ------------------------------
			
			tempTarget.z = -startCamera.targetDistance;
			var startTransform:Matrix3D = startCamera.transform;
			var startPosition:Vector3D = startTransform.position;
			var startQuat:Quaternion = Quaternion.fromMatrix( startCamera.transform );
			var startTargetPosition:Vector3D = startTransform.transformVector( tempTarget );
			
			// ----------
			
			tempTarget.z = -endCamera.targetDistance;
			var endTransform:Matrix3D = endCamera.transform;
			var endPosition:Vector3D = endTransform.position;
			var endQuat:Quaternion = Quaternion.fromMatrix( endCamera.transform );			
			var endTargetPosition:Vector3D = endTransform.transformVector( tempTarget );
			
			// ----------
			
			var midQuat:Quaternion = new Quaternion(); 
			midQuat.slerpInPlace( startQuat, endQuat, blendFactor );
			midQuat.setToMatrix( _tempMatrix_ );
			
			var midTarget:Vector3D = new Vector3D(
				blend( startTargetPosition.x, endTargetPosition.x, blendFactor ),
				blend( startTargetPosition.y, endTargetPosition.y, blendFactor ),
				blend( startTargetPosition.z, endTargetPosition.z, blendFactor )
			);
			
			// calculate interpolated target distance
			var targetDistance:Number = blend( startCamera.targetDistance, endCamera.targetDistance, blendFactor );
			
			//trace( targetDistance );
			
			// create vector of interpolated target distance
			tempTarget.z = targetDistance;
			
			// transform interpolated length with camera rotation
			tempTarget = _tempMatrix_.transformVector( tempTarget );
			tempTarget.incrementBy( midTarget );
			
			// set interpolated camera position by offsetting transformed target distance from target position
			_tempMatrix_.appendTranslation( tempTarget.x, tempTarget.y, tempTarget.z );
			
			camera.$transform.setMatrix3D( _tempMatrix_ );
			_animatingCameraTargetDistance = targetDistance;
			// initialize camera with matrix and distance
			//				initCamera( camera, cameraNode, (float)targetDistance, &tempMatrix );
		}
		
		private static function blend( v1:Number, v2:Number, f:Number ):Number
		{
			return ( v1 * ( 1 - f ) ) + ( v2 * f );
		}
	}
}

import com.adobe.math.*;
import com.adobe.scenegraph.*;

import flash.geom.*;
{
	class CameraInfo
	{
		public var targetDistance:Number;
		public var transform:Matrix3D;
		public var kind:String;
		public var fov:Number;
		public var vps:Number;
		
		public function CameraInfo( targetDistance:Number = 10, transform:Matrix3D = null )
		{
			this.transform			= transform ? transform : new Matrix3D();
			this.targetDistance		= targetDistance;
		}
	}
	}