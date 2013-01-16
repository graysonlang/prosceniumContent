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
	import flash.utils.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	/**
	 * <p>This sample demonstrates custom material model with custom shader.</p>
	 * 
	 * <p>While MaterialStandard has all basic material models, sometime, you may want to be able to use your own shader.
	 * MaterialCustom and MaterialCustomAGAL are the custom materials for such case. 
	 * MaterialCustom takes PixelBender3D shaders, and MaterialCustomALGL takes AGAL shaders. 
	 * See DemoPool.as for MaterialCustomAGAL.
	 * </p>
	 * 
	 * <p> To use custom material, shaders must be provides, and the shader constants must be set 
	 * in the materialCallback function. This function will be called when an object with the 
	 * custom material is rendered. </p>
	 * 
	 * <p> Shadow is supported and depth rendering will be automatically supported since Proscenium generates shaders to render depth. </p>
	 * <p> Custom material cannot be applied to skin-animated characters. </p>
	 */
	public class TestCustomMaterial extends BasicDemo
	{
		// ======================================================================
		//	Embedded Resources
		// ----------------------------------------------------------------------
		[ Embed( source="/../res/kernels/out/TestCustomMaterial.v.pb3dasm", mimeType="application/octet-stream" ) ]
		protected static const VertexProgramAsm:Class;
		
		[ Embed( source="/../res/kernels/out/TestCustomMaterial.m.v.pb3dasm", mimeType="application/octet-stream" ) ]
		protected static const MaterialVertexProgramAsm:Class;
		
		[ Embed( source="/../res/kernels/out/TestCustomMaterial.m.f.pb3dasm", mimeType="application/octet-stream" ) ]
		protected static const FragmentProgramAsm:Class;

		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const COLOR:Vector.<Number>					= new <Number>[ 0, .5, 0, 1 ];
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function TestCustomMaterial()
		{
			super();
			shadowMapEnabled = true;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function initModels():void
		{
			// create MaterialCustom
			var programs:Vector.<String> = new Vector.<String>();
			
			var bytes:ByteArray = new VertexProgramAsm() as ByteArray;
			var vertexProgram:String = bytes.readUTFBytes( bytes.bytesAvailable );
			
			bytes = new MaterialVertexProgramAsm() as ByteArray;
			var materialVertexProgram:String = bytes.readUTFBytes( bytes.bytesAvailable );
			
			bytes = new FragmentProgramAsm() as ByteArray;
			var fragmentProgram:String = bytes.readUTFBytes( bytes.bytesAvailable );

			var mtrl:MaterialCustom = new MaterialCustom( vertexProgram, fragmentProgram, materialVertexProgram, materialCallback, "customMaterial" );
			
			// create a box and add it to the scene
			var box:SceneMesh = MeshUtils.createBox( 3, 4, 20, mtrl, "box" );
			box.transform.appendRotation( 70, new Vector3D( 1/Math.sqrt(3), 1/Math.sqrt(3), 1/Math.sqrt(3) ) );
			box.setPosition( 0, 5, 0 );
			scene.addChild( box );

			// create a standard material box and add it to the scene
			var mtrlStandard:MaterialStandard = new MaterialStandard();
			var boxStandard:SceneMesh = MeshUtils.createBox( 3, 4, 20, mtrlStandard, "boxStandard" );
			boxStandard.setPosition( 10, 5, 2 );
			scene.addChild( boxStandard );

			// ground plane
			var material:MaterialStandard = new MaterialStandard();
			material.ambientColor.set( .5, .5, .5 );
			material.specularColor.set( .0, .0, .0 );
			material.specularExponent = 25;
			
			plane = MeshUtils.createPlane( 50, 50, 20, 20, material, "plane" );
			plane.transform.appendTranslation( 0, -2, 0 );
			scene.addChild( plane );

			// define shadow casters
			if ( lights )
			{
				if ( lights[ 0 ] && lights[ 0 ].shadowMapEnabled ) 
					lights[ 0 ].addToShadowMap( box, boxStandard );
				
				if ( lights[1] && lights[ 1 ].shadowMapEnabled )
					lights[ 1 ].addToShadowMap( box, boxStandard );
			}
			
			scene.ambientColor.set( .4, .4, .4 );
			
			SceneLight.shadowMapSamplingDistantLights = RenderSettings.SHADOW_MAP_SAMPLING_3x3;
			scene.ambientColor.set(1.0, 1.0, 1.0);
		}
		
		private static const _tempMatrix_:Matrix3D = new Matrix3D();
		public function materialCallback( material:MaterialCustom, settings:RenderSettings, renderable:SceneRenderable, data:* = null ):void
		{
			_tempMatrix_.copyFrom( scene.activeCamera.transform ); 
			_tempMatrix_.invert();
			_tempMatrix_.prepend( renderable.worldTransform );
			_tempMatrix_.append( scene.activeCamera.projectionMatrix );
			
			material.programConstantsHelper.setMatrixParameterByName(
				Context3DProgramType.VERTEX, 
				"objectToClipSpaceTransform",
				_tempMatrix_,
				true
			);
			
			material.programConstantsHelper.setNumberParameterByName(
				Context3DProgramType.FRAGMENT,
				"color",
				COLOR
			);
		}

		override protected function enterFrameEventHandler( event:Event ):void
		{
			callPresentOnRender = false;
			super.enterFrameEventHandler( event );

			if (lights)
			{
				var w:Number  = 200;
				if ( lights && lights[0] && lights[0].shadowMap )
				{
					lights[0].shadowMap.showMeTheTexture( instance, instance.width, instance.height, 0, 0, w );
				}
				if ( lights && lights[1] && lights[1].shadowMap )
				{
					lights[1].shadowMap.showMeTheTexture( instance, instance.width, instance.height, w, 0, w );
				}
			}

			instance.present();
		}
	}
}