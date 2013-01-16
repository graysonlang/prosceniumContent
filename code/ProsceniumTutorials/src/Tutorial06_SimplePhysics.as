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
	
	import flash.display.*;
	import flash.display3D.*;
	import flash.events.*;
	import flash.geom.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class Tutorial06_SimplePhysics extends BasicDemo
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var mSim:PelletManager;

		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function Tutorial06_SimplePhysics()
		{
			super();
			shadowMapSize    = 256;
			shadowMapEnabled = true;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function initModels():void
		{
			instance.backgroundColor.set( .5, .5, .8 );
			instance.primarySettings.fogMode	= RenderSettings.FOG_LINEAR;
			instance.primarySettings.fogStart	= 0;
			instance.primarySettings.fogEnd		= .01;
			instance.primarySettings.fogDensity	= 50;

			// create plane material
			var material:MaterialStandard = new MaterialStandard();
			material.diffuseColor.set( 0, .4, 0 );
			material.specularColor.set( .8, .8, .8 );
			material.ambientColor.set( .2, .2, .2 );

			//
			mSim = new PelletManager;

			// create a plane and add it to the scene
			var plane:SceneMesh = mSim.createStaticInfinitePlane( 1000, 1000, 2, 2, material, "plane" );
			plane.appendTranslation( 0, -2, 0 );
			scene.addChild( plane );
			
			// create cubes and add it to the scene
			var cube0:SceneMesh = mSim.createBox( 5, 5, 5 );
			cube0.appendRotation( 40, Vector3D.X_AXIS );
			cube0.appendTranslation( 0, 6, 0 );
			scene.addChild( cube0 );

			var cube1:SceneMesh = mSim.createBox( 12, 1, 4 );
			cube1.appendRotation( 30, Vector3D.Z_AXIS );
			cube1.appendTranslation( -2, 15, 0 );
			scene.addChild( cube1 );
			
			// create a sphere and add it to the scene
			var sphere:SceneMesh = mSim.createSphere( 3, 32, 16 );
			sphere.setPosition( -10, 2, 0 );
			scene.addChild( sphere );			

			if ( lights )
			{
				lights[0].setPosition( 10, 20, 10);
				
				if ( lights[0].shadowMapEnabled )
					lights[0].addToShadowMap( cube0, cube1, sphere );
				
				if ( lights[1].shadowMapEnabled )
					lights[1].addToShadowMap( cube0, cube1, sphere );
			}
		}
		
		override protected function onAnimate( t:Number, dt:Number ):void
		{
			mSim.stepWithSubsteps( dt, 2 );
		}
	}
}