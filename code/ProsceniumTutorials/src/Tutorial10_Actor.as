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
	import com.adobe.scenegraph.loaders.collada.ColladaLoader;
	import com.adobe.toddler.*;
	
	import flash.display.*;
	import flash.display3D.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.ui.Keyboard;
	import flash.utils.*;
	
	import pellet.collision.dispatch.btCollisionObject;
	import pellet.collision.shapes.*;
	import pellet.dynamics.*;
	import pellet.math.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	/**
	 * This example shows how to use Collada animation to create an interactive animated character.
	 */
	public class Tutorial10_Actor extends BasicDemo
	{		
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		// User actions (up, down, left, right) are mapped to a binary mask.
		static private const kMoveForward:uint						= 1 << 0;
		static private const kMoveBackward:uint						= 1 << 1;
		static private const kMoveLeft:uint							= 1 << 2;
		static private const kMoveRight:uint						= 1 << 3;
		
		// This mask is mapped to a code for direction according to this chart:
		//	5			1			3
		//				^	
		//				|
		//	4	<	-	0	-	>	8
		//				|
		//				v
		//	6			2			7
		static private const kFlagToCode:Vector.<uint>				= new <uint>[ 0, 1, 2, 0, 4, 5, 6, 0, 8, 3, 7, 0, 0, 0, 0, 0 ];

		// And the code is mapped to a yaw angle around the vertical y-axis. 
		static private const kCodeToYaw:Vector.<Number>				= new <Number>[ 0., 0, Math.PI, -.25 * Math.PI, .5 * Math.PI, .25 * Math.PI, .75 * Math.PI, -.75 * Math.PI, -.5 * Math.PI ];

		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		// We use a phyics simulator to drive a bounding capsule with user-controlled motors
		private var mPellet:PelletManager;
		private var mCapsule:SceneNode;		
		private var mGo:Motor, mStop:Motor, mActiveMotor:Motor;

		private var mMoveFlag:uint;
		
		// The bounding capsule will set the position and orientation of the character while the actor follows in-place motions.
		private var mActor:Actor;
				
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		function Tutorial10_Actor()
		{
			super();
			shadowMapEnabled = true;
			SceneGraph.OIT_ENABLED = true; // Enable order independent transparency, false by default
			
			// Use go to move capsule in desired direction.
			mGo = new Motor;
			// The gains are tuned by hand because they depend on weight, friction, terrain, and so on:
			// - Begin with second parameter (Ki) set to zero.
			// - Increase the first parameter (Kp) until capsule reaches the target speed as desired.
			// Small Kp values may get there too slowly.  Large Kp values may push the capsule offscreen.
			// Somewhere in between the capsule will oscillate.  A good setting for Kp is usually half of that value.
			// - Increase the second parameter (Ki) so that capsule reaches the desired speed despite friction or other
			// objects that may impede its progress.  But large Ki values may push hte capsule offscreen. 
			mGo.setGains( 70, 30 );
			// The speed can be set to match the footwork in Actor's motion.
			mGo.speed = 1;
			
			// And stop to hold it in place.
			mStop = new Motor;
			// Same tuning strategy applies here.
			mStop.setGains( 1e2, 10 );
			mStop.speed = 0;
			
			// The actor will first stand in place.
			mActiveMotor = mStop;
			
			stage.addEventListener( KeyboardEvent.KEY_UP, releaseHandler );
		}

		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function initModels():void
		{
			mPellet = new PelletManager();

			scene.addChild( newGround() );			
			
			mCapsule = newCapsule( .35, 1, true );
			mCapsule.name = "capsule";
			mCapsule.setPosition( 0, 5, 0 );
			scene.addChild( mCapsule );
		
			// We are using a freely available motion (jazz dancing) and character (Alexis) from mixamo.com
			// in order to see the character you will need to create an account and download the model yourself
			// and place it in the res/content/dance/ directory.
			var loader:ColladaLoader = new ColladaLoader( "../res/content/dance/dance.dae" );
			loader.addEventListener( Event.COMPLETE, newActor, false, 0, true );			
		}		
		
		private function newGround():SceneNode
		{
			var ground:SceneMesh = MeshUtils.createPlane( 100, 100 );
			var state:PelletState = new PelletState( ground );
			var shape:btStaticPlaneShape = new btStaticPlaneShape( 0, 1, 0, 0 );
			// mass = 0 so rigidbody is static
			var localInertia:btVector3 = new btVector3();
			var cInfo:btRigidBodyConstructionInfo = new btRigidBodyConstructionInfo( 0, state, shape, localInertia );			
			var groundRigidBody:PelletRigidBody = new PelletRigidBody( cInfo );
			ground.physicsObject = groundRigidBody;
			
			mPellet.dynamicsWorld.addRigidBody( groundRigidBody );
			
			return ground;			
		}
		
		private function newCapsule( r:Number, h:Number, displayCapsule:Boolean = false ):SceneNode
		{
			var obj:SceneNode = new SceneNode();
	
			var shape:btCapsuleShape = new btCapsuleShapeY( r, h );			
			var offset:btTransform = new btTransform();
			offset.basis.setIdentity();
			offset.origin.setValue( 0, 0.5 * h + r, 0 );
			var state:PelletState = new PelletState( obj, offset.origin );
			
			var mass:Number = 75; // kg			
			var localInertia:btVector3 = new btVector3( 1e30, 1e30, 1e30 );
			
			var cInfo:btRigidBodyConstructionInfo = new btRigidBodyConstructionInfo( mass, state, shape, localInertia );
			var b:PelletRigidBody = new PelletRigidBody( cInfo );
			b.setActivationState( btCollisionObject.DISABLE_DEACTIVATION );
			
			obj.physicsObject = b;			
			mPellet.dynamicsWorld.addRigidBody( b );

			// Draw bounding capsule used in simulation and to determine world location.
			if ( displayCapsule )
			{	
				var uTess:int = 32;
				var vTess:int = 2;
				var material:MaterialStandard = new MaterialStandard();
				material.diffuseColor.set( .6, .6, .6 );
				material.opacity = .5;
				
				var mesh:SceneMesh = MeshUtils.createCylinder( r, h, uTess, vTess, material );
				mesh.prependTranslation( 0, r, 0 );
				mesh.prependRotation( -90, Vector3D.X_AXIS );
				var sphere0:SceneMesh = MeshUtils.createSphere( r, uTess, uTess, material );
				sphere0.appendTranslation( 0, r, 0 );
				var sphere1:SceneMesh = MeshUtils.createSphere( r, uTess, uTess, material );
				sphere1.appendTranslation( 0, r + h, 0 );
				obj.addChild( mesh );
				obj.addChild( sphere0 );
				obj.addChild( sphere1 );
			}			
			
			return obj;
		}
		
		private function newActor( event:Event ):void
		{
			var loader:ModelLoader = event.target as ModelLoader;
			loader.model.addTo( mCapsule );
			
			mActor = new Actor();
			mActor.initWithNode( mCapsule );
			
			var script:MotionPrimitive = new MotionPrimitive();
			script.initWithDAE( mActor, loader.model.animations );
			mActor.prepare();
			mActor.script = script;	
			
			if ( lights )
			{
				lights[0].setPosition( 10, 20, 10 );
				if ( lights[ 0 ].shadowMapEnabled )
					lights[ 0 ].addToShadowMap( mCapsule );	// define casters
			}
		}
		
		override protected function keyboardEventHandler( e:KeyboardEvent ):void
		{
			switch( e.keyCode )
			{
				case Keyboard.UP:	// Up				
					mMoveFlag |= kMoveForward;
					break;
					
				case Keyboard.DOWN:	// Down
					mMoveFlag |= kMoveBackward;
					break;	

				case Keyboard.LEFT:	// Left
					mMoveFlag |= kMoveLeft;
					break;	

				case Keyboard.RIGHT:	// Right
					mMoveFlag |= kMoveRight;
					break;

				default:
					super.keyboardEventHandler(e);
			}
			
			updateDirection();
		}
		
		protected function releaseHandler( e:KeyboardEvent ):void
		{
			switch( e.keyCode )
			{
				case Keyboard.UP:	// Up				
					mMoveFlag &= ~kMoveForward;
					break;
					
				case Keyboard.DOWN:	// Down
					mMoveFlag &= ~kMoveBackward;
					break;	

				case Keyboard.LEFT:	// Left
					mMoveFlag &= ~kMoveLeft;
					break;	

				case Keyboard.RIGHT:	// Right
					mMoveFlag &= ~kMoveRight;
					break;
			}
			
			updateDirection();
		}		
		
		private function updateDirection():void
		{
			var moveCode:uint = kFlagToCode[ mMoveFlag ];
			if ( moveCode > 0 )
			{
				if ( mActiveMotor != mGo ) 
				{
					mActiveMotor = mGo;
					mActiveMotor.reset();
				}				
				
				var a:Number = kCodeToYaw[ moveCode ]
				mActiveMotor.heading = a;
				
				var T:Matrix3D = new Matrix3D();
				T.prependRotation( a * 180 / Math.PI, Vector3D.Y_AXIS );				
				mCapsule.physicsObject.setWorldTransformBasis( T );
			}
			else
			{
				if ( mActiveMotor != mStop ) 
				{
					mActiveMotor = mStop;
					mActiveMotor.reset();
				}
			}
		}
		
		override protected function onAnimate( t:Number, dt:Number ):void
		{
			if ( mPellet ) 
			{
				mActiveMotor.apply( mCapsule.physicsObject, dt );
				mPellet.stepWithSubsteps( dt, 2 );
			}
			
			if ( mActor ) 
				mActor.moveWithTime( dt );
		}
		
		override protected function initLights():void
		{
			var material:MaterialStandard;
			
			// --------------------------------------------------
			//	Light #1
			// --------------------------------------------------
			lights = new Vector.<SceneLight>();
			var light:SceneLight;
			
			light = new SceneLight( SceneLight.KIND_DISTANT, "distant light" );
			light.color.set( .9, .88, .85 );
			light.shadowMapEnabled = shadowMapEnabled;
			light.setShadowMapSize( shadowMapSize, shadowMapSize );
			light.transform.prependRotation( -95, Vector3D.X_AXIS );
			light.transform.appendTranslation( .1, 2, .1 );
			lights.push( light );
			
			light = new SceneLight( SceneLight.KIND_DISTANT, "distant light" );
			light.color.set( .9, .88, .85 );
			light.lookat(
				new Vector3D( 0, 5, -5 ),
				new Vector3D( 0, .5, 0 ),
				new Vector3D( 0, 1, 0 )
			);
			lights.push( light );
			
			for each ( light in lights ) {
				scene.addChild( light );
			}
		}
		
		override protected function resetCamera():void
		{
			scene.activeCamera.fov = 65;
			scene.activeCamera.aspect = stage.stageWidth / stage.stageHeight;
			scene.activeCamera.lookat(
				new Vector3D( 0, 3, -5 ),
				new Vector3D( 0, .5, 0 ),
				new Vector3D( 0, 1, 0 )
			);	
		}		
	}
}

