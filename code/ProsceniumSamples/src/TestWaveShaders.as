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
	import flash.display.*;
	import flash.events.*;
	import flash.filters.*;
	import flash.geom.*;
	import flash.utils.*;
	
	// ===========================================================================
	//	Metadata Tag
	// ---------------------------------------------------------------------------
	[ SWF( width="512", height="512" ) ]
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class TestWaveShaders extends Sprite
	{
		// ======================================================================
		//	Embedded Resources
		// ----------------------------------------------------------------------
		[ Embed( source="/../res/kernels/out/WaveEquation.pbj", mimeType="application/octet-stream" ) ]
		protected static const WaveEquation:Class;
		
		[ Embed( source="/../res/kernels/out/WaveInitial.pbj", mimeType="application/octet-stream" ) ]
		protected static const WaveInitial:Class;
		
		[ Embed( source="/../res/kernels/out/HeightToNormal.pbj", mimeType="application/octet-stream" ) ]
		protected static const HeightToNormal:Class;
		
		[ Embed( source="/../res/content/poolBound256.png" ) ]
		protected static const POOL_MASK_256:Class;
		
		[ Embed( source="/../res/content/poolBound512.png" ) ]
		protected static const POOL_MASK_512:Class;
		
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		protected static const RIPPLE_WIDTH:uint					= 512;
		protected static const RIPPLE_HEIGHT:uint					= RIPPLE_WIDTH;
		protected static const OTHER_SCHEME:Boolean					= false;
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _waveEquationShader:Shader;					// Used to compute the finite difference wave equation height map over time
		protected var _waveEquationShaderFilter:ShaderFilter;

		protected var _heightToNormalShader:Shader;					// Used to turn the height map into a normal map
		protected var _heightToNormalShaderFilter:ShaderFilter;

		protected var _bitmapData0:BitmapData;
		protected var _bitmapData1:BitmapData;
		protected var _bitmapData2:BitmapData;
		protected var _targetData:BitmapData;
		
		protected var _target:Bitmap;

		protected var _rippleCenterX:Number	= RIPPLE_WIDTH  / 2.0; 
		protected var _rippleCenterY:Number	= RIPPLE_HEIGHT / 2.0;
		
		protected var _startTime:uint;
		protected var _frameCycleCount:uint;
		
		protected static var _rect:Rectangle = new Rectangle( 0, 0, RIPPLE_WIDTH, RIPPLE_HEIGHT ); 
		protected static var _point:Point = new Point();
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function TestWaveShaders()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;

			// --------------------------------------------------
			
			_bitmapData0 = new BitmapData( RIPPLE_WIDTH, RIPPLE_HEIGHT, false, 0 );
			_bitmapData1 = new BitmapData( RIPPLE_WIDTH, RIPPLE_HEIGHT, false, 0 );
			_bitmapData2 = new BitmapData( RIPPLE_WIDTH, RIPPLE_HEIGHT, false, 0 );
			
			_targetData = new BitmapData( RIPPLE_WIDTH, RIPPLE_HEIGHT, false, 0 );
			_target = new Bitmap( _targetData );
			stage.addChild( _target );	

			// --------------------------------------------------
			
			_waveEquationShader = new Shader( new WaveEquation() as ByteArray );
			_waveEquationShader.data[ "speed" ].value = [ 1.0 ];

			if ( OTHER_SCHEME )
			{
				_waveEquationShader.data[ "prev" ].input = _bitmapData0;
				_waveEquationShader.data[ "src" ].value  = _bitmapData1;
			}
			_waveEquationShaderFilter = new ShaderFilter( _waveEquationShader );
			
			_heightToNormalShader = new Shader( new HeightToNormal() as ByteArray );
			_heightToNormalShaderFilter = new ShaderFilter( _heightToNormalShader );
			
			// --------------------------------------------------
			
			// Used to set up the initial state
			var waveInitialShader:Shader = new Shader( new WaveInitial() as ByteArray );
			var waveInitialShaderFilter:ShaderFilter =  new ShaderFilter( waveInitialShader )
			var poolMaskBitmap:Bitmap = ( RIPPLE_WIDTH == 256 ) ? new POOL_MASK_256() : new POOL_MASK_512();

			if ( OTHER_SCHEME )
				_bitmapData1.applyFilter( poolMaskBitmap.bitmapData, _rect, _point, waveInitialShaderFilter );
			else
				_bitmapData0.applyFilter( poolMaskBitmap.bitmapData, _rect, _point, waveInitialShaderFilter );

			poolMaskBitmap.bitmapData.dispose();
			
			// --------------------------------------------------
			
			_startTime = getTimer();
			stage.addEventListener( Event.ENTER_FRAME, enterFrameEventHandler );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		
		protected static var _once:Boolean = true;
		protected function enterFrameEventHandler( event:Event ):void
		{
			var t:Number = ( getTimer() - _startTime ) / 1000;
			
			if ( (( t * 25 ) % 16) < 2 )
			{
				_rippleCenterX = Math.random() * RIPPLE_WIDTH;
				_rippleCenterY = Math.random() * RIPPLE_HEIGHT;
				_waveEquationShader.data[ "center" ].value = [ _rippleCenterX, _rippleCenterY ];
				_waveEquationShader.data[ "amplitude" ].value = [ 0.5 * ( Math.random() - 0.5 ) * 2.0];
				_waveEquationShader.data[ "radiusSquared" ].value = [ 64.0 * ( Math.random() ) ];
				
				_once = true;
			}
			else
			{
				if ( _once )
				{
					_waveEquationShader.data[ "amplitude" ].value = [ 0.0 ];
					_once = false;
				}
			}

			if ( OTHER_SCHEME )
			{
				_bitmapData2.applyFilter( _bitmapData1, _rect, _point, _waveEquationShaderFilter );
				_bitmapData0.copyPixels( _bitmapData1, _rect, _point );
				_bitmapData1.copyPixels( _bitmapData2, _rect, _point );
				_targetData.applyFilter( _bitmapData2, _rect, _point, _heightToNormalShaderFilter );
			}
			else
			{
				if ( _frameCycleCount == 0 )
				{
					_frameCycleCount = 1;
					
					_waveEquationShader.data[ "prev" ].input = _bitmapData1;
					_waveEquationShader.data[ "src" ].value  = _bitmapData0;
					
					_bitmapData1.applyFilter( _bitmapData0, _rect, _point, _waveEquationShaderFilter );
					_targetData.applyFilter( _bitmapData1, _rect, _point, _heightToNormalShaderFilter );
				}
				else
				{
					_frameCycleCount = 0;
					
					_waveEquationShader.data[ "prev" ].input = _bitmapData0;
					_waveEquationShader.data[ "src" ].value  = _bitmapData1;
					
					_bitmapData0.applyFilter( _bitmapData1, _rect, _point, _waveEquationShaderFilter );
					_targetData.applyFilter( _bitmapData0, _rect, _point, _heightToNormalShaderFilter );
				}				
			}
		}
	}
}