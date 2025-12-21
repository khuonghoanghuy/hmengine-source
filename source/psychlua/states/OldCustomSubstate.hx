package psychlua.states;

import flixel.FlxObject;

class OldCustomSubstate extends MusicBeatSubstate
{
	public static var name:String = 'unnamed';
	public static var instance:OldCustomSubstate;

	#if LUA_ALLOWED
	public static function implement(funk:FunkinLua)
	{
		var lua = funk.lua;
		Lua_helper.add_callback(lua, "openCustomSubstate", openCustomSubstate);
		Lua_helper.add_callback(lua, "closeCustomSubstate", closeCustomSubstate);
		Lua_helper.add_callback(lua, "insertToCustomSubstate", insertToCustomSubstate);
	}
	#end
	
	public static function openCustomSubstate(name:String, ?pauseGame:Bool = false)
	{
		if(pauseGame)
		{
			FlxG.camera.followLerp = 0;
			MusicBeatState.getState().persistentUpdate = false;
			MusicBeatState.getState().persistentDraw = true;
			if (PlayState.instance != null) {
				PlayState.instance.paused = true;
				if(FlxG.sound.music != null) {
					FlxG.sound.music.pause();
					PlayState.instance.vocals.pause();
				}
			}
		}
		MusicBeatState.getState().openSubState(new CustomSubstate(name));
	}

	public static function closeCustomSubstate()
	{
		if(instance != null)
		{
			MusicBeatState.getState().closeSubState();
			return true;
		}
		return false;
	}

	public static function insertToCustomSubstate(tag:String, ?pos:Int = -1)
	{
		if(instance != null)
		{
			var tagObject:FlxObject = cast (MusicBeatState.getVariables().get(tag), FlxObject);

			if(tagObject != null)
			{
				if(pos < 0) instance.add(tagObject);
				else instance.insert(pos, tagObject);
				return true;
			}
		}
		return false;
	}

	override function create()
	{
		instance = this;
		MusicBeatState.getState().setOnHScript('customSubstate', instance);


		MusicBeatState.getState().callOnScripts('onCustomSubstateCreate', [name]);
		super.create();
		MusicBeatState.getState().callOnScripts('onCustomSubstateCreatePost', [name]);
	}
	
	public function new(name:String)
	{
		OldCustomSubstate.name = name;
		MusicBeatState.getState().setOnHScript('customSubstateName', name);
		super();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}
	
	override function update(elapsed:Float)
	{
		MusicBeatState.getState().callOnScripts('onCustomSubstateUpdate', [name, elapsed]);
		super.update(elapsed);
		MusicBeatState.getState().callOnScripts('onCustomSubstateUpdatePost', [name, elapsed]);
	}

	override function destroy()
	{
		MusicBeatState.getState().callOnScripts('onCustomSubstateDestroy', [name]);
		instance = null;
		name = 'unnamed';

		MusicBeatState.getState().setOnHScript('customSubstate', null);
		MusicBeatState.getState().setOnHScript('customSubstateName', name);
		super.destroy();
	}
}
