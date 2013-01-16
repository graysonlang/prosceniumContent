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
	import com.adobe.scenegraph.loaders.*;
	import com.adobe.scenegraph.loaders.collada.*;
	import com.adobe.scenegraph.loaders.obj.*;
	import com.adobe.utils.*;
	
	import flash.desktop.NativeApplication;
	import flash.display.*;
	import flash.events.*;
	import flash.filesystem.*;
	import flash.net.*;
	import flash.utils.*;
	
	// ===========================================================================
	//	Metadata Tag
	// ---------------------------------------------------------------------------
	[ SWF( width="290", height="0" ) ]
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class UtilityConvertModelsToBinary extends Sprite
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		protected static const MODELS:Vector.<String>				= new <String>[
			"content/Duck/Duck.obj",
			"content/PalmTrees/PalmTrees.obj",
			"content/Pool/Pool.obj",
			"content/Sailboat/Sailboat.obj"
		];
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _loaders:Vector.<ModelLoader>					= new <ModelLoader>[];
		protected var _files:Vector.<FileReference>					= new <FileReference>[];
		protected var _references:uint								= MODELS.length;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		
		public function UtilityConvertModelsToBinary()
		{
			for each ( var uri:String in MODELS )
			{
				var extension:String = URIUtils.getFileExtension( uri );
				
				var loader:ModelLoader;
				
				switch( extension.toUpperCase() )
				{
					case "DAE":	loader = new ColladaLoader( uri );	break;
					case "OBJ":	loader = new OBJLoader( uri );		break;
					
					default:
						continue;
				}
				
				_loaders.push( loader );
				loader.addEventListener( Event.COMPLETE, completeEventHandler, false, 0, true );
			}
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		protected function completeEventHandler( event:Event ):void
		{
			var loader:ModelLoader = event.target as ModelLoader;
			
			var inputFilename:String = URIUtils.getFilename( loader.model.filename );
			
			var index:int = inputFilename.lastIndexOf( "." );
			var filepart:String = inputFilename.slice( 0, index );
			
			var model:ModelData = loader.model;
			var bytes:ByteArray = model.toBinary();
			bytes.position = 0;

			var outputFilename:String = filepart + ".p3d";

			var file:File = new File( File.applicationDirectory.nativePath + "/output/" + outputFilename );
			
			var stream:FileStream = new FileStream();
			stream.open( file, FileMode.WRITE );
			stream.writeBytes( bytes );
			stream.close();
			
			trace( "[Save Complete]", outputFilename );
			
			if ( --_references == 0 )
				quit();
		}
		
		protected function quit():void
		{
			var timer:Timer = new Timer( 200, 1 );
			timer.addEventListener( TimerEvent.TIMER, function( event:TimerEvent ):void { NativeApplication.nativeApplication.exit(); } );
			timer.start(); 
		}
	}
}