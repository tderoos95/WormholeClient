class ConnectionEventGridSubscriber extends WormholeEventGridSubscriber;

// Connection topics
const AuthenticationResponse   = "wormhole/authentication/response";
const ConnectionAttempt        = "wormhole/connection/attempt";
const ConnectionEstablished    = "wormhole/connection/established";
const ConnectionLost           = "wormhole/connection/lost";

// Timer elapse topics
const ConnectionTimeOutTimer   = "wormhole/connection/timer/timeout";
const ReconnectTimer           = "wormhole/connection/timer/reconnect";

var EventGridTimerController TimerController; 
var WormholeSettings Settings;

function PostBeginPlay()
{
    Super.PostBeginPlay();
    TimerController = WormholeConnection.WormholeMutator.TimerController;
    Settings = WormholeConnection.WormholeMutator.Settings;
}

function ProcessEvent(string Topic, JsonObject Json)
{
    if(Topic ~= AuthenticationResponse)
        ProcessAuthenticationResponse(Json);
    else if(Topic ~= ConnectionAttempt)
        OnConnectionAttempt();
    else if(Topic ~= ConnectionEstablished)
        OnConnectionEstablished();
    else if(Topic ~= ConnectionLost)
        OnConnectionLost();
    else if(Topic ~= ConnectionTimeOutTimer)
        OnTimeoutElapsed();
    else if(Topic ~= ReconnectTimer)
        OnReconnectTimerElapsed();
}

function ProcessAuthenticationResponse(JsonObject Json)
{
    if(!WormholeConnection.IsInState('AwaitingAuthentication'))
        return;
    
    if(Json.GetBool("Success"))
    {
        WormholeConnection.GotoState('Authenticated');
        log("Authentication successful", 'Wormhole');
    }
    else
    {
        WormholeConnection.GotoState('NotConnected');
        log("Authentication failed, disconnecting...", 'Wormhole');
    }
}

function OnConnectionAttempt()
{
    if(Settings.ConnectTimeout > 0)
        TimerController.CreateTimer(ConnectionTimeOutTimer, Settings.ConnectTimeout);
}

function OnConnectionEstablished()
{
    TimerController.DestroyTimer(ConnectionTimeOutTimer);
    TimerController.DestroyTimer(ReconnectTimer);
}

function OnConnectionLost()
{
    log("Connection to wormhole remote server lost", 'Wormhole');

    if(Settings.bAutoReconnect)
    {
        log("Attempting to reconnect in " $ Settings.ReconnectInterval $ " seconds", 'Wormhole');
        TimerController.CreateTimer(ReconnectTimer, Settings.ReconnectInterval);
    }
}

function OnTimeoutElapsed()
{
    log("Connection to wormhole remote server timed out.", 'Wormhole');

    if(Settings.bAutoReconnect)
    {
        log("Attempting to reconnect in " $ Settings.ReconnectInterval $ " seconds", 'Wormhole');
        TimerController.CreateTimer(ReconnectTimer, Settings.ReconnectInterval);
    }
}

function OnReconnectTimerElapsed()
{
    log("Attempting to reconnect...", 'Wormhole');
    WormholeConnection.Reconnect();
}

defaultproperties
{
    SubscriptionTopics(0)="wormhole/authentication/response";   // AuthenticationResponse
    SubscriptionTopics(1)="wormhole/connection/";               // Connection wildcard for all wormhole/connection type events
}