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
	import pellet.collision.dispatch.*;
	import pellet.collision.phasebroad.*;
	import pellet.collision.phasenarrow.*;
	import pellet.collision.shapes.*;
	import pellet.dynamics.*;
	import pellet.dynamics.solver.*;
	import pellet.math.*;
	import com.adobe.utils.*;
	
	import flash.display.*;
	import flash.display3D.*;
	import flash.geom.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class PelletState implements btMotionState
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		private var mNode:SceneNode;
		private var mTbody:btTransform;
		private var mDelta:btVector3;
		
		private static var sT:Matrix3D								= new Matrix3D();
		private static const _rawData_:Vector.<Number>				= new Vector.<Number>( 16, true );
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function PelletState( node:SceneNode, delta:btVector3 = null ):void
		{
			mNode = node;
			mDelta = new btVector3();
			
			if ( delta )
				mDelta.set( delta );
			else
				mDelta.setZero();
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		// Set from Pellet only for active objects
		private static var _tempTransform:btTransform				= new btTransform();
		public function setWorldTransform( transform:btTransform ):void
		{
			// node should not notify us of this change: unsubscribe body observer
			var b:IRigidBody = mNode.physicsObject;			
			mNode.physicsObject = null;
			
			_tempTransform.set( transform );
			_tempTransform.origin.sub( mDelta );
			_tempTransform.copyToRawData( _rawData_ );
			sT.copyRawDataFrom( _rawData_ );
			mNode.transform = sT;
			
			// subscribe body observer
			mNode.physicsObject = b;
		}
		
		public function getWorldTransform( transform:btTransform ):void
		{
			mNode.transform.copyRawDataTo( _rawData_ );
			transform.copyFromRawData( _rawData_ );
			transform.origin.add( mDelta );
		}
	}	
}