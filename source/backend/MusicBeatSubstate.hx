package backend;

import flixel.FlxSubState;

class MusicBeatSubstate extends ScriptedSubstate
{
	public function new()
	{
		super();

		if (parentState != null)
			parentState.active = true;
	}

	override function close() {
		// Reactivate the parent state when this substate closes
		if (parentState != null)
			parentState.active = true;
		
		super.close();
	}

	override function closeSubState() {
		// Reactivate the parent state when this substate closes
		if (parentState != null)
			parentState.active = true;
		
		super.closeSubState();
	}

	override function destroy() {
		// Make sure to reactivate parent state on destroy too
		if (parentState != null && !parentState.active)
			parentState.active = true;
		
		super.destroy();
	}

	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return Controls.instance;

	override function update(elapsed:Float)
	{
		//everyStep();
		if(!persistentUpdate) MusicBeatState.timePassedOnState += elapsed;
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if(curStep > 0)
				stepHit();

			if(PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}

		super.update(elapsed);
	}

	private function updateSection():Void
	{
		if(stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while(curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if(curStep < 0) return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if(stepsToDo > curStep) break;
				
				curSection++;
			}
		}

		if(curSection > lastSection) sectionHit();
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep/4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public function stepHit():Void
	{
		#if HSCRIPT_ALLOWED
		if (hscript != null && hscript.exists('onStepHit')) hscript.call('onStepHit', []);
		#end

		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		#if HSCRIPT_ALLOWED
		if (hscript != null && hscript.exists('onBeatHit')) hscript.call('onBeatHit', []);
		#end
	}
	
	public function sectionHit():Void
	{
		#if HSCRIPT_ALLOWED
		if (hscript != null && hscript.exists('onSectionHit')) hscript.call('onSectionHit', []);
		#end
	}
	
	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if(PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}
}
