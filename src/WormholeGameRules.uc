class WormholeGameRules extends GameRules;

var MutWormhole WormholeMutator;
var EventGrid EventGrid;

var string PlayerSuicided;
var string StringSuicide;
var string StringSuicideDrowned;
var string StringSuicideFell;
var string StringSuicideLava;

var struct PendingKill {
	var Controller Killed;
	var Controller Killer;
	var class<DamageType> DamageType;
} QueuedKill;

var bool bFirstBlood;

function PreBeginPlay()
{
    Super.PreBeginPlay();
    WormholeMutator = MutWormhole(Owner);
    EventGrid = WormholeMutator.EventGrid;
}

function bool PreventDeath(Pawn KilledPawn, Controller Killer, class<DamageType> DamageType, vector HitLocation)
{
	if(KilledPawn == None)
		return Super.PreventDeath(KilledPawn, Killer, DamageType, HitLocation);;

	// Queue the kill for later processing, any mutator in the chain can still call it off at this point
	QueuedKill.Killed = KilledPawn.Controller;
	QueuedKill.Killer = Killer;
	QueuedKill.DamageType = DamageType;

	return Super.PreventDeath(KilledPawn, Killer, DamageType, HitLocation);
}

function ScoreKill(Controller Killer, Controller Killed)
{
	// Now that we are sure the playuer is killed, we can process the kill
	// (Queueing it first is a workaround to know the DamageType of the kill)
    if (PlayerController(Killed) != None)
	{
		if(QueuedKill.DamageType != None)
		{
			OnPlayerKilled(Killer, PlayerController(Killed), QueuedKill.DamageType);
		}
	}

	// Check whether this is first actual kill
	if (PlayerController(Killer) != None && Killer != Killed)
	{
		if (bFirstBlood)
		{
			bFirstBlood = false;
			OnFirstBlood(PlayerController(Killer));
		}
	}

    if (NextGameRules != None)
		NextGameRules.ScoreKill(Killer, Killed);
}

function OnPlayerKilled(Controller Killer, PlayerController Killed, class<DamageType> DamageType)
{
	local string DeathMessage;
	local JsonObject Json;
    local PlayerController KillerPC;
	local string KilledPlayerId, KillerPlayerId;
	local bool bSuicide;
	
    // Prepare death message pt I
	if(Killer == None || Killer == Killed)
	{
		bSuicide = true;
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
	else if(Killer != None)
	{
		DeathMessage = DamageType.default.DeathString;
		
		if(Killer.PlayerReplicationInfo != None)
			DeathMessage = Repl(DeathMessage, "%k", Killer.PlayerReplicationInfo.PlayerName);
		else if(Killer.Pawn != None && Len(Killer.Pawn.MenuName) > 0)
			DeathMessage = Repl(DeathMessage, "%k", Killer.Pawn.MenuName);
		else
			DeathMessage = Repl(DeathMessage, "%k", Killer.Name);
	}


	// PlayerIdHash changes when player disconnects, retrieve stored value instead
    KilledPlayerId = WormholeMutator.GetStoredPlayerIdHash(Killed.GetHumanReadAbleName());
	DeathMessage = Repl(DeathMessage, "%o", Killed.PlayerReplicationInfo.PlayerName);

	Json = new class'JsonObject';
    Json.AddString("KilledId", KilledPlayerId);
    Json.AddString("KilledName", class'Utils'.static.StripIllegalCharacters(Killed.PlayerReplicationInfo.PlayerName));


    KillerPC = PlayerController(Killer);
    if(KillerPC != None)
    {
    	KillerPlayerId = WormholeMutator.GetStoredPlayerIdHash(KillerPC.GetHumanReadAbleName());
        Json.AddString("KillerId", KillerPlayerId);
        Json.AddString("KillerName", class'Utils'.static.StripIllegalCharacters(KillerPC.PlayerReplicationInfo.PlayerName));
    }

    // Send player death message
    Json.AddString("DeathMessage", class'Utils'.static.StripIllegalCharacters(DeathMessage));

	if (bSuicide)
		EventGrid.SendEvent("player/suicided", Json);
	else EventGrid.SendEvent("player/died", Json);

    // Send player OUT
	if (Killed.PlayerReplicationInfo != None && Killed.PlayerReplicationInfo.bOutOfLives)
		OnPlayerOut(Killed);
}

function OnPlayerOut(PlayerController Player)
{
	local JsonObject Json;

	Json = new class'JsonObject';
	Json.AddString("PlayerId", Player.GetPlayerIDHash());
	Json.AddString("PlayerName", class'Utils'.static.StripIllegalCharacters(Player.PlayerReplicationInfo.PlayerName));
	EventGrid.SendEvent("player/out", Json);
}

function OnFirstBlood(PlayerController Killer)
{
	local JsonObject Json;

	Json = new class'JsonObject';
	Json.AddString("PlayerId", Killer.GetPlayerIDHash());
	Json.AddString("PlayerName", class'Utils'.static.StripIllegalCharacters(Killer.PlayerReplicationInfo.PlayerName));
	EventGrid.SendEvent("match/firstblood", Json);
}

defaultproperties
{
	bFirstBlood=true
    PlayerSuicided="%o %s"
    StringSuicide="suicided"
    StringSuicideDrowned="drowned"
    StringSuicideFell="left a small crater"
    StringSuicideLava="crashed and burned"
}