// ================================================================================
//	Helper Classes
// --------------------------------------------------------------------------------
import com.adobe.scenegraph.*;
import com.adobe.toddler.*;

import flash.geom.*;

import pellet.math.*;
{
	class Motor
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var mImpulses:Vector.<PIFeedback>;
		protected var mSpeed:Number
		protected var mHeading:Number;
		protected var mUnitDirection:Vector3D;
		
		// ----------------------------------------------------------------------
		
		protected static const _v_:Vector3D = new Vector3D();
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get speed():Number
		{
			return mSpeed;		
		}
		
		public function set speed( s:Number ):void
		{
			mSpeed = s;
			setTargetDirection();
		}
		
		public function set heading( a:Number ):void
		{
			mUnitDirection.setTo( Math.sin( a ), 0, Math.cos( a ) );
			setTargetDirection();
		}
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function Motor()
		{
			mImpulses = new <PIFeedback>[ new PIFeedback, new PIFeedback ];
			mUnitDirection = new Vector3D( 0, 0, 1 );
			mSpeed = 0;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function setGains( Kp:Number, Ki:Number ):void
		{
			for each ( var f:PIFeedback in mImpulses ) {
				f.setGains( Kp, Ki );
			}
		}
		
		public function reset():void
		{
			for each ( var f:PIFeedback in mImpulses ) {
				f.reset(); 
			}
		}
		
		protected function setTargetDirection():void
		{
			var v:Vector3D = mUnitDirection.clone();
			v.scaleBy( mSpeed );
			mImpulses[ 0 ].setpoint = v.x;
			mImpulses[ 1 ].setpoint = v.z;		
		}
		
		public function apply( b:IRigidBody, dt:Number ):void
		{
			b.getVelocityLinear( _v_ );
			var delta:btVector3 = new btVector3(
				mImpulses[ 0 ].update( _v_.x, dt),
				0,
				mImpulses[ 1 ].update( _v_.z, dt )
			);
			b.applyImpulseToCenter( delta.x, delta.y, delta.z );
		}
	}
}