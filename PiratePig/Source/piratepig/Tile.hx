package piratepig;


import flash.display.Bitmap;
import flash.display.Sprite;
import motion.Actuate;
import motion.actuators.GenericActuator;
import motion.easing.Linear;
import motion.easing.Quad;
import openfl.Assets;


class Tile extends Sprite {
	
	
	public var column:Int;
	public var moving:Bool;
	public var removed:Bool;
	public var row:Int;
	public var type:Int;
	
	
	public function new (imagePath:String) {
		
		super ();
		
		var image = new Bitmap (Assets.getBitmapData (imagePath));
		image.smoothing = true;
		addChild (image);
		
		mouseChildren = false;
		buttonMode = true;
		
		graphics.beginFill (0x000000, 0);
		graphics.drawRect (-5, -5, 66, 66);
		
	}
	
	// инициализация
	public function initialize ():Void {
		
		moving = false; // не двигается
		removed = false; // не удалена
		
		mouseEnabled = true; // готова к перемещению
		buttonMode = true; // в режиме кнопки
		// нормальные размеры и прозрачность
		scaleX = 1; 
		scaleY = 1;
		alpha = 1;
		
	}
	
	// падение плитки
	public function moveTo (duration:Float, targetX:Float, targetY:Float):Void {
		
		moving = true;
		
		Actuate.tween (this, duration, { x: targetX, y: targetY } ).ease (Quad.easeOut).onComplete (this_onMoveToComplete);
		
	}
	
	// Удаление плиток
	public function remove (animate:Bool = true):Void {
		
		#if (js && (dom || !openfl_html5)) // если js и (dom или не openfl_html5)
		animate = false; // не анимировано
		#end
		
		if (!removed) { // если не удалено
			
			if (animate) { // если анимировано
				
				mouseEnabled = false; // запретить мышку
				buttonMode = false; // отключить режим кнопки
				
				parent.addChildAt (this, 0);  // добавляем наследника 
				Actuate.tween (this, 0.6, { alpha: 0, scaleX: 2, scaleY: 2, x: x - width / 2, y: y - height / 2 } ).onComplete (this_onRemoveComplete); // анимаця удаления (увеличивается и растворяется)
				
			} else {
				
				this_onRemoveComplete ();
				
			}
			
		}
		
		removed = true;
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	private function this_onMoveToComplete ():Void {
		
		moving = false;
		
	}
	
	
	private function this_onRemoveComplete ():Void {
		
		parent.removeChild (this); // после анимации удаляем наследника (я хз зачем)
		
	}
	
	
}