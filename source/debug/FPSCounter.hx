package debug;

import flixel.FlxG;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFieldAutoSize;
import openfl.display.Sprite;
import openfl.display.Shape;
import openfl.filters.DropShadowFilter;
import openfl.events.Event;
import haxe.Timer;

class FPSCounter extends Sprite
{
    public var currentFPS(default, null):Int;
    public var memoryMegas(get, never):Float;

    @:noCompletion private var times:Array<Float>;
    private var tf:TextField;
    private var padding:Float = 8;
    private var bg:Shape;
    private var deltaTimeout:Float = 0.0;
    private var gcTimer:Float = 0.0;

    public function new(x:Float = 10, y:Float = 10, color:Int = 0xFFFFFF)
    {
        super();
        this.x = x;
        this.y = y;

        currentFPS = 0;
        times = [];

        // background shape
        bg = new Shape();
        addChild(bg);

        // text field
        tf = new TextField();
        tf.selectable = false;
        tf.mouseEnabled = false;
        tf.defaultTextFormat = new TextFormat("_sans", 14, color, true);
        tf.autoSize = TextFieldAutoSize.LEFT;
        tf.multiline = true;
        tf.embedFonts = false;
        tf.x = padding;
        tf.y = padding;
        tf.text = "FPS: ";

        addChild(tf);

        this.filters = [new DropShadowFilter(2, 45, 0, 0.6, 4, 4)];
        drawBackground(0x000000, 0.5);
        addEventListener(Event.ENTER_FRAME, onEnterFrame);
    }

    private function drawBackground(color:Int, alpha:Float):Void
    {
        var w = Math.max(120, tf.width + padding * 2);
        var h = tf.height + padding * 2;
        var g = bg.graphics;
        g.clear();
        g.beginFill(color, alpha);

        // draw rounded rect with radius 8
        #if openfl_legacy
        g.drawRoundRect(0, 0, w, h, 8);
        #else
        g.drawRoundRect(0, 0, w, h, 8, 8);
        #end
        g.endFill();

        // ensure tf inside
        tf.x = padding;
        tf.y = padding;
    }

    // Event Handler
    private function onEnterFrame(e:Event):Void
    {
        gcTimer += FlxG.elapsed;
        if (gcTimer >= 5.0) {
            try {
				cpp.vm.Gc.run(true);
			} catch(_e:Dynamic) {}
            gcTimer = 0.0;
        }

        var deltaTime = FlxG.elapsed * 1000; // ms
        final now:Float = Timer.stamp() * 1000;
        times.push(now);
        while (times.length > 0 && times[0] < now - 1000) times.shift();

        if (deltaTimeout < 250) {
            deltaTimeout += deltaTime;
            return;
        }

        currentFPS = times.length < FlxG.updateFramerate ? times.length : FlxG.updateFramerate;
        updateText();
        deltaTimeout = 0.0;
    }

    public dynamic function updateText():Void {
        var memStr = flixel.util.FlxStringUtil.formatBytes(memoryMegas);
        tf.text = 'FPS: ' + Std.string(currentFPS) + '\nMemory: ' + memStr;

        var bgColor:Int = 0x1E1E1E;
        var alphaVal:Float = 0.6;
        if (currentFPS < FlxG.drawFramerate * 0.5) {
            bgColor = 0x550000;
        } else if (currentFPS < FlxG.drawFramerate * 0.85) {
            bgColor = 0x554400;
        } else {
            bgColor = 0x003300;
        }
        drawBackground(bgColor, alphaVal);
    }

    inline function get_memoryMegas():Float
        return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);
}
