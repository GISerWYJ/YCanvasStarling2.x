package sk.yoz.ycanvas.map.display
{
    import com.adobe.utils.AGALMiniAssembler;
    
    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DVertexBufferFormat;
    import flash.display3D.IndexBuffer3D;
    import flash.display3D.VertexBuffer3D;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import sk.yoz.math.FastCollisions;
    
    import starling.core.Starling;
    import starling.display.DisplayObject;
    import starling.errors.MissingContextError;
    import starling.events.Event;
    import starling.rendering.IndexData;
    import starling.rendering.Painter;
    import starling.rendering.Program;
    import starling.rendering.VertexData;
    import starling.utils.MatrixUtil;
    
    public class AbstractGraphics extends DisplayObject
    {
        /**
        * Vertex data are calculated.
        */
        protected var vertexData:starling.rendering.VertexData;
		protected var indexDataHelp:IndexData;
        private var vertexBuffer:VertexBuffer3D;
        
        /**
        * Index data.
        */
        protected var indexData:Vector.<uint>;
        private var indexBuffer:IndexBuffer3D;
        
        /**
        * Helper object to avoid temporary objects.
        */
        private var renderAlpha:Vector.<Number> = new <Number>[1.0, 1.0, 1.0, 1.0];
        
        public function AbstractGraphics()
        {
            var type:String = Event.CONTEXT3D_CREATE;
            Starling.current.addEventListener(type, onContextCreated);
            
            registerPrograms();
            
            super();
        }
        
        protected function get programName():String
        {
            throw new Error("Method not implemented");
        }
        
        /**
        * @inheritDoc
        */
        override public function getBounds(targetSpace:DisplayObject,
            resultRect:Rectangle=null):Rectangle
        {
            if(resultRect == null)
                resultRect = new Rectangle();
            
            var matrix:Matrix = getTransformationMatrix(targetSpace);
            var lt:Point = MatrixUtil.transformCoords(matrix,
                bounds.x, bounds.y);
            var rb:Point = MatrixUtil.transformCoords(matrix,
                bounds.x + bounds.width, bounds.y + bounds.height);
            resultRect.setTo(lt.x, lt.y, rb.x - lt.x, rb.y - lt.y);
            return resultRect;
        }
        
        /**
        * Disposes all resources and listeners.
        */
        public override function dispose():void
        {
            var type:String = Event.CONTEXT3D_CREATE;
            Starling.current.removeEventListener(type, onContextCreated);
            
            if(vertexBuffer)
                vertexBuffer.dispose();
            
            if(indexBuffer)
                indexBuffer.dispose();
            
            super.dispose();
        }
        
        /**
        * @inheritDoc
        */
        override public function render(painter:Painter):void
        {
			painter.finishMeshBatch(); //.finishQuadBatch();
			//painter//support.raiseDrawCount();
            
            renderAlpha[3] = alpha * this.alpha;
            
            var context:Context3D = Starling.context;
            if(context == null)
                throw new MissingContextError();
            
           // support.applyBlendMode(false);
			
            var preogram:Program = Starling.current.painter.getProgram(programName);
			preogram.activate(context);
           
            context.setVertexBufferAt(0, vertexBuffer, 
               0,
                Context3DVertexBufferFormat.FLOAT_2); 
            context.setVertexBufferAt(1, vertexBuffer, 2,
                Context3DVertexBufferFormat.FLOAT_4);
           // context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX,
           //     0, support.mvpMatrix3D, true);
            context.setProgramConstantsFromVector(Context3DProgramType.VERTEX,
                4, renderAlpha, 1);
            
            context.drawTriangles(indexBuffer, 0, indexData.length / 3);
            
            context.setVertexBufferAt(0, null);
            context.setVertexBufferAt(1, null);
        }
        
        protected function updateVertexBuffer():void
        {
            if(vertexBuffer)
                vertexBuffer.dispose();
            
            vertexBuffer = Starling.context.createVertexBuffer(
                vertexData.numVertices, 8);
            vertexBuffer.uploadFromByteArray(vertexData.rawData, 0,0,
                vertexData.numVertices);
        }
        
        protected function updateIndexBuffer():void
        {
            if(indexBuffer)
                indexBuffer.dispose();
            
            indexBuffer = Starling.context.createIndexBuffer(indexData.length);
            indexBuffer.uploadFromVector(indexData, 0, indexData.length);
        }
        
        /**
        * Evaluates hitTest at indices in a specific range.
        */
        protected function hitTestIndices(localPoint:Point, 
            indexMin:uint, indexMax:uint):Boolean
        {
            var i1:uint, i2:uint, i3:uint;
            var p1:Point = new Point;
            var p2:Point = new Point;
            var p3:Point = new Point;
            for(i1 = indexMin; i1 <= indexMax; i1 += 3)
            {
                i2 = i1 + 1;
                i3 = i2 + 1;
                
                vertexData.getPoint(indexData[i1], "position", p1);
                vertexData.getPoint(indexData[i2], "position", p2);
                vertexData.getPoint(indexData[i3], "position", p3);
				
                if(FastCollisions.pointInTriangle(localPoint.x, 
                    localPoint.y, p1.x, p1.y, p2.x, p2.y, p3.x, p3.y))
                    return true;
            }
            
            return false;
        }
        
        /**
        * Creates vertex and fragment programs from assembly.
        */
        private function registerPrograms():void
        {
            if(Starling.current.painter.hasProgram(programName))
                return;
            
            // va0 -> position
            // va1 -> color
            // vc0 -> mvpMatrix (4 vectors, vc0 - vc3)
            // vc4 -> alpha
            
            // 4x4 matrix transform to output space
            // multiply color with alpha and pass it to fragment shader
            var vertex:AGALMiniAssembler = new AGALMiniAssembler();
            vertex.assemble(Context3DProgramType.VERTEX, 
                "m44 op, va0, vc0\n" + 
                "mul v0, va1, vc4");
			
            
            // just forward incoming color
            var fragment:AGALMiniAssembler = new AGALMiniAssembler();
            fragment.assemble(Context3DProgramType.FRAGMENT, "mov oc, v0");
            
			var programm:Program = new Program(vertex.agalcode, fragment.agalcode);
            Starling.current.painter.registerProgram(programName, programm);
               // fragment.agalcode);
        }
        
        /**
        * The old context was lost, a new buffers and shaders are created.
        */
        protected function onContextCreated(event:Event):void
        {
            registerPrograms();
        }
    }
}