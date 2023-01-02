class ConnectionEventGridSubscriber extends WormholeEventGridSubscriber;

// Connection topics
const AuthenticationResponse     = "wormhole/authentication/response";
const ConnectionAttempt          = "wormhole/connection/attempt";
const ConnectionEstablished      = "wormhole/connection/established";
const ConnectionLost             = "wormhole/connection/lost";

// Internal
const SuccessfullyAuthenticated  = "wormhole/internal/authenticated";

// Timer elapse topics
const ConnectionTimeOutTimer     = "wormhole/connection/timer/timeout";
const ReconnectTimer             = "wormhole/connection/timer/reconnect";

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
        HandleConnectionAttempt();
    else if(Topic ~= ConnectionEstablished)
        HandleConnectionEstablished();
    else if(Topic ~= ConnectionLost)
        HandleConnectionLost();
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
        HandleAuthenticationSuccessful();
    }
    else
    {
        WormholeConnection.GotoState('NotConnected');
        log("Authentication failed, disconnecting...", 'Wormhole');
    }
}

function HandleAuthenticationSuccessful()
{
    EventGrid.SendEvent(SuccessfullyAuthenticated, None);
}

function HandleConnectionAttempt()
{
    if(Settings.ConnectTimeout > 0)
        TimerController.CreateTimer(ConnectionTimeOutTimer, Settings.ConnectTimeout);
}

function HandleConnectionEstablished()
{
    TimerController.DestroyTimer(ConnectionTimeOutTimer);
    TimerController.DestroyTimer(ReconnectTimer);
}

function HandleConnectionLost()
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