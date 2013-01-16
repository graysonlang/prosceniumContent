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
	import pellet.collision.dispatch.*;
	import pellet.collision.phasebroad.*;
	import pellet.collision.phasenarrow.*;
	import pellet.collision.shapes.*;
	import pellet.dynamics.*;
	import pellet.dynamics.solver.*;
	import pellet.math.*;
	import com.adobe.scenegraph.*;
	import com.adobe.scenegraph.loaders.*;
	import com.adobe.utils.*;
	
	import flash.display.*;
	import flash.display3D.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class TestPhysicsFractalTerrain extends BasicDemo
	{
		// ======================================================================
		//	Embedded Resources
		// ----------------------------------------------------------------------
		[ Embed( source="res/content/asphalt002.jpg" ) ]
		protected static const BITMAP:Class;
		
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		private static const USE_HEIGHTFIELD:Boolean					= false;
		
		private static const NUM_SPHERES:Number							= 2;
		private static const NUM_BOXES:Number							= 2;
		private static const NUM_TETRAHEDRONS:Number					= 2;
		private static const NUM_CYLINDERS:Number						= 2;
		private static const NUM_CAPSULES:Number						= 1;
		private static const NUM_CONES:Number      						= 5;
		private static const NUM_CONVEX:Number							= 5;
		private static const NUM_COMPOUNDS:Number						= 0;
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _pellet:PelletManager;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function TestPhysicsFractalTerrain()
		{
			super();
			shadowMapEnabled = true;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		private static var offset:Number = 0.;
		private static var worldMin:btVector3 = new btVector3 (-1000,-1000,-1000);
		private static var worldMax:btVector3 = new btVector3 (1000,1000,1000);
		private static var _tmpVec:Vector.<Number> = new Vector.<Number>(16);
		private static var _tmpMat:Matrix3D = new Matrix3D;
		
		protected function getMaterial():MaterialStandard
		{
			var material:MaterialStandard = new MaterialStandard( "randMtrl" );	// material name is used
			material.diffuseColor.set( .2+MathUtils.random()*.8, .2+MathUtils.random()*.8, .2+MathUtils.random()*.8 );
			return material;
		}
		
		override protected function initModels():void
		{
			scene.ambientColor.set(1.0, 1.0, 1.0, 1.0);
			SceneLight.shadowMapSamplingDistantLights = RenderSettings.SHADOW_MAP_SAMPLING_3x3;

			instance.backgroundColor.set( .5,.5,.8);
			instance.primarySettings.fogMode    = RenderSettings.FOG_LINEAR;
			instance.primarySettings.fogStart   = 0;
			instance.primarySettings.fogEnd     = 0.01;
			instance.primarySettings.fogDensity = 50;
			
			//
			_pellet = new PelletManager;
			
			var terrain:SceneMesh;
			if(USE_HEIGHTFIELD==false)
				terrain = _pellet.createStaticFractalTerrainAsTriangleMesh( 100, 100, 500, 500, 20, 0.35, 1,1, null, 'terrain', null, null, 6762 );
			else
				terrain = _pellet.createStaticFractalTerrainAsHeightField( 100, 100, 500, 500, 20, 0.35, 1,1, null, 'terrain', null, null, 6762 );
			scene.addChild( terrain );
			
			var i:int;
			var material:MaterialStandard;
			
			// create boxes
			for (i=0; i<NUM_BOXES; i++)
			{
				var box:SceneMesh = _pellet.createBox( 2,4,3, getMaterial() );
				box.setPosition( 1 + 2.5*i, 20, 1.1 );
				scene.addChild( box );
				lights[0].addToShadowMap( box );	// define casters
			}
			
			// create spheres
			var textureMap:TextureMap = new TextureMap( new BITMAP().bitmapData );
			for (i=0; i<NUM_SPHERES; i++)
			{
				var mtrlSphere:MaterialStandard = getMaterial();
				mtrlSphere.diffuseMap = textureMap; 
				var sphere:SceneMesh = _pellet.createSphere( 2, 32, 16, mtrlSphere );
				sphere.setPosition( 1 + 2.5*i, 10, 10.1 );
				scene.addChild( sphere );
				lights[0].addToShadowMap( sphere );	// define casters
			}
			
			// create cones
			for (i=0; i<NUM_CONES; i++)
			{
				var cone:SceneNode = _pellet.createCone( 2, 4, 32, 16, getMaterial() );
				cone.setPosition( 1 + 2.5*i, 10, 15.1 );
				scene.addChild( cone );
				lights[0].addToShadowMap( cone );	// define casters
			}
			
			// create tetrahedrons
			for (i=0; i<NUM_TETRAHEDRONS; i++)
			{
				var tet:SceneNode = _pellet.createRegularTetrahedron( 2, getMaterial() );
				tet.setPosition( 1 + 2.5*i, 10, 5.1 );
				scene.addChild( tet );
				lights[0].addToShadowMap( tet );	// define casters
			}
			
			// create cylinders
			for (i=0; i<NUM_CYLINDERS; i++)
			{
				var cyl:SceneNode = _pellet.createCylinder(5, 1, 32,2, getMaterial() );
				cyl.setPosition( 1 + 2.5*i, 30, 1.1 );
				scene.addChild( cyl );
				lights[0].addToShadowMap( cyl );	// define casters
			}
			
			// create capsules
			for (i=0; i<NUM_CAPSULES; i++)
			{
				var capsule:SceneNode = _pellet.createCapsule(1, 3, 32, 2, getMaterial() );
				capsule.setPosition( 1 + 2.5*i, 30, 1.1 );
				scene.addChild( capsule );
				lights[0].addToShadowMap( capsule );	// define casters
			}
		}
		
		override protected function enterFrameEventHandler( event:Event ):void
		{
			if(_pellet)
				_pellet.step();

			callPresentOnRender = false;
			super.enterFrameEventHandler( event );
			instance.present();
		}
	}
}