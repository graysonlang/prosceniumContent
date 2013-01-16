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
	import com.adobe.utils.*;
	
	import flash.display.*;
	import flash.display3D.*;
	import flash.display3D.textures.*;
	import flash.events.*;
	import flash.filters.*;
	import flash.geom.*;
	import flash.utils.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	/**
	 * DemoPool demonstrates a number of Proscenium features 
	 * 
	 * <ul>
	 *   <li> Pixel Bender shaders are used to animate the pool waves.</li>
	 *   <li> Mesh instancing is to share mesh data among multiple instances.
	 *        From a single duck model, multiple instances are created.
	 *        Each instance can has its own material properties as well as orientation and position.
	 *        This feature is used to render the duck in red when it reaches to the edge of the pool.</li>
	 *   <li> Transformation-only instancing is to share everything but (world) transformation matrix. 
	 *        Palm trees are rendered using transformation instancing. Material cannot be changed but the rendering is much faster.
	 *        For even larger number of instancing, Proscenium provides SceneInstanceBucket class. See TestForestHuge.as for more information</li> 
	 *   <li> MaterialCustomAGAL: water ripple is rendered using custom material, in which we can define custom AGAL shader.
	 *        See TestMaterialCustom.as for custom material using PixelBender3D shader.
	 *        Note that custom material cannot be applied to skin animated mesh in the current Proscenium version.
	 *        Shaders constants are bound in materialCallback().</li>
	 * </ul>
	 */
	public class DemoPool extends BasicDemo
	{
		// ======================================================================
		//	Embedded Resources
		// ----------------------------------------------------------------------
		[Embed (source="/../res/kernels/out/WaveEquation.pbj", mimeType="application/octet-stream")]
		protected static const WaveEquation:Class;
		
		[Embed (source="/../res/kernels/out/WaveInitial.pbj", mimeType="application/octet-stream")]
		protected static const WaveInitial:Class;
		
		[Embed (source="/../res/kernels/out/HeightToNormal.pbj", mimeType="application/octet-stream")]
		protected static const HeightToNormal:Class;
		
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		protected static const RIPPLE_WIDTH:uint					= 256;
		protected static const RIPPLE_HEIGHT:uint					= RIPPLE_WIDTH;
		
		protected static const VERTEX_FORMAT:VertexFormat			= new VertexFormat(
			new <VertexFormatElement>[
				new VertexFormatElement( VertexFormatElement.SEMANTIC_POSITION, 0, Context3DVertexBufferFormat.FLOAT_3, 0, "position"  ),
				new VertexFormatElement( VertexFormatElement.SEMANTIC_NORMAL,   3, Context3DVertexBufferFormat.FLOAT_3, 0, "normal" ),
				new VertexFormatElement( VertexFormatElement.SEMANTIC_TEXCOORD, 6, Context3DVertexBufferFormat.FLOAT_2, 0, "texcoord" )
			]
		);
		
		protected static const IMAGE_FILENAMES:Vector.<String>		= new <String>[
			"../res/content/skybox/px.png",
			"../res/content/skybox/nx.png",
			"../res/content/skybox/py.png",
			"../res/content/skybox/ny.png",
			"../res/content/skybox/pz.png",
			"../res/content/skybox/nz.png",
			( RIPPLE_WIDTH == 256 ) ? "../res/content/poolBound256.png" : "../res/content/poolBound512.png"
		];
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _start:uint;
		
		protected var _material:MaterialCustomAGAL;
		protected var _textureRipple:Texture;
		
		protected var _waveEquationShader:Shader;		// Used to compute the finite difference wave equation height map over time
		protected var _waveEquationShaderFilter:ShaderFilter;
		protected var _heightToNormalShader:Shader;		// Used to turn the height map into a normal map
		protected var _heightToNormalShaderFilter:ShaderFilter;
		
		protected var _bitmapData0:BitmapData;
		protected var _bitmapData1:BitmapData;
		protected var _targetData:BitmapData;
		protected var _targetBitmap:Bitmap;
	
		protected var _frameCycleCount:uint;
		
		protected var _rippleCenterX:Number	= RIPPLE_WIDTH  / 2.0; 
		protected var _rippleCenterY:Number	= RIPPLE_HEIGHT / 2.0;
		
		protected var _startTime:uint;

		protected var _poolLoader:OBJLoader;
		protected var _treeLoader:OBJLoader;
		
		protected var _poolModel:ModelData;
		protected var _treeModel:ModelData;
		protected var _duckModel:ModelData;
		protected var _sailboatModel:ModelData;
		
		//	Properties
		protected var _sky:SceneSkyBox;
		protected var _pool:SceneMesh;
		protected var _water:SceneMesh;
		protected var _waterRefMap:RenderTextureReflection
		
		protected var _duckMtrl:MaterialStandard;
		protected var _ducks:Vector.<SceneMesh>;
		protected var _duckMaterialBinding:MaterialBinding;
		
		protected var _duckMotions:Vector.<DuckMotion>;
		protected var _sailboat:SceneMesh;
		
		protected static var _rect:Rectangle = new Rectangle( 0, 0, RIPPLE_WIDTH, RIPPLE_HEIGHT ); 
		protected static var _point:Point = new Point();
		
		protected var _poolMaskBitmap:Bitmap;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function DemoPool()
		{
			super();
			shadowMapEnabled = false;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function enterFrameEventHandler( event:Event ):void
		{
			if (true)
			{
				super.enterFrameEventHandler(event);
			}
			else
			{
				// show contents of render-to-textures
				callPresentOnRender = false;	// turnoff automatic present
				super.enterFrameEventHandler( event );	// draw the scene
			
				var w:Number  = 300;
				if ( _waterRefMap )
					_waterRefMap.showMeTheTexture( instance, width, height,   width-w, 0, w );
			
				instance.present();	// manually call present
			}
			
			advanceAnimation();
			animateWaterRipple();
		}

		override protected function initLights():void
		{
			lights = new Vector.<SceneLight>();
			var light:SceneLight;
			
			light = new SceneLight();
			light.kind = "distant";
			light.color.set( 0.8 * 1, 0.8 * .98, 0.8 * .9 );
			light.transform.prependRotation( -90, Vector3D.Y_AXIS );
			light.transform.prependRotation( -55, Vector3D.X_AXIS );
			light.shadowMapEnabled = shadowMapEnabled;
			light.setShadowMapSize( shadowMapSize, shadowMapSize );
			lights.push( light );
			
			light = new SceneLight();
			light.color.set( 0.5 * .5, 0.5 * .6, 0.5 * .7, 1 );
			light.appendTranslation( -20, 2, 20 );
			light.shadowMapEnabled = shadowMapEnabled;
			light.setShadowMapSize( shadowMapSize, shadowMapSize );
			lights.push( light );
			
			for each ( light in lights ) {
				scene.addChild( light );
			}
		}
		
		override protected function resetCamera():void
		{
			_camera = scene.activeCamera;
			_camera.identity();
			_camera.appendTranslation( 0, 0, 55 );
			_camera.appendRotation( -15, Vector3D.X_AXIS );
			_camera.appendRotation( -30, Vector3D.Y_AXIS, ORIGIN );
		}
		
		override protected function initModels():void
		{
			//scene.drawBoundingBox = true;
			SceneGraph.OIT_ENABLED = true;			// Set to true for proper transparency layering
			SceneGraph.OIT_LAYERS = 2;				// Set to two to see the first two layers of transparency properly ordered. Valid range is 1 to 2
			SceneGraph.OIT_HYBRID_ENABLED = false;	// We leave false, since there are no particles

			LoadTracker.loadImages( IMAGE_FILENAMES, imageLoadComplete );
		}
		
		protected function imageLoadComplete( bitmaps:Dictionary ):void
		{
			var i:uint;
			
			var bitmapDatas:Vector.<BitmapData> = new Vector.<BitmapData>( 6, true );
			var bitmap:Bitmap;
			
			for ( i = 0; i < 6; i++ )
				bitmapDatas[ i ] = bitmaps[ IMAGE_FILENAMES[ i ] ].bitmapData;
			
			// sky
			_sky = new SceneSkyBox( bitmapDatas, false );
			scene.addChild( _sky );
			_sky.name = "Sky"
			
			_frameCycleCount = 0;;
			_start = getTimer();
				
			LoadTracker.load( "../res/content/Pool.p3d", loadPoolComplete );
			
			//_poolLoader = new OBJLoader( "../res/content/Pool.obj" );
			//_poolLoader.addEventListener( Event.COMPLETE, loadPoolObjComplete );

			scene.ambientColor.set( .4,.4,.4 );
			
			_poolMaskBitmap = bitmaps[ IMAGE_FILENAMES[ 6 ] ];
		}
		
		// --------------------------------------------------
		
		protected function loadPoolComplete( bytes:ByteArray, info:* = null ):void
		{
			_poolModel = ModelData.fromBinary( bytes );
			LoadTracker.load( "../res/content/duck.p3d", loadDuckComplete );
		}
		
		protected function loadPoolObjComplete( event:Event ):void
		{
			_poolModel = _poolLoader.model;
			LoadTracker.load( "../res/content/duck.p3d", loadDuckComplete );
		}

		protected function loadDuckComplete( bytes:ByteArray, info:* = null ):void
		{
			_duckModel = ModelData.fromBinary( bytes );
			LoadTracker.load( "../res/content/Sailboat.p3d", loadSailboatComplete );
		}
		
		protected function loadSailboatComplete( bytes:ByteArray, info:* = null ):void
		{
			_sailboatModel = ModelData.fromBinary( bytes );

			LoadTracker.load( "../res/content/PalmTrees.p3d", loadTreesComplete );
			
			//_treeLoader = new OBJLoader( "../res/content/PalmTrees/PalmTrees.obj" );
			//_treeLoader.addEventListener( Event.COMPLETE, loadPalmTreeObjComplete );
		}
		
		protected function loadTreesComplete( bytes:ByteArray, info:* = null ):void
		{
			_treeModel = ModelData.fromBinary( bytes );
			complete();
		}

		protected function loadPalmTreeObjComplete( event:Event ):void
		{
			var loader:ModelLoader = event.target as ModelLoader;
			_treeModel = loader.model;
			complete();
		}
		
		protected function complete( event:Event = null ):void
		{
			print( "Load time:", ( getTimer() - _start ) / 1000 );
			
			var i:uint;
			var manifest:ModelManifest;
			
			// the pool
			var pool:SceneNode = new SceneNode( "PoolRoot" );
			_poolModel.addTo( pool );
			scene.addChild( pool );
			
			trace( scene );
			
			// palmtree models
			var tree:SceneNode = new SceneNode( "PalmTrees" );
			manifest = _treeModel.addTo( tree );
			pool.addChild( tree );

			// locate trees by using instanceTransforms.
			// this just renders trees in multiple locations with single SceneMesh object.
			// this is faster than full instancing used for DUCKs below
			manifest.meshes[ 0 ].createTransformInstanceByPosition(80,0,0);
			for ( i=0; i < 20; i++ )
				manifest.meshes[ 0 ].createTransformInstanceByPosition( 200 * Math.cos( i ), 0, 200 * Math.sin( i ) );
			
			// create ducks
			manifest = _duckModel.addTo( pool );
			_duckMtrl = manifest.meshes[ 0 ].material as MaterialStandard;
			if ( _duckMtrl )
				_duckMtrl.ambientColor.set(_duckMtrl.diffuseColor.r*0.6, _duckMtrl.diffuseColor.g*0.6, _duckMtrl.diffuseColor.b*0.6);
			
			_ducks = new Vector.<SceneMesh>;
			_ducks.push( manifest.meshes[ 0 ] );
			// create multiple ducks using instance(), which will share vertex/index buffers, 
			// but everything else will be copied to new SceheMesh object
			// this way, each instance can
			//     change material property, 
			//     has its own bounding box, and 
			//     can be picked.
			for ( i = 1; i < 8; i++ )
			{
				_ducks.push( manifest.meshes[ 0 ].instance() );
				pool.addChild(_ducks[i]);
			}
			
			var material:MaterialStandard = new MaterialStandard();
			_duckMaterialBinding = new MaterialBinding( material );
			material.diffuseColor.set( 1, 0, 0 );

			_duckMotions = new Vector.<DuckMotion>;
			for ( i = 0; i < 8; i++ )
			{
				_duckMotions.push( new DuckMotion() ); 
				_duckMotions[ i ].setCurrPose( i * 5 - 10, 0, i * Math.PI / 16 );
			}
			
			// create sailboat
			manifest = _sailboatModel.addTo( pool );
			_sailboat = manifest.meshes[ 0 ];
			_sailboat.transform.appendTranslation(5, 0, 5);
			//var sailboatMtrl:MaterialStandard = manifest.meshes[ 0 ].elements[ 0 ].material as MaterialStandard;
			//sailboatMtrl.ambientColor.set(sailboatMtrl.diffuseColor.r*0.6, sailboatMtrl.diffuseColor.g*0.6, sailboatMtrl.diffuseColor.b*0.6);
			
			// set up the pool water
			_pool = pool.getChildByIndex( 0 ) as SceneMesh;
			_water = new SceneMesh( "Water" );
			_water.transform = _pool.transform;
			_water.addElement( _pool.getElementByName( "water" ) );
			_pool.deleteElement( _pool.getElementByName( "water" ) );
			
			scene.addChild(_water);			
			
			_waterRefMap = new RenderTextureReflection( 1024, 1024);
			_waterRefMap.reflectionGeometry = _water;
			if (true)
			{
				_waterRefMap.addSceneNode( pool );	// water reflection will only have nearby objects: pool, boat, ducks, and the nearby palmtree
				_waterRefMap.addSceneNode( _sky );
			} else
				_waterRefMap.addSceneNode( scene );	// just reflect everything

			_water.addPrerequisiteNode( _waterRefMap.renderGraphNode );	// reflection texture is a prerequisite: reflection texture should be rendered before we render the water surface
			var minX:Number = _water.boundingBox.minX;
			var minZ:Number = _water.boundingBox.minZ;
			var maxX:Number = _water.boundingBox.maxX;
			var maxZ:Number = _water.boundingBox.maxZ;
			DuckMotion.setPoolRange( minX, maxX, minZ, maxZ );
/*			
			// distance map testers
			var d:Vector.<Number> = new Vector.<Number>(3);
			for( var xx:Number=-100; xx<100; xx+=5 )
			{
				for( var zz:Number=-100; zz<100; zz+=5 )
				{
					DuckMotion.getDistanceToPoolBoundary( d, xx, zz );
					var mtrl:MaterialStandard = new MaterialStandard( "sphereMtrlInstanced");
					if ( d[ 0 ] > 0 ){
						mtrl.diffuseColor.set(d[ 0 ]/10,0,1,1);
					} else {
						mtrl.diffuseColor.set(0,-d[ 0 ]/10,0,1);
					}
					var materialBindings:Dictionary = new Dictionary;
					materialBindings["duck"] = mtrl;
					var sphere:SceneMesh = _ducks[ 0 ].instance(null, null, materialBindings);
					sphere.transform.appendRotation( - Math.atan2(d[ 2 ],d[ 1 ])*180/3.141582654, new Vector3D(0,1,0) );
					sphere.transform.appendTranslation( xx, 0, zz );
					scene.addChild( sphere );
				}
			}
*/			

			// Vertex Shader
			const VERTEX_SHADER_SOURCE:String =
				// ------------------------------
				//	Inputs
				// ------------------------------
				//	va0			position
				//	va1			normal
				//	va2			texcoord
				
				// ------------------------------
				//	Constants
				// ------------------------------
				//	vc16-vc19	Model View Projection matrix
				//	vc20		Object space eye position
				//	vc21		zero vector
				
				// ------------------------------
				//	Operations
				// ------------------------------
				// compute vector to eye
				"sub vt0, vc20, va0\n" +
				
				// ------------------------------
				//	Output
				// ------------------------------
				"m44 vt0, va0, vc16\n" +   // 4x4 matrix transform from stream 0 to output clipspace
				"mov op, vt0\n" +
				
				"mov v0, va2\n" +				// copy texcoord from stream 1 to fragment program
				"mov v1, vt0\n" +				// position
				"mov v2, va1\n" +				// normal
				"";
				
			// Fragment Shader
			const FRAGMENT_SHADER_SOURCE:String =
				// ------------------------------
				//	Inputs
				// ------------------------------
				//	v0.xy		texcoord
				//	v1			position
				//	v2			normal
				//	fs0			reflection texture sampler
				//	fs1			normal map texture sampler
				
				// ------------------------------
				//	Constants
				// ------------------------------
				//	fc0			zero vector <0,0,0,0>
				//	fc1			one vector <1,1,1,1>
				//  fc2         {alpha, 0,0,0}
				//	fc3			eye vector
				
				// ------------------------------
				//	Operations
				// ------------------------------
				"mov ft2.xy, v0.xy\n" +
				"sub ft2.y, fc1.x, ft2.y\n" +
				"tex ft1, ft2.xy, fs1 <2d,linear,wrap>\n" +
				"sub ft1.xy, ft1.xy, fc2.ww\n" +
				"mul ft1.xy, ft1.xy, fc2.zz\n" +			// ft1 = normal
				
				"sub ft2, v1, fc3\n" +						// view direction
				"nrm ft2.xyz, ft2.xyz\n" + 					// ft2.xyz = normalized view direction
				
				"mov ft3, ft1\n" +
				"sub ft3.z, ft3.z, fc1.x\n" +				// diff(n)
				
				"mul ft3.xy, ft3.xy, ft2.z\n" +				// delta r = 2*view_z (delta nx, delta ny) : just use this without projecting onto the plane
				
				"add ft3.xy, ft3.xy, v0\n" +
				"tex ft0, ft3.xy, fs0 <2d,linear,wrap>\n" +	// reflection map: bound to sampler 0 in the mtrl callback
				"mul ft0, ft0, fc2.yyyy\n"+

				"add ft0.xyz, ft0.xyz, fc4.xyz\n" +
				
				// ------------------------------
				//	Output
				// ------------------------------
				"mov ft0.w, fc2.x\n" +
				"mov oc, ft0\n" +						// outputColor0 {oC0} = color {ft1}
				"";
				
			// --------------------------------------------------
			
			_material = new MaterialCustomAGAL( VERTEX_SHADER_SOURCE, FRAGMENT_SHADER_SOURCE, VERTEX_FORMAT, materialCallback, "Ripple" );
			_material.opaque = false;
			
			_waveEquationShader = new Shader( new WaveEquation() as ByteArray );
			_waveEquationShader.data[ "speed" ].value = [ 1.0 ];
			_waveEquationShaderFilter = new ShaderFilter( _waveEquationShader );
			
			_heightToNormalShader = new Shader( new HeightToNormal() as ByteArray );
			_heightToNormalShaderFilter = new ShaderFilter( _heightToNormalShader );
			
			// --------------------------------------------------
			
			_bitmapData0 = new BitmapData( RIPPLE_WIDTH, RIPPLE_HEIGHT, false, 0 );
			_bitmapData1 = new BitmapData( RIPPLE_WIDTH, RIPPLE_HEIGHT, false, 0 );
			
			_targetData = new BitmapData( RIPPLE_WIDTH, RIPPLE_HEIGHT, false, 0 );
			_targetBitmap = new Bitmap( _targetData );
//			stage.addChild( _targetBitmap );
			
			_textureRipple = instance.createTexture( RIPPLE_WIDTH, RIPPLE_HEIGHT, Context3DTextureFormat.BGRA, false );
			_water.material = _material;
			
			// --------------------------------------------------

			// Used to set up the initial state
			var waveInitialShader:Shader = new Shader( new WaveInitial() as ByteArray );
			var waveInitialShaderFilter:ShaderFilter =  new ShaderFilter( waveInitialShader )
			_bitmapData0.applyFilter( _poolMaskBitmap.bitmapData, _rect, _point, waveInitialShaderFilter );
			_poolMaskBitmap.bitmapData.dispose();
			
			// --------------------------------------------------

			advanceAnimation();		// to init objs in the right place
			animateWaterRipple();	// to have the normal map computed
		}

		protected function materialCallback( material:MaterialCustomAGAL, settings:RenderSettings, renderable:SceneRenderable, data:* = null ):void
		{			
			var camera:SceneCamera   = scene.activeCamera;
			var modelMatrix:Matrix3D = renderable.worldTransform.clone();
			var viewMatrix:Matrix3D  = camera.transform.clone(); 
			viewMatrix.invert();
			var projectionMatrix:Matrix3D = camera.projectionMatrix.clone();
			
			var mvpMatrix:Matrix3D = new Matrix3D();
			mvpMatrix.append( modelMatrix );
			mvpMatrix.append( viewMatrix );
			mvpMatrix.append( projectionMatrix );
			
			_waterRefMap.bind( settings, 0 );
			instance.setTextureAt( 1, _textureRipple );
			
			var m1:Matrix3D = modelMatrix.clone();
			m1.invert();
			var cameraPosition:Vector3D = camera.transform.position;
			cameraPosition = m1.transformVector( cameraPosition );
			var eye:Vector.<Number> = Vector.<Number>([cameraPosition.x, cameraPosition.y, cameraPosition.z, 1]);
			
			instance.setProgramConstantsFromMatrix( Context3DProgramType.VERTEX, 16, mvpMatrix, true );
			instance.setProgramConstantsFromVector( Context3DProgramType.VERTEX, 20, eye );
			
			instance.setProgramConstantsFromVector( Context3DProgramType.FRAGMENT, 0, Vector.<Number>([0, 0, 0, 0]) );
			instance.setProgramConstantsFromVector( Context3DProgramType.FRAGMENT, 1, Vector.<Number>([1, 1, 1, 1]) );
			instance.setProgramConstantsFromVector( Context3DProgramType.FRAGMENT, 2, Vector.<Number>([0.65, .5, 0.5*0.3, 0.5]) );	// water alpha, ref.map contribution, two ripple factors
			instance.setProgramConstantsFromVector( Context3DProgramType.FRAGMENT, 3, eye );
			instance.setProgramConstantsFromVector( Context3DProgramType.FRAGMENT, 4, Vector.<Number>([0.1, 0.1, 0.2, 1]) );		// ambient water color
		}
		
		protected function advanceAnimation():void
		{
			if (!_ducks) return;
			if (!_sailboat) return;
			
			var t:Number = ( getTimer() - _startTime ) / 1000;
			
			const om:Number = .1;
			const r:Number  = 20;
			var x:Number = 10 + r * Math.sin( om * t * 2 ) * .6;
			var z:Number = -5 + r * Math.sin( om * t ) * 1.3;
			var ax:Vector3D = new Vector3D( 0, 1, 0 );
			var angle:Number = Math.atan2(
				z - _sailboat.transform.position.z,
				x - _sailboat.transform.position.x
			);
			
			_sailboat.transform.identity( );
			_sailboat.transform.appendRotation( 90 - angle * 180 / Math.PI, ax );
			_sailboat.transform.appendTranslation( x, 0, z );
			_sailboat.dirtyTransform();

			var count:uint = _ducks.length;
			for ( var i:uint = 0; i < count; i++ )
			{
				_duckMotions[ i ].moveObject();

				var materialName:String = "Body";
				
				var duck:SceneMesh = _ducks[ i ];
				var motion:DuckMotion = _duckMotions[ i ];
				
				var materialBindings:MaterialBindingMap;
				var materialBinding:MaterialBinding;

				if ( !duck.materialBindings )
					duck.materialBindings = new MaterialBindingMap();
				
				if ( motion.nearBorder )
					duck.materialBindings.setBinding( materialName, _duckMaterialBinding );
				else
					duck.materialBindings.setBinding( materialName );
			
				angle = motion.angles[ 0 ];
				x     = motion.position[ 0 ];
				z     = motion.position[ 1 ];

				duck.transform.identity( );
				duck.transform.appendRotation( -angle * 180 / Math.PI, ax );
				duck.transform.appendTranslation( x, -.3, z );
				duck.dirtyTransform();
			}
		}
		
		protected function animateWaterRipple():void
		{
			if ( !_pool )
				return;
			
			var t:Number = ( getTimer() - _startTime ) / 1000;
			
			if ( (( t * 25 ) % 16) < 2 )
			{
				_rippleCenterX = Math.random() * RIPPLE_WIDTH;
				_rippleCenterY = Math.random() * RIPPLE_HEIGHT;
				_waveEquationShader.data[ "center" ].value = [ _rippleCenterX, _rippleCenterY ];
				_waveEquationShader.data[ "amplitude" ].value = [ 0.5 * ( Math.random() - 0.5 ) * 2.0];
				_waveEquationShader.data[ "radiusSquared" ].value = [ 64.0 * ( Math.random() ) ];
			}
			else
				_waveEquationShader.data["amplitude"].value = [ 0.0 ];
			
			if ( _frameCycleCount == 0 )
			{
				_frameCycleCount = 1;
				
				_waveEquationShader.data[ "prev" ].input = _bitmapData1;
				_waveEquationShader.data[ "src" ].value  = _bitmapData0;
				
				_bitmapData1.applyFilter( _bitmapData0, _rect, _point, _waveEquationShaderFilter );
				_targetData.applyFilter( _bitmapData1, _rect, _point, _heightToNormalShaderFilter );
			}
			else
			{
				_frameCycleCount = 0;
				
				_waveEquationShader.data[ "prev" ].input = _bitmapData0;
				_waveEquationShader.data[ "src" ].value  = _bitmapData1;
				
				_bitmapData0.applyFilter( _bitmapData1, _rect, _point, _waveEquationShaderFilter );
				_targetData.applyFilter( _bitmapData0, _rect, _point, _heightToNormalShaderFilter );
			}				
			
			_textureRipple.uploadFromBitmapData( _targetData );			// Upload the result to the surface texture
		}
	}
}

