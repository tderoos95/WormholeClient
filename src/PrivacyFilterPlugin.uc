class PrivacyFilterPlugin extends WormholePlugin;

var string Prefix;
var bool EnableColoredPrefix;

function PreBeginPlay()
{
    log("PrivacyFilterPlugin PreBeginPlay");
    log("PrivacyFilterPlugin PreBeginPlay");
    log("PrivacyFilterPlugin PreBeginPlay");
    log("PrivacyFilterPlugin PreBeginPlay");
    log("PrivacyFilterPlugin PreBeginPlay");
}


function OnInitialize()
{
    log("PrivacyFilterPlugin initialized");
    log("PrivacyFilterPlugin initialized");
    log("PrivacyFilterPlugin initialized");
    log("PrivacyFilterPlugin initialized");
    log("PrivacyFilterPlugin initialized");
    log("PrivacyFilterPlugin initialized");
    log("PrivacyFilterPlugin initialized");
}

function function bool PreventReportChat(PlayerReplicationInfo PRI, coerce string Message, name Type)
{
    log("PrivacyFilterPlugin PreventReportChat: " $ Message);
    
    if(Left(Message, 2) ~= Prefix)
        return false;
    return true;
}

defaultproperties {
    PluginName="PrivacyFilter"
    Prefix="!d"
    EnableColoredPrefix=False
}