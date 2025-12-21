package backend;

import flixel.FlxSubState;
#if HSCRIPT_ALLOWED
import psychlua.*;
import psychlua.HScript.HScriptInfos;
import crowplexus.iris.Iris;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
#end

class ScriptedSubstate extends FlxSubState
{
    #if HSCRIPT_ALLOWED
    public var hscript:HScript = null;
    #end

    public var parentState:MusicBeatSubstate;
    
    override function create() {
        super.create();

        loadSubstateScripts(Type.getClassName(Type.getClass(this)).split('.').pop());
        
        #if HSCRIPT_ALLOWED
        if(hscript != null && hscript.exists('onCreate')) hscript.call('onCreate');
        #end
    }
    
    override function update(elapsed:Float) {
        super.update(elapsed);
        
        #if HSCRIPT_ALLOWED
        if(hscript != null && hscript.exists('onUpdate')) hscript.call('onUpdate', [elapsed]);
        #end
    }
    
    override function destroy() {
        #if HSCRIPT_ALLOWED
        if (hscript != null)
        {
            if(hscript.exists('onDestroy')) hscript.call('onDestroy');
            hscript.destroy();
            hscript = null;
        }
        #end
        
        super.destroy();
    }
    
    #if HSCRIPT_ALLOWED
    public function loadSubstateScripts(name:String)
    {
        var doPush:Bool = false;
        var scriptFile:String = 'scripts/substates/' + name + '.hx';
        
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
    }
    
    public function startHScriptsNamed(scriptFile:String):Bool
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
        if (hscript != null && !exclusions.contains(hscript.origin)) hscript.set(variable, arg);
        #end
    }
    
    public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
        var returnVal:Dynamic = LuaUtils.Function_Continue;
        
        #if HSCRIPT_ALLOWED
        if(exclusions == null) exclusions = [];
        if(excludeValues == null) excludeValues = [];
        excludeValues.push(LuaUtils.Function_Continue);

        if (hscript == null) return returnVal;

        @:privateAccess
        if(hscript == null || !hscript.exists(funcToCall) || (exclusions != null && exclusions.contains(hscript.origin)))
            return returnVal;

        var callValue = hscript.call(funcToCall, args);
        if(callValue != null)
        {
            var myValue:Dynamic = callValue.returnValue;

            if((myValue == LuaUtils.Function_StopHScript || myValue == LuaUtils.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
            {
                returnVal = myValue;
            }

            if(myValue != null && !excludeValues.contains(myValue))
                returnVal = myValue;
        }
        #end
        return returnVal;
    }
    #end

    override function closeSubState() {
        #if HSCRIPT_ALLOWED
        if (hscript != null)
        {
            hscript.destroy();
            hscript = null;
        }
        #end

        super.closeSubState();
    }

    override function close() {
        #if HSCRIPT_ALLOWED
        if (hscript != null)
        {
            hscript.destroy();
            hscript = null;
        }
        #end

        super.close();
    }
}