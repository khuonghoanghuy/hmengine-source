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
    public var hscriptArray:Array<HScript> = [];
    #end

    public var parentState:MusicBeatSubstate;
    
    override function create() {
        super.create();

        loadSubstateScripts(Type.getClassName(Type.getClass(this)).split('.').pop());
        
        #if HSCRIPT_ALLOWED
        for (script in hscriptArray)
            if(script != null && script.exists('onCreate'))
                script.call('onCreate');
        #end
    }
    
    override function update(elapsed:Float) {
        super.update(elapsed);
        
        #if HSCRIPT_ALLOWED
        for (script in hscriptArray)
            if(script != null && script.exists('onUpdate'))
                script.call('onUpdate', [elapsed]);
        #end
    }
    
    override function destroy() {
        #if HSCRIPT_ALLOWED
        for (script in hscriptArray)
            if(script != null)
            {
                if(script.exists('onDestroy')) script.call('onDestroy');
                script.destroy();
            }
        hscriptArray = null;
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
            if(Iris.instances.exists(scriptFile))
                doPush = false;

            if(doPush) initHScript(scriptFile);
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
            hscriptArray.push(newScript);
        }
        catch(e:IrisError)
        {
            var pos:HScriptInfos = cast {fileName: file, showLine: false};
            Iris.error(Printer.errorToString(e, false), pos);
            var newScript:HScript = cast (Iris.instances.get(file), HScript);
            if(newScript != null)
                newScript.destroy();
        }
    }
    
    public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
        #if HSCRIPT_ALLOWED
        if(exclusions == null) exclusions = [];
        for (script in hscriptArray) {
            if(exclusions.contains(script.origin))
                continue;
            script.set(variable, arg);
        }
        #end
    }
    
    public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
        var returnVal:Dynamic = LuaUtils.Function_Continue;
        
        #if HSCRIPT_ALLOWED
        if(exclusions == null) exclusions = [];
        if(excludeValues == null) excludeValues = [];
        excludeValues.push(LuaUtils.Function_Continue);

        var len:Int = hscriptArray.length;
        if (len < 1)
            return returnVal;

        for(script in hscriptArray)
        {
            @:privateAccess
            if(script == null || !script.exists(funcToCall) || exclusions.contains(script.origin))
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
        #end
        return returnVal;
    }
    #end

    override function closeSubState() {
        #if HSCRIPT_ALLOWED
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

        super.closeSubState();
    }

    override function close() {
        #if HSCRIPT_ALLOWED
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

        super.close();
    }
}