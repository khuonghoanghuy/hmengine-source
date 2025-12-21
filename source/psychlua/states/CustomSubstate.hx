package psychlua.states;

class CustomSubstate extends MusicBeatSubstate
{
    var _prevPersistent:Bool = false;

    public function new(name:String) {
        super();

        var state = MusicBeatState.getState();
        if (state != null) {
            _prevPersistent = state.persistentUpdate;
            state.persistentUpdate = false;
        }

        loadSubstateScripts(name);
    }

    override function closeSubState() {
        var state = MusicBeatState.getState();
        if (state != null) state.persistentUpdate = _prevPersistent;
        super.closeSubState();
    }

    override function close() {
        var state = MusicBeatState.getState();
        if (state != null) state.persistentUpdate = _prevPersistent;
        super.close();
    }

    override function destroy() {
        var state = MusicBeatState.getState();
        if (state != null) state.persistentUpdate = _prevPersistent;
        super.destroy();
    }
}