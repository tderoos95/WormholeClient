class WormholePlugin extends Actor
    abstract;

var string PluginName;
var bool HasRemoteSettings; // Are settings are stored in Portal?
var EventGrid EventGrid;
var MutWormhole WormholeMutator;
var JsonObject PluginSettings;

public function OnInitialize()
{ }

public function OnPlayerConnected(string Ip, int PlayerIndex)
{ }

public function OnPlayerDisconnected(int PlayerIndex)
{ }

public function bool PreventReportChat(PlayerReplicationInfo PRI, coerce string Message, name Type)
{
    return false;
}