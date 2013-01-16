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
	import com.adobe.display.*;
	import com.adobe.scenegraph.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	/**
	 * This sample presents code that creates a mesh from scratch.
	 * <p>
	 * Creates vertex and index data, builds a SceneMeshData, and then adds it to the scene.
	 * The object will be rendered when the scene is rendered.
	 * </p>
	 * addTo() will return a ModelManifest, inside which, the SceneMesh can be retrieved if necessary.
	 */
	public class Tutorial09_ProceduralGeometry extends BasicDemo
	{
		// ======================================================================
		//	Embedded Resources
		// ----------------------------------------------------------------------
		[ Embed( source="/../res/content/spectrum.png" ) ]
		protected static const SPECTRUM_BITMAP:Class;
		
		[ Embed( source="/../res/content/stone.png" ) ]
		protected static const STONE_BITMAP:Class;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function Tutorial09_ProceduralGeometry()
		{
			super();
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function initModels():void 
		{
			// --------------------------------------------------
			//	Populate vertex data
			// --------------------------------------------------
			var vertexData:VertexData = new VertexData();
			
			// positions
			vertexData.addSource( new Source( "positions", new ArrayElementFloat( new <Number>[ -5,-5,5, -5,-5,-5, 5,-5,-5, 5,-5,5, -5,5,5, 5,5,5, 5,5,-5, -5,5,-5 ] ), 3 ) );
			
			// texture coordinates
			vertexData.addSource( new Source( "texcoords", new ArrayElementFloat( new <Number>[ 1,0, 1,1, 0,1, 0,0 ] ), 2 ) );
			
			// surface normals
			vertexData.addSource( new Source( "normals", new ArrayElementFloat( new <Number>[ 0,-1,0, 0,1,0, 0,0,1, 1,0,0, 0,0,-1, -1,0,0 ] ), 3 ) );
			
			var inputs:Vector.<Input> = new <Input>[
				new Input( Input.SEMANTIC_POSITION, "positions", 0 ),
				new Input( Input.SEMANTIC_TEXCOORD, "texcoords", 1 ),
				new Input( Input.SEMANTIC_NORMAL, "normals", 2 )
			];

			
			// --------------------------------------------------
			//	Create materials
			// --------------------------------------------------
			var spectrumMaterial:MaterialStandard = new MaterialStandard();
			spectrumMaterial.diffuseMap = new TextureMap( new SPECTRUM_BITMAP().bitmapData );
			
			var stoneMaterial:MaterialStandard = new MaterialStandard();
			stoneMaterial.diffuseMap = new TextureMap( new STONE_BITMAP().bitmapData );
			
			
			// --------------------------------------------------
			//	Create cube from polylist
			// --------------------------------------------------
			var box1:SceneMesh = new SceneMesh( "Box from Polylist" );
			
			// 24 unique vertices
			var polylist:Vector.<uint> = new <uint>[ 0,0,0, 1,1,0, 2,2,0, 3,3,0, 4,3,1, 5,0,1, 6,1,1, 7,2,1, 0,3,2, 3,0,2, 5,1,2, 4,2,2, 3,3,3, 2,0,3, 6,1,3, 5,2,3, 2,3,4, 1,0,4, 7,1,4, 6,2,4, 1,3,5, 0,0,5, 4,1,5, 7,2,5 ];
			
			// 6 quads
			var polygonVertexCounts:Vector.<uint> = new <uint>[ 4, 4, 4, 4, 4, 4 ];
			box1.addElement( MeshElementTriangles.fromPolylist( vertexData, 6, inputs, polylist, polygonVertexCounts, name, null, spectrumMaterial ) );
			
			scene.addChild( box1 );
			
			
			// --------------------------------------------------
			//	Creating cube from 6 polygons
			// --------------------------------------------------
			var box2:SceneMesh = new SceneMesh( "Box from Polygons" );
				
			// 6 quads
			var polygons:Vector.<Vector.<uint>> = new <Vector.<uint>>[
				new <uint>[ 0,0,0, 1,1,0, 2,2,0, 3,3,0 ],
				new <uint>[ 4,3,1, 5,0,1, 6,1,1, 7,2,1 ],
				new <uint>[ 0,3,2, 3,0,2, 5,1,2, 4,2,2 ],
				new <uint>[ 3,3,3, 2,0,3, 6,1,3, 5,2,3 ],
				new <uint>[ 2,3,4, 1,0,4, 7,1,4, 6,2,4 ],
				new <uint>[ 1,3,5, 0,0,5, 4,1,5, 7,2,5 ]
			];
			box2.addElement( MeshElementTriangles.fromPolygons( vertexData, 6, inputs, polygons, name, null, stoneMaterial ) );
			
			box2.appendTranslation( 15, 0, 0 );
			
			scene.addChild( box2 );
			
			// --------------------------------------------------
			//	Trace the contents of the scene
			// --------------------------------------------------
			trace( scene );
		}
	}
}