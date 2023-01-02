class ChatSpectator extends MessagingSpectator;

var MutWormhole WormholeMutator;
var string SpectatorName;
var ChatSpectatorEventGridSubscriber SpectatorEventGridSubscriber;
var EventGrid EventGrid;

event PreBeginPlay()
{
	Super.PreBeginPlay();
	
	WormholeMutator = MutWormhole(Owner);

	SpectatorEventGridSubscriber = Spawn(class'ChatSpectatorEventGridSubscriber', self);
	EventGrid = SpectatorEventGridSubscriber.GetOrCreateEventGrid();
	SpectatorName = WormholeMutator.Settings.ChatSpectatorName;

	EventGrid.SendEvent("wormhole/chatspectator/chatspecator_name_" $ SpectatorName, None);
	PlayerReplicationInfo.PlayerName = SpectatorName;
}

function InitPlayerReplicationInfo()
{
	Super.InitPlayerReplicationInfo();
	PlayerReplicationInfo.PlayerName = SpectatorName;
}

function TeamMessage(PlayerReplicationInfo PRI, coerce string Message, name Type)
{
	local JsonObject Json;

	if(Type == 'Say' && PRI != None && PRI != PlayerReplicationInfo && WormholeMutator != None)
	{
		Json = new class'JsonObject';
		Json.AddString("PlayerId", PlayerController(PRI.Owner).GetPlayerIdHash());
		Json.AddString("PlayerName", PRI.PlayerName);
		Json.AddString("Message", Message);

		EventGrid.SendEvent("player/chat", Json);
	}
}

defaultproperties
{
	SpectatorName = "Discord";
}