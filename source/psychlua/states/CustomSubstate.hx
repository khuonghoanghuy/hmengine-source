package psychlua.states;

class CustomSubstate extends MusicBeatSubstate
{
    public function new(name:String) {
        super();

        loadSubstateScripts(name);
    }
}