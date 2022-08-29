class ChatSpectator extends MessagingSpectator;

var MutWormhole WormholeMutator;
var string SpectatorName;

event PostBeginPlay()
{
	Super.PostBeginPlay();
	
	WormholeMutator = MutWormhole(Owner);
	SpectatorName = WormholeMutator.Settings.ChatSpectatorName;
	PlayerReplicationInfo.PlayerName = SpectatorName;
}

function InitPlayerReplicationInfo()
{
	Super.InitPlayerReplicationInfo();
	PlayerReplicationInfo.PlayerName = SpectatorName;
}

function TeamMessage(PlayerReplicationInfo PRI, coerce string Message, name Type)
{
	if(Type == 'Say' && PRI != None && PRI != PlayerReplicationInfo && WormholeMutator != None)
	{
        // todo use event grid
		//WormholeMutator.OnIngameChat(PRI, Message);
	}
}

defaultproperties
{
	SpectatorName = "Discord";
}