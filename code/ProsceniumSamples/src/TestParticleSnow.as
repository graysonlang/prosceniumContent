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
	public class TestParticleSnow extends BasicDemo
	{
		// ======================================================================
		//	Embedded Resources
		// ----------------------------------------------------------------------
		[ Embed( source="/../res/content/sprites1.png" ) ]
		protected static const SPRITES:Class;
		
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		protected const GPU_SNOW_NUM_PARTICLES:uint					= 10000;
		protected const CPU_SNOW_NUM_PARTICLES:uint					= 1000;
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _particleSnow:SceneParticles					= new SceneParticles();
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function TestParticleSnow()
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
			instance.backgroundColor.set( .8, .8, 1 );
			instance.primarySettings.fogMode = RenderSettings.FOG_EXP;
			instance.primarySettings.fogDensity = 500;
			
			var material:MaterialStandard = new MaterialStandard();
			material.diffuseColor.set( .5, .45, .4 );
			material.specularColor.set( 0, 0, 0 );
			material.specularExponent = 50;

			var plane:SceneMesh = MeshUtils.createFractalTerrain( 100, 100, 300, 300, 10, 0.35, 1, 1, material, "terrain" );
			plane.transform.appendTranslation( 0, -30, 0 );
			scene.addChild( plane );
			
			////////////////////////////////
			// create particles
			scene.addChild( _particleSnow );
			createCPUSnow();
			for ( var i:uint = 0; i < 30; i++ )
				createGPUSnow();
		}	
		
		override protected function onAnimate( t:Number, dt:Number ):void
		{
			onAnimateGPUSnow( t, dt );
			onAnimateCPUSnow( t, dt );
		}
		
		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// cpu-snow
		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		private var _cpuSnowID:uint = 0;
		protected function createCPUSnow():void
		{
			var textureMap:TextureMap = new TextureMap( new SPRITES().bitmapData );
			var pos1:Vector3D = new Vector3D();
			var size:Vector.<Number> = new <Number>[ 1, 1 ];
			var texSel:Vector.<uint> = new <uint>[ 0, 2, 3, 4, 5, 6, 7, 12, 13 ];
			var i:uint;
			
			// create an active particle group
			_cpuSnowID = _particleSnow.createParticleSet();
			var ps:QuadSetParticles = _particleSnow.sets[ _cpuSnowID ];
			ps.callbackBeforeDrawTriangle = GPUSnowCallbackBeforeDrawTriangle;
			ps.callbackAfterDrawTriangle  = GPUSnowCallbackAfterDrawTriangle;
			ps.setTexture( textureMap, 4, 4 );
			
			pos1.setTo( 0, 0, 0 );
			size[ 0 ] = size[ 1 ] = 1;
			ps.cpuStateStride = 2;
			ps.cpuState.length = CPU_SNOW_NUM_PARTICLES * ps.cpuStateStride;
			ps.numParticles = CPU_SNOW_NUM_PARTICLES;
			for ( i = 0; i < CPU_SNOW_NUM_PARTICLES; i++ )
			{
				pos1.setTo(
					( Math.random() - .5 ) * 200,
					Math.random() * 100,
					( Math.random() - .5 ) * 200
				);
				ps.setParticle( i, texSel[ i % texSel.length ], pos1, size );
				ps.cpuState[ i * 2 ] = 0;
				ps.cpuState[ i * 2 + 1 ] = 0;
			}
		}

		protected function CPUSnowCallbackBeforeDrawTriangle( settings:RenderSettings, style:uint = 0 ):void
		{
			instance.setBlendFactors( Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE );
			instance.setBlendFactors( Context3DBlendFactor.DESTINATION_ALPHA, Context3DBlendFactor.ONE );	// Assumes source alpha is opacity
		}
		
		protected function CPUSnowCallbackAfterDrawTriangle( settings:RenderSettings, style:uint = 0 ):void
		{
			instance.setBlendFactors( Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO );
		}
		
		protected function onAnimateCPUSnow( t:Number, dt:Number ):void
		{
			// animate snow
			var pg:QuadSetParticles = _particleSnow.sets[_cpuSnowID];
			var n:uint  = pg.numParticles;
			var s:uint  = pg.vertexBufferStride;
			var cs:uint = pg.cpuStateStride;
			
			for (var i:uint=0; i<n; i++)
			{
				pg.cpuState[i*cs  ] += (Math.random()-.5)*dt;
				pg.cpuState[i*cs+1] += (Math.random()-.5)*dt;

				var ix:uint = i*s*4;
				var x:Number = pg.vertexBuffer[ix  ] -  2*dt + 10*pg.cpuState[i*cs  ]*dt; 
				var y:Number = pg.vertexBuffer[ix+1] - 10*dt; 
				var z:Number = pg.vertexBuffer[ix+2]         + 10*pg.cpuState[i*cs+1]*dt;
				if(y < -30) {
					x = (Math.random()-.5)*200;
					y =  Math.random()    *100;
					z = (Math.random()-.5)*200;
					pg.cpuState[i*cs  ] = (Math.random()-.5);
					pg.cpuState[i*cs+1] = (Math.random()-.5);
				}
				pg.vertexBuffer[ix  ] = x; 	pg.vertexBuffer[ix+1] = y;	pg.vertexBuffer[ix+2] = z;		ix += s; 
				pg.vertexBuffer[ix  ] = x; 	pg.vertexBuffer[ix+1] = y;	pg.vertexBuffer[ix+2] = z;		ix += s; 
				pg.vertexBuffer[ix  ] = x; 	pg.vertexBuffer[ix+1] = y;	pg.vertexBuffer[ix+2] = z;		ix += s; 
				pg.vertexBuffer[ix  ] = x; 	pg.vertexBuffer[ix+1] = y;	pg.vertexBuffer[ix+2] = z;		ix += s; 
			}
			pg.uploadVectexBuffer = true;
		}

		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// gpu-snow
		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// va0      : xyz1 of center position
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
			"mov vt0,     va0\n" +				// vertex stream x,y,z
			"sub vt0.y,   vt0.y,  vc14.x\n" +
			"div vt0.y,   vt0.y,  vc14.y\n" + 
			"frc vt0.y,   vt0.y\n" + 
			"mul vt0.y,   vt0.y,  vc14.y\n" + 
			"add vt0.y,   vt0.y,  vc14.z\n" + 
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
		
		protected var GPUSNOW_VCONST14:Vector.<Number> = new <Number>[ 0, 0, 0, 0 ];	// angle
		protected var GPUSNOW_VCONST15:Vector.<Number> = new <Number>[ 10, 10, 0, 0 ];	// x,y,z		// point
		protected var GPUSNOW_FCONST1:Vector.<Number>  = new <Number>[ .9, 1.0, 0.9, 1 ];
		
		protected function GPUSnowCallbackBeforeDrawTriangle( settings:RenderSettings, style:uint = 0 ):void
		{
			instance.setProgramConstantsFromVector( Context3DProgramType.VERTEX,  14, GPUSNOW_VCONST14 );
			instance.setProgramConstantsFromVector( Context3DProgramType.VERTEX,  15, GPUSNOW_VCONST15 );
			instance.setProgramConstantsFromVector( Context3DProgramType.FRAGMENT, 1, GPUSNOW_FCONST1 );

			instance.setBlendFactors( Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE );
			instance.setBlendFactors( Context3DBlendFactor.DESTINATION_ALPHA, Context3DBlendFactor.ONE );	// Assumes source alpha is opacity
		}
		
		protected function GPUSnowCallbackAfterDrawTriangle( settings:RenderSettings, style:uint = 0 ):void
		{
			instance.setBlendFactors( Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO );
		}
		
		protected function createGPUSnow():void
		{
			var textureMap:TextureMap = new TextureMap( new SPRITES().bitmapData );
			var pos1:Vector3D = new Vector3D();
			var size:Vector.<Number> = new <Number>[ 1, 1 ];
			var texSel:Vector.<uint> = new <uint>[ 0, 2, 3, 4, 5, 6, 7, 12, 13 ];
			var i:uint;
			
			// create an active particle group
			var setID:int = _particleSnow.createParticleSet();
			var ps:QuadSetParticles = _particleSnow.sets[ setID ];
			ps.shaderVertex = group1VS;
			ps.shaderFragment = group1FS;
			ps.callbackBeforeDrawTriangle = GPUSnowCallbackBeforeDrawTriangle;
			ps.callbackAfterDrawTriangle  = GPUSnowCallbackAfterDrawTriangle;
			ps.setTexture( textureMap, 4, 4 );
			
			pos1.setTo(0,0,0);
			
			ps.numParticles = GPU_SNOW_NUM_PARTICLES;
			for ( i = 0; i < GPU_SNOW_NUM_PARTICLES; i++ )
			{
				var x:Number = ( Math.random() - .5 ) * 200;
				var y:Number = Math.random() * 130;
				var z:Number = ( Math.random() - .5 ) * 200;
				pos1.setTo(	x,	y,	z );
				size[ 0 ] = size[ 1 ] = .2;
				ps.setParticle( i, texSel[i%texSel.length], pos1, size ); 
			}
		}
		
		protected function onAnimateGPUSnow( t:Number, dt:Number ):void
		{
			GPUSNOW_VCONST14[ 0 ] = t * 3;
			GPUSNOW_VCONST14[ 1 ] = 130;
			GPUSNOW_VCONST14[ 2 ] = -30;
			//GPUSNOW_VCONST15[ 0 ] = 3 * Math.sin( 3 * t );
			//GPUSNOW_VCONST15[ 1 ] = 1 * Math.sin( .5 * t );
			//GPUSNOW_VCONST15[ 2 ] = 2 * Math.cos( 2 * t );
		}
	}
}