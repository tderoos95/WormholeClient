class Plugin_PrivacyFilter extends WormholePlugin;

var string Prefix;
var bool EnableColoredPrefix;

function OnInitialize()
{
    local string NewPrefix;
    local bool NewEnableColoredPrefix;

    log("Plugin_PrivacyFilter: Initializing plugin");

    if(PluginSettings == None)
    {
        log("Plugin_PrivacyFilter: PluginSettings is None");
        return;
    }

    NewPrefix = PluginSettings.GetString("Prefix");

    if(NewPrefix != "")
    {
        log("Plugin_PrivacyFilter: Loading Prefix from settings: " $ NewPrefix);
        Prefix = NewPrefix;
    }

    if(PluginSettings.HasValue("EnableColoredPrefix"))
    {
        NewEnableColoredPrefix = PluginSettings.GetBool("EnableColoredPrefix");
        log("Plugin_PrivacyFilter: Loading EnableColoredPrefix from settings: " $ NewEnableColoredPrefix);
        EnableColoredPrefix = NewEnableColoredPrefix;
    }

    log("Plugin_PrivacyFilter: Plugin initialized");
}

function function bool PreventReportChat(PlayerReplicationInfo PRI, coerce string Message, name Type)
{
    if(Left(Message, 2) ~= Prefix)
        return false;
    return true;
}

defaultproperties {
    PluginName="PrivacyFilter"
    Prefix="!d"
    EnableColoredPrefix=False
}