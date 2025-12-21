package psychlua.states;

class CustomSubstate extends MusicBeatSubstate
{
    public function new(name:String) {
        super();

        loadSubstateScripts(name);
    }

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