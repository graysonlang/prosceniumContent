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
	import com.adobe.scenegraph.loaders.collada.*;
	import com.adobe.scenegraph.loaders.obj.*;
	
	import flash.display.*;
	import flash.display3D.*;
	import flash.display3D.textures.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	/**
	 * <p>This sample demonstrates the picking feature provided by the SceneGraph.pick method.</p>
	 * 
	 * <p>Proscenium provides a 6-axis bounding box. 
	 * For animated objects, bounding boxes will be updated automatically when necessary.
	 * For skinned characters, the bounding box is currently not fully supported, only the bounding box for the rest post will be calculated. This is a known issue.
	 * </p>
	 * 
	 * <p>Note, since an object's bounding box is used for picking, picking is not pixel accurate unless the model is a box shape.</p>
	 * 
	 * <p>To visualize the objects' bounding boxes, press the 'b' key.</p>
	 */
	public class TestPicking extends BasicDemo
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _loader:OBJLoader;
		protected var _models:Vector.<SceneMesh>;
		protected var _boxes:Vector.<SceneMesh>;
		
		protected var _redMaterialBinding:MaterialBinding;
		protected var _greenMaterialBinding:MaterialBinding;
		protected var _blueMaterialBinding:MaterialBinding;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function TestPicking()
		{
			super();
			stage.addEventListener( MouseEvent.MOUSE_DOWN, mouseDownHandler );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function enterFrameEventHandler( event:Event ):void
		{
			super.enterFrameEventHandler(event);
			
			advanceAnimation();
			
			scene.ambientColor.set( .4,.4,.4 );
		}
		
		override protected function initModels():void
		{
			_loader = new OBJLoader( "../res/content/teapot.obj" );
			_loader.addEventListener( Event.COMPLETE, loadComplete );
		}
		
		protected function loadComplete( event:Event ):void
		{
			var models:SceneNode = new SceneNode();
			var boxes:SceneNode = new SceneNode();
			scene.addChild( models );
			scene.addChild( boxes );
			
			var redMaterial:MaterialStandard = new MaterialStandard();
			redMaterial.diffuseColor.set( 1, 0, 0 );
			_redMaterialBinding = new MaterialBinding( redMaterial );
			
			var greenMaterial:MaterialStandard = new MaterialStandard();
			greenMaterial.diffuseColor.set( 0, 1, 0 );
			_greenMaterialBinding = new MaterialBinding( greenMaterial );
			
			var blueMaterial:MaterialStandard = new MaterialStandard();
			blueMaterial.diffuseColor.set( 0, 0, 1 );
			_blueMaterialBinding = new MaterialBinding( blueMaterial );
			
			// create models
			var manifest:ModelManifest = _loader.model.addTo( scene );
			var mtrl:MaterialStandard = manifest.meshes[0].getElementByIndex( 0 ).material as MaterialStandard;
			mtrl.ambientColor.set( mtrl.diffuseColor.r*0.6, mtrl.diffuseColor.g*0.6, mtrl.diffuseColor.b*0.6 );
			
			_models = new Vector.<SceneMesh>;
			_models.push( manifest.meshes[ 0 ] );
			_models[ 0 ].name = "model0";
			
			var i:int;
			
			var ax:Vector3D = new Vector3D;
			for ( i=1; i<16; i++ )
			{
				var model:SceneMesh = manifest.meshes[0].instance();
				_models.push( model );
			}
			
			for ( i=0; i<_models.length; i++ )
			{
				_models[i].name = "model" + i;
				_models[i].userData = 0;		// selection status
				
				_models[i].setPosition( i*10 -50, 0, 0);
				ax.setTo( 0, i, -i);
				ax.normalize();
				_models[i].appendRotation( i*10, ax );
				
				models.addChild( _models[i] );
			}
			
			// create boxes
			_boxes = new Vector.<SceneMesh>;
			mtrl = new MaterialStandard;
			mtrl.diffuseColor.set( 1, 1, 0 );
			mtrl.name = "boxMaterial";
			var box:SceneMesh = MeshUtils.createBox( 3, 4, 20, mtrl, "box" );
			_boxes.push( box );
			for ( i = 1; i<4; i++ ) 
			{
				var boxi:SceneMesh = box.instance(); 
				_boxes.push( boxi );
			}
			
			for ( i = 0; i < _boxes.length; i++ )
			{
				_boxes[i].name = "box" + i;
				_boxes[i].userData = 0;		// selection status
				
				_boxes[i].setPosition( i*5 + 5, 5, 10);
				ax.setTo( 0, 1/Math.sqrt(2), 1/Math.sqrt(2));
				_boxes[i].appendRotation( i*40, ax );
				
				boxes.addChild( _boxes[i] );
			}
		}	
		
		protected function advanceAnimation():void
		{
			if ( !_models )
				return;
			
			_boxes[1].appendRotation( .1, Vector3D.X_AXIS, _boxes[1].position );
			_boxes[2].appendRotation( .1, Vector3D.Y_AXIS, _boxes[2].position );
			_boxes[3].appendRotation( .1, Vector3D.Z_AXIS, _boxes[3].position );
		}
		
		protected function mouseDownHandler( event:MouseEvent ):void
		{
			var x:Number =  (event.stageX - width *.5) / width *2;
			var y:Number = -(event.stageY - height*.5) / height*2;
			
			var node:SceneNode = scene.pick( x, y );
			
			if ( node )
			{
				var obj:SceneMesh = node as SceneMesh;
				var key:* = obj.getElementByIndex( 0 );
				
				if ( !obj.materialBindings )
					obj.materialBindings = new MaterialBindingMap();
				
				if ( obj.userData == 0 )
					obj.materialBindings.setBindingForMeshElement( key, _redMaterialBinding );
				else if ( obj.userData == 1 )
					obj.materialBindings.setBindingForMeshElement( key, _greenMaterialBinding );
				else if ( obj.userData == 2 )
					obj.materialBindings.setBindingForMeshElement( key, _blueMaterialBinding );
				else
					obj.materialBindings.setBindingForMeshElement( key, null );
				
				obj.userData = int(obj.userData) + 1;
				if ( int(obj.userData) > 3 )
					obj.userData = 0;
			}
			
			trace( "node = " + (node ? node.name : "null") );
		}
	}
}