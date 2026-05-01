# Chipm8nk
A CHIP-8 interpreter for ActionScript 3. It implements all of the 35 CHIP-8 instructions.

I wrote this code in Adobe Flash CS4, and this is also my first emulator in AS3. (i plan in making more emulators in the future :3)

# Importing Chipm8nk in Flash
In your .fla file, open Publish Settings (File > Publish Settings), go to the Flash tab and click Settings (next to Script), go to Source Path and press the folder icon and from there, navigate to where you downloaded the Chipm8nk source code and select the /src/ folder (if the /src/ folder is inside another folder, just go inside the folder where /src/ is and select it). Click the OK button and click it again on Publish Settings. 

Once you successfully imported the Chipm8nk library into your .fla file, creating a Chipm8nk instance is easy:

```
import cpu.chipm8nk.Chipm8nk

var cpu:Chipm8nk = new Chipm8nk(this);

```

# Loading CHIP-8 ROMS in Chipm8nk
To load a CHIP-8 ROM inside a Chipm8nk instance, use a FileReference + ByteArray like this (if you're loading roms from your computer):

```
import cpu.chipm8nk.Chipm8nk;
import flash.net.FileReference;
import flash.events.Event;

var cpu:Chipm8nk = new Chipm8nk(this);

var fileRef:FileReference = new FileReference();
var rom:ByteArray = new ByteArray();

function browseForROM() {
	fileRef.addEventListener(Event.SELECT, romSelected);
    fileRef.browse();
}

function romSelected(e:Event) {
	fileRef.addEventListener(Event.COMPLETE, loadIntoCPU);
	fileRef.load();
}

function loadIntoCPU(e:Event) {
	rom = fileRef.data;
  cpu.loadProgram(rom);
  cpu.run();
}
```

# Chipm8nk Functions

- `loadProgram(rom)` Loads the program inside `rom` at address 0x200 (`rom` is a ByteArray)
- `run()` If not already running, run the CHIP-8 ROM, until the `stop()` function is executed
- `stop()` If already running, pauses the interpreter from running the ROM, until the `run()` function is executed
- `isRunning()` Returns a boolean that says if the interpreter is running the ROM or not (false = not running, true = running)
- `setKeypad(key, val)` Sets the state of one of the keypad keys to false or true (`key` is a uint from 0x00 to 0x0F and `val` is a boolean)
- `setPaletteColors(palette)` Sets the palette colors to the colors inside the `palette` array (index 0 is the black color and index 1 is the white color by default)
- `step()` Executes the next instruction
