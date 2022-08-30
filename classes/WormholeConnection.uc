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

	DebugJson = new class'JsonObject';
	DebugJson.AddString("Data", Data);
	EventGrid.SendEvent("wormhole/debug/sendtext", DebugJson);

    SendText(Data);
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
			
			//OnTimeout = Connect;
			//SetTimeout(ConnectTimeout);
		}
		else if(ServerHostName != "" && ServerAddress.Port > 0)
		{
			EventGrid.SendEvent("wormhole/debug/resolving", None);
			Resolve(ServerHostName);
		}
		else
		{
			EventGrid.SendEvent("wormhole/debug/failed", None);
			log("ERROR - Missing server address or port.", Name);
		}
	}
	
	event Resolved(IpAddr Address)
	{
		EventGrid.SendEvent("wormhole/debug/resolved", None); // debug

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
		log("ERROR - Could not resolve server address.", Name);
	}
	
	event Opened()
	{
		EventGrid.SendEvent("wormhole/debug/connected", None); // debug

		// ClearTimeout();
		GotoState('ConnectionEstablished');
	}
	
	// function Timer()
	// {
		// OnTimeout();
	// }
	
// Reconnect:
	// log("Waiting before reconnecting", Name);
	// ServerAddress.Addr = 0;

begin:
	DebugJson = new class'JsonObject';
	DebugJson.AddString("State", "NotConnected");
	EventGrid.SendEvent("wormhole/debug/statechanged", DebugJson);
	// OnTimeout = Connect;
	// SetTimeout(ReconnectDelay);
}

state ConnectionEstablished
{
	event ReceivedText(string Message)
	{
		local JsonObject Json;

		Json = class'JsonConvert'.static.Deserialize(Message);
		EventGrid.SendEvent("wormhole/debug/receivedtext", Json);
		// local int Code;
		// local string Data;
		
		// DissectMessage(Message, Code, Data);
		
		// Switch(Code)
		// {
		// 	case AuthenticationOK:
		// 		GotoState('Authenticated');
		// 		break;
		
		// 	case AccessDenied:
		// 		log("Access denied by server, make sure the IP is whitelisted in the Server settings", Name);
		// 		break;
	
		// 	default:
		// 		log("Unknown code received:" @ Code);
		// 		break;
		// }
	}
	
	event Closed()
	{
		EventGrid.SendEvent("wormhole/debug/disconnected", None); // debug
		GotoState('NotConnected');
	}

	function SendAuthenticationRequest()
	{
		local JsonObject Json;

		Json = new class'JsonObject';
		Json.AddString("Token", Settings.Token);
		Send("authentication/request", Json);
	}

Begin:
	log("Connection established", Name);	
	DebugJson = new class'JsonObject';
	DebugJson.AddString("State", "ConnectionEstablished");
	EventGrid.SendEvent("wormhole/debug/statechanged", DebugJson);	

	SendAuthenticationRequest();
}

state Authenticated
{
	event ReceivedText(string Message)
	{
		// local int Code;
		// local string Data;
		
		// DissectMessage(Message, Code, Data);
		
		// Switch(Code)
		// {
		// 	case DiscordMessage:
		// 		WormholeMutator.OnDiscordChat(Data);
		// 		break;
			
		// 	case DiscordCommand:
		// 		ExecuteCommand(Data);
		// 		break;
				
		// 	default:
		// 		log("Unknown code received:" @ Code);
		// 		break;
		// }
	}
	
	event Closed()
	{
		GotoState('NotConnected');
	}
	
Begin:
	log("Succesfully authenticated by server", Name);
	DebugJson = new class'JsonObject';
	DebugJson.AddString("State", "Authenticated");
	EventGrid.SendEvent("wormhole/debug/statechanged", DebugJson);	
	//SendServerDetails();
}


defaultproperties
{
	Name = 'WormholeBot'
}