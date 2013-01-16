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
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class Tutorial08_LoadedAnimation extends BasicScene
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var loader:ColladaLoader;
		public var animations:Vector.<AnimationController>;
		public var initialized:Boolean;
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function initLights():void
		{
			var light:SceneLight = new SceneLight();
			light.setPosition( 3, 4, 5 );
			scene.addChild( light );
		}
		
		override protected function resetCamera():void
		{
			scene.activeCamera.identity();
			scene.activeCamera.appendTranslation( 0, 0, 10 );
			scene.activeCamera.appendRotation( -15, Vector3D.X_AXIS );
		}
		
		override protected function initModels():void
		{
			loader = new ColladaLoader( "../res/content/AnimatedBones.dae" );
			loader.addEventListener( Event.COMPLETE, onLoad );
		}
		
		public function onLoad( event:Event ):void
		{
			var manifest:ModelManifest = loader.model.addTo( scene );
			animations = loader.model.animations;
			for each ( var anim:AnimationController in animations ) {
				anim.bind( scene );
			}
			
			initialized = true;
		}
		
		override protected function onAnimate( t:Number, dt:Number ):void
		{
			if ( !initialized ) return;
			for each ( var anim:AnimationController in animations )
			{
				anim.time = ( t % anim.length ) + anim.start;
			}
		}
	}
}