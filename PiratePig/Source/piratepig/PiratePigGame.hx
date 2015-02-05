package piratepig;


import flash.display.Bitmap;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filters.BlurFilter;
import flash.filters.DropShadowFilter;
import flash.geom.Point;
import flash.media.Sound;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import flash.Lib;
import motion.Actuate;
import motion.easing.Quad;
import openfl.Assets;


class PiratePigGame extends Sprite {
	
	
	private static var NUM_COLUMNS = 8; 
	private static var NUM_ROWS = 8;
	
	private static var tileImages = [ "images/game_bear.png", "images/game_bunny_02.png", "images/game_carrot.png", "images/game_lemon.png", "images/game_panda.png", "images/game_piratePig.png" ];
	
	private var Background:Sprite;
	private var IntroSound:Sound;
	private var Logo:Bitmap;
	private var Score:TextField;
	private var Sound3:Sound;
	private var Sound4:Sound;
	private var Sound5:Sound;
	private var TileContainer:Sprite;
	
	public var currentScale:Float;
	public var currentScore:Int;
	
	private var cacheMouse:Point;
	private var needToCheckMatches:Bool;
	private var selectedTile:Tile;
	private var tiles:Array <Array <Tile>>;
	private var usedTiles:Array <Tile>;
	
	
	public function new () {
		
		super ();
		
		initialize ();
		construct ();
		
		newGame ();
		
	}
	
	// Добавляем плитки
	private function addTile (row:Int, column:Int, animate:Bool = true):Void {
		
		var tile = null; // пустая плитка
		var type = Math.round (Math.random () * (tileImages.length - 1)); // случайный тип плитки
		// перебираем пустые плитки 
		for (usedTile in usedTiles) {
			// Если используемая плитка удалена и наследует null, и имеет тип как овый случайный тип
			if (usedTile.removed && usedTile.parent == null && usedTile.type == type) {
				
				tile = usedTile; // присваиваем плитке используемый таи плитки (видимо для экономии памяти)
				
			}
			
		}
		// Если плитка пустая 
		if (tile == null) {
			// создаём новую
			tile = new Tile (tileImages[type]);
			
		}
		// инициализируем плитку
		tile.initialize ();
		// применяем текущий тип и расположение в сетке
		tile.type = type;
		tile.row = row;
		tile.column = column;
		tiles[row][column] = tile; // сохраняем с вассиве
		
		var position = getPosition (row, column); // получаем позицию на поле
		// если в движении
		if (animate) {
			// ЗАдаём изначальную позицию для падения
			var firstPosition = getPosition (-1, column);
			
			#if (!js || openfl_html5) // если html5 или не js
			tile.alpha = 0; // делаем плитку прозрачной
			#end
			tile.x = firstPosition.x; // применяем позицию
			tile.y = firstPosition.y; // к плитке
			
			tile.moveTo (0.15 * (row + 1), position.x, position.y); // двигаем плитку на своё место
			#if (!js || openfl_html5) // если html5 или не js
			Actuate.tween (tile, 0.3, { alpha: 1 } ).delay (0.15 * (row - 2)).ease (Quad.easeOut); // двигаем тайл
			#end
			
		} else { 
			
			tile.x = position.x;
			tile.y = position.y;
			
		}
		
		TileContainer.addChild (tile); // размещаем плитки на поле
		needToCheckMatches = true; // проверяем ряды
		
	}
	
	
	private function construct ():Void {
		// Логотип
		Logo.smoothing = true;
		addChild (Logo);
		// Загрузка и настройка шрифта
		var font = Assets.getFont ("fonts/FreebooterUpdated.ttf");
		var defaultFormat = new TextFormat (font.fontName, 60, 0x000000);
		defaultFormat.align = TextFormatAlign.RIGHT;
		
		#if (js && !openfl_html5)
		defaultFormat.align = TextFormatAlign.LEFT;
		#end
		
		var contentWidth = 75 * NUM_COLUMNS;
		// Результат
		Score.x = contentWidth - 200;
		Score.width = 200;
		Score.y = 12;
		Score.selectable = false;
		Score.defaultTextFormat = defaultFormat;
		
		#if (!js || openfl_html5) // если html5 или не js
		Score.filters = [ new BlurFilter (1.5, 1.5), new DropShadowFilter (1, 45, 0, 0.2, 5, 5) ]; // включаем какие-то фильтры видимо для большей красоты
		#else // иначе просто выставляем координаты
		Score.y = 0; 
		Score.x += 90;
		#end
		
		Score.embedFonts = true; // используем встроеные шрифты
		addChild (Score); // выводим результат
		//Натройка фона
		Background.y = 85; 
		Background.graphics.beginFill (0xFFFFFF, 0.4);
		Background.graphics.drawRect (0, 0, contentWidth, 75 * NUM_ROWS);
		
		#if (!js || openfl_html5) // если html5 или не js
		Background.filters = [ new BlurFilter (10, 10) ]; // настройки фона
		addChild (Background);
		#end
		// Установки игрового поля
		TileContainer.x = 14;
		TileContainer.y = Background.y + 14;
		TileContainer.addEventListener (MouseEvent.MOUSE_DOWN, TileContainer_onMouseDown); // Слушатель нажатия клавиши мышки 
		Lib.current.stage.addEventListener (MouseEvent.MOUSE_UP, stage_onMouseUp); // слушатель отпускания мыши
		addChild (TileContainer); 
		
		IntroSound = Assets.getSound ("soundTheme");
		Sound3 = Assets.getSound ("sound3");
		Sound4 = Assets.getSound ("sound4");
		Sound5 = Assets.getSound ("sound5");
		
	}
	
	
	private function dropTiles ():Void {
		
		for (column in 0...NUM_COLUMNS) { // Перебираем столбцы
			
			var spaces = 0; // пустое пространство для плиток
			
			for (row in 0...NUM_ROWS) { // Перебираем строки
				
				var index = (NUM_ROWS - 1) - row; // Меняем порядок
				var tile = tiles[index][column]; // Перебраем столбец снизу в верх
				
				if (tile == null) { // Если плитка удалена 
					
					spaces++; // Добавляем пустое пространство
					
				} else { // Иначе
					
					if (spaces > 0) { // Если есть пустоты
						// получаем позицию индекс + пустота в колонке
						var position = getPosition (index + spaces, column);
						tile.moveTo (0.15 * spaces, position.x,position.y); // Роняем плитку
						
						tile.row = index + spaces; // сдвигаем плитку на новую позицию
						tiles[index + spaces][column] = tile; // сохраняем положение плитки в массиве
						tiles[index][column] = null; // очищаем старое положение
						
						needToCheckMatches = true; // проверяем на возникновение рядов
						
					}
					
				}
				
			}
			// перебираем пустоты
			for (i in 0...spaces) {
				// заполняем пустоты плитками
				var row = (spaces - 1) - i;
				addTile (row, column);
				
			}
			
		}
		
	}
	
