class WormholeConnection extends TcpLink;

const EndOfMessageChar   = ""; // "\\u001e"; // "";
const EndOfMessageString = "\\r\\n";

var MutWormhole WormholeMutator;
var WormholeSettings Settings;
var string ServerHostName;
var IpAddr ServerAddress;

var bool bConnected;

// EventGrid subscribers
var WormholeEventGridSubscriber WormholeEventGridSubscriber;
var GametypeEventGridSubscriber GametypeEventGridSubscriber;

// EventGrid for debugging purposes
var EventGrid EventGrid;
var JsonObject DebugJson;

// Delegates
delegate OnTimeout();

event PostBeginPlay()
{
	Super.PostBeginPlay();
	LoadSettings();
	SpawnSubscribers();
}

function LoadSettings()
{
	WormholeMutator = MutWormhole(Owner);
	Settings = WormholeMutator.Settings;
}

function SpawnSubscribers()
{
	WormholeEventGridSubscriber = Spawn(class'WormholeEventGridSubscriber');
	GametypeEventGridSubscriber = Spawn(class'GametypeEventGridSubscriber');
	EventGrid = GametypeEventGridSubscriber.GetOrCreateEventGrid();
}


function SendDebugDataToEventGrid(string Topic, JsonObject Json)
{
	if(Settings.bDebug)
		EventGrid.SendEvent(Topic, Json);
}

function SetConnection(string Server, int Port)
{
	ServerHostName		= Server;
	ServerAddress.Port	= Port;
	
	Connect();
}

function Connect();

function Send(string Topic, JsonObject EventData)
{
    local string Data;
	local JsonObject Json;

	Json = new class'JsonObject';
	Json.AddString("Topic", Topic);
	Json.AddJson("Data", EventData);

    Data = Json.ToString();
    Data $= EndOfMessageChar;

	if(Settings.bDebug)
	{
		DebugJson = new class'JsonObject';
		DebugJson.AddString("Data", Data);
		SendDebugDataToEventGrid("wormhole/debug/sendtext", DebugJson);
	}

    SendText(Data);
}

event Closed()
{
	SendDebugDataToEventGrid("wormhole/debug/disconnected", None);
	GotoState('NotConnected');
}


auto state NotConnected
{
	function Connect()
	{
		if(ServerAddress.Addr != 0 && ServerAddress.Port > 0)
		{
			if(BindPort() == 0)
			{
				log("ERROR - Can't bind port for bot connection.", Name);
			}
			else
			{
				log("Attempting to connect to discord bot", Name);
				Open(ServerAddress);
			}
		}
		else if(ServerHostName != "" && ServerAddress.Port > 0)
		{
			SendDebugDataToEventGrid("wormhole/debug/resolving", None);
			Resolve(ServerHostName);
		}
		else
		{
			SendDebugDataToEventGrid("wormhole/debug/failed", None);
			log("ERROR - Missing server address or port.", Name);
		}
	}
	
	event Resolved(IpAddr Address)
	{
		SendDebugDataToEventGrid("wormhole/debug/resolved", None);

		if(Address.Addr != 0)
		{
			ServerAddress.Addr = Address.Addr;
			Connect();
		}
		else
			log("ERROR - Resolving resulted in 0.0.0.0", Name);
	}
	
	event ResolveFailed()
	{
		SendDebugDataToEventGrid("wormhole/debug/resolvefailed", None);
		log("ERROR - Could not resolve server address.", Name);
	}
	
	event Opened()
	{
		SendDebugDataToEventGrid("wormhole/debug/connected", None);
		GotoState('AwaitingHandshake');
	}
	
begin:
	if(Settings.bDebug)
	{
		DebugJson = new class'JsonObject';
		DebugJson.AddString("State", "NotConnected");
		SendDebugDataToEventGrid("wormhole/debug/statechanged", DebugJson);
	}
}

state AwaitingHandshake
{
	event ReceivedText(string Message)
	{
		local JsonObject Json;

		if(class'JsonConvert'.static.EndsWith(Message, EndOfMessageChar))
			Message = Left(Message, Len(Message) - 1);

		Json = class'JsonConvert'.static.Deserialize(Message);
		SendDebugDataToEventGrid("wormhole/debug/receivedtext", Json);
	}

	function SendHandshakeRequest()
	{

	}
	
Begin:
	log("Connection established", Name);

	if(Settings.bDebug)
	{
		DebugJson = new class'JsonObject';
		DebugJson.AddString("State", "AwaitingHandshake");
		SendDebugDataToEventGrid("wormhole/debug/statechanged", DebugJson);
	}

	SendHandshakeRequest();
}

state HandshakePerformed
{
	function SendAuthenticationRequest()
	{
		local JsonObject Json;

		Json = new class'JsonObject';
		Json.AddString("Token", Settings.Token);
		Send("authentication/request", Json);
	}

begin:
	log("Handshake performed", Name);

	if(Settings.bDebug)
	{
		DebugJson = new class'JsonObject';
		DebugJson.AddString("State", "HandshakePerformed");
		SendDebugDataToEventGrid("wormhole/debug/statechanged", DebugJson);
	}
}

state Authenticated
{
	event ReceivedText(string Message)
	{

	}
	
	event Closed()
	{
		GotoState('NotConnected');
	}
	
Begin:
	log("Succesfully authenticated by server", Name);

	if(Settings.bDebug)
	{
		DebugJson = new class'JsonObject';
		DebugJson.AddString("State", "Authenticated");
		SendDebugDataToEventGrid("wormhole/debug/statechanged", DebugJson);
	}
}


defaultproperties
{
	Name = 'WormholeBot'
}