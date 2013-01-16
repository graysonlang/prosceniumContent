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
	import com.adobe.scenegraph.loaders.*;
	
	import flash.display.*;
	import flash.display3D.*;
	import flash.display3D.textures.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;

	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class TestPointLightShadow extends BasicDemo
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		protected static const AXIS:Vector3D						= new Vector3D(
			1 / Math.sqrt( 3 ),
			1 / Math.sqrt( 3 ),
			1 / Math.sqrt( 3 )
		);
		
		protected static const TRANSLATIONS:Vector.<Vector3D>		= new <Vector3D>[
			new Vector3D( -1, -1, -1 ),
			new Vector3D( 1, -1, -1 ),
			new Vector3D( -1, 1, -1 ),
			new Vector3D( 1, 1, -1 ),
			new Vector3D( -1, -1, 1 ),
			new Vector3D( 1, -1, 1 ),
			new Vector3D( -1, 1, 1 ),
			new Vector3D( 1, 1, 1 ),
		];
		
		protected static const ROTATIONS:Vector.<Matrix3D>			= new <Matrix3D>[
			new Matrix3D(),
			new Matrix3D(),
			new Matrix3D(),
			new Matrix3D(),
			new Matrix3D(),
			new Matrix3D(),
		];
		
		ROTATIONS[ 0 ].appendRotation( 90, Vector3D.Z_AXIS );
		ROTATIONS[ 1 ].appendRotation( -90, Vector3D.Z_AXIS );
		ROTATIONS[ 2 ].appendRotation( -180, Vector3D.Z_AXIS );
		ROTATIONS[ 4 ].appendRotation( -90, Vector3D.X_AXIS );
		ROTATIONS[ 5 ].appendRotation( 90, Vector3D.X_AXIS );
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _castersSet:SceneNode;
		protected var _donut:SceneMesh;
		protected var _initialized:Boolean;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function TestPointLightShadow()
		{
			super();
			shadowMapEnabled = true;
			//enableLightSpheres = true;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function initLights():void
		{
			//instance.setCulling( Context3DTriangleFace.BACK );
			
			lights = new Vector.<SceneLight>();
			var light:SceneLight;
			var sphere:SceneMesh;
			var material:MaterialStandard;
			
			// --------------------------------------------------
			//	Light #1
			// --------------------------------------------------
			light = new SceneLight();
			light.color.set( 1, 1, 1 );
			light.kind = "point";
			light.shadowMapEnabled = shadowMapEnabled;
			light.setShadowMapSize( shadowMapSize, shadowMapSize );
			
			if ( enableLightSpheres )
			{
				material = new MaterialStandard( "light" );
				material.emissiveColor = light.color;
				sphere = MeshUtils.createSphere( .25, undefined, undefined, material, "light sphere" );
				light.addChild( sphere );
			}
			lights.push( light );
			
			// --------------------------------------------------
			
			for each ( light in lights ) {
				scene.addChild( light );
			}
			// shadow acne control
			SceneLight.shadowMapZBiasFactor		  			= 5;//2;
			SceneLight.shadowMapVertexOffsetFactor			= 0;//3;
			SceneLight.shadowMapSamplerNormalOffsetFactor	= 2;
	}
		
		override protected function initModels():void
		{
			var filenames:Vector.<String> = new Vector.<String>();
			
			var material:MaterialStandard = new MaterialStandard();
			material.diffuseColor.set( 1, 1, 1 );
			material.specularColor.set( 1, 1, 1 );
			material.specularExponent = 30;

			_castersSet = new SceneNode( "castersSet" );
			scene.addChild( _castersSet );
			
			//var cube:SceneMesh = MeshUtils.createCube( 50 );
			//_castersSet.addChild( cube );
			//cube.appendTranslation( 0, -30, 0 );
			//
			//plane = MeshUtils.createFractalTerrain( 100, 100, 300, 300, 50, 1, 1, material, "terrain" );
			//plane.transform.appendTranslation( 0, -30, 0 );
			//scene.addChild( plane );
			//
			//var name:String = "Box";
			//var modelData:ModelData = new ModelData();
			//var meshData:SceneMeshData = new SceneMeshData( name );
			//var sceneData:SceneGraphData = new SceneGraphData( name );
			//sceneData.addChild( meshData );
			//modelData.addScene( sceneData );
			//
			//meshData.addSource( new Source( "positions", new ArrayElementFloat( Vector.<Number>( [ -.5,-.5,.5, -.5,-.5,-.5, .5,-.5,-.5, .5,-.5,.5, -.5,.5,.5, .5,.5,.5, .5,.5,-.5, -.5,.5,-.5 ] ) ), 3 ) );
			//meshData.addSource( new Source( "texcoords", new ArrayElementFloat( Vector.<Number>( [ 1,0, 1,1, 0,1, 0,0 ] ) ), 2 ) );
			//meshData.addSource( new Source( "normals", new ArrayElementFloat( Vector.<Number>( [ 0,-1,0, 0,1,0, 0,0,1, 1,0,0, 0,0,-1, -1,0,0 ] ) ), 3 ) );
			//
			//var inputs:Vector.<Input> = new <Input>[
			//	new Input( Input.SEMANTIC_POSITION, "positions", 0 ),
			//	new Input( Input.SEMANTIC_TEXCOORD, "texcoords", 1 ),
			//	new Input( Input.SEMANTIC_NORMAL, "normals", 2 )
			//];
			//for each ( var input:Input in inputs ) { meshData.addVertexInput( input ); }
			//
			//var vcount:Vector.<uint>;
			//
			//var primitive:Vector.<uint> = new <uint>[ 0,0,0, 1,1,0, 2,2,0, 3,3,0, 4,3,1, 5,0,1, 6,1,1, 7,2,1, 0,3,2, 3,0,2, 5,1,2, 4,2,2, 3,3,3, 2,0,3, 6,1,3, 5,2,3, 2,3,4, 1,0,4, 7,1,4, 6,2,4, 1,3,5, 0,0,5, 4,1,5, 7,2,5 ];
			//vcount = new <uint>[ 4, 4, 4, 4, 4, 4 ];
			//var polylist:MeshElementDataPolylist = new MeshElementDataPolylist( meshData, 6, inputs, primitive, vcount, name );
			//meshData.elements.push( polylist );
			//
			//var manifest:ModelManifest = modelData.addTo( scene as SceneNode );
			//
			//var box:SceneMesh = manifest.meshes[ 0 ];
			//box.appendScale( 10, 10, -10 );
			//box.appendTranslation( 0, 0, 0 );
			
			var i:uint;
			var s:Number = 50;
			
			for ( i = 0; i < 6; i++ )
			{
				var face:SceneMesh = MeshUtils.createPlane( 50, 50, 0, 0, material );
				face.transform.appendTranslation( 0, -s / 2, 0 );
				face.transform.append( ROTATIONS[ i ] );
				_castersSet.addChild( face );
			}
			
			s = 5;
			for ( i = 0; i < 4; i++ )
			{
				//var sphere:SceneMesh = MeshUtils.createSphere( .25 * ( i + 1 ), 2 + i, 2 + i );
				var sphere:SceneMesh = MeshUtils.createSphere( 1, 2 + i, 2 + i );
				var t:Vector3D = TRANSLATIONS[ i ];
				sphere.transform.appendTranslation( s * t.x, s * t.y, s * t.z );
				_castersSet.addChild( sphere );
			}
			
			// define shadow casters
			if ( lights )
				if ( lights[0] && lights[0].shadowMapEnabled ) lights[ 0 ].addToShadowMap( _castersSet );			
			
			_initialized = true;
		}
		
		override protected function enterFrameEventHandler( event:Event ):void
		{
			if ( !_initialized )
				return;
			
			callPresentOnRender = false;
			super.enterFrameEventHandler( event );
			instance.present();
		}
		
		override protected function onAnimate( t:Number, dt:Number ):void
		{
			if ( !_initialized )
				return;
		}
	}
}

	
