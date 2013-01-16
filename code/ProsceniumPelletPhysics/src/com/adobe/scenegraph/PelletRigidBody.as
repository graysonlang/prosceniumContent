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
package com.adobe.scenegraph
{
	// ===========================================================================
	//	Imports
	// ---------------------------------------------------------------------------
	import flash.geom.*;
	
	import pellet.dynamics.*;
	import pellet.math.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class PelletRigidBody extends btRigidBody implements IRigidBody
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		private static const _rawData_:Vector.<Number> = new Vector.<Number>( 16, true );
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		/** @private **/
		public function set mass( v:Number ):void					{ this.setMass( v ); }
		public function get mass():Number							{ return 1 / getInvMass(); }

		/** @private **/
		override public function set restitution( v:Number ):void	{ m_restitution = v; }
		override public function get restitution():Number			{ return m_restitution; }

		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function PelletRigidBody( constructionInfo:btRigidBodyConstructionInfo )
		{
			super( constructionInfo );
		}

		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		//private static const _btt_:btTransform = new btTransform();		
		//override public function set transform( m:Matrix3D ):void
		//{
		//	_btt_.copyFromMatrix3D( m );
		//	setCenterOfMassTransform( _btt_ );
		//}
		
		public function doActivate( forceActivation:Boolean = false ):void
		{
			activate( forceActivation );
		}
		
		public function updateTransform():void
		{
			var w:btTransform = new btTransform();
			getMotionState().getWorldTransform( w );
			// TODO: verify for static/kinematic objects: see comment in btRigidBody set transform
			setCenterOfMassTransform( w );
		}
		
		private static const _v_:Vector3D = new Vector3D();
		public function getVelocityLinear( result:Vector3D = null ):Vector3D
		{
			if ( !result )
				result = _v_;
				
			result.x = m_linearVelocity.x;
			result.y = m_linearVelocity.y;
			result.z = m_linearVelocity.z;
			
			return result;
		}
		public function setVelocityLinear( x:Number = 0, y:Number = 0, z:Number = 0 ):void
		{
			setLinearVelocity( x, y, z );
		}
		
		public function setVelocityAngular( x:Number = 0, y:Number = 0, z:Number = 0 ):void
		{
			setAngularVelocity( x, y, z );
		}
		
		private static const _btv_:btVector3 = new btVector3();
		public function applyImpulseToCenter( x:Number, y:Number, z:Number ):void
		{
			_btv_.x = x;
			_btv_.y = y;
			_btv_.z = z;
			super.applyCentralImpulse( _btv_ );
		}

		public function setWorldTransformBasis( matrix:Matrix3D ):void
		{
			matrix.copyRawDataTo( _rawData_ )
			worldTransform.basis.copyFromRawData( _rawData_ );
		}
	}
}