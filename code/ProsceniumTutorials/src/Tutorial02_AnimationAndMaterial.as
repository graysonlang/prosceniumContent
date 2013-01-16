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
	public class Tutorial02_AnimationAndMaterial extends BasicDemo
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _cubeInstanced:SceneMesh;
		protected var _redMaterialBinding:MaterialBinding;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function Tutorial02_AnimationAndMaterial()
		{
			super();
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function initModels():void
		{
			var plane:SceneMesh = MeshUtils.createPlane( 50, 50, 20, 20, null, "plane" );
			plane.transform.appendTranslation( 0, -2, 0 );
			scene.addChild( plane );

			// create a new standard material
			var material:MaterialStandard = new MaterialStandard( "cubeMtrl" );	// material name is used
			material.diffuseColor.set( 0, 1, 0 );

			var cube:SceneMesh = MeshUtils.createCube( 5, material, "cube" );
			cube.appendTranslation( 0, 6, -10 );
			scene.addChild( cube );

			// create an instance of the cube (mesh data is shared)
			_cubeInstanced = cube.instance( "cube-instanced" );
			_cubeInstanced.appendTranslation( 0, 6, 0 );
			scene.addChild( _cubeInstanced );
			
			var redMaterial:MaterialStandard = new MaterialStandard();
			redMaterial.diffuseColor.set( 1, 0, 0 );
			_redMaterialBinding = new MaterialBinding( redMaterial );
			
			var torus:SceneMesh = MeshUtils.createDonut( .25, 1.5, 50, 10, null, "torus" );
			torus.appendTranslation( 10, 2, 0 );
			var rotAxis:Vector3D = new Vector3D( 1, 1, 1 );
			rotAxis.normalize();
			torus.appendRotation( 45, rotAxis );
			scene.addChild( torus );
			
			var sphere:SceneMesh = MeshUtils.createSphere( 3, 50, 50, null, "superSphere" );
			sphere.setPosition( -10, 2, 0 );
			scene.addChild( sphere );
		}

		// animation is performed in onAnimate
		override protected function onAnimate( t:Number, dt:Number ):void
		{
			_cubeInstanced.setPosition( Math.cos( t ) * 3, 6, Math.sin( t ) * 3 );

			// Since a SceneMesh can have multiple submeshes of different materials, 
			// and since the submeshes can be shared amongst multiple SceneMesh instances,
			// direct access to the material is not provided.
			// To change material, one can create a new material and add it to the binding
			// Note that the material name is used to indicate which material is remapped.
			if ( !_cubeInstanced.materialBindings )
				_cubeInstanced.materialBindings = new MaterialBindingMap();
				
			if ( _cubeInstanced.position.x < 0 )
				_cubeInstanced.materialBindings.setBinding( "cubeMtrl", _redMaterialBinding );
			else
				_cubeInstanced.materialBindings.setBinding( "cubeMtrl", null );
		}
	}
}