	// Поиск рядов (в строчку или в столбик, считать очки или нет)
	private function findMatches (byRow:Bool, accumulateScore:Bool = true):Array <Tile> {
		// Массив для найденых рядов
		var matchedTiles = new Array <Tile> ();
		
		var max:Int; 		// для пущей уневерсальности 
		var secondMax:Int;	// если стка будет не равномерной
		// Если выбран поиск по горизонтали
		if (byRow) {
			
			max = NUM_ROWS; 
			secondMax = NUM_COLUMNS;
			
		} else {
			
			max = NUM_COLUMNS;
			secondMax = NUM_ROWS;
			
		}
		
		for (index in 0...max) {
			
			var matches = 0; // ряды
			var foundTiles = new Array <Tile> (); // Массив найденых плиток
			var previousType = -1; // предыдущий тип
			
			for (secondIndex in 0...secondMax) {
				
				var tile:Tile;
				
				if (byRow) { // если поиск по горизонтали
					
					tile = tiles[index][secondIndex]; 
					
				} else { // если поиск по вертикали
					
					tile = tiles[secondIndex][index];
					
				}
				// если плитка пустая и не двигается
				if (tile != null && !tile.moving) {
					// если предыдущий тип не равен -1
					if (previousType == -1) {
						
						previousType = tile.type; // Сохраняем текущий тип
						foundTiles.push (tile); // сохраняем текущую плитку
						continue;
						
					} else if (tile.type == previousType) { // если текущий тип равен предыдущему
						
						foundTiles.push (tile); // сохраняем плитку
						matches++; // прибовляем к переменной "вряд"
						
					}
					
				}
				// Если плитки нет или она двигается или тип плитки не равен предыдущей или второй индекс равен secondmax-1
				if (tile == null || tile.moving || tile.type != previousType || secondIndex == secondMax - 1) {
					// если в ряду 2 или более и предыдущий тип не равен -1
					if (matches >= 2 && previousType != -1) {
						
						if (accumulateScore) { // если результат засчитывается
							
							if (matches > 3) { // если вряд более 3х плиток
								
								Sound5.play (); // проиграть звук
								
							} else if (matches > 2) {// 
								
								Sound4.play ();
								
							} else {
								
								Sound3.play ();
								
							}
							
							currentScore += Std.int (Math.pow (matches, 2) * 50);
							
						}
						
						matchedTiles = matchedTiles.concat (foundTiles);
						
					}
					
					matches = 0;
					foundTiles = new Array <Tile> ();
					
					if (tile == null || tile.moving) {
						
						needToCheckMatches = true;
						previousType = -1;
						
					} else {
						
						previousType = tile.type;
						foundTiles.push (tile);
						
					}
					
				}
				
			}
			
		}
		
		return matchedTiles;
		
	}
	
