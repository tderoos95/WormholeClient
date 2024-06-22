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
}

function InitPlayerReplicationInfo()
{
	Super.InitPlayerReplicationInfo();
	PlayerReplicationInfo.PlayerName = SpectatorName;
}

function TeamMessage(PlayerReplicationInfo PRI, coerce string Message, name Type)
{
	if(Type == 'Say' && PRI != None && PRI != PlayerReplicationInfo && WormholeMutator != None)
		HandleChat(PRI, Message, Type);
}

function HandleChat(PlayerReplicationInfo PRI, coerce string Message, name Type)
{
	local JsonObject Json;
	local string FormattedMessage;

	if(WormholeMutator.PreventReportChat(PRI, Message, Type))
		return;

	FormattedMessage = WormholeMutator.FormatChatMessage(PRI, Message, Type);

	Json = new class'JsonObject';
	Json.AddString("PlayerId", PlayerController(PRI.Owner).GetPlayerIdHash());
	Json.AddString("PlayerName", class'Utils'.static.StripIllegalCharacters(PRI.PlayerName));
	Json.AddString("Message", class'Utils'.static.StripIllegalCharacters(FormattedMessage));
	EventGrid.SendEvent("player/chat", Json);
}

defaultproperties
{
	SpectatorName = "Discord";
}