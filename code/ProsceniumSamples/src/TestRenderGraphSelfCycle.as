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
	import com.adobe.utils.*;
	
	import flash.display.*;
	import flash.display3D.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;
	
	import pellet.collision.dispatch.*;
	import pellet.collision.phasebroad.*;
	import pellet.collision.phasenarrow.*;
	import pellet.collision.shapes.*;
	import pellet.dynamics.*;
	import pellet.dynamics.solver.*;
	import pellet.math.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class TestRenderGraphSelfCycle extends BasicDemo
	{
		// ======================================================================
		//	Embedded Resources
		// ----------------------------------------------------------------------
		[ Embed( source="../res/content/Sailboat.p3d", mimeType="application/octet-stream" ) ]
		protected static var BOATDATA:Class;
		
		[ Embed( source="res/content/asphalt002.jpg" ) ]
		protected static const BITMAP:Class;
		
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		private static const NUM_SPHERES:Number							= 2;
		private static const NUM_BOXES:Number							= 2;
		private static const NUM_CYLINDERS:Number						= 1;
		private static const NUM_CAPSULES:Number						= 2;
		private static const NUM_CONES:Number      						= 1;
		private static const NUM_TETRAHEDRONS:Number					= 2;
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _pellet:PelletManager;

		private static var offset:Number = 0.;
		private static var worldMin:btVector3							= new btVector3( -1000, -1000, -1000 );
		private static var worldMax:btVector3							= new btVector3( 1000, 1000, 1000 );
		private static var _tmpVec:Vector.<Number>						= new Vector.<Number>( 16 );
		private static var _tmpMat:Matrix3D								= new Matrix3D();
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function TestRenderGraphSelfCycle()
		{
			super();
			shadowMapEnabled = true;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		protected function getMaterial():MaterialStandard
		{
			var material:MaterialStandard = new MaterialStandard( "randMtrl" );	// material name is used
			material.diffuseColor.set( .2 + MathUtils.random() * .8, .2 + MathUtils.random() * .8, .2 + MathUtils.random() * .8 );
			material.ambientColor.set( .2, .2, .2 );
			material.specularExponent = 20;
			material.specularColor.set( 1, 1, 1 );
			return material;
		}
		
		override protected function initModels():void
		{
			scene.ambientColor.set( 1, 1, 1 );
			SceneLight.shadowMapSamplingDistantLights = RenderSettings.SHADOW_MAP_SAMPLING_3x3;
			
			_pellet = new PelletManager();
			
			// boat
			var scale:Number = 10;
			var boatModel:ModelData = ModelData.fromBinary( new BOATDATA() as ByteArray );
			var boatModelManifest:ModelManifest = boatModel.addTo( null );
			
			for each ( var boatMesh:SceneMesh in boatModelManifest.meshes )
			{
				var indices:Vector.<uint> = new Vector.<uint>;
				var vertices:Vector.<Number> = new Vector.<Number>;
				var indexVertexArray:btTriangleIndexVertexArray;
				var shape:btBvhTriangleMeshShape;
				var boatCollision:SceneNode;
				var rbody:btRigidBody;
				
				boatMesh.getIndexVertexArrayCopyForAllElements( indices, vertices );
				indexVertexArray = new btTriangleIndexVertexArray( indices.length/3, indices, vertices.length/3, vertices );
				shape = new btBvhTriangleMeshShape(indexVertexArray,false);
				boatCollision = new SceneNode;
				boatMesh.addChild( boatCollision );
				rbody = _pellet.createRigidBody(boatCollision, 0, shape);
				shape.setLocalScaling(scale,scale,scale);
				boatCollision.physicsObject.collisionFlags |= btCollisionObject.CF_STATIC_OBJECT;

				boatMesh.appendScale(scale,scale,scale);
				boatMesh.appendTranslation(10,0,-20);
				boatCollision.appendTranslation(10,0,-20);
				scene.addChild( boatMesh );
				lights[ 0 ].addToShadowMap( boatMesh );	// define casters
				lights[ 1 ].addToShadowMap( boatMesh );	// define casters
			}
			
			// terrain/water
			const NUM_VERTS_X:int = 30;
			const NUM_VERTS_Y:int = 30;
			const TRIANGLE_SIZE:Number = 1000 / NUM_VERTS_X;
			const WAVEHEIGHT:Number = 10.;
			
			var numVertices:int = NUM_VERTS_X*NUM_VERTS_Y;
			var numTriangles:int = 2 * ( NUM_VERTS_X - 1 ) *( NUM_VERTS_Y - 1 );
			
			var terrainVertices:Vector.<Number>	= new Vector.<Number>( numVertices * 3 );
			var terrainIndices:Vector.<uint> = new Vector.<uint>( numTriangles * 3 );
			
			var i:int, j:int;
			for ( i = 0; i < NUM_VERTS_X; i++ )
			{
				for ( j = 0; j < NUM_VERTS_Y; j++ )
				{
					terrainVertices[ (i+j*NUM_VERTS_X) * 3     ] = (j-(NUM_VERTS_Y-1)*0.5) * TRIANGLE_SIZE;
					terrainVertices[ (i+j*NUM_VERTS_X) * 3 + 1 ] = WAVEHEIGHT * Math.sin(i+offset)*Math.cos(j+offset);
					terrainVertices[ (i+j*NUM_VERTS_X) * 3 + 2 ] = (i-(NUM_VERTS_X-1)*0.5) * TRIANGLE_SIZE;
				}
			}
			
			var index:int = 0;
			for ( i = 0; i < NUM_VERTS_X - 1; i++ )
			{
				for ( j = 0; j < NUM_VERTS_Y - 1; j++ )
				{
					terrainIndices[index++] =  j   *NUM_VERTS_X + i;
					terrainIndices[index++] =  j   *NUM_VERTS_X + i+1;
					terrainIndices[index++] = (j+1)*NUM_VERTS_X + i+1;
					
					terrainIndices[index++] =  j   *NUM_VERTS_X + i;
					terrainIndices[index++] = (j+1)*NUM_VERTS_X + i+1;
					terrainIndices[index++] = (j+1)*NUM_VERTS_X + i;
				}
			}
			var ground:SceneMesh = _pellet.createStaticTriangleMesh( numTriangles, terrainIndices, numVertices, terrainVertices );
			var mtrlWater:MaterialStandard = new MaterialStandard;
			mtrlWater.diffuseColor.set( 0.4, 0.4, .4 );
			ground.getElementByIndex( 0 ).material = mtrlWater;
			scene.addChild( ground );
			
			var material:MaterialStandard;
			
			// create boxes
			for (i=0; i<NUM_BOXES; i++)
			{
				var box:SceneMesh = _pellet.createBox( 2, 4, 3, getMaterial() );
				box.setPosition( 1 + 2.5 * i, 40, 1.1 );
				scene.addChild( box );
				lights[ 0 ].addToShadowMap( box );	// define casters
				lights[ 1 ].addToShadowMap( box );	// define casters
			}
			
			// create spheres
			var textureMap:TextureMap = new TextureMap( new BITMAP().bitmapData );
			for ( i = 0; i < NUM_SPHERES; i++ )
			{
				var mtrlSphere:MaterialStandard = getMaterial();
				mtrlSphere.diffuseMap = textureMap; 
				var sphere:SceneMesh = _pellet.createSphere( 2, 32, 16, mtrlSphere );
				sphere.setPosition( 1 + 2.5*i, 40, 10.1 );
				scene.addChild( sphere );
				lights[ 0 ].addToShadowMap( sphere );	// define casters
				lights[ 1 ].addToShadowMap( sphere );	// define casters
			}
			
			// create cones
			for ( i = 0; i < NUM_CONES; i++ )
			{
				var cone:SceneNode = _pellet.createCone( 2, 4, 32, 16, getMaterial() );
				cone.setPosition( 1 + 2.5*i, 40, -15.1 );
				scene.addChild( cone );
				lights[ 0 ].addToShadowMap( cone );	// define casters
				lights[ 1 ].addToShadowMap( cone );	// define casters
			}
			
			// create tetrahedrons
			for ( i = 0; i < NUM_TETRAHEDRONS; i++ )
			{
				var tet:SceneMesh = _pellet.createRegularTetrahedron( 2, getMaterial() );
				tet.setPosition( 1 + 2.5 * i, 40, 5.1 );
				scene.addChild( tet );
				lights[ 0 ].addToShadowMap( tet );	// define casters
				lights[ 1 ].addToShadowMap( tet );	// define casters
			}
			
			// create cylinders
			for ( i = 0; i < NUM_CYLINDERS; i++ )
			{
				var cyl:SceneNode = _pellet.createCylinder(5, 1, 32,2, getMaterial() );
				cyl.setPosition( 1 + 2.5*i, 50, 1.1 );
				scene.addChild( cyl );
				lights[ 0 ].addToShadowMap( cyl );	// define casters
				lights[ 1 ].addToShadowMap( cyl );	// define casters
			}
			
			// create capsules
			for ( i = 0; i < NUM_CAPSULES; i++ )
			{
				var capsule:SceneNode = _pellet.createCapsule(1, 3, 32, 2, getMaterial() );
				capsule.setPosition( 1 + 2.5 * i, 30, 1.1 );
				scene.addChild( capsule );
				lights[ 0 ].addToShadowMap( capsule );	// define casters
				lights[ 1 ].addToShadowMap( capsule );	// define casters
			}

			// shadow acne control
			SceneLight.shadowMapZBiasFactor		  			= 0;//2;
			SceneLight.shadowMapVertexOffsetFactor			= 0;//3;
			SceneLight.shadowMapSamplerNormalOffsetFactor	= 3;
			//SceneLight.adjustDistantLightShadowMapToCamera = false;
		
			////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			// break direct rendering to primary and create a new color render target/texture (HDR target, etc)
			instance.createPostProcessingColorBuffer();
			var X:RenderTexture = instance.colorBuffer;
			var Y:RenderTexture = new RenderTexture( instance.width, instance.height, "Y" ); 
			
			var re:RenderGraphNodePPElement = new RenderGraphNodePPElement( X, Y,  RenderGraphNodePPElement.IIR1, "Y = IIR1" );
			re.iirCoefIn  = 0.2;
			re.iirCoefOut = 0.8;
			Y.renderGraphNode = re; 
			Y.renderGraphNode.addStaticPrerequisite( X.renderGraphNode );
			Y.renderGraphNode.addStaticPrerequisite( Y.renderGraphNode );		// self cycle
			
			var YToPrimry:RenderGraphNode = new RenderGraphNodePPElement( Y, null,  RenderGraphNodePPElement.COPY, "ToPrimary" );
			YToPrimry.addStaticPrerequisite( Y.renderGraphNode );

			instance.renderGraphRoot.clearAllPrerequisite( );
			instance.renderGraphRoot.addStaticPrerequisite(YToPrimry);
			////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

			// fog and bk
			instance.backgroundColor.set( .5,.5,.8);
			instance.primarySettings.fogMode    = RenderSettings.FOG_LINEAR;
			instance.primarySettings.fogStart   = 0;
			instance.primarySettings.fogEnd     = 0.01;
			instance.primarySettings.fogDensity = 50;
			X.backgroundColor.set( .5,.5,.8);
			X.targetSettings.fogMode    = RenderSettings.FOG_LINEAR;
			X.targetSettings.fogStart   = 0;
			X.targetSettings.fogEnd     = 0.01;
			X.targetSettings.fogDensity = 50;

			//
			_camera.transform.appendRotation( -15, Vector3D.Y_AXIS );
			_camera.setPosition( -20, 20, 40 );
		}
		
		protected var _n:uint = 0;
		override protected function enterFrameEventHandler( event:Event ):void
		{
			//if ( _n++ < 155 )
			{
				if ( _pellet )
					_pellet.step();
				
				callPresentOnRender = false;
				super.enterFrameEventHandler( event );
	
				//if ( false && lights )
				//{
				//	var w:Number  = 200;
				//	var pos:Number = 0;
				//	for each ( var lt:SceneLight in lights )
				//	if ( lt.shadowMap && lt.shadowMapEnabled )
				//	{
				//		lt.shadowMap.showMeTheTexture( instance, instance.width, instance.height, pos, 0, w );
				//		pos += w;
				//	}
				//}

				instance.present();
			}
		}
	}
}