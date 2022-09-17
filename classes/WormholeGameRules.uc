class WormholeGameRules extends GameRules;

var MutWormhole WormholeMutator;
var EventGrid EventGrid;

var string PlayerSuicided;
var string StringSuicide;
var string StringSuicideDrowned;
var string StringSuicideFell;
var string StringSuicideLava;

struct PendingKill {
	var Controller Killed;
	var Controller Killer;
	var class<DamageType> DamagaType;
};

var array<PendingKill> PendingKills;

function PreBeginPlay()
{
    Super.PreBeginPlay();
    WormholeMutator = MutWormhole(Owner);
    EventGrid = WormholeMutator.EventGrid;
}

function bool PreventDeath(Pawn KilledPawn, Controller Killer, class<DamageType> DamageType, vector HitLocation)
{
	// Queue the kill for later processing
	QueuePendingKill(KilledPawn.Controller, Killer, DamageType);

	return Super.PreventDeath(KilledPawn, Killer, DamageType, HitLocation);
}

function QueuePendingKill(Controller Killed, Controller Killer, class<DamageType> DamageType)
{
	local int NewIndex;
	
	// Queue the kill for later processing
	NewIndex = PendingKills.Length;
	PendingKills.Length = NewIndex + 1;

	PendingKills[NewIndex].Killed = Killed;
	PendingKills[NewIndex].Killer = Killer;
	PendingKills[NewIndex].DamagaType = DamageType;
}

function PendingKill DequeuPendingKill(Controller Killed, Controller Killer)
{
	local int i;
	local PendingKill PendingKill;
	
	for (i = 0; i < PendingKills.length; i++)
	{
		if (PendingKills[i].Killed == Killed && PendingKills[i].Killer == Killer)
		{
			PendingKill = PendingKills[i];
			PendingKills.Remove(i, 1);
		}
	}
	
	return PendingKill;
}

function ScoreKill(Controller Killer, Controller Killed)
{
	local PendingKill PendingKill;

    if (PlayerController(Killed) != None)
	{
		PendingKill = DequeuPendingKill(Killed, Killer);

		if(PendingKill.DamagaType != None)
		{
			OnPlayerKilled(Killer, PlayerController(Killed), PendingKill.DamagaType);
			PendingKills.Remove(PendingKills.Length - 1, 1);
		}
	}

    if (NextGameRules != None)
		NextGameRules.ScoreKill(Killer,Killed);
}

function OnPlayerKilled(Controller Killer, PlayerController Killed, class<DamageType> DamageType)
{
	local string DeathMessage;
	local JsonObject Json;
    local PlayerController KillerPC;
	
    // Prepare death message pt I
	if(Killer == None || Killer == Killed)
	{
		DeathMessage = PlayerSuicided;
			
		if (class<FellLava>(DamageType) != None)
			DeathMessage = Repl(DeathMessage, "%s", StringSuicideLava);
		else if (class<Fell>(DamageType) != None)
			DeathMessage = Repl(DeathMessage, "%s", StringSuicideFell);
		else if (class<Drowned>(DamageType) != None)
			DeathMessage = Repl(DeathMessage, "%s", StringSuicideDrowned);
		else
			DeathMessage = Repl(DeathMessage, "%s", StringSuicide);
	}
	else
	{
		DeathMessage = DamageType.default.DeathString;
		
		if(Killer.PlayerReplicationInfo != None)
			DeathMessage = Repl(DeathMessage, "%k", Killer.PlayerReplicationInfo.PlayerName);
		else if(Killer.Pawn != None && Len(Killer.Pawn.MenuName) > 0)
			DeathMessage = Repl(DeathMessage, "%k", Killer.Pawn.MenuName);
		else
			DeathMessage = Repl(DeathMessage, "%k", Killer.Name);
	}

    // Prepare death message pt II
	DeathMessage = Repl(DeathMessage, "%o", Killed.PlayerReplicationInfo.PlayerName);

	Json = new class'JsonObject';
    Json.AddString("KilledId", Killed.GetPlayerIDHash());
    Json.AddString("KilledName", Killer.PlayerReplicationInfo.PlayerName);


    KillerPC = PlayerController(Killer);
    if(KillerPC != None)
    {
        Json.AddString("KillerId", KillerPC.GetPlayerIDHash());
        Json.AddString("KillerName", KillerPC.PlayerReplicationInfo.PlayerName);
    }

    // Send player death message
    Json.AddString("DeathMessage", DeathMessage);
    EventGrid.SendEvent("player/died", Json);

    // Send player OUT
	if (Killed.PlayerReplicationInfo != None && Killed.PlayerReplicationInfo.bOutOfLives)
	{
        Json = new class'JsonObject';
        Json.AddString("PlayerId", Killed.GetPlayerIDHash());
        Json.AddString("PlayerName", Killed.PlayerReplicationInfo.PlayerName);
        EventGrid.SendEvent("player/out", Json);
	}
}

defaultproperties
{
    PlayerSuicided="%o %s"
    StringSuicide="suicided"
    StringSuicideDrowned="drowned"
    StringSuicideFell="left a small crater"
    StringSuicideLava="crashed and burned"
}