	// Получаем позицию на экране
	private function getPosition (row:Int, column:Int):Point {
		// какой-то свой замут с размерами
		//                            73               73
		return new Point (column * (57 + 16), row * (57 + 16));
		
	}
	
	// Инициализация
	private function initialize ():Void {
		
		currentScale = 1; // текуший размер
		currentScore = 0; // текущий результат
		
		tiles = new Array <Array <Tile>> (); // Массив игровых плиток
		usedTiles = new Array <Tile> (); // Массив используемых плиток
		
		// Заполняем массив пустотой
		for (row in 0...NUM_ROWS) {
			
			tiles[row] = new Array <Tile> ();
			
			for (column in 0...NUM_COLUMNS) {
				
				tiles[row][column] = null;
				
			}
			
		}
		
		Background = new Sprite ();
		Logo = new Bitmap (Assets.getBitmapData ("images/logo.png"));
		Score = new TextField ();
		TileContainer = new Sprite ();
		
	}
	
	//Начало игры
	public function newGame ():Void {
		// Обнуляем результат
		currentScore = 0;
		Score.text = "0";
		// очищаем сетку
		for (row in 0...NUM_ROWS) {
			
			for (column in 0...NUM_COLUMNS) {
				
				removeTile (row, column, false); // удаляем плитки с поля
				
			}
			
		}
		// наполняем сетку
		for (row in 0...NUM_ROWS) {
			
			for (column in 0...NUM_COLUMNS) {
				
				addTile (row, column, false); // Добавляем плитки
				
			}
			
		}
		
		IntroSound.play (); // проигрываем вступительную музыку
		
		removeEventListener (Event.ENTER_FRAME, this_onEnterFrame); 
		addEventListener (Event.ENTER_FRAME, this_onEnterFrame);
		
	}
	
	// удаление плитки
	public function removeTile (row:Int, column:Int, animate:Bool = true):Void {
		// текущая плитка
		var tile = tiles[row][column];
		// Если не пустая
		if (tile != null) {
			
			tile.remove (animate); // Удаляем плитку
			usedTiles.push (tile); // Добавляем плитку в используемые (карман для плиток)
			
		}
		
		tiles[row][column] = null; // Убираем плитку с поля
		
	}
	
	
	public function resize (newWidth:Int, newHeight:Int):Void {
		
		var maxWidth = newWidth * 0.90;
		var maxHeight = newHeight * 0.86;
		
		currentScale = 1;
		scaleX = 1;
		scaleY = 1;
		
		#if (js || !openfl_html5)
		
		var currentWidth = 75 * NUM_COLUMNS;
		var currentHeight = 75 * NUM_ROWS + 85;
		
		#else
		
		var currentWidth = width;
		var currentHeight = height;
		
		#end
		
		if (currentWidth > maxWidth || currentHeight > maxHeight) {
			
			var maxScaleX = maxWidth / currentWidth;
			var maxScaleY = maxHeight / currentHeight;
			
			if (maxScaleX < maxScaleY) {
				
				currentScale = maxScaleX;
				
			} else {
				
				currentScale = maxScaleY;
				
			}
			
			scaleX = currentScale;
			scaleY = currentScale;
			
		}
		
		x = newWidth / 2 - (currentWidth * currentScale) / 2;
		
	}
	
