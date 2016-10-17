package sk.yoz.ycanvas.map.managers
{
    import com.greensock.TweenNano;
    
    import flash.geom.Point;
    
    import sk.yoz.ycanvas.map.YCanvasMap;
    import sk.yoz.ycanvas.map.events.CanvasEvent;
    import sk.yoz.ycanvas.map.valueObjects.Limit;
    import sk.yoz.ycanvas.map.valueObjects.Transformation;
    import sk.yoz.ycanvas.utils.TransformationUtils;
    
    import starling.display.DisplayObject;

    /**
    * An abstract implementation of transformation manager.
    */
    public class AbstractTransformationManager
    {
        public static const PI2:Number = Math.PI * 2;
        
        protected var controller:YCanvasMap;
        protected var transitionDuration:Number = .25;
        protected var transformation:Transformation = new Transformation;
        protected var transformationTarget:Transformation = new Transformation;
        
        private var limit:Limit;
        private var tween:TweenNano;
        
        private var _allowMove:Boolean;
        private var _allowZoom:Boolean;
        private var _allowRotate:Boolean;
        private var _allowInteractions:Boolean;
        private var _transforming:Boolean;
        
        public function AbstractTransformationManager(controller:YCanvasMap, 
            limit:Limit, transitionDuration:Number=.5)
        {
            this.controller = controller;
            this.limit = limit;
            this.transitionDuration = transitionDuration;
            
            allowMove = true;
            allowZoom = true;
            allowRotate = true;
            
            updateTransformation();
            
            controller.addEventListener(CanvasEvent.TRANSFORMATION_FINISHED, onCanvasTransformationFinished);
        }
        
        public function dispose():void
        {
            stop();
            disposeTween();
            
            allowMove = false;
            allowZoom = false;
            allowRotate = false;
            allowInteractions = false;
            
            controller.removeEventListener(CanvasEvent.TRANSFORMATION_FINISHED, onCanvasTransformationFinished);
            
            controller = null;
        }
        
        public function set allowMove(value:Boolean):void
        {
            if(allowMove == value)
                return;
            
            _allowMove = value;
            validateInteractions();
        }
        
        public function get allowMove():Boolean
        {
            return _allowMove;
        }
        
        public function set allowZoom(value:Boolean):void
        {
            if(allowZoom == value)
                return;
            
            _allowZoom = value;
            validateInteractions();
        }
        
        public function get allowZoom():Boolean
        {
            return _allowZoom;
        }
        
        public function set allowRotate(value:Boolean):void
        {
            if(allowRotate == value)
                return;
            
            _allowRotate = value;
            validateInteractions();
        }
        
        public function get allowRotate():Boolean
        {
            return _allowRotate;
        }
        
        protected function set allowInteractions(value:Boolean):void
        {
            if(allowInteractions == value)
                return;
            
            _allowInteractions = value;
        }
        
        protected function get allowInteractions():Boolean
        {
            return _allowInteractions;
        }
        
        protected function set transforming(value:Boolean):void
        {
            if(transforming == value)
                return;
            
            _transforming = value;
        }
        
        protected function get transforming():Boolean
        {
            return _transforming;
        }
		
		public function get center():Point{
			return new Point(transformationTarget.centerX, transformationTarget.centerY);
		}
        
        protected static function normalizeRadians(radians:Number):Number
        {
            radians %= PI2;
            if(radians > Math.PI)
                radians -= PI2;
            else if(radians < -Math.PI)
                radians += PI2;
            return radians;
        }
        
        protected function limitScale(scale:Number):Number
        {
            if(scale > limit.minScale)
                return limit.minScale;
            if(scale < limit.maxScale)
                return limit.maxScale;
            return scale;
        }
        
        protected function limitCenterX(centerX:Number):Number
        {
            if(centerX < limit.minCenterX)
                return limit.minCenterX;
            if(centerX > limit.maxCenterX)
                return limit.maxCenterX;
            return centerX;
        }
        
        protected function limitCenterY(centerY:Number):Number
        {
            if(centerY < limit.minCenterY)
                return limit.minCenterY;
            if(centerY > limit.maxCenterY)
                return limit.maxCenterY;
            return centerY;
        }
        
        protected function stop():void
        {
        }
        
        private function validateInteractions():void
        {
            allowInteractions = allowMove || allowZoom || allowRotate;
        }
        
        private function updateTransformation():void
        {
            transformationTarget.centerX = transformation.centerX = controller.center.x;
            transformationTarget.centerY = transformation.centerY = controller.center.y;
            transformationTarget.scale = transformation.scale = controller.scale;
            transformationTarget.rotation = transformation.rotation = controller.rotation;
        }
        
        public function moveByTween(deltaX:Number, deltaY:Number):void
        {
            moveToTween(
                transformationTarget.centerX + deltaX, 
                transformationTarget.centerY + deltaY);
        }
        
        public function moveToTween(centerX:Number, centerY:Number):void
        {
            doTween(centerX, centerY, NaN, NaN, onMoveToTweenUpdate);
        }
        
        public function moveRotateToTween(centerX:Number, centerY:Number,
            rotation:Number):void
        {
            var delta:Number = normalizeRadians(rotation - transformationTarget.rotation);
            rotation = transformationTarget.rotation + delta;
            doTween(centerX, centerY, NaN, rotation, onMoveRotateToTweenUpdate);
        }
        
        public function moveRotateScaleToTween(centerX:Number, centerY:Number,
            rotation:Number, scale:Number):void
        {
            var delta:Number = normalizeRadians(rotation - transformationTarget.rotation);
            rotation = transformationTarget.rotation + delta;
            doTween(centerX, centerY, scale, rotation, onMoveRotateScaleToTweenUpdate);
        }
        
        public function rotateByTween(delta:Number, lock:Point=null):void
        {
            rotateToTween(transformationTarget.rotation + delta);
        }
        
        public function rotateToTween(rotation:Number, lock:Point=null):void
        {
            var delta:Number = normalizeRadians(rotation - transformationTarget.rotation);
            rotation = transformationTarget.rotation + delta;
            doTween(NaN, NaN, NaN, rotation, onRotateToTweenUpdate(lock));
        }
        
        public function rotateScaleToTween(rotation:Number, scale:Number):void
        {
            var delta:Number = normalizeRadians(rotation - transformationTarget.rotation);
            rotation = transformationTarget.rotation + delta;
            doTween(NaN, NaN, scale, rotation, onRotateScaleToTweenUpdate);
        }
        
        public function scaleByTween(delta:Number, lock:Point=null):void
        {
            scaleToTween(transformationTarget.scale * delta, lock);
        }
        
        public function scaleToTween(scale:Number, lock:Point=null):void
        {
            doTween(NaN, NaN, scale, NaN, onScaleToTweenUpdate(lock));
        }
        
        public function showBoundsTween(left:Number, right:Number, top:Number,
            bottom:Number):void
        {
            var centerX:Number = (left + right) / 2;
            var centerY:Number = (top + bottom) / 2;
            
            var targetLeftTop:Point = controller.canvasToViewPort(new Point(left, top));
            var targetRightBottom:Point = controller.canvasToViewPort(new Point(right, bottom));
            var targetMinX:Number = Math.min(targetLeftTop.x, targetRightBottom.x);
            var targetMaxX:Number = Math.max(targetLeftTop.x, targetRightBottom.x);
            var targetMinY:Number = Math.min(targetLeftTop.y, targetRightBottom.y);
            var targetMaxY:Number = Math.max(targetLeftTop.y, targetRightBottom.y);
            
            var deltaScaleX:Number = 
                Math.abs(controller.viewPort.width) /
                Math.abs(targetMaxX - targetMinX);
            
            var deltaScaleY:Number = 
                Math.abs(controller.viewPort.height) /
                Math.abs(targetMaxY - targetMinY);
            
            var deltaScale:Number = Math.min(deltaScaleX, deltaScaleY);
            var scale:Number = controller.scale * deltaScale;
            
            doTween(centerX, centerY, scale, controller.rotation, onMoveScaleToTweenUpdate);
        }
        
        public function showDisplayObjectTween(displayObject:DisplayObject):void
        {
            showBoundsTween(
                displayObject.bounds.left - displayObject.pivotX,
                displayObject.bounds.right - displayObject.pivotX,
                displayObject.bounds.top - displayObject.pivotY,
                displayObject.bounds.bottom - displayObject.pivotY);
        }
        
        private function doTween(centerX:Number, centerY:Number, scale:Number, 
            rotation:Number, updateCallback:Function):void
        {
            var data:Object = {onUpdate:updateCallback, onComplete:onTweenComplete};
            if(isNaN(centerX))
                transformationTarget.centerX = transformation.centerX = controller.center.x;
            else
                transformationTarget.centerX = data.centerX = limitCenterX(centerX);
            
            if(isNaN(centerY))
                transformationTarget.centerY = transformation.centerY = controller.center.y;
            else
                transformationTarget.centerY = data.centerY = limitCenterY(centerY);
            
            if(isNaN(scale))
                transformationTarget.scale = transformation.scale = controller.scale;
            else
                transformationTarget.scale = data.scale = limitScale(scale);
            
            if(isNaN(rotation))
                transformationTarget.rotation = transformation.rotation = controller.rotation;
            else
                transformationTarget.rotation = data.rotation = rotation;
            
            disposeTween();
            tween = TweenNano.to(transformation, transitionDuration, data);
            transforming = true;
            controller.dispatchEvent(new CanvasEvent(CanvasEvent.TRANSFORMATION_STARTED));
        }
        
        private function disposeTween():void
        {
            if(!tween)
                return;
            
            tween.kill();
            tween = null;
        }
        
        private function onTweenComplete():void
        {
            disposeTween();
            controller.dispatchEvent(new CanvasEvent(CanvasEvent.TRANSFORMATION_FINISHED));
        }
        
        private function onMoveToTweenUpdate():void
        {
            TransformationUtils.moveTo(controller, 
                new Point(transformation.centerX, transformation.centerY));
        }
        
        private function onMoveRotateToTweenUpdate():void
        {
            TransformationUtils.moveRotateTo(controller, 
                new Point(transformation.centerX, transformation.centerY), 
                transformation.rotation);
        }
        
        private function onMoveRotateScaleToTweenUpdate():void
        {
            TransformationUtils.moveRotateTo(controller, 
                new Point(transformation.centerX, transformation.centerY), 
                transformation.rotation);
            controller.scale = transformation.scale;
        }
        
        private function onRotateToTweenUpdate(lock:Point):Function
        {
            return function():void
            {
                TransformationUtils.rotateTo(controller, transformation.rotation, lock);
                transformationTarget.centerX = transformation.centerX = controller.center.x;
                transformationTarget.centerY = transformation.centerY = controller.center.y;
            }
        }
        
        private function onRotateScaleToTweenUpdate():void
        {
            TransformationUtils.rotateScaleTo(controller, transformation.rotation, transformation.scale);
        }
        
        private function onScaleToTweenUpdate(lock:Point):Function
        {
            return function():void
            {
                TransformationUtils.scaleTo(controller, transformation.scale, lock);
                transformationTarget.centerX = transformation.centerX = controller.center.x;
                transformationTarget.centerY = transformation.centerY = controller.center.y;
            }
        }
        
        private function onMoveScaleToTweenUpdate():void
        {
            TransformationUtils.scaleTo(controller, transformation.scale,
                new Point(transformationTarget.centerX, transformationTarget.centerY));
            controller.center = new Point(transformation.centerX, transformation.centerY);
        }
        
        private function onCanvasTransformationFinished(event:CanvasEvent):void
        {
            transforming = false;
            updateTransformation();
        }
    }
}