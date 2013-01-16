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
	public class Tutorial07_Texture extends BasicDemo
	{
		// ======================================================================
		//	Embedded Resources
		// ----------------------------------------------------------------------
		[ Embed( source="/../res/content/foliage022.jpg" ) ]
		protected static const BITMAP:Class;

		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function Tutorial07_Texture()
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
			var textureMap:TextureMap = new TextureMap( new BITMAP().bitmapData );
			material.diffuseMap = textureMap; 
			material.specularColor.set( .2, .2, .2 );
			material.ambientColor.set( .2, .2, .2 );

			// create a plane and add it to the scene
			var plane:SceneMesh = MeshUtils.createPlane( 50, 50, 20, 20, material, "plane" );
			plane.appendTranslation( 0, -2, 0 );
			scene.addChild( plane );
		}
	}
}