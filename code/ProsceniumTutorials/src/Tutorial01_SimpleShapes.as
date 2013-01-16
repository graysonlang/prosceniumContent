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
	import flash.geom.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class Tutorial01_SimpleShapes extends BasicDemo
	{
		public function Tutorial01_SimpleShapes()
		{
			super();
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function initModels():void
		{
			// create plane material
			var material:MaterialStandard = new MaterialStandard();
			material.diffuseColor.set( 0, .4, 0 );
			material.specularColor.set( .8, .8, .8 );
			material.ambientColor.set( .2, .2, .2 );

			// create a plane and add it to the scene
			var plane:SceneMesh = MeshUtils.createPlane( 50, 50, 20, 20, material, "plane" );
			plane.appendTranslation( 0, -2, 0 );
			scene.addChild( plane );
			
			// create a cube and add it to the scene
			var cube:SceneMesh = MeshUtils.createCube( 5 );
			cube.appendTranslation( 0, 6, 0 );
			scene.addChild( cube );
			
			// create a torus and add it to the scene
			var torus:SceneMesh = MeshUtils.createDonut( .25, 1.5, 50, 10, null, "torus" );
			torus.appendTranslation( 10, 2, 0 );
			var rotAxis:Vector3D = new Vector3D( 1, 1, 1 );
			rotAxis.normalize();
			torus.appendRotation( 45, rotAxis );
			scene.addChild( torus );
			
			// create a sphere and add it to the scene
			var sphere:SceneMesh = MeshUtils.createSphere( 3, 50, 50, null, "sphere" );
			sphere.setPosition( -10, 2, 0 );
			scene.addChild( sphere );			
		}
	}
}