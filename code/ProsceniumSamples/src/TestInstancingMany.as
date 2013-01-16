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
	/**
	 * TestInstancingMany renders a few trees models in hundreds of different locations.
	 */
	public class TestInstancingMany extends BasicScene
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		protected static const CAMERA_ORIGIN:Vector3D				= new Vector3D( 0, 270, 20 );
		protected static const ORIGIN:Vector3D						= new Vector3D( 0, 0, 0 );

		protected static const IMAGE_FILENAMES:Vector.<String>		= new <String>[
			"../res/content/skybox/px.png",
			"../res/content/skybox/nx.png",
			"../res/content/skybox/py.png",
			"../res/content/skybox/ny.png",
			"../res/content/skybox/pz.png",
			"../res/content/skybox/nz.png",
			"../res/content/sandYellow.jpg"
		];
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _loaders:Vector.<OBJLoader> = new Vector.<OBJLoader>;
		protected var _loaded:uint = 0;
		protected var _lightDirectional:SceneLight;
		protected var _sky:SceneSkyBox;
		
		protected var _ground:HeightField = new HeightField;
		protected var _groundOffsetY:Number = -30;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function TestInstancingMany():void
		{
			super();
			SceneGraph.OIT_ENABLED = true;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function initLights():void
		{
			// This value must be set before the shadow map is created - before the lights are initialized
			
			var dynamicallyFitShadows:Boolean = false;
			
			if (dynamicallyFitShadows)
			{
				// With this options shadows are crisper but a bit jittery
				SceneLight.adjustDistantLightShadowMapToCamera = true;	// Frame the area around the camera for more shadow resolution
				SceneLight.cascadedShadowMapCount = 4; // 4 shadow maps in one texture. We support 2 and 4, but only for distant lights.
			}
			else
			{
				// With this option shadows are blurry but stable, however they may alias near the horizon
				SceneLight.adjustDistantLightShadowMapToCamera = false;
				SceneLight.cascadedShadowMapCount = 1; // 4 shadow maps in one texture. We support 2 and 4, but only for distant lights.
			}

			// Transparent shadows need to use 3x3 sampling
			SceneLight.oneLayerTransparentShadows = true;
			SceneLight.shadowMapSamplingDistantLights = RenderSettings.SHADOW_MAP_SAMPLING_3x3;

			// shadow acne control
			SceneLight.shadowMapZBiasFactor		  			= 0;//2;
			SceneLight.shadowMapVertexOffsetFactor			= 0;//3;
			SceneLight.shadowMapSamplerNormalOffsetFactor	= 2;

			super.initLights();

			var light:SceneLight;
			var sphere:SceneMesh;
			
			_lightDirectional = new SceneLight();
			_lightDirectional.color.set( .5, .5, .5 );
			_lightDirectional.appendTranslation( -20, 20, 20 );
			_lightDirectional.kind = "distant";
			_lightDirectional.shadowMapEnabled = true;
			_lightDirectional.setShadowMapSize( 2048, 2048 );
			_lightDirectional.transform.prependRotation( -90, Vector3D.Y_AXIS );
			_lightDirectional.transform.prependRotation( -55, Vector3D.X_AXIS );

			scene.addChild( _lightDirectional );
		}
		
		override protected function initModels():void
		{
			LoadTracker.loadImages( IMAGE_FILENAMES, imageLoadComplete );
		}
		
		protected function imageLoadComplete( bitmaps:Dictionary ):void
		{
			// sky
			var bitmapDatas:Vector.<BitmapData> = new Vector.<BitmapData>( 6, true );
			for ( var i:uint = 0; i < 6; i++ )
				bitmapDatas[ i ] = bitmaps[ IMAGE_FILENAMES[ i ] ].bitmapData;
			_sky = new SceneSkyBox( bitmapDatas, false );
			scene.addChild( _sky );
			_sky.name = "Sky"
				
			scene.ambientColor.set( .65, .65, .65 );
			
			// build terrain
			var material:MaterialStandard = new MaterialStandard();
			material.diffuseMap = new TextureMap( bitmaps[ IMAGE_FILENAMES[ 6 ] ].bitmapData );
			material.diffuseColor.set( .5, .5, .5 );
			material.ambientColor.set( 1, 1, .9 );
			material.specularColor.set( 0, 0, 0 );
			material.specularExponent = 30;
			
			var terrain:SceneMesh = MeshUtils.createFractalTerrain
				(
					100, 100,      	// tesellation 
					20000, 20000,  	// size
					1000,          	// height
					0.35,			// fractalRatio controls the roughness at small scales
					5000, 5000,     // texcoord scale
					material, "terrain", null, _ground
				);
			terrain.transform.appendTranslation( 0, _groundOffsetY, 0 );
			scene.addChild( terrain );
			
			_ground.offsetY = _groundOffsetY;
			
			// load trees
			_loaders.push( new OBJLoader( "../res/content/PalmTrees/PalmTree1.obj" ) );
			_loaders.push( new OBJLoader( "../res/content/PalmTrees/PalmTree2.obj" ) );
			_loaders.push( new OBJLoader( "../res/content/PalmTrees/PalmTree3.obj" ) );
			_loaders.push( new OBJLoader( "../res/content/PalmTrees/PalmTree4.obj" ) );
			_loaders.push( new OBJLoader( "../res/content/PalmTrees/PalmTree5.obj" ) );
			_loaders.push( new OBJLoader( "../res/content/PalmTrees/PalmTree6.obj" ) );

			for each ( var loader:OBJLoader in _loaders ) {
				loader.addEventListener( Event.COMPLETE, loadComplete );
			}
			
			_loaded = 0;
		}
		
		protected function loadComplete( event:Event ):void
		{
			_loaded++;
			if ( _loaded < _loaders.length )
				return;

			var models:Vector.<ModelManifest> = new Vector.<ModelManifest>;
			var useTransformInstance:Boolean = true;
			for each (var loader:OBJLoader in _loaders)
			{
				var tree:SceneNode = new SceneNode;
				models.push( loader.model.addTo( tree ) );
				if ( useTransformInstance )
					scene.addChild( tree );
			}
			
			var x:Number, y:Number, z:Number;
			var n:int   = 10;
			var space:Number = 20;
			var i:int, j:int;
			
			for (i = -n; i<=n; i++)
			{
				for (j = -n; j<=n; j++)
				{
					x = i * space + ( MathUtils.random() * (space * .9 ) );
					z = j * space + ( MathUtils.random() * (space * .9 ) );
					y = _ground.getHeight( x, z ) - 2;
					var modelID:uint = MathUtils.random() * (_loaders.length-1);
					if ( useTransformInstance )
					{
						models[modelID].meshes[ 0 ].createTransformInstanceByPosition( x, y, z );
					}
					else
					{
						var treeInstanced:SceneMesh = models[modelID].meshes[ 0 ].instance();
						treeInstanced.setPosition( x, y, z );
						scene.addChild( treeInstanced );
					}
				}
			}
			if ( _lightDirectional && _lightDirectional.shadowMapEnabled ) 
			{
				for each ( var mm:ModelManifest in models ) 
					_lightDirectional.addToShadowMap( mm.meshes[ 0 ] );
			}
			
			// --------------------------------------------------
			
			if (false)
			{
				if ( useTransformInstance )
				{
					var markers:SceneMesh = MeshUtils.createSphere( 5, 10, 10, null, "marker" );
					scene.addChild( markers );
					
					for ( j = 0; j < _ground.numPointsZ; j += 5 )
					{
						for ( i = 0; i < _ground.numPointsX; i += 5 )
						{
							x = _ground.getX( i ) * 1.1 + 5;
							z = _ground.getZ( j ) * 1.1 + 5;
							markers.createTransformInstanceByPosition( x, _ground.getHeight( x, z ), z );
						}
					}
				}
				else
				{
					var marker:SceneMesh = MeshUtils.createSphere( 5, 10, 10, null, "marker" );
					for ( j = 0; j < _ground.numPointsZ; j += 5 )
					{
						for ( i = 0; i < _ground.numPointsX; i += 5 )
						{
							var m:SceneMesh = marker.instance();
							x = _ground.getX( i ) * 1.1  + 5;
							z = _ground.getZ( j ) * 1.1  + 5;
							m.setPosition( x, _ground.getHeight( x, z ), z );
							scene.addChild( m );
						}
					}
				}
			}
		}
		
		override protected function enterFrameEventHandler( event:Event ):void
		{
			callPresentOnRender = false;
			super.enterFrameEventHandler( event );
			
			if ( false && _lightDirectional ) // Set to true to see the shadow map
			{
				var w:Number  = 512;
				if ( _lightDirectional.shadowMap )
				{
					_lightDirectional.shadowMap.showMeTheTexture( instance, instance.width, instance.height, 0, 0, w );
				}
			}
			
			instance.present();
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
							resetCamera();
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
			
			var x:Number = _camera.transform.position.x;
			var y:Number = _camera.transform.position.y;
			var z:Number = _camera.transform.position.z;
			
			var eyeHeight:Number = 5.0;
			
			if ( y < _ground.getHeight( x, z ) + eyeHeight )
				_camera.setPosition( x, _ground.getHeight( x, z ) + eyeHeight, z );
		}
		
		override protected function mouseEventHandler( event:MouseEvent, target:InteractiveObject, offset:Point, data:* = undefined ):void
		{
			super.mouseEventHandler( event, target, offset, data );
			
			_camera = scene.activeCamera;
			var x:Number = _camera.transform.position.x;
			var y:Number = _camera.transform.position.y;
			var z:Number = _camera.transform.position.z;
			
			var eyeHeight:Number = 5.0;
			
			if ( y < _ground.getHeight( x, z ) + eyeHeight )
				_camera.setPosition( x, _ground.getHeight( x, z ) + eyeHeight, z );
		}
		
		override protected function resetCamera():void
		{
			_camera = scene.activeCamera;
			_camera.identity();
			_camera.position = CAMERA_ORIGIN;
			_camera.appendRotation( -15, Vector3D.X_AXIS );
			_camera.appendRotation( -25, Vector3D.Y_AXIS, ORIGIN );
		}
	}
}