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
	public class TestParticleFires extends BasicDemo
	{
		// ======================================================================
		//	Embedded Resources
		// ----------------------------------------------------------------------
		[ Embed( source="/../res/content/sprites1.png" ) ]
		public static const SPRITES:Class;
		
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const FIRE_NUM_PARTICLES:uint					= 1000;
		public static const EXPLOSION_NUM_PARTICLES:uint			= 500;
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _fire1:SceneParticleFire						= new SceneParticleFire();
		protected var _fire2:SceneParticleFire						= new SceneParticleFire();
		protected var _explosion:Vector.<SceneParticleExplosion>	= new Vector.<SceneParticleExplosion>();
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function TestParticleFires()
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
			SceneGraph.OIT_ENABLED = false;			// No transparent surfaces presents
			SceneGraph.OIT_HYBRID_ENABLED = false;	// We leave false, since there are no transparent surfaces present

			// background and terrain
			instance.backgroundColor.set( .0,.0,.0);
			instance.primarySettings.fogMode = RenderSettings.FOG_EXP;
			instance.primarySettings.fogDensity = 500;
			
			var material:MaterialStandard = new MaterialStandard();
			material.diffuseColor.set( .5, .5, .5 );
			material.specularColor.set( .0, .0, .0 );
			material.specularExponent = 30;
			
			var plane:SceneMesh = MeshUtils.createFractalTerrain( 100, 100, 800, 800, 40, 0.35, 1, 1, material, "terrain" );
			plane.transform.appendTranslation( 0, -30, 0 );
			scene.addChild( plane );
			
			////////////////////////////////////////////////////////////////////////////////////////////////
			// create particles
			scene.addChild( _fire1 );
			_fire1.createParticleGroup();
			_fire1.setPosition( 10, -20, -50);
			_fire1.color0[0] = .2;
			_fire1.color0[1] = .2;
			_fire1.color0[2] = 0;
			
			scene.addChild( _fire2 );
			_fire2.createParticleGroup();
			_fire2.setPosition( 10, -20, -50);
			_fire2.color0[0] = .6;
			_fire2.color0[1] = 0;
			_fire2.color0[2] = 0;
			
			for (var i:int=0; i<40; i++) {
				var e:SceneParticleExplosion = new SceneParticleExplosion;
				e.createParticleGroup();
				e.setPosition(	 200 + 500*(Math.random()-0.5),
								 100 +  50*(Math.random()-0.5),
								-200 + 200*(Math.random()-0.5));
				e.color[0] = Math.random();
				e.color[1] = Math.random();
				e.color[2] = Math.random();
				e.velocity = 10 + Math.random()*20;
				scene.addChild( e );
				_explosion.push( e );
			}
			////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			// motion blurring
			instance.createPostProcessingColorBuffer();
			var X:RenderTexture = instance.colorBuffer;
			var Y:RenderTexture = new RenderTexture( instance.width, instance.height, "Y" ); 
			
			var re:RenderGraphNodePPElement = new RenderGraphNodePPElement( X, Y,  RenderGraphNodePPElement.IIR1, "Y = IIR1" );
			re.iirCoefIn  = 0.05;
			re.iirCoefOut = 0.95;
			Y.renderGraphNode = re; 
			Y.renderGraphNode.addStaticPrerequisite( X.renderGraphNode );
			Y.renderGraphNode.addStaticPrerequisite( Y.renderGraphNode );		// self cycle
			
			var YToPrimry:RenderGraphNode = new RenderGraphNodePPElement( Y, null,  RenderGraphNodePPElement.COPY, "ToPrimary" );
			YToPrimry.addStaticPrerequisite( Y.renderGraphNode );
			
			instance.renderGraphRoot.clearAllPrerequisite( );
			instance.renderGraphRoot.addStaticPrerequisite(YToPrimry);
			////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		}	
		
		private var windX:Number = 0;
		private var windY:Number = 0;
		private var windZ:Number = 0;
		
		override protected function onAnimate( t:Number, dt:Number ):void
		{
			windX += 10*(Math.random()-0.5) * dt;
			windY +=    (Math.random()-0.5) * dt;
			windZ += 10*(Math.random()-0.5) * dt;
			
			if (Math.random()<0.01*dt)
			{
				windX = windY = windZ = 0;
			}
			
			_fire1.onAnimateParticleGroup( t, dt, windX, windY, windZ );
			_fire2.onAnimateParticleGroup( t, dt, windX, windY, windZ );
			
			for each (var e:SceneParticleExplosion in _explosion )
			{
				if (e.density > 0.1) {
					e.onAnimateParticleGroup( t, dt );
				} else {
					e.t0 = t;
					e.density = 1;
					e.setPosition(	 200 + 500*(Math.random()-0.5),
									 100 +  50*(Math.random()-0.5),
									-200 + 200*(Math.random()-0.5));
					e.color[0] = Math.random();
					e.color[1] = Math.random();
					e.color[2] = Math.random();
					e.velocity = 10 + Math.random()*20;
				}
			}
		}
	}
}

