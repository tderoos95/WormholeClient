class WormholePlugin extends Actor
    abstract;

var string PluginName;
var bool HasRemoteSettings; // settings are stored in Portal
var EventGrid EventGrid;
var MutWormhole WormholeMutator;
var JsonObject PluginSettings;

public function OnInitialize()
{
}

public function Mutate(string Command, PlayerController PC)
{ }

public function OnPlayerConnected(string Ip, int PlayerIndex)
{ }

public function OnPlayerDisconnected(int PlayerIndex)
{ }

public function ModifyPlayer(Pawn Other)
{ }

public function bool PreventReportChat(PlayerReplicationInfo PRI, coerce string Message, name Type)
{
    return false;
}