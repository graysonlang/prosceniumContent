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
	 * TestInstancingMassive demonstrates rendering massive number objects.
	 * A few trees models are rendered in tends of thousands of different locations.
	 * Models are placed in different buckets that are occluded. 
	 * If the bucket is far away, all objects will be rendered as billboard.
	 * Billboard textures will be computed automatically as the camera moves,
	 * and textures will be automatically located in a sub-region of a texture.
	 */
	public class TestInstancingMassive extends BasicScene
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
		protected var _loaders:Vector.<OBJLoader>					= new Vector.<OBJLoader>();
		protected var _loaded:uint									= 0;
		protected var _lightDirectional:SceneLight;
		protected var _sky:SceneSkyBox;
		
		protected var _ground:HeightField							= new HeightField();
		protected var _groundOffsetY:Number							= -30;
		protected var _staticObjs:SceneInstanceBuckets				= new SceneInstanceBuckets();
		
		protected var _orbitCamera:Boolean = false;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function TestInstancingMassive():void
		{
			super();
			SceneGraph.OIT_HYBRID_ENABLED = false;
			SceneGraph.OIT_ENABLED = false;
		}
		
		// ======================================================================
		//	Event Handler Related
		// ----------------------------------------------------------------------
		override protected function onAnimate( t:Number, dt:Number ):void
		{
			if ( !_ground || !_ground.heights )
				return;

			if ( _orbitCamera )
			{
				var r:Number = 1000;
				var period:Number = 30;
				var angle:Number = t / period * 2 * Math.PI;
				var x:Number = r * Math.sin( angle );
				var z:Number = r * Math.cos( angle );
				var h:Number = _ground.getHeight( x, z ) + 5;
				var y:Number = h < 400 ? 400 : h;
				
				_camera.identity();
				_camera.appendRotation( -20, Vector3D.X_AXIS );	  // pitch down
				_camera.appendRotation( angle * 180 / Math.PI, Vector3D.Y_AXIS ); // orbit
				_camera.setPosition( x, y, z );
			}
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
							_orbitCamera = !_orbitCamera;
							if ( _orbitCamera==false ) resetCamera();
							break;
						
						case 38:	// Up
							if ( event.ctrlKey )		_camera.interactiveRotateFirstPerson( 0, ROTATE_AMOUNT );
							else if ( event.shiftKey )	_camera.interactivePan( 0, -PAN_AMOUNT );
							else						_camera.interactiveForwardFirstPerson( PAN_AMOUNT*10 );
							break;
						
						case 40:	// Down
							if ( event.ctrlKey )		_camera.interactiveRotateFirstPerson( 0, -ROTATE_AMOUNT );
							else if ( event.shiftKey )	_camera.interactivePan( 0, PAN_AMOUNT );
							else						_camera.interactiveForwardFirstPerson( -PAN_AMOUNT*10 );
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
						
						case 72:	// H
							SceneGraph.OIT_HYBRID_ENABLED = !SceneGraph.OIT_HYBRID_ENABLED;
							trace( "Hybril Layer Peeling:", SceneGraph.OIT_HYBRID_ENABLED ? "enabled" : "disabled" );
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
			
			var eyeHeight:Number = 5;
			
			//if ( y < _ground.getHeight( x, z ) + eyeHeight )
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
		
		override protected function initLights():void
		{
			//
			var light:SceneLight;
			var sphere:SceneMesh;
			
			_lightDirectional = new SceneLight();
			_lightDirectional.color.set( .5, .5, .5 );
			_lightDirectional.appendTranslation( -20, 20, 20 );
			_lightDirectional.kind = "distant";
			_lightDirectional.transform.prependRotation( -90, Vector3D.Y_AXIS );
			_lightDirectional.transform.prependRotation( -55, Vector3D.X_AXIS );
			scene.addChild( _lightDirectional );

			// This value must be set before the shadow map is created - before the lights are initialized
			SceneLight.cascadedShadowMapCount = 0; // 4 shadow maps in one texture. We support 2 and 4, but only for distant lights.
			
			// Transparent shadows need to use 3x3 sampling
			SceneLight.oneLayerTransparentShadows = false;
			SceneLight.shadowMapSamplingDistantLights = RenderSettings.SHADOW_MAP_SAMPLING_3x3;
			
			// shadow acne control
			SceneLight.shadowMapZBiasFactor		  			= 0;//2;
			SceneLight.shadowMapVertexOffsetFactor			= 0;//3;
			SceneLight.shadowMapSamplerNormalOffsetFactor	= 2;

			//
			_lightDirectional.shadowMapEnabled = true;			/// set "true" to turn on shadows.
			_lightDirectional.setShadowMapSize( 512, 512 );
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
			
			scene.ambientColor.set( .5, .5, .5 );
			
			// build terrain
			var material:MaterialStandard = new MaterialStandard();
			material.diffuseMap = new TextureMap( bitmaps[ IMAGE_FILENAMES[ 6 ] ].bitmapData );
			material.diffuseColor.set( .5, .5, .5 );
			material.ambientColor.set( 1, 1, .9 );
			material.specularColor.set( 0, 0, 0 );
			material.specularExponent = 30;
			
			var terrain:SceneMesh = MeshUtils.createFractalTerrain(
				100, 100,      	// tesellation 
				10000, 10000,  	// size
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
			
			for each (var loader:OBJLoader in _loaders)
			loader.addEventListener( Event.COMPLETE, loadComplete);
			_loaded = 0;
		}
		
		protected function loadComplete( event:Event ):void
		{
			_loaded++;
			if ( _loaded < _loaders.length )
				return;
			
			// build forest -----------------------------------------------------
			for each (var loader:OBJLoader in _loaders)
			{
				var tree:SceneNode = new SceneNode;
				var modelManifest:ModelManifest = loader.model.addTo( tree );
				_staticObjs.addModel( modelManifest.meshes[0] );
			}
			scene.addChild( _staticObjs );
			
			if ( _lightDirectional && _lightDirectional.shadowMapEnabled ) 
				_lightDirectional.addToShadowMap( _staticObjs );
 
			var downshift:Vector.<Number> = new <Number>[ 0, 0, 0, 3, 0, 0 ];
			
			var bn:uint = 10;
			for (var bi:int=-bn; bi<=bn; bi++)
			{
				for (var bj:int=-bn; bj<=bn; bj++)
				{
					var n:int        = 5;
					var space:Number = 30;
					
					var x0:Number = bi*space*2*n*1.2; 
					var y0:Number = 0;
					var z0:Number = bj*space*2*n*1.2;
					
					for (var i:int=-n; i<=n; i++)
					{
						for (var j:int=-n; j<=n; j++)
						{
							var modelID:uint = MathUtils.random() * (_loaders.length-1);

							var x:Number = x0 + i * space + (MathUtils.random()  * (space*0.9));
							var z:Number = z0 + j * space + (MathUtils.random()  * (space*0.9));
							var y:Number = y0 + _ground.getHeight( x, z ) - downshift[modelID];
							var bucketID:int = (bn+bj)*(bn*2+1) + (bn+bi);
							_staticObjs.createInstanceAt(bucketID, modelID, x, y, z);
						}
					}
				}
			}
			
			print( _staticObjs.numObjects + " trees in " + _staticObjs.numBuckets + " buckets" );
		}
		
		override protected function enterFrameEventHandler( event:Event ):void
		{
			callPresentOnRender = false;
			super.enterFrameEventHandler( event );
			
			if ( false && _lightDirectional ) // Set to true to see the shadow map
			{
				var w:Number  = 128;
				if ( _lightDirectional.shadowMap )
				{
					_lightDirectional.shadowMap.showMeTheTexture( instance, instance.width, instance.height, 0, 0, w );
				}
			}
			
			if ( false && _staticObjs ) {
				instance.setBlendFactors( Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA );
				_staticObjs.showBillboardTexture( instance, 0, 0.0 );
			}

			instance.present();
		}
	}
}