// ================================================================================
//	Helper Classes
// ================================================================================
import com.adobe.scenegraph.*;

import flash.display.*;
import flash.display3D.*;
import flash.geom.*;
{
	class SceneParticleFire extends SceneParticles
	{
		public var color0:Vector.<Number> = new Vector.<Number>( 4, true );
		public var color1:Vector.<Number> = new <Number>[0.02,0.02,0.02,1.];
		protected var _particle_lifetime:Number = 5;

		////////////////////////////////////////////////////////////////////////////////////
		// particle group: fire
		////////////////////////////////////////////////////////////////////////////////////
		// va0      : xyz1 of center position
		// va1.xy   : uv					
		// va2.xy   : width/height	: size
		// va3.xy   : textureID		:
		
		// vc0      : [ 0, 1, .5, 0 ]
		// vc1      : worldTransform
		// vc5      : camera.modelTransform
		// vc9      : camera.cameraTransform = view*proj
		// vc13.xy  : subtexture width/height in clipspace
		
		// vc14.xy  : angle
		// vc15.xyz : x,y,z
		static protected var group1VS:String =
			"mov vt0, va0\n" + "mov vt0, va1\n" + "mov vt0, va2\n" + "mov vt0, va3\n" +
			
			/////////////////////////////////////////////////////////////////////
			// animate
			"mov vt0,     va0\n" +				// vertex stream x,y,z
			/////////////////////////////////////////////////////////////////////
			
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
			"mov v0,     vt0\n" +

			// color is in vc16.xyz.
			// gray  is in vc17.xyz. Make particle gray as the particle time goes.
			"mov vt0.w,   va4.x\n" +
			"mov vt0.xyz, vc16.xyz\n" +
			"mul vt0.xyz, vt0.xyz,  vt0.www\n" +		// color * alpha
			"sub vt1.w,   vc0.y,    va4.x\n"   +		// 1-alpha
			"mul vt1.xyz, vc17.xyz, vt1.www\n" +		// gray * (1-alpha)
			"add vt0.xyz, vt0.xyz,  vt1.xyz\n" +

			"mov v1,      vt0\n" +
			"";
		
		// fc0.xy = {0,1}
		static protected var group1FS:String = 
			"tex ft0,   v0.xy, fs0 <2d,linear,wrap> \n" +
			"mul ft0.w, ft0.w, v1.x\n" +
			"mov ft0.xyz, v1.xyz\n" +
			
			"mul ft0.xyz, ft0, ft0.w \n" + // premultiply alpha
			"mov oc,    ft0 \n" +
			"";
		
		private var fireSetID:int;
		
		public function createParticleGroup():void
		{
			var textureMap:TextureMap = new TextureMap( new TestParticleFires.SPRITES().bitmapData );
			var pos1:Vector3D = new Vector3D(0,0,0);
			var size:Vector.<Number> = new Vector.<Number>; size.push(1,1);
			var texSel:Vector.<uint> = new <uint>[12, 13, 14, 15];
			var i:uint;
			
			// create an active particle group
			fireSetID = createParticleSet(1);
			var ps:QuadSetParticles = sets[fireSetID];
			ps.shaderVertex   = group1VS;
			ps.shaderFragment = group1FS;
			ps.callbackBeforeDrawTriangle = callbackBeforeDrawTriangle;
			ps.callbackAfterDrawTriangle  = callbackAfterDrawTriangle;
			ps.setTexture( textureMap, 4, 4 );
			
			pos1.setTo(0,0,0);
			size[0] = size[1] = 1;
			
			ps.numParticles = TestParticleFires.FIRE_NUM_PARTICLES;
			
			// prepare velocity state: this is to be modified by CPU.
			ps.cpuStateStride = 4;
			ps.cpuState.length = TestParticleFires.FIRE_NUM_PARTICLES * ps.cpuStateStride;
			
			for (i = 0; i<TestParticleFires.FIRE_NUM_PARTICLES; i++) {
				pos1.setTo(	(Math.random()-.5)*2,
							(Math.random()-.5)*1,
							(Math.random()-.5)*2);
				ps.setParticle( i, texSel[i%texSel.length], pos1, size );
				ps.cpuState[i*ps.cpuStateStride  ] = Math.random()*_particle_lifetime;	// time
				ps.cpuState[i*ps.cpuStateStride+1] = 0;	// vx
				ps.cpuState[i*ps.cpuStateStride+2] = 0;	// vy
				ps.cpuState[i*ps.cpuStateStride+3] = 0;	// vz
			}
		}
		
		protected function callbackBeforeDrawTriangle( settings:RenderSettings, style:uint = 0 ):void
		{
			var ps:QuadSetParticles = sets[fireSetID];
			settings.instance.setVertexBufferAt( 4, ps.verticesDynamic, 9, Context3DVertexBufferFormat.FLOAT_1 ); // textureI,J
			settings.instance.setProgramConstantsFromVector( Context3DProgramType.VERTEX, 16, color0 );
			settings.instance.setProgramConstantsFromVector( Context3DProgramType.VERTEX, 17, color1 );
		}
		
		protected function callbackAfterDrawTriangle( settings:RenderSettings, style:uint = 0 ):void
		{
			settings.instance.setVertexBufferAt( 4, null ); 
		}
		
		public function onAnimateParticleGroup( t:Number, dt:Number, windX:Number, windY:Number, windZ:Number ):void
		{
			// animate group 0
			var ps:QuadSetParticles = sets[fireSetID];
			var n:uint  = ps.numParticles;
			var s:uint  = ps.vertexBufferStride;
			var s0:uint = ps.vertexBufferStrideMin;
			var vs:uint = ps.cpuStateStride;
			
			for (var i:uint=0; i<n; i++)
			{
				ps.cpuState[i*ps.cpuStateStride  ] += dt;	// time
				ps.cpuState[i*ps.cpuStateStride+1] += 10*(Math.random()-.5)*dt + windX*dt;
				ps.cpuState[i*ps.cpuStateStride+2] +=  5*(Math.random()   )*dt + windY*dt;
				ps.cpuState[i*ps.cpuStateStride+3] += 10*(Math.random()-.5)*dt + windZ*dt;
				
				var ix:uint = i*s*4;
				var x:Number = ps.vertexBuffer[ix  ] + ps.cpuState[i*ps.cpuStateStride+1] * dt; 
				var y:Number = ps.vertexBuffer[ix+1] + ps.cpuState[i*ps.cpuStateStride+2] * dt; 
				var z:Number = ps.vertexBuffer[ix+2] + ps.cpuState[i*ps.cpuStateStride+3] * dt;
				
				if(ps.cpuState[i*ps.cpuStateStride  ] > _particle_lifetime) {
					x = (Math.random()-.5)*2;
					y = (Math.random()-.5)*1;
					z = (Math.random()-.5)*2;
					ps.cpuState[i*ps.cpuStateStride  ] = 0;
					ps.cpuState[i*ps.cpuStateStride+1] = 0;	// vx
					ps.cpuState[i*ps.cpuStateStride+2] = 0;	// vy
					ps.cpuState[i*ps.cpuStateStride+3] = 0;	// vz
				}
				
				var time_fraction:Number = ps.cpuState[i*ps.cpuStateStride  ] / _particle_lifetime;
				var alpha:Number = (1 - time_fraction);
				ps.vertexBuffer[ix  ] = x;
				ps.vertexBuffer[ix+1] = y;
				ps.vertexBuffer[ix+2] = z;
				ps.vertexBuffer[ix+s0] = alpha;
				ix += s; 
				
				ps.vertexBuffer[ix  ] = x;
				ps.vertexBuffer[ix+1] = y;
				ps.vertexBuffer[ix+2] = z;
				ps.vertexBuffer[ix+s0] = alpha;
				ix += s; 
				
				ps.vertexBuffer[ix  ] = x;
				ps.vertexBuffer[ix+1] = y;
				ps.vertexBuffer[ix+2] = z;
				ps.vertexBuffer[ix+s0] = alpha;
				ix += s; 
				
				ps.vertexBuffer[ix  ] = x;
				ps.vertexBuffer[ix+1] = y;
				ps.vertexBuffer[ix+2] = z;
				ps.vertexBuffer[ix+s0] = alpha;
				ix += s; 
			}
			ps.uploadVectexBuffer = true;
		}
	}

	class SceneParticleExplosion extends SceneParticles
	{
		public var t0:Number = 0;
		public var velocity:Number  = 10;
		public var density:Number   = 1;
		public var color:Vector.<Number>  = new <Number>[ .9, 0.2, 0.1, 1 ];
		
		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// particle group: explosion
		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// va0      : velocity
		// va1.xy   : uv					
		// va2.xy   : width/height	: size
		// va3.xy   : textureID		:
		
		// vc0      : [ 0, 1, .5, 0 ]
		// vc1      : worldTransform
		// vc5      : camera.modelTransform
		// vc9      : camera.cameraTransform = view*proj
		// vc13.xy  : subtexture width/height in clipspace
		
		// vc14.x   : time 
		// vc15.xyz : x,y,z
		static protected var group1VS:String = 
			"mov vt0, va0\n" + "mov vt0, va1\n" + "mov vt0, va2\n" + "mov vt0, va3\n" +
			
			/////////////////////////////////////
			// animate
			"mov vt0,     vc15\n" +					// center
			"mul vt1.xyz, va0.xyz, vc14.xxx\n" +
			"add vt0.xyz, vt0.xyz, vt1.xyz\n"  +
			"sub vt0.y,   vt0.y,   vc14.y\n" +
			
			"mov v1, vc14.zzzz\n" + 
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
			"mul ft0.w, ft0.w, v1.x\n" +
			"sub ft1.x, ft0.w, fc0.z \n" +
			"kil ft1.x \n" +
			
			"mov ft0.xyz, fc1.xyz\n" +
			"mul ft0.xyz, ft0, ft0.w \n" + // premultiply alpha
			"mov oc,    ft0 \n" +
			"";
		
		protected var VCONST14:Vector.<Number> = new <Number>[ 0, 0, 0, 0 ];		// v-radial, v-fall, transparency
		protected var VCONST15:Vector.<Number> = new <Number>[ 0, 10, 0, 1 ];	// x,y,z		// point
		
		protected function callbackBeforeDrawTriangle( settings:RenderSettings, style:uint = 0 ):void
		{
			settings.instance.setProgramConstantsFromVector( Context3DProgramType.VERTEX,  14, VCONST14 );
			settings.instance.setProgramConstantsFromVector( Context3DProgramType.VERTEX,  15, VCONST15 );
			settings.instance.setProgramConstantsFromVector( Context3DProgramType.FRAGMENT, 1, color );
		}
		
		protected function callbackAfterDrawTriangle( settings:RenderSettings, style:uint = 0 ):void
		{
		}
		
		public function createParticleGroup():void
		{
			var textureMap:TextureMap = new TextureMap( new TestParticleFires.SPRITES().bitmapData );
			var vel:Vector3D = new Vector3D(0,0,0);
			var size:Vector.<Number> = new Vector.<Number>; size.push(1,1);
			var texSel:Vector.<uint> = new <uint>[12, 13, 14, 15];
			var i:uint;
			
			// create an active particle group
			var setID:int = createParticleSet();
			var ps:QuadSetParticles = sets[setID];
			ps.shaderVertex = group1VS;
			ps.shaderFragment = group1FS;
			ps.callbackBeforeDrawTriangle = callbackBeforeDrawTriangle;
			ps.callbackAfterDrawTriangle  = callbackAfterDrawTriangle;
			ps.setTexture( textureMap, 4, 4 );
			
			vel.setTo(0,0,0);
			
			ps.numParticles = TestParticleFires.EXPLOSION_NUM_PARTICLES;
			for (i = 0; i<TestParticleFires.EXPLOSION_NUM_PARTICLES; i++)
			{
				var x:Number, y:Number, z:Number, r:Number;
				do {
					x = (Math.random()-.5)*2;
					y = (Math.random()-.5)*2;
					z = (Math.random()-.5)*2;
					r = x*x + y*y + z*z;
				} while (r > 1);
				
				vel.setTo(	x,	y,	z );
				size[0] = size[1] = 2;
				ps.setParticle( i, texSel[i%texSel.length], vel, size ); 
			}
		}

		public function onAnimateParticleGroup( t:Number, dt:Number ):void
		{
			t = t - t0; 
			VCONST14[0] = velocity*t;
			VCONST14[1] = t*t*5;
			VCONST14[2] = density = 1 / (velocity/20*t*t + .1);
		}
	}
}