class Plugin_Greeter extends WormholePlugin
    config(Wormhole);

var config string WelcomeMessage;
var config int WelcomeMessageDelay;

struct IPendingWelcomeMessage {
    var PlayerController PC;
    var float ScheduledSendTime;
};

var array<IPendingWelcomeMessage> PendingMessages;

function OnInitialize()
{
    if(WelcomeMessage == "")
    {
        Destroy();
        return;
    }

    SetTimer(1, true);
}

function OnPlayerConnected(string Ip, int PlayerIndex)
{
    StartWelcomeTimerFor(WormholeMutator.Players[PlayerIndex].PC);
}

function StartWelcomeTimerFor(PlayerController PC)
{
    PendingMessages.Insert(0, 1);
    PendingMessages[0].PC = PC;
    PendingMessages[0].ScheduledSendTime = Level.TimeSeconds + WelcomeMessageDelay;
}

function Timer()
{
    ProcessWelcomeMessages();
}

function ProcessWelcomeMessages()
{
    local PlayerController PC;
    local int i;

    for(i = 0; i < PendingMessages.Length; ++i)
    {
        if(PendingMessages[i].ScheduledSendTime <= Level.TimeSeconds)
        {
            PC = PendingMessages[i].PC;
            PendingMessages.Remove(i, 1);
            i--;

            if(PC != None)
                SendWelcomeMessageTo(PC);
        }
    }
}

function SendWelcomeMessageTo(PlayerController PC)
{
    local PlayerReplicationInfo SenderPri;

    if(WormholeMutator.ChatSpectator == None)
        return;

    SenderPri = WormholeMutator.ChatSpectator.PlayerReplicationInfo;
    
    if(Level.Game.BroadcastHandler != None && SenderPri != None)
        Level.Game.BroadcastHandler.BroadcastText(SenderPri, PC, WelcomeMessage, 'Say');
}

defaultproperties
{
    WelcomeMessage="Hello and welcome to the server! Please be aware that all chat messages are being sent to Discord. If you have any questions, feel free to ask!"
    WelcomeMessageDelay=30
} 