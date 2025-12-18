package options;

class ModdingSettingsSubState extends BaseOptionsMenu
{
    public function new() {
		title = Language.getPhrase('modding_menu', 'Modding Settings');
		rpcTitle = 'Modding Settings Menu'; //for Discord Rich Presence

		var option:Option = new Option('Allow Console',
			'If checked, when pressing "OPEN CONSOLE" key, is will pop up a new console window.',
			'allowConsole',
			BOOL);
		addOption(option);

        super();
    }
}