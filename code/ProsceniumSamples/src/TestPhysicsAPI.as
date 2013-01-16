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
	public class TestPhysicsAPI extends BasicDemo
	{
		// ======================================================================
		//	Embedded Resources
		// ----------------------------------------------------------------------
		[ Embed( source="res/content/asphalt002.jpg" ) ]
		protected static const BITMAP:Class;
		
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		private static const NUM_SPHERES:Number							= 2;
		private static const NUM_BOXES:Number							= 2;
		private static const NUM_CYLINDERS:Number						= 2;
		private static const NUM_CAPSULES:Number						= 2;
		private static const NUM_CONES:Number      						= 2;
		private static const NUM_CONVEX:Number							= 2;
		private static const NUM_COMPOUNDS:Number						= 2;
		
		private static const NUM_CONVEXPARAM0:Number					=  1;	//radius
		
		// 0 = bvhmesn, 1=static plane, 2==heightfield
		private static const GROUND_SHAPE:int							= 0;
		
		private static const NUM_VERTS_X:int							= 30;
		private static const NUM_VERTS_Y:int							= 30;
		private static const TRIANGLE_SIZE:Number						= 1000 / NUM_VERTS_X;
		private static const WAVEHEIGHT:Number							= 10;
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _totalVerts:int									= NUM_VERTS_X * NUM_VERTS_Y;
		
		// ground shape : btBvhTriangleMeshShape
		protected var _totalTerrainTriangles:int						= 2*(NUM_VERTS_X-1)*(NUM_VERTS_Y-1);
		protected var _terrainShape:btBvhTriangleMeshShape;
		protected var _indexVertexArrays:btTriangleIndexVertexArray;
		protected var _terrainVertices:Vector.<Number>					= new Vector.<Number>();
		protected var _terrainIndices:Vector.<uint>						= new Vector.<uint>();
		
		// ground shape : btStaticPlaneShape
		protected var _staticPlane:btStaticPlaneShape;
		
		// ground shape : btHeightfieldTerrainShape
		protected var _heightfieldTerrain:btHeightfieldTerrainShape;
		protected var _heights:Vector.<Number>							= new Vector.<Number>();
		
		//
		protected var _staticBodies:Vector.<btRigidBody>				= new Vector.<btRigidBody>();
		protected var _groundShape:btCollisionShape;
		
		// ------------------------------------------------------------------
		protected var _broadphase:btBroadphaseInterface;
		protected var _dispatcher:btCollisionDispatcher;
		protected var _solver:btConstraintSolver;
		protected var _collisionConfiguration:btDefaultCollisionConfiguration;
		protected var _defaultContactProcessingThreshold:Number			= bt.BT_LARGE_FLOAT;
		
		protected var _dynamicsWorld:btDynamicsWorld;
		
		// rigid body sim
		protected var _simObjects:Vector.<btRigidBody>					= new Vector.<btRigidBody>();
		
		// display
		protected var _visObjects:Vector.<SceneNode>					= new Vector.<SceneNode>();
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function TestPhysicsAPI()
		{
			super();
			shadowMapEnabled = true;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		
		public function setBVHMeshVertexPositions( offset:Number ):void
		{
			var i:int, j:int;
			var slopex:Number = 1e-5;
			var slopez:Number = 1e-8;
			
			for ( i=0;i<NUM_VERTS_X;i++) {
				for (j=0;j<NUM_VERTS_Y;j++) {
					_terrainVertices[ (i+j*NUM_VERTS_X) * 3     ] = (i-(NUM_VERTS_Y-1)*0.5) * TRIANGLE_SIZE  + slopex*i+slopex;
					_terrainVertices[ (i+j*NUM_VERTS_X) * 3 + 1 ] = WAVEHEIGHT * Math.sin(i+offset)*Math.cos(j+offset);
					_terrainVertices[ (i+j*NUM_VERTS_X) * 3 + 2 ] = (j-(NUM_VERTS_X-1)*0.5) * TRIANGLE_SIZE  + slopez*j+slopez;
				}
			}
			
			var index:int = 0;
			for ( i=0; i<NUM_VERTS_X-1; i++) for (j=0;j<NUM_VERTS_Y-1;j++)
			{
				_terrainIndices[index++] =  j   *NUM_VERTS_X + i;
				_terrainIndices[index++] = (j+1)*NUM_VERTS_X + i+1;
				_terrainIndices[index++] =  j   *NUM_VERTS_X + i+1;
				
				_terrainIndices[index++] =  j   *NUM_VERTS_X + i;
				_terrainIndices[index++] = (j+1)*NUM_VERTS_X + i;
				_terrainIndices[index++] = (j+1)*NUM_VERTS_X + i+1;
			}
		}
		
		protected function setHeightfield( offset:Number ):void
		{
			var i:int, j:int;
			
			for (j=0;j<NUM_VERTS_Y;j++) {
				for ( i=0;i<NUM_VERTS_X;i++) {
					_heights[i+j*NUM_VERTS_X] = WAVEHEIGHT * Math.sin(i+offset) * Math.cos(j+offset);
				}
			}
			setBVHMeshVertexPositions( 0. );
			_indexVertexArrays = new btTriangleIndexVertexArray( _totalTerrainTriangles, _terrainIndices, _totalVerts, _terrainVertices );
		}
		
		protected function initPellet():void
		{
			_collisionConfiguration = new btDefaultCollisionConfiguration();
			_dispatcher = new btCollisionDispatcher(_collisionConfiguration);
			
			var worldMin:btVector3 = new btVector3(-1000,-1000,-1000);
			var worldMax:btVector3 = new btVector3( 1000, 1000, 1000);
			_broadphase = new btAxisSweep3(worldMin,worldMax);
			_solver = new btSequentialImpulseConstraintSolver();
			_dynamicsWorld = new btDiscreteDynamicsWorld(_dispatcher,_broadphase,_solver,_collisionConfiguration);
			_dynamicsWorld.getSolverInfo().m_splitImpulse = 1;//true;
			
			var mass:Number = 0.;
			var startTransform:btTransform = new btTransform;
			
			///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			// STATIC SHAPES
			///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			_terrainVertices.length = _totalVerts  * 3;
			_terrainIndices.length  = _totalTerrainTriangles * 3;
			
			if (GROUND_SHAPE==0) {
				setBVHMeshVertexPositions( 0.);
				_indexVertexArrays = new btTriangleIndexVertexArray( _totalTerrainTriangles, _terrainIndices, _totalVerts, _terrainVertices );
				
				var useQuantizedAabbCompression:Boolean = false;
				_terrainShape = new btBvhTriangleMeshShape(_indexVertexArrays,useQuantizedAabbCompression);
				_groundShape = _terrainShape as btCollisionShape;
			} else
				if (GROUND_SHAPE==1) {
					_staticPlane = new btStaticPlaneShape( 0,1,0, 0 );
					_groundShape = _staticPlane as btCollisionShape;
				} else
					if (GROUND_SHAPE==2) {
						_heights.length = _totalVerts;
						setHeightfield( 0. );
						_heightfieldTerrain = new btHeightfieldTerrainShape(
							NUM_VERTS_X, NUM_VERTS_X, 
							_heights,
							1,				// heightScale
							-100,100,		// minHeight, maxHeight
							1,				// upAxis
							true);			// edge flip
						_heightfieldTerrain.setLocalScaling( TRIANGLE_SIZE,1,TRIANGLE_SIZE );
						_groundShape = _heightfieldTerrain as btCollisionShape;
					}
			//
			startTransform.setIdentity();
			var static:btRigidBody = localCreateRigidBody(mass, startTransform, _groundShape);
			_staticBodies.push( static );
			static.collisionFlags = static.collisionFlags | btCollisionObject.CF_STATIC_OBJECT;
			
			///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			// DYNAMIC SHAPES
			///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			var i:int;
			
			// create boxes
			if (NUM_BOXES > 0)
			{
				startTransform.setIdentity();
				startTransform.origin.setValue(0,-2,0);
				var boxShape:btBoxShape = new btBoxShape(new btVector3(1.2, 1,.6));
				for (i=0; i<NUM_BOXES; i++) {
					startTransform.origin.setValue(1 + 2.5*i, 10, 1.1);
					localCreateRigidBody(1, startTransform, boxShape as btCollisionShape);
				}
			}
			
			// create spheres
			if (NUM_SPHERES > 0)
			{
				startTransform.setIdentity();
				startTransform.origin.setValue(10,-2,0);
				var sphereShape:btSphereShape = new btSphereShape(1.2);
				for (i=0; i<NUM_SPHERES; i++) {
					startTransform.origin.setValue(1 + 2.5*i, 10, 1.1);
					localCreateRigidBody(1, startTransform, sphereShape as btCollisionShape);
				}
			}
			
			// create cylinders
			if (NUM_CYLINDERS > 0)
			{
				startTransform.setIdentity();
				startTransform.origin.setValue(10,-2,0);
				var cylinderShape:btCylinderShapeZ = new btCylinderShapeZ(1.2,5) ;
				for (i=0; i<NUM_CYLINDERS; i++) {
					startTransform.origin.setValue(1 + 2.5*i, 10, 5.1);
					localCreateRigidBody(1, startTransform, cylinderShape as btCollisionShape);
				}
			}
			
			// create capsules
			if (NUM_CAPSULES > 0)
			{
				startTransform.setIdentity();
				startTransform.origin.setValue(10,-2,0);
				var capsuleShape:btCapsuleShapeZ = new btCapsuleShapeZ( 2, 9);
				for (i=0; i<NUM_CAPSULES; i++) {
					startTransform.origin.setValue(1 + 2.5*i, 30, -5.1);
					localCreateRigidBody(1, startTransform, capsuleShape as btCollisionShape);
				}
			}
			
			// create cones
			if (NUM_CONES > 0)
			{
				startTransform.setIdentity();
				startTransform.origin.setValue(10,-2,0);
				var coneShape:btConeShapeZ = new btConeShapeZ(4, 9) ;
				for (i=0; i<NUM_CONES; i++) {
					startTransform.origin.setValue(4 + 9.5*i, 10, -20.1);
					localCreateRigidBody(1, startTransform, coneShape as btCollisionShape);
				}
			}
			
			// create convex
			if (NUM_CONVEX > 0)
			{
				startTransform.setIdentity();
				startTransform.origin.setValue(10,-2,0);
				MeshUtils.createIcosahedron( NUM_CONVEXPARAM0 );
				var hull:Vector.<Number> = MeshUtils.getLastConvexHull();
				var convexShape:btConvexHullShape = new btConvexHullShape( hull, hull.length/3 ) ;
				for (i=0; i<NUM_CONVEX; i++) {
					startTransform.origin.setValue(4 + 2.5*i, 10,  0.1);
					localCreateRigidBody(1, startTransform, convexShape as btCollisionShape);
				}
			}
			
			// create compounds
			if (NUM_COMPOUNDS > 0)
			{
				var compoundShape:btCompoundShape = new btCompoundShape;
				var childShape0:btCylinderShapeZ = new btCylinderShapeZ(  4, 1 );
				var childShape1:btCylinderShapeZ = new btCylinderShapeZ( .8, 4 );
				var childShape2:btSphereShape = new btSphereShape(1);
				var childShape3:btSphereShape = new btSphereShape(1);
				
				var localTransform:btTransform = new btTransform;
				localTransform.setIdentity();
				compoundShape.addChildShape(localTransform,childShape0);
				compoundShape.addChildShape(localTransform,childShape1);
				localTransform.origin.z =  2;
				compoundShape.addChildShape(localTransform,childShape2);
				localTransform.origin.z = -2;
				compoundShape.addChildShape(localTransform,childShape3);
				
				for (i=0; i<NUM_COMPOUNDS; i++) {
					startTransform.origin.setValue(1 + 5*i, 20, -2.1);
					localCreateRigidBody(1, startTransform, compoundShape as btCollisionShape);
				}
			}
		}
		
		protected function localCreateRigidBody( mass:Number, startTransform:btTransform, shape:btCollisionShape ):btRigidBody
		{
			bt.assert((!shape || shape.shapeType != btBroadphaseNativeTypes.INVALID_SHAPE_PROXYTYPE));
			
			//rigidbody is dynamic if and only if mass is non zero, otherwise static
			var isDynamic:Boolean = (mass != 0.);
			
			var localInertia:btVector3 = new btVector3(0,0,0);
			if (isDynamic)
				shape.calculateLocalInertia(mass,localInertia);
			
			//using motionstate is recommended, it provides interpolation capabilities, and only synchronizes 'active' objects
			var myMotionState:btDefaultMotionState = new btDefaultMotionState(startTransform);
			var cInfo:btRigidBodyConstructionInfo = new btRigidBodyConstructionInfo(mass,myMotionState,shape,localInertia);
			
			var body:PelletRigidBody = new PelletRigidBody(cInfo);
			body.setContactProcessingThreshold( _defaultContactProcessingThreshold );
			
			_dynamicsWorld.addRigidBody(body);
			
			_simObjects.push(body);
			_visObjects.push(null);
			
			return body;
		}
		
		public function copyTransform( source:btTransform, target:SceneNode ):void
		{
			var basis:btMatrix3x3 = source.basis; 
			var origin:btVector3  = source.origin; 
			_tmpVec[ 0] = basis.v00;	_tmpVec[ 1] = basis.v01;	_tmpVec[ 2] = basis.v02;	_tmpVec[ 3] = origin.x;
			_tmpVec[ 4] = basis.v10;	_tmpVec[ 5] = basis.v11;	_tmpVec[ 6] = basis.v12;	_tmpVec[ 7] = origin.y;
			_tmpVec[ 8] = basis.v20;	_tmpVec[ 9] = basis.v21;	_tmpVec[10] = basis.v22;	_tmpVec[11] = origin.z;
			_tmpVec[12] = 0;			_tmpVec[13] = 0;			_tmpVec[14] = 0;			_tmpVec[15] = 1;
			_tmpMat.copyRawDataFrom( _tmpVec, 0, true );
			target.transform = _tmpMat;
		}
		
		private static var offset:Number = 0.;
		private static var worldMin:btVector3 = new btVector3 (-1000,-1000,-1000);
		private static var worldMax:btVector3 = new btVector3 (1000,1000,1000);
		private static var _tmpVec:Vector.<Number> = new Vector.<Number>(16);
		private static var _tmpMat:Matrix3D = new Matrix3D;
		override protected function onAnimate( t:Number, dt:Number ):void
		{
			var dt:Number = 0.01;//getDeltaTimeMicroseconds() * 0.000001f;
			
			// step the simulation
			if (_dynamicsWorld)
				_dynamicsWorld.stepSimulation( 1/60, 0 );
			
			for (var i:int=0; i<_simObjects.length; i++) {
				if (_visObjects[i]!=null)
				{
					copyTransform( _simObjects[i].worldTransform, _visObjects[i] ); 
				}
			}
		}
		
		override protected function initModels():void
		{
			scene.ambientColor.set(1.0, 1.0, 1.0, 1.0);
			SceneLight.shadowMapSamplingDistantLights = RenderSettings.SHADOW_MAP_SAMPLING_3x3;
			initPellet();
			
			instance.backgroundColor.set( .5,.5,.8);
			instance.primarySettings.fogMode    = RenderSettings.FOG_LINEAR;
			instance.primarySettings.fogStart   = 0;
			instance.primarySettings.fogEnd     = 0.01;
			instance.primarySettings.fogDensity = 50;
			
			var mesh:SceneMesh;
			switch( GROUND_SHAPE )
			{
				case 0:
					mesh = MeshUtils.generateSceneMesh( _totalTerrainTriangles, _terrainIndices, _totalVerts, _terrainVertices );
					break;
				
				case 1:
					mesh = MeshUtils.createPlane( 1000, 1000, 10, 10 );
					break;
				
				case 2:
					mesh = MeshUtils.generateSceneMesh( _totalTerrainTriangles, _terrainIndices, _totalVerts, _terrainVertices );
					break;

				default:
					throw new Error( "Unexpected ground shape type!" );
			}
			
			scene.addChild( mesh );
			
			var sphereMaterial:MaterialStandard = new MaterialStandard( "sphereMaterial" );	// material name is used
			var textureMap:TextureMap = new TextureMap( new BITMAP().bitmapData );
			sphereMaterial.diffuseMap = textureMap; 
			
			var objRoot:SceneMesh;
			// create cubes
			var boxSize:btVector3 = new btVector3;
			for (var i:int=0; i<_simObjects.length; i++)
			{
				var material:MaterialStandard = new MaterialStandard( "randMtrl" );	// material name is used
				material.diffuseColor.set( MathUtils.random(), MathUtils.random(), MathUtils.random() );
				material.specularColor = material.diffuseColor.clone();
				
				var box:btBoxShape = _simObjects[i].collisionShape as btBoxShape;
				if(box!=null)
				{
					box.getHalfExtentsWithoutMargin(boxSize);
					_visObjects[i] = MeshUtils.createBox( boxSize.x*2, boxSize.y*2, boxSize.z*2, material, "cube[0]" )
					_visObjects[i].setPosition(
						_simObjects[i].worldTransform.origin.x,
						_simObjects[i].worldTransform.origin.y,
						_simObjects[i].worldTransform.origin.z );
					
					scene.addChild( _visObjects[i] );
					lights[0].addToShadowMap( _visObjects[i] );	// define casters
					continue;
				}
				
				var sphere:btSphereShape = _simObjects[i].collisionShape as btSphereShape;
				if(sphere!=null)
				{
					_visObjects[i] = MeshUtils.createSphere( sphere.getRadius(), 32, 32, sphereMaterial );
					_visObjects[i].setPosition(
						_simObjects[i].worldTransform.origin.x,
						_simObjects[i].worldTransform.origin.y,
						_simObjects[i].worldTransform.origin.z );
					
					scene.addChild( _visObjects[i] );
					lights[0].addToShadowMap( _visObjects[i] );	// define casters
					continue;
				}
				
				var cylinder:btCylinderShape = _simObjects[i].collisionShape as btCylinderShape;
				if(cylinder!=null)
				{
					_visObjects[i] = new SceneNode; 
					_visObjects[i].setPosition(
						_simObjects[i].worldTransform.origin.x,
						_simObjects[i].worldTransform.origin.y,
						_simObjects[i].worldTransform.origin.z );
					
					objRoot = MeshUtils.createCylinder( cylinder.radius, cylinder.length, 32, 2, material );
					objRoot.appendTranslation( 0, 0, -cylinder.length/2 );
					_visObjects[i].addChild( objRoot );
					scene.addChild( _visObjects[i] );
					lights[0].addToShadowMap( _visObjects[i] );	// define casters
					continue;
				}
				
				var capsule:btCapsuleShape = _simObjects[i].collisionShape as btCapsuleShape;
				if(capsule!=null)
				{
					_visObjects[i] = new SceneNode; 
					_visObjects[i].setPosition(
						_simObjects[i].worldTransform.origin.x,
						_simObjects[i].worldTransform.origin.y,
						_simObjects[i].worldTransform.origin.z
					);
					
					objRoot = MeshUtils.createCylinder( capsule.radius, capsule.length, 32, 2, material );
					objRoot.appendTranslation( 0, 0, -capsule.length/2);
					_visObjects[i].addChild( objRoot );
					
					var childShape:SceneMesh;
					childShape = MeshUtils.createSphere( capsule.radius, 32, 32, material );
					childShape.appendTranslation(0,0, 0);
					objRoot.addChild( childShape );
					childShape = MeshUtils.createSphere( capsule.radius, 32, 32, material );
					childShape.appendTranslation(0,0, capsule.length);
					objRoot.addChild( childShape );
					
					scene.addChild( _visObjects[i] );
					lights[0].addToShadowMap( _visObjects[i] );	// define casters
					continue;
				}
				
				var cone:btConeShape = _simObjects[i].collisionShape as btConeShape;
				if(cone!=null)
				{
					_visObjects[i] = new SceneNode; 
					_visObjects[i].setPosition(
						_simObjects[i].worldTransform.origin.x,
						_simObjects[i].worldTransform.origin.y,
						_simObjects[i].worldTransform.origin.z );
					
					objRoot = MeshUtils.createCone( cone.radius, cone.radius*1e-5, cone.length, 32, 2, material );
					objRoot.appendTranslation( 0, 0, -cone.length/2 );
					_visObjects[i].addChild( objRoot );
					scene.addChild( _visObjects[i] );
					lights[0].addToShadowMap( _visObjects[i] );	// define casters
					continue;
				}
				
				var conexHull:btConvexHullShape = _simObjects[i].collisionShape as btConvexHullShape;
				if(conexHull!=null)
				{
					_visObjects[i] = new SceneNode; 
					_visObjects[i].setPosition(
						_simObjects[i].worldTransform.origin.x,
						_simObjects[i].worldTransform.origin.y,
						_simObjects[i].worldTransform.origin.z );
					
					objRoot = MeshUtils.createIcosahedron( NUM_CONVEXPARAM0, material );
					//objRoot.appendTranslation( 0, 0, -cone.length/2 );
					_visObjects[i].addChild( objRoot );
					scene.addChild( _visObjects[i] );
					lights[0].addToShadowMap( _visObjects[i] );	// define casters
					continue;
				}
				
				var compound:btCompoundShape = _simObjects[i].collisionShape as btCompoundShape;
				if(compound!=null)
				{
					_visObjects[i] = new SceneNode;
					
					var n:int = compound.getNumChildShapes();
					for (var k:int=0; k<n; k++)
					{
						switch( compound.getChildShape(k).shapeType )
						{
							case btBroadphaseNativeTypes.CYLINDER_SHAPE_PROXYTYPE:
								cylinder = compound.getChildShape(k) as btCylinderShape;
								childShape = MeshUtils.createCylinder( cylinder.radius, cylinder.length, 32, 2, material );
								copyTransform( compound.getChildTransform(k), childShape ); 
								childShape.appendTranslation( 0, 0, -cylinder.length/2 );
								_visObjects[i].addChild( childShape );							
								break;
							case btBroadphaseNativeTypes.SPHERE_SHAPE_PROXYTYPE:
								sphere = compound.getChildShape(k) as btSphereShape;
								childShape = MeshUtils.createSphere( sphere.getRadius(), 32, 32, material );
								copyTransform( compound.getChildTransform(k), childShape ); 
								_visObjects[i].addChild( childShape );							
								break;
						}
					}
					_visObjects[i].setPosition(
						_simObjects[i].worldTransform.origin.x,
						_simObjects[i].worldTransform.origin.y,
						_simObjects[i].worldTransform.origin.z );
					scene.addChild( _visObjects[i] );
					lights[0].addToShadowMap( _visObjects[i] );	// define casters
					continue;
				}
			}
		}
		
		override protected function enterFrameEventHandler( event:Event ):void
		{
			callPresentOnRender = false;
			super.enterFrameEventHandler( event );
			instance.present();
		}
	}
}