class ConnectionEventGridSubscriber extends WormholeEventGridSubscriber;

// Connection topics
const AuthenticationResponse   = "wormhole/authentication/response";
const ConnectionAttempt        = "wormhole/connection/attempt";
const ConnectionFailed         = "wormhole/connection/failed";
const ConnectionEstablished    = "wormhole/connection/established";
const ConnectionLost           = "wormhole/connection/lost";

// Timer elapse topics
const ConnectionTimeOutTimer = "wormhole/connection/timer/timeout";
const ReconnectTimer         = "wormhole/connection/timer/reconnect";

var EventGridTimerController TimerController; 
var WormholeSettings Settings;

function PreBeginPlay()
{
    Super.PreBeginPlay();
    TimerController = WormholeConnection.WormholeMutator.TimerController;
    Settings = WormholeConnection.WormholeMutator.Settings;
}

function ProcessEvent(string Topic, JsonObject Json)
{
    if(Topic ~= AuthenticationResponse)
        ProcessAuthenticationResponse(Json);
    else if(Topic ~= ConnectionAttempt)
        OnConnectionAttempt();
    else if(Topic ~= ConnectionFailed)
        OnConnectionFailed();
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
    TimerController.CreateTimer(ConnectionTimeOutTimer, Settings.ConnectTimeout);
}

function OnConnectionFailed()
{
    TimerController.CreateTimer(ReconnectTimer, Settings.ReconnectInterval);
}

function OnConnectionEstablished()
{
    TimerController.DestroyTimer(ConnectionTimeOutTimer);
    TimerController.DestroyTimer(ReconnectTimer);
}

function OnConnectionLost()
{
    TimerController.CreateTimer(ReconnectTimer, Settings.ReconnectInterval);
}

function OnTimeoutElapsed()
{
    if(WormholeConnection.IsInState('Connected'))
        return;
    
    log("Connection timed out, disconnecting...", 'Wormhole');
    WormholeConnection.GotoState('NotConnected');

    // todo set reconnect timer
}

function OnReconnectTimerElapsed()
{
    if(WormholeConnection.IsInState('Connected'))
        return;
    
    WormholeConnection.GotoState('NotConnected');
    log("Reconnecting...", 'Wormhole');
    
    // todo connect
}

defaultproperties
{
    SubscriptionTopics(0)="wormhole/authentication/response";   // AuthenticationResponse
    SubscriptionTopics(1)="wormhole/connection/";               // Connection wildcard for all wormhole/connection type events
}