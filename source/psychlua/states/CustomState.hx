package psychlua.states;

class CustomState extends MusicBeatState
{
    public function new(nameState:String) {
        super();

        loadStateScripts(nameState);
    }
}