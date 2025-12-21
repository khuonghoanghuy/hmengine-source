package backend;

import flixel.FlxState;
import psychlua.*;
#if HSCRIPT_ALLOWED
import psychlua.HScript.HScriptInfos;
import crowplexus.iris.Iris;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
#end

class ScriptedState extends FlxState
{
	#if HSCRIPT_ALLOWED
	public var hscript:HScript = null;
	public var hscriptArray:Array<HScript> = [];
	#end

	public var controls(get, never):Controls;
	private function get_controls()
	{
		return Controls.instance;
	}

    override function create() {
        super.create();

		loadStateScripts(Type.getClassName(Type.getClass(this)).split('.').pop());

		#if HSCRIPT_ALLOWED
		if (hscript != null && hscript.exists('onCreate')) hscript.call('onCreate');
		if (hscriptArray != null)
		{
			for (script in hscriptArray)
			{
				if (script != null && script.exists('onCreate')) script.call('onCreate');
			}
		}
		#end
	}

    override function update(elapsed:Float) {
        if (ClientPrefs.data.allowReloadState) {
            if (controls.RELOAD_STATE) {
				trace('Reloading State...');
				#if HSCRIPT_ALLOWED
				if (hscript != null)
				{
					if (hscript.exists('onReloadState')) hscript.call('onReloadState');
					hscript.destroy();
					hscript = null;
				}

				if (hscriptArray != null)
				{
					for (script in hscriptArray)
						if (script != null)
						{
							script.destroy();
						}
					hscriptArray = [];
				}
				#end
                
                MusicBeatState.switchState(MusicBeatState.getState());
                return;
            }
        }
		
		super.update(elapsed);

		#if HSCRIPT_ALLOWED
		// Suspend state HScript callbacks while a substate is active
		if (subState == null)
		{
			if (hscript != null && hscript.exists('onUpdate')) hscript.call('onUpdate', [elapsed]);
			if (hscriptArray != null)
			{
				for (script in hscriptArray)
					if (script != null && script.exists('onUpdate')) script.call('onUpdate', [elapsed]);
			}
		}
		#end
    }

    override function destroy() {
        super.destroy();

		#if HSCRIPT_ALLOWED
		if (hscript != null)
		{
			if(hscript.exists('onDestroy')) hscript.call('onDestroy');
			hscript.destroy();
			hscript = null;
		}
		if (hscriptArray != null)
		{
			for (script in hscriptArray)
				if (script != null)
				{
					if (script.exists('onDestroy')) script.call('onDestroy');
					script.destroy();
				}
			hscriptArray = [];
		}
		#end
    }

	#if HSCRIPT_ALLOWED
    public function loadStateScripts(name:String)
    {
		#if HSCRIPT_ALLOWED
		var doPush:Bool = false;
		var scriptFile:String = 'scripts/states/' + name + '.hx';
		#if MODS_ALLOWED
		var replacePath:String = Paths.modFolders(scriptFile);
		if(FileSystem.exists(replacePath))
		{
			scriptFile = replacePath;
			doPush = true;
		}
		else
		#end
		{
			scriptFile = Paths.getSharedPath(scriptFile);
			if(FileSystem.exists(scriptFile))
				doPush = true;
		}

		if(doPush)
		{
			if(!Iris.instances.exists(scriptFile)) initHScript(scriptFile);
		}
		#end
    }

	public function startHScriptsNamed(scriptFile:String)
	{
		#if MODS_ALLOWED
		var scriptToLoad:String = Paths.modFolders(scriptFile);
		if(!FileSystem.exists(scriptToLoad))
			scriptToLoad = Paths.getSharedPath(scriptFile);
		#else
		var scriptToLoad:String = Paths.getSharedPath(scriptFile);
		#end

		if(FileSystem.exists(scriptToLoad))
		{
			if (Iris.instances.exists(scriptToLoad)) return false;

			initHScript(scriptToLoad);
			return true;
		}
		return false;
	}

	public function initHScript(file:String)
	{
		var newScript:HScript = null;
		try
		{
			newScript = new HScript(null, file);
			if (newScript.exists('onCreate')) newScript.call('onCreate');
			trace('initialized hscript interp successfully: $file');
			hscript = newScript;
		}
		catch(e:IrisError)
		{
			var pos:HScriptInfos = cast {fileName: file, showLine: false};
			Iris.error(Printer.errorToString(e, false), pos);
			var existing:HScript = cast (Iris.instances.get(file), HScript);
			if(existing != null)
				existing.destroy();
			hscript = null;
		}
	}

	public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = [];
		if (hscriptArray != null)
		{
			for (script in hscriptArray)
			{
				if (script == null) continue;
				if (exclusions.contains(script.origin)) continue;
				script.set(variable, arg);
			}
		}
		if (hscript != null && !exclusions.contains(hscript.origin)) hscript.set(variable, arg);
		#end
	}

	public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;

		#if HSCRIPT_ALLOWED
		// If a substate is open, suspend calling HScript callbacks on the state
		if (subState != null)
			return returnVal;

		if(exclusions == null) exclusions = new Array();
		if(excludeValues == null) excludeValues = new Array();
		excludeValues.push(LuaUtils.Function_Continue);

		// First, try scripts in the array (if any)
		if (hscriptArray != null)
		{
			for (script in hscriptArray)
			{
				@:privateAccess
				if(script == null || !script.exists(funcToCall) || (exclusions != null && exclusions.contains(script.origin)))
					continue;

				var callValue = script.call(funcToCall, args);
				if(callValue != null)
				{
					var myValue:Dynamic = callValue.returnValue;

					if((myValue == LuaUtils.Function_StopHScript || myValue == LuaUtils.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
					{
						returnVal = myValue;
						break;
					}

					if(myValue != null && !excludeValues.contains(myValue))
						returnVal = myValue;
				}
			}
		}

		// Then single hscript fallback
		if (hscript != null && !((exclusions != null) && exclusions.contains(hscript.origin)) && hscript.exists(funcToCall))
		{
			var callValue2 = hscript.call(funcToCall, args);
			if(callValue2 != null)
			{
				var myValue2:Dynamic = callValue2.returnValue;

				if((myValue2 == LuaUtils.Function_StopHScript || myValue2 == LuaUtils.Function_StopAll) && !excludeValues.contains(myValue2) && !ignoreStops)
				{
					returnVal = myValue2;
				}

				if(myValue2 != null && !excludeValues.contains(myValue2))
					returnVal = myValue2;
			}
		}
		#end

		return returnVal;
	}
	#end

	#if (HSCRIPT_ALLOWED && LUA_ALLOWED)
	public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

		var result:Dynamic = PlayState.instance.callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if(result == null || excludeValues.contains(result)) result = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
		return result;
	}
	#end
}