{
	import com.adobe.scenegraph.*;
	import com.adobe.scenegraph.loaders.collada.*;
	import com.adobe.scenegraph.loaders.obj.*;
	
	import flash.display.*;
	import flash.display3D.*;
	import flash.display3D.textures.*;
	import flash.events.*;
	import flash.filters.*;
	import flash.geom.*;
	import flash.utils.*;

	internal class DuckMotion
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const POOL_DISTANCE_MAP:Vector.<Vector.<Number>> = new <Vector.<Number>>[
			new <Number>[ -25.2389,  -13.4536,   -3.6056,    4.4721,    8.0000,    7.2801,    2.0000,   -7.8102,  -14.3178,   -8.2462,   -7.0000,   -9.0554,  -15.2315,  -24.2074,  -35.3553,  -47.6340 ],
			new <Number>[ -16.1245,   -2.8284,    9.8489,   18.7883,   24.0000,   22.8035,   15.5563,    3.6056,   -1.0000,    7.2801,   10.0000,    6.3246,   -2.2361,  -12.7279,  -25.2389,  -38.9487 ],
			new <Number>[  -9.4340,    5.8310,   19.7231,   32.0156,   39.5601,   37.5766,   26.1725,   17.4642,   15.5242,   21.9317,   26.0000,   20.8087,   10.2956,   -3.6056,  -17.4642,  -32.2800 ],
			new <Number>[  -6.0000,   10.7703,   26.2488,   41.4367,   54.5619,   48.7955,   39.1152,   32.5730,   31.2570,   35.7771,   41.7612,   32.6497,   18.6815,    3.6056,  -12.3693,  -27.6586 ],
			new <Number>[  -6.0000,   11.0000,   27.0000,   42.7200,   57.4282,   61.2944,   53.2259,   48.0521,   47.1699,   50.5964,   53.0848,   37.1214,   21.2132,    5.8310,  -11.0000,  -27.0000 ],
			new <Number>[  -8.0623,    7.2801,   21.9317,   35.0000,   44.2832,   51.8652,   61.6198,   63.7887,   63.1269,   65.9697,   53.7587,   38.0789,   22.5610,    7.2801,   -7.0711,  -19.1050 ],
			new <Number>[ -14.3178,   -1.0000,   12.7279,   22.4722,   29.9666,   39.0512,   50.2096,   62.6817,   76.3217,   73.0821,   57.8705,   42.9535,   28.6531,   16.2788,    4.2426,   -9.4340 ],
			new <Number>[ -19.4165,  -10.6301,    1.0000,    8.5440,   16.6433,   27.5862,   40.7063,   54.5619,   69.0797,   78.7210,   64.4127,   50.8035,   38.6005,   26.4008,   13.0000,   -2.0000 ],
			new <Number>[  -6.4031,    2.0000,    2.2361,   -5.6569,    5.0000,   18.7883,   33.5261,   48.7032,   64.0312,   79.5550,   73.2462,   61.0737,   48.5489,   34.1760,   19.3132,    4.0000 ],
			new <Number>[   4.4721,   16.5529,   17.0000,    5.0000,   -2.2361,   13.6015,   29.2746,   45.1774,   61.1310,   77.1038,   83.6301,   69.8570,   54.3415,   38.6394,   23.0000,    7.0000 ],
			new <Number>[   8.0000,   24.0000,   25.0000,    9.0000,   -4.0000,   13.0000,   29.0000,   45.0000,   60.8276,   75.9605,   85.1469,   70.3420,   54.7449,   39.0000,   23.0000,    7.0000 ],
			new <Number>[   3.6056,   14.7648,   15.0000,    3.6056,   -5.0990,   10.4403,   25.4951,   40.3113,   54.3783,   66.4003,   70.8308,   62.6259,   49.6488,   34.9285,   19.9249,    4.4721 ],
			new <Number>[  -7.8102,   -1.0000,   -1.0000,   -7.8102,  -10.4403,    5.0000,   18.7883,   32.2025,   43.9318,   52.3927,   55.0000,   49.9300,   40.2244,   27.6586,   13.8924,   -1.0000 ],
			new <Number>[ -21.4709,  -16.2788,  -16.2788,  -21.0238,  -17.4642,   -3.6056,    9.8995,   21.4009,   30.8869,   37.3363,   39.0000,   35.4401,   27.8029,   17.6918,    5.3852,   -8.4853 ],
			new <Number>[ -35.8469,  -32.1403,  -32.1403,  -35.7351,  -25.6125,  -13.4536,   -1.4142,    8.9443,   16.7631,   21.8403,   23.0000,   20.3961,   14.3178,    5.6569,   -5.6569,  -17.6918 ],
			new <Number>[ -50.9608,  -48.0937,  -48.0937,  -48.0104,  -35.8050,  -24.0416,  -13.8924,   -5.0000,    2.0000,    6.0000,    7.0000,    5.0000,   -1.0000,   -8.0623,  -17.4929,  -28.2843 ]
		];

		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var dt:Number = 0.01;
		public var t:Number  = 0;
		
		protected var _nearBorder:Boolean;

		protected var _linearVelocity:Number  = 0;
		protected var _angularVelocity:Number = 0;

		protected var _position:Vector.<Number> = new Vector.<Number>(3);   // position (of the rear trailer)
		protected var _angles:Vector.<Number>   = new Vector.<Number>(8);   // angles / gen-coords /  configs
		
		public static var pool_min_x:Number;
		public static var pool_max_x:Number;
		public static var pool_min_z:Number;
		public static var pool_max_z:Number;

		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get position():Vector.<Number>		 		{ return _position; }
		public function get angles():Vector.<Number>				{ return _angles; }
		public function get nearBorder():Boolean					{ return _nearBorder; }

		// ======================================================================
		//	 Constructor
		// ----------------------------------------------------------------------
		public function DuckMotion()
		{
			_linearVelocity = 5 + Math.random() * 5;
		}

		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		static public function setPoolRange( xmin:Number, xmax:Number, zmin:Number, zmax:Number ):void
		{
			pool_min_x = xmin;
			pool_max_x = xmax;
			pool_min_z = zmin;
			pool_max_z = zmax;
		}
		static protected function sampleDistanceToPoolBoundary( i:int, j:int ):Number
		{
			if ( 0 <= i && i <= 15  &&  0 <= j && j <= 15 )
				return 	POOL_DISTANCE_MAP[ j ][ i ];

			// expansion
			if(i <  0) return sampleDistanceToPoolBoundary( 0,j) + (sampleDistanceToPoolBoundary( 1,j) - sampleDistanceToPoolBoundary( 0,j)) *  i;
			if(i > 15) return sampleDistanceToPoolBoundary(15,j) + (sampleDistanceToPoolBoundary(15,j) - sampleDistanceToPoolBoundary(14,j)) * (i-15);
			if(j <  0) return sampleDistanceToPoolBoundary(j, 0) + (sampleDistanceToPoolBoundary(j, 1) - sampleDistanceToPoolBoundary(j, 0)) *  j;
			if(j > 15) return sampleDistanceToPoolBoundary(j,15) + (sampleDistanceToPoolBoundary(j,15) - sampleDistanceToPoolBoundary(j,14)) * (j-15);
			
			return 0;	// we should not come here
		}
		static public function getDistanceToPoolBoundary( d:Vector.<Number>, x:Number, z:Number ):void
		{
			// map (x,y) to (i,j)
			var u:Number = ( x - pool_min_x ) / ( pool_max_x - pool_min_x );
			var v:Number = ( z - pool_min_z ) / ( pool_max_z - pool_min_z );

			var i:int = Math.floor( u * 16 );
			var j:int = Math.floor( v * 16 );
			var mi:Number = u * 16 - i;
			var mj:Number = v * 16 - j;

			// get the sample quad
			var d00:Number = sampleDistanceToPoolBoundary( i  , j );
			var d10:Number = sampleDistanceToPoolBoundary( i+1, j );
			var d01:Number = sampleDistanceToPoolBoundary( i  , j+1 );
			var d11:Number = sampleDistanceToPoolBoundary( i+1, j+1 );

			d[ 0 ] = d00 * (1-mi) * (1-mj)
				 + d10 * (  mi) * (1-mj)
				 + d01 * (1-mi) * (  mj)
				 + d11 * (  mi) * (  mj);
			d[ 1 ] = d10 - d00;
			d[ 2 ] = d01 - d00;
			d[ 0 ] = d00;//(0.5<=u && u<=1 && 0.45<=v && v<=.55) ? 1 : -1;
		}
		
		public function moveObject():void
		{
			t += dt;

			var d:Vector.<Number> = new Vector.<Number>( 3 );
			
			// read the distance map
			getDistanceToPoolBoundary( d, _position[ 0 ], _position[ 1 ]);

			// compute the uphill & heading directions
			var sz:Number = Math.sqrt( d[ 1 ] * d[ 1 ] + d[ 2 ] * d[ 2 ] );
			var grad_x:Number = d[ 1 ] / sz;
			var grad_y:Number = d[ 2 ] / sz;
			
			var head_x:Number =  Math.cos(_angles[ 0 ]);	
			var head_y:Number =  Math.sin(_angles[ 0 ]);	

			// check if at border
			var nearBorderPrev:Boolean = _nearBorder;
			_nearBorder = d[ 0 ] < 20;
			var nearBorderReached:Boolean = nearBorderPrev == false && _nearBorder == true;
			var nearBorderEscaped:Boolean = nearBorderPrev == true && _nearBorder == false;

			if ( nearBorderReached )
			{
				_angularVelocity = ( Math.random() > 0.5 ) ? ( 10 + Math.random() * 3 )
								  						 : ( -10 - Math.random() * 3 );
			}
			else
			{
				if ( !_nearBorder )	
					if ( Math.random() < dt/2 )	// every 2 sec
						_angularVelocity = Math.random() * 0.1;
			}

			if ( nearBorderEscaped )
			{
				_angularVelocity = Math.random() * 0.1;
			}
			
			if ( !_nearBorder )
			{
				if ( Math.random() < dt / 2 )	// every 2 sec
					_linearVelocity = 5 + Math.random() * 5;
			}
			else
			{
				if ( ( grad_x * head_x + grad_y * head_y ) > Math.cos( Math.PI / 3 ) )
					_linearVelocity = 5;
				else
					_linearVelocity = .1;
			}

			_position[ 0 ] += dt * _linearVelocity  * head_x;
			_position[ 1 ] += dt * _linearVelocity  * head_y;
			_angles[ 0 ]   += dt * _angularVelocity;
			_angles[ 0 ] = Math.atan2(
				Math.sin( _angles[ 0 ] ),
				Math.cos( _angles[ 0 ] )
			);
		}
		
		public function setCurrPose( x:Number, y:Number, a0:Number ):void
		{
			_position[ 0 ] = x;
			_position[ 1 ] = y;
			_angles[ 0 ] = a0;
		}
	}
}