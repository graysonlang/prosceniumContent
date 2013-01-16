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
	 * <p> particle demo </p>
	 */
	public class TestParticleGalaxy extends BasicDemo
	{
		// ======================================================================
		//	Embedded Resources
		// ----------------------------------------------------------------------
		[ Embed( source="/../res/content/sprites1.png" ) ]
		protected static const SPRITES:Class;
		
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		protected const GALAXY_NUM_PARTICLES:uint					= 10000;
		protected const GALAXY_NUM_GALAXIES:uint					= 20;
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _galaxies:Vector.<SceneParticles>				= new Vector.<SceneParticles>();
		protected var _sphereSet:SceneNode;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function TestParticleGalaxy()
		{
			super();
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function enterFrameEventHandler( event:Event ):void
		{
			super.enterFrameEventHandler( event );
			
			scene.ambientColor.set( .4, .4, .4 );
		}
		
		override protected function initModels():void
		{
			// background and terrain
			instance.backgroundColor.set( .0, .0, .0 );
			instance.primarySettings.fogMode = RenderSettings.FOG_EXP;
			instance.primarySettings.fogDensity = 500;

			////////////////////////////////
			// create a sphere to test transparency
			_sphereSet = new SceneNode( "sphereSet" );
			scene.addChild( _sphereSet );
			
			var sphere1Material:MaterialStandard = new MaterialStandard( "sphere 1" );
			sphere1Material.diffuseColor.set( .75, .75, .75 );
			sphere1Material.specularColor.set( .5, .5, .5 );
			sphere1Material.specularExponent = 50;
			sphere1Material.opacity = 0.95;
			
			//			sphere1Material.diffuseMap = metal;
			var sphere1:SceneMesh = MeshUtils.createSphere( 6, 32, 32, sphere1Material, "Sphere 1" );
			sphere1.transform.appendScale( 4.0, 4.0, 4.0 );
			sphere1.transform.appendTranslation( 0, 0, 0 );
			_sphereSet.addChild( sphere1 );
			
			
			////////////////////////////////
			// create particles
			for (var i:uint=0; i<GALAXY_NUM_GALAXIES; i++)
			{
				var g:SceneParticles = new SceneParticles;
				scene.addChild( g );

				_galaxies.push( g );
				createGalaxy( g );

				g.appendTranslation(
					( Math.random() - .5 ) * 100,
					( Math.random() - .5 ) * 100,
					( Math.random() - .5 ) * 100
				);
				g.appendRotation( Math.random() * 360, Vector3D.X_AXIS );
				g.appendRotation( Math.random() * 360, Vector3D.Y_AXIS );
				g.appendRotation( Math.random() * 360, Vector3D.Z_AXIS );
			}
			
			// Since we have semi-transparent surfaces, we want to show them with up to two layers of transparency so
			// enable OIT
			SceneGraph.OIT_ENABLED = true; // Enable order independent transparency, false by default
			SceneGraph.OIT_LAYERS = 1; // Valid values are 1 and 2, it is 2 by default
			
			// Since we are adding particles to the scene, and have other transparent meshes we enable hybrid OIT so that
			// the particles and the transparent surfaces will be rendered correctly together.
			// Particles will be attenuated correctly by the first transparent surface.
			// If set to false only particles closer than the nearest opaque or transparent surface will be visible.
			SceneGraph.OIT_HYBRID_ENABLED = true; // Enable hybrid order independent transparency, false by default
		}	
		
		override protected function onAnimate( t:Number, dt:Number ):void
		{
			onAnimateGalaxy( t, dt );
		}

		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// particle group1
		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// va0      : r,y,angle
		// va1.xy   : uv					
		// va2.xy   : width/height	: size
		// va3.xy   : textureID		:
		
		// vc0      : [ 0, 1, .5, 0 ]
		// vc1      : worldTransform
		// vc5      : camera.modelTransform
		// vc9      : camera.cameraTransform = view*proj
		// vc13.xy  : subtexture width/height in clipspace
		
		// vc14.xy  : angle, 
		// vc15.xyz : x,y,z
		static protected var group1VS:String = 
			"mov vt0, va0\n" + "mov vt0, va1\n" + "mov vt0, va2\n" + "mov vt0, va3\n" +
			
			/////////////////////////////////////
			// animate
			"mov vt0,     va0\n" +				// vertex stream x,y,z have r,y,angle
			"div vt1.y,   vc14.x, va0.x\n" +	// w*t/r
			"add vt1.x,   va0.z,  vt1.y\n" +	// angle + w*t
			"cos vt0.x,   vt1.x\n" +
			"sin vt0.z,   vt1.x\n" +
			"mul vt0.xz,  vt0.xz,  va0.xx\n" +	// *r
			"add vt0.xyz, vt0.xyz, vc15.xyz\n" +
			/////////////////////////////////////
			
			// worldTransform
			"m44 vt0, vt0, vc1 \n" +

			// add offset to this vertex (corner)
			"mov vt1,    vc0.xxxx\n" +
			"sub vt1.x,  va1.x, vc0.z\n" +
			"sub vt1.y,  vc0.z, va1.y\n" + 		
			"mul vt1.xy, vt1.xy, va2.xy\n" +	// vt1.xy \in [-.5,.5]  <--  va1.xy = [0,1]
			
			"mul vt2.xyz, vc5.xyz, vt1.x\n" +	// row0 of camera modeltransform
			"mul vt3.xyz, vc6.xyz, vt1.y\n" +	// row1 of camera modeltransform
			"add vt0.xyz, vt0.xyz, vt2.xyz \n" +
			"add vt0.xyz, vt0.xyz, vt3.xyz \n" +
			
			// cameraTransform
			"m44 vt0, vt0, vc9 \n" +
			"mov op,  vt0 \n" +
			
			// compute texcoord by mapping va1 to the view port
			"mul vt0.xy, va1.xy, vc13.xy\n" +	// texcoord. * wh
			"mul vt1.xy, va3.xy, vc13.xy\n" +	// ij*wh
			"add vt0.xy, vt0.xy, vt1.xy\n" +	//
			"mov v0, vt0\n" +
			"";
		
		// fc0.xy = {0,1}
		static protected var group1FS:String = 
			"tex ft0,   v0.xy, fs0 <2d,linear,wrap> \n" +
			"sub ft1.x, ft0.w, fc0.z \n" +
			"kil ft1.x \n" +
			
			"mov ft0.xyz, fc1.xyz\n" +
			"mul ft0.xyz, ft0, ft0.w \n" + // premultiply alpha
			"mov oc,    ft0 \n" +
			"";

		protected var GROUP1_VCONST14:Vector.<Number> = new <Number>[ 0, 0, 0, 0 ];	// angle
		protected var GROUP1_VCONST15:Vector.<Number> = new <Number>[ 10, 10, 0, 0 ];	// x,y,z		// point
		protected var GROUP1_FCONST1:Vector.<Number>  = new <Number>[ .7, 0.7, 1.0, 1 ];
		protected function callbackBeforeDrawTriangle( settings:RenderSettings, style:uint = 0 ):void
		{
			instance.setProgramConstantsFromVector( Context3DProgramType.VERTEX,  14, GROUP1_VCONST14 );
			instance.setProgramConstantsFromVector( Context3DProgramType.VERTEX,  15, GROUP1_VCONST15 );
			instance.setProgramConstantsFromVector( Context3DProgramType.FRAGMENT, 1, GROUP1_FCONST1 );
		}

		protected function callbackAfterDrawTriangle( settings:RenderSettings, style:uint = 0 ):void
		{
		}
		
		protected function createGalaxy( g:SceneParticles ):void
		{
			var groupID:int;
			var textureMap:TextureMap = new TextureMap( new SPRITES().bitmapData );
			var pos1:Vector3D = new Vector3D( 0, 0, 0 );
			var size:Vector.<Number> = new <Number>[ 1, 1 ];
			var texSel:Vector.<uint> = new <uint>[ 12, 13, 14, 15 ];
			var i:uint;
			
			// create an active particle group
			groupID = g.createParticleSet();
			var pg:QuadSetParticles = g.sets[ groupID ];
			pg.shaderVertex = group1VS;
			pg.shaderFragment = group1FS;
			pg.callbackBeforeDrawTriangle = callbackBeforeDrawTriangle;
			pg.callbackAfterDrawTriangle  = callbackAfterDrawTriangle;
			pg.setTexture( textureMap, 4, 4 );
			
			pos1.setTo(0,0,0);
			
			pg.numParticles = GALAXY_NUM_PARTICLES;
			for ( i = 0; i < GALAXY_NUM_PARTICLES; i++ )
			{
				var r:Number = .5 + Math.random() * 15;
				var angle:Number = Math.random() * Math.PI * 2;
				var y:Number = ( Math.random() - .5 )*.5 * ( 5 / (.05 * r * r + 1 ) );
				pos1.setTo(	r,	y,	angle );
				size[ 0 ] = size[ 1 ] = .01 + .2 * Math.random();
				pg.setParticle( i, texSel[ i % texSel.length ], pos1, size ); 
			}
		}
		
		protected function onAnimateGalaxy( t:Number, dt:Number ):void
		{
			GROUP1_VCONST14[ 0 ] = t * 3;
		}
	}
}