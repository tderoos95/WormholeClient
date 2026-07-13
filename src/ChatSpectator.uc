class ChatSpectator extends MessagingSpectator;

var MutWormhole WormholeMutator;
var string SpectatorName;
var ChatSpectatorEventBusSubscriber SpectatorEventBusSubscriber;
var EventBus EventBus;

event PreBeginPlay()
{
	Super.PreBeginPlay();
	
	WormholeMutator = MutWormhole(Owner);

	SpectatorEventBusSubscriber = Spawn(class'ChatSpectatorEventBusSubscriber', self);
	EventBus = SpectatorEventBusSubscriber.GetOrCreateEventBus();
	SpectatorName = WormholeMutator.Settings.ChatSpectatorName;

	EventBus.SendEvent("wormhole/chatspectator/chatspecator_name_" $ SpectatorName, None);
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
	Json.AddString("PlayerName", class'JsonLib.JsonUtils'.static.StripIllegalCharacters(PRI.PlayerName));
	Json.AddString("Message", class'JsonLib.JsonUtils'.static.StripIllegalCharacters(FormattedMessage));
	EventBus.SendEvent("player/chat", Json);
}

defaultproperties
{
	SpectatorName = "Discord";
}