	// Смена плиток (перенашиваемая плитка, строка замены, столбец замены)
	private function swapTile (tile:Tile, targetRow:Int, targetColumn:Int):Void {
		// Если столбец замены больше или равен 0 и меньше количества столбцов и строка замены больше или равен 0 и меньше количества строк
		if (targetColumn >= 0 && targetColumn < NUM_COLUMNS && targetRow >= 0 && targetRow < NUM_ROWS) {
			
			var targetTile = tiles[targetRow][targetColumn]; // сохраняем плитку с которой будет производиться замена
			
			if (targetTile != null && !targetTile.moving) { // Если целевая плитка не пустая и не двигается
				
				tiles[targetRow][targetColumn] = tile; 		// меняем плитки
				tiles[tile.row][tile.column] = targetTile;	// между собой
				// Если при поиске рядов совпали типы меняемых плиток (универсально, но неэффективно)
				if (findMatches (true, false).length > 0 || findMatches (false, false).length > 0) {
					// производим замену
					targetTile.row = tile.row; 
					targetTile.column = tile.column;
					tile.row = targetRow;
					tile.column = targetColumn;
					var targetTilePosition = getPosition (targetTile.row, targetTile.column); //получаем новые координаты целевой плитки
					var tilePosition = getPosition (tile.row, tile.column); // получаем новые координаты текущей плитки
					
					targetTile.moveTo (0.3, targetTilePosition.x, targetTilePosition.y); // анимация перемещения
					tile.moveTo (0.3, tilePosition.x, tilePosition.y); // анимация перемещения
					
					needToCheckMatches = true; // проверяем на ряды
					
				} else { // иначе
					
					tiles[targetRow][targetColumn] = targetTile; // всё остаётся на 
					tiles[tile.row][tile.column] = tile;		 // своих местах
					
				}
				
			}
			
		}
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	// слушатель отпускания клавиши мыши
	private function stage_onMouseUp (event:MouseEvent):Void {
		// если записано положение мыши и выбрана плитка и плитка не движется
		if (cacheMouse != null && selectedTile != null && !selectedTile.moving) {
			
			var differenceX = event.stageX - cacheMouse.x;
			var differenceY = event.stageY - cacheMouse.y;
			// Если абсолютное число differenceX или differenceY больше 10
			if (Math.abs (differenceX) > 10 || Math.abs (differenceY) > 10) {
				
				var swapToRow = selectedTile.row; // сохраняем строку
				var swapToColumn = selectedTile.column; // сохраняем столбц
				// Если абсолютное число differenceX больше differenceY
				if (Math.abs (differenceX) > Math.abs (differenceY)) {
					// Если differenceX имеет отрицательное значение
					if (differenceX < 0) {
						
						swapToColumn --; // дикрементируем сохранённый столбец
						
					} else { // Иначе
						
						swapToColumn ++; // инкрементируем
						
					}
					
				} else { // Иначе
					// Если differenceY имеет отрицательное значение
					if (differenceY < 0) {
						
						swapToRow --; // дикрементируем сохнанённую строку
						
					} else { //Иначе
						
						swapToRow ++; // инкрементируем
						
					}
					
				}
				
				swapTile (selectedTile, swapToRow, swapToColumn); // Меняем плитки местами
				
			}
			
		}
		
		selectedTile = null;
		cacheMouse = null;
		
	}
	
	// Обновление экрана
	private function this_onEnterFrame (event:Event):Void {
		// Если нужно проверить ряды
		if (needToCheckMatches) {
			
			var matchedTiles = new Array <Tile> (); // Массив рядов
			
			// Поиск рядов по горизонтали
			matchedTiles = matchedTiles.concat (findMatches (true));
			// Поиск рядов по вертикали
			matchedTiles = matchedTiles.concat (findMatches (false));
			// Очистка плиток попавших в ряд
			for (tile in matchedTiles) {
				
				removeTile (tile.row, tile.column); // убеваем тайлы
				
			}
			// Обновление результатов
			if (matchedTiles.length > 0) {
				
				Score.text = Std.string (currentScore); // Выводим результат
				dropTiles (); // раняем плитки с верху в низ
				
			}
			
		}
		
	}
	
	// Слуштель нажатой клавиши мышки
	private function TileContainer_onMouseDown (event:MouseEvent):Void {
		
		if (Std.is (event.target, Tile)) {// если то во что кликнула мышь является плиткой
			
			selectedTile = cast event.target; // ДЕлаем небезопасный слепок выббраной плитки
			cacheMouse = new Point (event.stageX, event.stageY); // записываем положение мыши на поле
			
		} else { // Иначе обнуляем
			
			cacheMouse = null;
			selectedTile = null;
			
		}
		
	}
	
	
}