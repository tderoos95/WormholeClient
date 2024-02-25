class WormholePlugin extends Actor
    abstract;

var EventGrid EventGrid;
var MutWormhole WormholeMutator;

public function OnInitialize()
{ }

public function OnPlayerConnected(string Ip, int PlayerIndex)
{ }

public function OnPlayerDisconnected(int PlayerIndex)
{ }

public function bool PreventReportChat(PlayerReplicationInfo PRI, out string Message, name Type)
{
    return false;
}

public function string FormatChatMessage(PlayerReplicationInfo PRI, coerce string Message, name Type)
{
    return Message;
}