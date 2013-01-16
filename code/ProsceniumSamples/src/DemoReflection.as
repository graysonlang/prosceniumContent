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
	 * DemoReflection sets up reflective surfaces and environment maps.
	 * 
	 * To create a reflective surface
	 * <ul>
	 *   <li> Create a reflection texture render target using RenderTextureReflection</li>
	 *   <li> Add scene graph nodes to the map using addSceneNode(), so that the scene is rendered to the map.
	 *        If you want to have entire scene reflected, use addSceneNode( scene).
	 *        If you want only node1 and node2 to be reflected, just use addSceneNode( node1, node2 ) </li>
	 *   <li> Set the map to material of reflection object (e.g., a mirror). Ex: material.emissiveMap = _largeRefMap</li>
	 *   <li> Define the reflection object (e.g., a mirror). Ex: _largeRefMap.reflectionGeometry = _mirror. </li>
	 * </ul>
	 * 
	 * Environment cube maps are rendered at the centers of reflective spheres in this demo. 
	 * To create an environment cube map,
	 * <ul>
	 *   <li> Create a cube map using RenderTextureCube.</li>
	 *   <li> Add scene graph nodes to the cube map. This nodes will be rendered to the cube map.</li>
	 *   <li> Set the map to the sphere material. Ex: material.environmentMap = cubeMap</li>
	 *   <li> Attach the map to the sphere. Ex: cubeMap.attachedNode = sphere. 
	 *        This will make the cube map rendered from the center of the sphere. 
	 *        Therefore, when the sphere moves, the cube map will be rendered from the new sphere location.</li>
	 * </ul>
	 */
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class DemoReflection extends BasicDemo
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		/**@private*/
		protected static const SKYBOX_FILENAMES:Vector.<String>		= new <String>[
			"../res/content/skybox/px.png",
			"../res/content/skybox/nx.png",
			"../res/content/skybox/py.png",
			"../res/content/skybox/ny.png",
			"../res/content/skybox/pz.png",
			"../res/content/skybox/nz.png",
		];
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _sky:SceneSkyBox;
		protected var _spheres:Vector.<SceneNode>;
		protected var _cubeMaps:Vector.<RenderTextureCube>;
		protected var _mirror:SceneMesh;
		protected var _mirrorSmall:SceneMesh;
		
		protected var _initialized:Boolean;
		
		protected var _largeRefMap:RenderTextureReflection;
		protected var _smallRefMap:RenderTextureReflection;

		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function DemoReflection()
		{
			super();
			shadowMapEnabled = true;
			shadowMapSize = 512;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function initModels():void
		{
			// set the camera pose
			_camera.transform.identity();
			_camera.transform.appendRotation( -15, Vector3D.X_AXIS );
			_camera.setPosition( 20, 25, 70 );

			// start loading models
			LoadTracker.loadImages( SKYBOX_FILENAMES, imageLoadComplete );
		}
		
		protected function imageLoadComplete( bitmaps:Dictionary ):void
		{
			var bitmapDatas:Vector.<BitmapData> = new Vector.<BitmapData>( 6, true );
			var bitmap:Bitmap;
			
			for ( var i:uint = 0; i < 6; i++ )
				bitmapDatas[ i ] = bitmaps[ SKYBOX_FILENAMES[ i ] ].bitmapData;
			
			// sky
			_sky = new SceneSkyBox( bitmapDatas, false );
			
			scene.addChild( _sky );
			_sky.name = "Sky";
			
			// spheres
			_spheres = new Vector.<SceneNode>();
			_cubeMaps = new Vector.<RenderTextureCube>;
			createReflectiveSphere(   20, 10, -20,  5, _spheres, _cubeMaps, "Sphere0" );
			createReflectiveSphere(  -10, 30, -20, 15, _spheres, _cubeMaps, "Sphere1" );
			createReflectiveSphere(   20, 22, -20,  5, _spheres, _cubeMaps, "Sphere2" );
			createReflectiveSphere(  -10,  5, -10, 10, _spheres, _cubeMaps, "Sphere3" );
			
			var sphereMaterial:MaterialStandard = new MaterialStandard();
			sphereMaterial.diffuseColor.set( .5, .5, .5 );
			sphereMaterial.specularColor.set( .3, .3, .3 );
			sphereMaterial.ambientColor.set( .1, .1, .1 );
			sphereMaterial.specularExponent = 30.0;

			createSphere( -25, 15, -15,  5, _spheres, "Sphere4", sphereMaterial );
			createSphere(  -7,  0,  -7,  2, _spheres, "Sphere4-1", sphereMaterial );
			_spheres[ 4 ].addChild( _spheres[ 5 ] );

			_largeRefMap = new RenderTextureReflection( 1024, 1024 );
			_largeRefMap.renderGraphNode.name = "MirrorRefMap";
			_largeRefMap.renderGraphNode.addSceneNode( new SceneNode( "mirror Root" ) );

			var material:MaterialStandard = new MaterialStandard();
			material.emissiveMap = _largeRefMap;				// simply bind the reflection map as an emissive texture since this is added to diffuse lighting
			material.diffuseColor.set( 0, 0, 0 );
			material.specularColor.set( .2, .2, .2 );
			material.ambientColor.set( 0, 0, 0 );
			_mirror = MeshUtils.createPlane( 100, 100, 2, 2, material );
			_mirror.transform.appendTranslation( 10, 0, 10 );
			_mirror.name = "Mirror";
			_largeRefMap.reflectionGeometry = _mirror;		// reflection map should know the reflection surface
			
			var mtrlMirrorFrame:MaterialStandard = new MaterialStandard();
			mtrlMirrorFrame.diffuseColor.set( 0.08, .07, .05 );
			var mirrorFrame:SceneMesh = MeshUtils.createPlane( 110, 110, 2, 2, mtrlMirrorFrame );
			mirrorFrame.transform.appendTranslation( 0, -.5, 0 );
			_mirror.addChild( mirrorFrame );

			// small mirror
			_smallRefMap = new RenderTextureReflection( 256, 256 );
			_smallRefMap.renderGraphNode.name = "SmallMirrorRefMap";
			_smallRefMap.renderGraphNode.addSceneNode( new SceneNode( "small mirror Root" ) );
			material = new MaterialStandard();
			material.emissiveMap = _smallRefMap;
			material.diffuseColor.set( 0, 0, 0 );
			material.ambientColor.set( .6, .6, .9 );
			material.specularColor.set( 0, 0, .0 );
			_mirrorSmall = MeshUtils.createPlane( 20, 20, 2, 2, material );	// reflection surface should be orthogonal to y direction initially
			_mirrorSmall.transform.appendRotation( 90, Vector3D.X_AXIS );				// and then transformed to any orientation
			_mirrorSmall.transform.appendTranslation( 35, 15, -10 );
			_mirrorSmall.name = "SmallMirror";
			_smallRefMap.reflectionGeometry = _mirrorSmall;								// attach the reflection map to mirror
			
			//mirrorFrame = ProceduralGeometry.createPlane( 22, 22, 2, 2, mtrlMirrorFrame );
			//mirrorFrame.transform.appendTranslation( 0, -0.1, 0 );
			//_mirrorSmall.addChild(mirrorFrame);
			
			// add the root, i.e., scene so that everything is reflected
			_cubeMaps[0].addSceneNode( scene );
			_cubeMaps[1].addSceneNode( scene );
			_cubeMaps[2].addSceneNode( scene );
			_cubeMaps[3].addSceneNode( scene );
			_largeRefMap.addSceneNode( scene );
			_smallRefMap.addSceneNode( scene );
			
			scene.addChild( _spheres[ 0 ] );
			scene.addChild( _spheres[ 1 ] );
			scene.addChild( _spheres[ 2 ] );
			scene.addChild( _spheres[ 3 ] );
			scene.addChild( _spheres[ 4 ] );
			scene.addChild( _mirror );
			scene.addChild( _mirrorSmall );
			
			lights[0].setPosition( 10, 20, 10 );
			
			// define shadow casters
			if ( lights )
			{
				if ( lights[0] && lights[0].shadowMapEnabled )
					lights[ 0 ].addToShadowMap( scene );

				if ( lights[1] && lights[1].shadowMapEnabled )
					lights[ 1 ].addToShadowMap( scene );
			}
			
			_initialized = true;
		}
		
		protected function createReflectiveSphere(
			x:Number, y:Number, z:Number, r:Number, 
			spheres:Vector.<SceneNode>, 
			cubeMaps:Vector.<RenderTextureCube>,
			name:String
		):void
		{
			var cubeMap:RenderTextureCube = new RenderTextureCube( 128 );

			var material:MaterialStandard = new MaterialStandard();
			material.environmentMap = cubeMap;
			material.ambientColor.set( 0, 0, 0 );
			material.diffuseColor.set( 0, 0, 0 );
			material.specularColor.set( .2, .2, .2 );
			material.specularExponent = 30;
			material.environmentMapStrength = .95;
			
			var sphere:SceneMesh = MeshUtils.createSphere( r, 48, 48, material, name );
			sphere.transform.appendTranslation( x, y, z );
			
			// cubeMap should know the location where it is rendered
			cubeMap.attachedNode = sphere;
			
			spheres.push( sphere );
			cubeMaps.push( cubeMap );
		}
		
		protected function createSphere( x:Number, y:Number, z:Number, r:Number, 
										 spheres:Vector.<SceneNode>, 
										 name:String,
										 sphereMaterial:MaterialStandard):void
		{
			var sphereMap:RenderTextureCube;
			var sphere:SceneMesh = MeshUtils.createSphere( r, 24, 24, sphereMaterial, name );
			sphere.transform.appendTranslation( x, y, z );
			spheres.push( sphere );
		}
		
		override protected function onAnimate( t:Number, dt:Number ):void
		{
			if ( !_initialized )
				return;

			_spheres[ 0 ].setPosition( Math.sin( t ) * 30 - 15,  10, Math.cos( t ) * 30 );
			_spheres[ 4 ].setPosition( Math.sin( t ) * 30 +  5,  10, Math.cos( t ) * 30 );
			_spheres[ 5 ].transform.appendRotation( 10, Vector3D.Y_AXIS );

			_mirrorSmall.prependRotation( .1 , Vector3D.X_AXIS);
			_mirrorSmall.prependRotation( .2 , Vector3D.Y_AXIS);
			_mirrorSmall.prependRotation( .25, Vector3D.Z_AXIS);
		}

		override protected function enterFrameEventHandler( event:Event ):void
		{
			if ( true )
			{
				super.enterFrameEventHandler( event );	// draw the scene
			}
			else
			{
				// show render-to-textures
				callPresentOnRender = false;					// turn off the automatic present
				super.enterFrameEventHandler( event );	// draw the scene
				
				// show texture maps for debugging purpose
				var w:Number  = 150;
				if ( _largeRefMap )
					_largeRefMap.showMeTheTexture( instance, instance.width, instance.height,   0, 0, w );
				
				if ( _cubeMaps && _cubeMaps[0] )
					_cubeMaps[0].showMeTheTexture( instance, instance.width, instance.height,   w, 0, w );
	
				if ( _smallRefMap )
					_smallRefMap.showMeTheTexture( instance, instance.width, instance.height, 2*w, 0, w );

				//if ( _sky )
				//	_sky.cubeMap.showMeTheTexture( instance, instance.width, instance.height, 3*w, 0, w );
					
				// now, present
				instance.present();	
			}
		}
	}
}