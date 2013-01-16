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
	
	import flash.display.*;
	import flash.display3D.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;
	
	// ===========================================================================
	// !!! NOTE !!!
	// ---------------------------------------------------------------------------
	//	This example relies upon an animated character model that is part of the
	//	Collada samples files located at the following URL:
	//	http://collada.org/collada/releases/samples.zip
	//
	//	Download samples.zip and extract the files from it,
	//	then place the following files into the ./res/content subfolder:
	//		"astroBoy_walk.dae"
	//		"boy_10.tga"
	// ---------------------------------------------------------------------------
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class TestBones extends BasicDemo
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _colladaLoader:ColladaLoader;
		protected var _initialized:Boolean;
	
		protected var _animations:Vector.<AnimationController>;
		
		protected var _modelRoot:SceneNode;
		
		protected var _boys:Vector.<SceneMesh>;
		protected var _time:Number = 0;
		
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function TestBones()
		{
			super();
			shadowMapEnabled = true;
			shadowMapSize = 2048;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function resetCamera():void
		{
			_camera = scene.activeCamera;
			_camera.identity();
			_camera.setPosition( 0, 1, 8 );
			_camera.appendRotation( -15, Vector3D.X_AXIS );
			_camera.appendRotation( 135, Vector3D.Y_AXIS );
		}
		
		override protected function initLights():void
		{
			var material:MaterialStandard;
			lights = new Vector.<SceneLight>();
			var light:SceneLight;
			var sphere:SceneMesh;
			
			// --------------------------------------------------

			light = new SceneLight( SceneLight.KIND_DISTANT, "distant light" );
			light.color.set( .9, .88, .8 );
			light.transform.appendRotation( -45, Vector3D.X_AXIS );
			light.transform.appendRotation( 135, Vector3D.Y_AXIS );
			light.shadowMapEnabled = shadowMapEnabled;
			light.setShadowMapSize( shadowMapSize, shadowMapSize );
			lights.push( light );
			
			light = new SceneLight( SceneLight.KIND_POINT, "point light" );
			light.color.set( 1, .98, .95 );
			light.move( 0, 3, 0 );
			light.shadowMapEnabled = shadowMapEnabled;
			light.setShadowMapSize( shadowMapSize, shadowMapSize );
			lights.push( light );
			
			// --------------------------------------------------
			
			for each ( light in lights )
			{
				scene.addChild( light );
				
				if ( light.shadowMapEnabled )
				{
					light.createShadowMap();
					scene.addPrerequisite( light.renderGraphNode );
				}
			}
		}
		
		override protected function initModels():void
		{
			_colladaLoader = new ColladaLoader( "../res/content/astroBoy_walk.dae" );
			_colladaLoader.addEventListener( Event.COMPLETE, completeEventHandler, false, 0, true );
			
			var material:MaterialStandard = new MaterialStandard();
			material.diffuseColor.set( .4, .6, .8 );
			material.specularExponent = 35;
				
			plane = MeshUtils.createPlane( 1000, 1000, 20, 20, material, "plane" );
			plane.appendTranslation( 0, 0, 0 );
			scene.addChild( plane );
		}
		
		protected function completeEventHandler( event:Event ):void
		{
			var node:SceneNode = new SceneNode();
			node.appendScale( 10, 10, 10 );
			scene.addChild( node );
			
			var loader:ModelLoader = event.target as ModelLoader;
			var manifest:ModelManifest = loader.model.addTo( node );

			if ( false )
			{
				// remove point light from seymour.dae collada file
				var lightNode:SceneNode = scene.getDescendantByName( "pointLight1" );
				if ( lightNode )
				{
					var light:SceneLight = lightNode.getChildByIndex( 0 ) as SceneLight;
					if ( light )
						light.color.set( .25, .25, .25 );
					//lightNode.removeFromScene();
				}
			}

			_animations = loader.model.animations;
			for each ( var animation:AnimationController in _animations ) {
				animation.bind( node );
				trace( "\nAnimation length:", animation.length.toFixed( 2 ) + "s" );
			}
			
			instance.backgroundColor.set( .8, .8, .8 );
			instance.primarySettings.fogMode = RenderSettings.FOG_EXP;
			instance.primarySettings.fogDensity = 5000;
			
			var boy:SceneMesh = scene.getDescendantByName( "SceneMesh-0" ) as SceneMesh;
			if ( boy )
			{
				var boyNode:SceneNode = scene.getDescendantByName( "boy" );
				
				if ( boyNode )
				{
					_boys = new Vector.<SceneMesh>();
					
					_boys.push( boy );
					
					for ( var i:uint = 1; i < 8; i++ )
					{
						var boyInstance:SceneMesh = boy.instance( "boy" + (i+1) );
						boyNode.addChild( boyInstance );
						_boys.push( boyInstance );
					}
				}
			}
			else
			{
				var bones:SceneNode = scene.getDescendantByName( "SceneNode-2" );
				if ( bones )
					bones.appendTranslation( 0, 2, 0 );
			}
			
			for each ( var l:SceneLight in lights )
			if ( l.shadowMapEnabled )
			{
				l.addToShadowMap( boy );

				for each ( var b:SceneMesh in _boys ) {
					l.addToShadowMap( b );
				}
			}
			
			trace( loader.model );
			trace( scene );
			
			_initialized = true;
		}
		
		override protected function onAnimate( t:Number, dt:Number ):void
		{
			if ( !_initialized )
				return;

			for each ( var animation:AnimationController in _animations ) {
				animation.time = ( t % animation.length ) + animation.start;
			}
			
			var angle:Number = t * 35;
			if ( _boys )
			{
				for each ( var boy:SceneMesh in _boys )
				{
					boy.identity();
					boy.appendTranslation( -20, 0, 0 )
					boy.appendRotation( angle, Vector3D.Y_AXIS );
					angle += 360 / _boys.length ;
				}
			}
		}

		// debugging code for testing indermediate buffer used for calculating shadows
		//override protected function enterFrameEventHandler( event:Event ):void
		//{
		//	callPresentOnRender = false;
		//	super.enterFrameEventHandler( event );
		//	
		//	var w:Number  = 200;
		//	if ( lights && lights[0] && lights[0].shadowMap )
		//		lights[0].shadowMap.showMeTheTexture( instance, instance.width, instance.height, 0, 0, w );
		//	if ( lights && lights[1] && lights[1].shadowMap )
		//		lights[1].shadowMap.showMeTheTexture( instance, instance.width, instance.height, w, 0, w );
		//	
		//	instance.present();
		//}
	}
}