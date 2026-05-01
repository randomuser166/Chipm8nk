// made by scratchfurry 2026

package cpu.chipm8nk {
	import flash.events.Event;
	import flash.utils.ByteArray;
	import flash.display.Sprite;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
    import flash.events.SampleDataEvent;
	import flash.display.BitmapData;
	import flash.display.Bitmap;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Rectangle;
	import flash.net.SharedObject;
	
	public class Chipm8nk extends Sprite {
		private var memory:Vector.<uint> = new Vector.<uint>(0x1000);
		
		private var V:Vector.<uint> = new Vector.<uint>(16);
		private var I:uint = 0x000;
		private var PC:uint = 0x200;
		private var SP:uint = 0x00;
		private var DT:uint = 0x00;
		private var ST:uint = 0x00;
		
		private var stack:Vector.<uint> =  new Vector.<uint>(16);
		private var keypad:Vector.<uint> = new Vector.<uint>(16);
		private var gfx:Vector.<uint> = new Vector.<uint>(128 * 64);
		private var timer:Timer = new Timer(1000 / 60);
		
		
		private var beep:Sound = new Sound();
		private var beepChannel:SoundChannel;
		private var isBeeping:Boolean = false;
		private var screen:BitmapData = new BitmapData(256, 128, false, 0x000000);
		private var screenBitmap:Bitmap = new Bitmap(screen);
		private var drawFlag:Boolean = false;
		private var colors:Array = [0x000000, 0xFFFFFF];
		private var container:DisplayObjectContainer;
		private var running:Boolean = false;
		private var hiRes:Boolean = false;
		private var screenWidth = 64;
		private var screenHeight = 32;
		
		
		
		private const InstructionsPerFrame = 5;
		
		
		
		private const CHIP8Fontset:Array = [
									        0xF0, 0x90, 0x90, 0x90, 0xF0, // 0 char
									        0x20, 0x60, 0x20, 0x20, 0x70, // 1 char
									        0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2 char
									        0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3 char
									        0x90, 0x90, 0xF0, 0x10, 0x10, // 4 char
									        0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5 char
									        0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6 char
									        0xF0, 0x10, 0x20, 0x40, 0x40, // 7 char
									        0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8 char
									        0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9 char
									        0xF0, 0x90, 0xF0, 0x90, 0x90, // A char
									        0xE0, 0x90, 0xE0, 0x90, 0xE0, // B char
									        0xF0, 0x80, 0x80, 0x80, 0xF0, // C char
									        0xE0, 0x90, 0x90, 0x90, 0xE0, // D char
									        0xF0, 0x80, 0xF0, 0x80, 0xF0, // E char
									        0xF0, 0x80, 0xF0, 0x80, 0x80, // F char
									       ]
		
		
		public function Chipm8nk(sr:DisplayObjectContainer) {
			trace("======= Chipm8nk =======");
			trace("A CHIP-8 interpreter for ActionScript 3");
			trace("");
			trace("made by randomuser166 :3");
			trace("");
			trace("https://github.com/randomuser166");
			trace("");
			trace("------------------------");
			beep.addEventListener(SampleDataEvent.SAMPLE_DATA, generateTone);
			loadFont();
			container = sr;
			container.addChild(screenBitmap);
		}
		
		public function reset() {
			gfx = new Vector.<uint>(128 * 64);
			stack =  new Vector.<uint>(16);
			memory = new Vector.<uint>(0x1000);
			loadFont();
			V = new Vector.<uint>(16);
		    I = 0x000;
		    PC = 0x200;
		    SP = 0x00;
		    DT = 0x00;
		    ST = 0x00;
		}
		
		private function generateTone(e:SampleDataEvent):void {
           var frequency:Number = 440;
           var sampleRate:int = 44100;
    
           for (var i:int = 0; i < 2048; i++) {
               var t:Number = (i / sampleRate) * frequency;
               var sample:Number = (Math.sin(t * 2 * Math.PI) > 0) ? 0.25 : -0.25;
        
               e.data.writeFloat(sample);
               e.data.writeFloat(sample);
            }
        }
		
		private function loadFont() {
			for (var f:int = 0; f <= CHIP8Fontset.length; f++) {
				memory[0x50 + f] = CHIP8Fontset[f];
			}
		}
		
		public function loadProgram(rom:ByteArray) {
			trace ("program size: " + rom.length + " bytes long");
			trace("");
			for (var i:int = 0; i <= rom.length; i++) {
				memory[0x200 + i] = rom[i];
			}
		}
		
		public function run() {
			addEventListener(Event.ENTER_FRAME, emulatorLoop);
			timer.addEventListener(TimerEvent.TIMER, updateTimers);
			timer.start();
			running = true;
		}
		
		public function stop() {
			removeEventListener(Event.ENTER_FRAME, emulatorLoop);
			timer.stop();
			timer.removeEventListener(TimerEvent.TIMER, updateTimers);
		    
			stopBeep();
			running = false;
		}
		
		public function get isRunning() {
			return running;
		}
		
		
		private function emulatorLoop(e:Event):void {
			for (var i:int = 0; i <= InstructionsPerFrame; i++) {
				step();
			}
		}
		
		public function setKeypad(key:uint, val:Boolean) {
			if (val) keypad[key & 0x0F] = 0x01;
			if (!val) keypad[key & 0x0F] = 0x00;
		}
		
		private function updateTimers(e:TimerEvent) {
			if (DT > 0) DT--;
			
			if (ST > 0) {
				ST--;
				startBeep();
			} else {
				stopBeep();
			}
		}
		
		private function startBeep() {
			if (!isBeeping) {
				trace("beep!");
				beepChannel = beep.play(0, int.MAX_VALUE);
				isBeeping = true;
			}
		}
		
		private function stopBeep() {
			if (isBeeping && beepChannel) {
				beepChannel.stop();
				isBeeping = false;
			}
		}
		
		public function setPaletteColors(palette:Array) {
			colors[0] = palette[0];
			colors[1] = palette[1];
			render();
		}
		
		private function render() {
			screen.fillRect(screen.rect, colors[0]); rect = new Rectangle(0, 0, 4, 4);
			
			var rect:Rectangle;
			
			for (var pixelY:int = 0; pixelY < screenHeight; pixelY++) {
				for (var pixelX:int = 0; pixelX < screenWidth; pixelX++) {
					if (gfx[pixelY * screenWidth + pixelX] == 0x01) {
						rect.x = pixelX * rect.width;
						rect.y = pixelY * rect.height;
						screen.fillRect(rect, colors[1]);
					}
				}
			}
			screenBitmap.bitmapData = screen;
		}
			
		public function step() {
			var opcode:uint = (memory[PC] << 8) | memory[PC + 1];
			PC += 2;
			
			var X:int = (opcode & 0x0F00) >> 8;
            var Y:int = (opcode & 0x00F0) >> 4;
            var N:int = opcode & 0x000F;
            var NN:int = opcode & 0x00FF;
            var NNN:int = opcode & 0x0FFF;
			
			
			switch (opcode & 0xF000) {
				case 0x0000:
				    if (NN == 0xE0) { // cls
					    gfx = new Vector.<uint>(128 * 64);
						drawFlag = true;
					}
					
					if (NN == 0xEE) { // rts
					    SP = (SP - 1)& 0x0F;
						PC = stack[SP];
					}
					
					break;
				
				case 0x1000: // jmp nnn
				    PC = NNN;
					break;
				
				case 0x2000: // call NNN
				    stack[SP] = PC;
					SP = (SP + 1) & 0x0F;
					PC = NNN;
					break;
				
				case 0x3000: // if vx == NN
				    if (V[X] == NN) PC = (PC + 2) & 0xFFF;
					break;
				
				case 0x4000: // if vx != NN
				    if (V[X] != NN) PC = (PC + 2) & 0xFFF;
					break;
				
				case 0x5000: // if vx == vy
				    if (V[X] == V[Y]) PC = (PC + 2) & 0xFFF;
					break;
				
				case 0x6000: // vx = NN
				    V[X] = NN;
					break;
				
				case 0x7000: // vx += NN
				    V[X] = (V[X] + NN) & 0xFF;
					break;
				
				case 0x8000:
				    if (N == 0x00) { // vx = vy
					    V[X] = V[Y];
					}
					
					if (N == 0x01) { // vx |= vy
					    V[X] |= V[Y];
					}
					
					if (N == 0x02) { // vx &= vy
					    V[X] &= V[Y];
					}
					
					if (N == 0x03) { // vx ^= vy
					    V[X] ^= V[Y];
					}
					
					if (N == 0x04) { // vx += vy (carry)
						if ((V[X] + V[Y]) > 0xFF) V[0x0F] = 0x01;
						else V[0x0F] = 0x00;
						V[X] = (V[X] + V[Y]) & 0xFF;
					}
					
					if (N == 0x05) { // vx -= vy (NOT borrow)
						if (V[X] > V[Y]) V[0x0F] = 0x01;
						else V[0x0F] = 0x00;
						
						V[X] = (V[X] - V[Y]) & 0xFF;
					}
					
					if (N == 0x06) { // vx >>= 1
						V[0x0F] = V[X] & 0x01;
						V[X] = (V[Y] >> 1) & 0xFF;
					}
					
					if (N == 0x07) { // vx = vy - vx (NOT borrow)
						if (V[Y] > V[X]) V[0x0F] = 0x01;
						V[X] = (V[Y] - V[X]) & 0xFF;
						V[0x0F] = 0x00;
					}
					
					if (N == 0x0E) { // vx <<= 1
						V[0x0F] = V[X] & 0x80;
						V[X] = (V[Y] << 1) & 0xFF;
					}
					
					break;
				
				case 0x9000: // if vx != vy
				    if (V[X] != V[Y]) PC = (PC + 2) & 0xFFF;
					break;
				
				case 0xA000: // I = NNN
				    I = NNN;
					break;
				
				case 0xB000: // jmp nnn + v0
				    PC = (NNN + V[0]) & 0xFFF;
					break;
				
				case 0xC000: // vx = rand 0-255 & NN
				    var randomNum = Math.random() * 255
					V[X] = randomNum & NN;
					break;
				
				case 0xD000: // draw at vx, vy, n
				    V[0x0F] = 0x00;
					
					for (var row:int = 0; row < N; row++) {
						for (var col:int = 0; col < 8; col++) {
							if ((memory[I + row] & (0x80 >> col)) != 0) {
								var pixelX:int = (V[X] + col) % screenWidth;
								var pixelY:int = (V[Y] + row) % screenHeight;
								var i:int = pixelX + pixelY * screenWidth;
								
								if(gfx[i] == 0x01) V[0x0F] = 0x01;
								gfx[i] ^= 0x01;
							}
						}
					}
					drawFlag = true;
					break;
				
				case 0xE000:
				    if (NN == 0x9E) { // if key vx pressed
					    if (keypad[V[X]] == 0x01) PC = (PC + 2) & 0xFFF;
					}
					
					if (NN == 0xA1) { // if key vx not pressed
					    if (keypad[V[X]] != 0x01) PC = (PC + 2) & 0xFFF;
					}
					
					break;
				
				case 0xF000:
				    if (NN == 0x07) { // vx = DT
						V[X] = DT;
					}
					
					if (NN == 0x0A) { // wait for keypress
					    var pressed = false;
						
						for (var k:int = 0; k <= 16; k++) {
							if (keypad[k] == 0x01) {
								V[X] = k;
								pressed = true;
								break;
							}
						}
						if (!pressed) PC = (PC - 2) & 0xFFF;
					}
						
					
					if (NN == 0x15) { // DT = vx
					    DT = V[X];
					}
					
					if (NN == 0x18) { // ST = vx
					    ST = V[X];
					}
					
					if (NN == 0x1E) { // I += vx
					    I = (I + V[X]) & 0xFFF;
					}
					
					if (NN == 0x29) { // I = address of hex font vx
					    I = 0x50 + (V[X] * 5);
					}
					
					if (NN == 0x33) { // memory[I] = bcd of vx
					     memory[I] = V[X] / 100;
						 memory[I + 1] = (V[X] / 10) % 10;
						 memory[I + 2] = V[X] % 10;
					}
					
					if (NN == 0x55) { // memory[I] = v0 through vx
					     for (var i:int = 0; i <= X; i++) {
							 memory[I + i] = V[i];
						 }
					}
					
					if (NN == 0x65) { // v0 through vx = memory[I]
					     for (var i:int = 0; i <= X; i++) {
							 V[i] = memory[I + i];
						 }
					}
					
					break;
				default:
				    trace("unknown opcode: " + opcode.toString(16).toUpperCase());
				    break;
			}
           if (drawFlag) {
			   render();
			   drawFlag = false;
		   }
		}
	}
}
