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
	import flash.events.*;
	import flash.filters.*;
	import flash.geom.*;
	import flash.text.*;
	import flash.text.engine.*;
	import flash.utils.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class Tutorial11_TextureFromDisplayObject extends BasicDemo
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		protected static const FORMAT:TextFormat					= new TextFormat( "Arial", 12, 0x0, true, false, false, null, null, TextFormatAlign.LEFT );
		protected static const LOG_OF_2:Number						= Math.log( 2 );
		
		protected static const POINT:Point							= new Point();
		
		protected static const ALPHA_TO_COLOR:ColorMatrixFilter		= new ColorMatrixFilter(
			[
				0, 0, 0, 1, 0,
				0, 0, 0, 1, 0,
				0, 0, 0, 1, 0,
				0, 0, 0, 1, 0,
			]
		);
		
		protected static const REMOVE_ALPHA:ColorMatrixFilter		= new ColorMatrixFilter(
			[
				1, 0, 0, 0, 0,
				0, 1, 0, 0, 0,
				0, 0, 1, 0, 0,
				0, 0, 0, 0, 255
			]
		);
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var texture:BitmapData;
		
		protected var _sprite:Sprite;
		protected var _label:TextField;
		
		protected var _rect:Rectangle;
		
		protected var _material:MaterialStandard;
		
		protected var _alpha:BitmapData;
		protected var _color:BitmapData;
		protected var _colorTexture:TextureMap;
		protected var _alphaTexture:TextureMap;
		
		protected var _quad:SceneMesh;
		
		protected var _initialized:Boolean;
		
		protected var _last:int;
		protected var _mspf:Number									= 1000 / 60;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function Tutorial11_TextureFromDisplayObject()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			SceneGraph.OIT_ENABLED = false;
			
			_sprite = new Sprite();
			_sprite.mouseEnabled = false;
			_sprite.mouseChildren = false;
			
			_label = new TextField();
			_label.background = false;
			_label.border = true;
			_label.borderColor = 0xcc3333;
			_label.mouseEnabled = false;
			
			var w:Number = 256;
			var h:Number = w;
			
			_rect	= new Rectangle( 0, 0, w, h );
			_color	= new BitmapData( w, h, true, 0x0 );
			_alpha	= new BitmapData( w, h, true, 0x0 );
			
			_sprite.addChild( _label );
			_sprite.graphics.beginFill( 0x336699 );
			_sprite.graphics.drawCircle( 32, 32, 28 );
			
			_last = getTimer();
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function initModels():void
		{
			super.initModels();
			
			_colorTexture = new TextureMap( _color, false, false, true, 0, null, false );
			_alphaTexture = new TextureMap( _alpha, false, true, true, 0, null, false );
			
			_material = new MaterialStandard();
			_material.specularColor.set( 0, 0, 0 );
			_material.emissiveMap = _colorTexture;
			_material.diffuseColor.set( 0, 0, 0 );
			_material.opacityMap = _alphaTexture;
			
			_quad = MeshUtils.createPlane( 10, 10, 10, 10, _material );
			_quad.appendRotation( 90, Vector3D.X_AXIS );
			scene.addChild( _quad );
			
			_initialized = true;
		}
		
		// ======================================================================
		//	Event Handler Related
		// ----------------------------------------------------------------------
		override protected function onAnimate( t:Number, dt:Number ):void
		{
			if ( !_initialized )
				return;
			
			var ms:uint = getTimer();
			_mspf = ( _mspf * 15 + ms - _last ) / 16;
			_last = ms;
			var fps:Number = Math.round( 1000 / _mspf );
			var s:String;
			
			s = fps.toString();
			s = ( Math.round( t * 100 ) / 100 ).toString()
			
			updateText( s );
		}
		
		protected static var first:Boolean = true;
		protected function updateText( string:String ):void
		{
			_label.text = string;
			_label.setTextFormat( new TextFormat( "Arial", 72, 0xffffffff, true ) );
			var metrics:TextLineMetrics = _label.getLineMetrics( 0 );
			_label.alpha = .75;
			
			var w:Number = metrics.width + 4;
			var h:Number = metrics.height + 4;
			_label.width = w;
			_label.height = h;
			
			_color.fillRect( _rect, 0x0 );
			_color.draw( _sprite );
			
			_alpha.applyFilter( _color, _rect, POINT, ALPHA_TO_COLOR );
			_color.applyFilter( _color, _rect, POINT, REMOVE_ALPHA );
			
			_colorTexture.update( _color, false );
			_alphaTexture.update( _alpha, false );
		}
		
		override protected function keyboardEventHandler( event:KeyboardEvent ):void
		{
			switch( event.type )
			{
				case KeyboardEvent.KEY_DOWN:
				{
					switch( event.keyCode )
					{
						case 79:	// o
							SceneGraph.OIT_ENABLED = !SceneGraph.OIT_ENABLED;
							trace( "Stenciled Layer Peeling:", SceneGraph.OIT_ENABLED ? "enabled" : "disabled" );
							break;
					}
				}
				default:
					super.keyboardEventHandler( event );
			}
		}
	}
}