package piratepig;


import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.system.Capabilities;
import flash.Lib;
import openfl.Assets;

/**
 * Базовый класс игры, отриовка фона и инициализация игрового процесса
 */
class PiratePig extends Sprite {
	
	
	private var Background:Bitmap; //Фон
	private var Footer:Bitmap; // Нижний колонтитул
	private var Game:PiratePigGame; // Игровое поле
	
	
	public function new () {
		
		super ();
		
		initialize (); // Инициализация
		construct (); // Установки и вывод
		
		resize (stage.stageWidth, stage.stageHeight); // Изменение размеров игры под размеры экрана
		stage.addEventListener (Event.RESIZE, stage_onResize); // Слушатель событий изменения размеров экрана\окна
		
	}
	
	
	private function construct ():Void {
		
		Footer.smoothing = true; // Сглаживание
		
		addChild (Background);
		addChild (Footer);
		addChild (Game);
		
	}
	
	
	private function initialize ():Void {
		
		Background = new Bitmap (Assets.getBitmapData ("images/background_tile.png"));
		Footer = new Bitmap (Assets.getBitmapData ("images/center_bottom.png"));
		Game = new PiratePigGame ();
		
	}
	
	// изменяем размер
	private function resize (newWidth:Int, newHeight:Int):Void {
		
		Background.width = newWidth;
		Background.height = newHeight;
		// получаем переменные размеров
		Game.resize (newWidth, newHeight);
		// применяем полученые размеры
		Footer.scaleX = Game.currentScale;
		Footer.scaleY = Game.currentScale;
		Footer.x = newWidth / 2 - Footer.width / 2;
		Footer.y = newHeight - Footer.height;
		
	}
	
	
	private function stage_onResize (event:Event):Void {
		
		resize (stage.stageWidth, stage.stageHeight);
		
	}
	
	
}
