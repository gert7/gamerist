#include <sourcemod>
#include <socket>
#include <sdktools>

public Plugin:myinfo =
{
  name = "Gamerist",
  author = "gert",
  description = "Video game reporter",
  version = "1.0",
  url = "http://www.gamerist"
};

// Message format (square brackets not included, numbers are plain ASCII):
// hndlr <- [decimal string]#[MSG]\n = Message N
// hndlr -> A[decimal string]#[MSG]\n = Acknowledged message number N

// the following messages are preceded by msgindex# and followed by \n
// hndlr <- I = Connection established
// hndlr <- L[index] = Ask for index
// hndlr -> L[stopnow|index|steamid1|team number] = add player to list(index, steamid, teamnumber, seperated by pipe, up to 32 characters)
// hndlr -> P[string] = Print this string to chat
// hndlr <- E[string] = Error with string, game finished STATE_FAILED
// hdnlr <- D = Game finished STATE_OVER
// hndlr <- DP[index|points] = Player with index, score
// hndlr <- DT[winningteam][losingteam] = Team with index, score; either DT23 or DT32
//
// hndlr <- H = heartbeat
// hndlr -> H = affirm
// hndlr -> T = server timed out!

#define MQLIMIT         64 // total capacity of the message queue
#define MAX_MESSAGESIZE 256
#define IDLIMIT         34
#define MAXIDSIZE       32

#define MAPS_NUMBER     3
#define MAPNAME_MAXSIZE 16

#define ERROR_GRACEFUL_SHUTDOWN           4
#define ERROR_MESSAGES_NOT_BEING_RECEIVED 5 // MQLIMIT is reached!!
#define ERROR_MESSAGE_LIMIT_REACHED       6 // 4 million messages is too much!!
#define ERROR_MESSAGE_ACKS_OUT_OF_SYNC    7 // Getting wrong numbers!!
#define ERROR_UNRECOGNIZED_MAP            8 // this should not happen at all
#define ERROR_SERVER_TIMED_OUT            9 // timed out to handlr
#define ERROR_NOT_ENOUGH_PLAYERS          10 // not enough players connected!
#define ERROR_VOTECANCEL                  11

#define TEAM_RED 2
#define TEAM_BLU 3

// Enums for winning modes
#define RULESET_ROUNDS_1 1
#define RULESET_ROUNDS_2 2
#define RULESET_ROUNDS_3 4
#define RULESET_FINAL    8 // like plr_pipeline/ctf_2fort - whoever wins the last round, wins
#define RULESET_RED      16 // like cp_dustbowl - if red wins any round, they win the game, otherwise blu

#define TEST_ALONE        1

new String:mapdata_names[MAPS_NUMBER][MAPNAME_MAXSIZE] = {"ctf_2fort", "cp_dustbowl", "plr_pipeline"};
new mapdata_rulesets[MAPS_NUMBER] = {9, 20, 12};

new String:allowedids[IDLIMIT][MAXIDSIZE]; // 1 string is 24 characters, null terminator included
new teamnumbers[IDLIMIT];

new String:messagequeue[MQLIMIT][MAX_MESSAGESIZE];
new clIndex        = 0; // The position of the last confirmed mid in the circular queue (left end)
new crIndex        = 0; // The position of the next mid to be added in the circular queue (right end, out of mqLIMIT)
new cmid           = 0; // Last confirmed mid (left end of queue, big number)
new nextmid        = 0; // The next mid to be added to the queue (right end of queue, next is this + 1)

new serverKilled   = 0;
new killingServer  = 0;

new waitingForResponse = 0;

new globalRoundsPlayed = 0;

#define WFP_MAX_TRIES   10
new wfptries = 1;

new voteCancelAvailable = 1;
new votedToCancel[32];

new Handle:sharedSocket;

// Integer power
power(x, y) // wow
{
  assert y >= 0
  new r = 1
  for (new i = 0; i < y; i++)
  r *= x
  return r
}

// Char to byte
byte(chr)
{
  return chr - 48
}

// String to integer
atoi(String:numero[], base)
{
  new result = 0;
  new ilen   = strlen(numero);
  for(new i = 0; i < ilen; i++)
  {
    result += byte(numero[i]) * (power(base, ilen - i - 1));
  }
  return result;
}

public OnPluginStart()
{
  PrintToChatAll("[GAMERIST] Gamerist starting up...");
  
  CreateTimer(2.0, RestartSocket);
  CreateTimer(10.0, HeartBeat);
  
  GetInitialData();
  
  PrintToChatAll(mapdata_names[1]);
  HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
  HookEvent("teamplay_round_win", Event_TeamplayRoundWin, EventHookMode_Post);
  HookEvent("player_say", Event_PlayerSay, EventHookMode_Post);
}

DeclareError(errno)
{
  PushMessage("E%d", errno);
}

KillServer(errno)
{
  if(errno != ERROR_GRACEFUL_SHUTDOWN)
    DeclareError(errno);
  serverKilled = errno;
  for(new i = 1; i < (GetMaxClients() + 1); i++) {
    if(IsClientConnected(i))
      KickClient(i, "Game ended with error %d", errno)
  }
}

public Action:HeartBeat(Handle:timer)
{
  PushMessage("H");
  CreateTimer(10.0, HeartBeat);
}

public Action:RestartSocket(Handle:timer)
{
  new Handle:socket = SocketCreate(SOCKET_TCP, OnSocketError);
  PrintToServer("[GAMERIST] Starting socket connect...");
  SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "127.0.0.1", 1996)
}

ClientListIndex(const String:auth[])
{
  PrintToServer("Looking for steamid %s", auth);
  for(new i = 0; i < IDLIMIT; i++)
  {
    if(strcmp(auth, allowedids[i]) == 0) {
      PrintToServer("Found at %d, teamnumber is %d", i, teamnumbers[i]);
      return i; }
  }
  // if(TEST_ALONE == 1) return 0;
  return -1;
}

ClientListIndexI(client)
{
  new String:sid[MAXIDSIZE];
  GetClientAuthId(client, AuthId_Steam2, sid, MAXIDSIZE);
  return ClientListIndex(sid);
}

//
// Allow the players to vote cancel
//

CountVoteCancels()
{
  new total = 0;
  for(new i = 0; i < 32; i++)
  {
    if(votedToCancel[i] == 1)
      total++;
  }
  return total;
}

public Action:VoteCancelSucceeds(Handle:timer)
{
  KillServer(ERROR_VOTECANCEL);
}

public Action:DisableVoteCancel(Handle:timer)
{
  PrintToChatAll("[GAMERIST] !votecancel is now disabled");
  voteCancelAvailable = 0;
}

public Action:Event_PlayerSay(Handle:event, const String:name[], bool dontBroadcast)
{
  new client = GetClientOfUserId(GetEventInt(event, "userid"));
  new String:text[12];
  GetEventString(event, "text", text, 12);
  if(strcmp(text, "!votecancel") == 0)
    if(voteCancelAvailable == 1)
    {
      if(TEST_ALONE == 0) votedToCancel[ClientListIndexI(client)] = 1;
      else votedToCancel[0] = 1;
      new count = CountVoteCancels();
      PrintToChatAll("[GAMERIST] Number of votes to cancel game: %d/4", count); // TODO: ensure 4 is a good number
      if(count >= 4)
      {
        PrintToChatAll("[GAMERIST] Voted to cancel game!!");
        DeclareError(ERROR_VOTECANCEL);
        killingServer = 1;
        CreateTimer(7.0, VoteCancelSucceeds);
      }
    }
}

//
// Get the rules for this map
//
MapListEnum()
{
  new String:curmap[MAPNAME_MAXSIZE];
  GetCurrentMap(curmap, MAPNAME_MAXSIZE);
  for(new i = 0; i < MAPS_NUMBER; i++)
  {
    if(strcmp(curmap, mapdata_names[i]) == 0) {
      return mapdata_rulesets[i]; }
  }
  return 0;
}

//
// Are there enough players?
// Should we keep waiting for them?
//
public Action:NotEnoughPlayers(Handle:timer)
{
  PrintToServer("NOT ENOUGH PLAYERS");
  KillServer(ERROR_NOT_ENOUGH_PLAYERS);
}

// Returns 1 or 0 based on whether or not the number of players is sufficient right now
AreEnoughPlayers()
{
  new ccount = 0;
  for(new i = 0; i < GetMaxClients(); i++)
  {
    if(IsClientConnected(i+1) && !IsFakeClient(i+1))
      ccount++;
  }
  new maxplayers = GetMaxClients();
  // PrintToServer("ccount vs maxplayers: %d/%d", ccount, maxplayers);
  if(ccount >= (maxplayers - 23)) // TODO: ensure this makes sense
    return 1;
  else
    return 0;
}

new gameStarted = 0; // in case playercount falls to 0 and it goes back to wfp

CheckPlayerCount(fatalmode)
{
  if(gameStarted == 0)
  {
    if(AreEnoughPlayers())
    {
      gameStarted = 1;
      PrintToChatAll("[GAMERIST] Enough players have joined!");
      PrintToChatAll("[GAMERIST] The game will start soon");
      PrintToChatAll("[GAMERIST] !votecancel will be available for 2 minutes");
      CreateTimer(120.0, DisableVoteCancel);
    }
    else if(fatalmode)
    {
      PrintToChatAll("[GAMERIST] Not enough players joined the game!");
      PrintToChatAll("[GAMERIST] Server shutting down!");
      CreateTimer(6.0, NotEnoughPlayers);
    }
  }
}

//
// Is the client in the whitelist?
//
public OnClientAuthorized(client, const String:auth[])
{
  PrintToServer("[GAMERIST] Client %d has SteamID %s", client, auth);
  if(serverKilled != 0)
    KickClient(client, "Game canceled due to error %d", serverKilled);
  else
    if(ClientListIndex(auth) == -1 && TEST_ALONE == 0)
      KickClient(client, "You are not in the whitelist!");
  CheckPlayerCount(0);
}

public Action:WaitingForPlayersReboot(Handle:timer)
{
  if(AreEnoughPlayers() == 0)
  {
    if(wfptries < WFP_MAX_TRIES)
    {
      wfptries++;
      PrintToChatAll("[GAMERIST] Not enough players, waiting for players %d/%d...", wfptries, WFP_MAX_TRIES);
      ServerCommand("mp_waitingforplayers_restart 1");
      CreateTimer(25.0, WaitingForPlayersReboot);
    }
    else
      CheckPlayerCount(1);
  }
}

public TF2_OnWaitingForPlayersStart()
{
  CreateTimer(25.0, WaitingForPlayersReboot);
}

public TF2_OnWaitingForPlayersEnd()
{
  CheckPlayerCount(1);
}

//
// Shut down the server, game is done
//
PreGracefulShutdown(winteam)
{
  new String:winteamStr[4];
  if(winteam == TEAM_RED) winteamStr = "RED"; else winteamStr = "BLU";
  PrintToChatAll("[GAMERIST] Game over! Winning team is team %s", winteamStr);
  CreateTimer(30.0, GracefulShutdown);
}

public Action:GracefulShutdown(Handle:timer)
{
  for(new i = 1; i < (GetMaxClients() + 1); i++) {
    if(IsClientConnected(i))
      KickClient(i, "Game has ended")
  }
  KillServer(ERROR_GRACEFUL_SHUTDOWN);
}

//
// Move the user to their team
//
public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) 
{
  new String:sid[MAXIDSIZE];
  new client = GetClientOfUserId(GetEventInt(event, "userid"));
  new team   = GetClientTeam(client);
  
  GetClientAuthId(client, AuthId_Steam2, sid, MAXIDSIZE);
  new ind = ClientListIndex(sid);
  if(ind == -1 && TEST_ALONE == 0){
    KickClient(client, "Client not in list somehow!");
    return 0;
  }
  // if(ind != -1) PrintToServer("%d has joined team %d, should be team %d", client, team, teamnumbers[ind]);
  if(ind != -1 && teamnumbers[ind] != team)
    ChangeClientTeam(client, teamnumbers[ind]);
  return Plugin_Handled;
}

//
// Tell handlr who won
//
PushAllPlayerScores()
{
  new String:playerScores[2048];
  playerScores[0] = 'D'; playerScores[1] = 'P';
  for(new i = 1; i < (GetMaxClients() + 1); i++) {
    if(IsClientConnected(i))
    {
      new String:oneplayer[48];
      
      new String:stid[MAXIDSIZE];
      GetClientAuthId(i, AuthId_Steam2, stid, MAXIDSIZE)
      Format(oneplayer, 48, "%s|%d|", stid, GetClientFrags(i));
      StrCat(playerScores, 2048, oneplayer);
    }
  }
  StrCat(playerScores, 2048, "&|"); // If fewer than playercount players are connected
  PushMessage(playerScores);
}

DeclareWinners(winningTeam)
{
  PushAllPlayerScores();
  new losingTeam;
  if(winningTeam == TEAM_RED)
    losingTeam = TEAM_BLU;
  else
    losingTeam = TEAM_RED;
  PushMessage("DT%d%d", winningTeam, losingTeam); // DT23 or DT32
  PreGracefulShutdown(winningTeam);
}

public Action:Event_TeamplayRoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
  new ruleset = MapListEnum();
  globalRoundsPlayed++;
  new roundsMax;
  if(ruleset & RULESET_ROUNDS_1)
    roundsMax = 1;
  else if(ruleset & RULESET_ROUNDS_2)
    roundsMax = 2;
  else if(ruleset & RULESET_ROUNDS_3)
    roundsMax = 3;
  if(ruleset & RULESET_FINAL) // CTF_2FORT/PLR_PIPELINE STYLE
  {
    if(globalRoundsPlayed == roundsMax)
      DeclareWinners(GetEventInt(event, "team"));
    else
      PrintToChatAll("[GAMERIST] Round over! Next round begins in %d seconds", GetConVarInt(FindConVar("mp_bonusroundtime")));
  }
  else if(ruleset & RULESET_RED) // CP_DUSTBOWL STYLE
  {
    new rwinningTeam = GetEventInt(event, "team");
    if(globalRoundsPlayed == roundsMax && rwinningTeam == TEAM_BLU)
      DeclareWinners(TEAM_BLU);
    else if(rwinningTeam == TEAM_RED)
      DeclareWinners(TEAM_RED);
    else
      PrintToChatAll("[GAMERIST] Round over! Next round begins in %d seconds", GetConVarInt(FindConVar("mp_bonusroundtime")));
  }
  else
    KillServer(ERROR_UNRECOGNIZED_MAP);
  return Plugin_Handled;
}

//
// Deal with handlr
//
public OnSocketConnected(Handle:socket, any:arg)
{
  PrintToServer("[GAMERIST] SOCKET CONNECTED");
  waitingForResponse = 0;
  sharedSocket = socket;
  TryToPushMessages();
}

GetInitialData()
{
  PushMessage("I");
}

AskForNextPlayer(index)
{
  new String:msg[4];
  Format(msg, 4, "L%d", index);
  PrintToServer("Asking for %d", index);
  PushMessage(msg);
}

handleMsgBody(String:str[])
{
  switch(str[0])
  {
    case 'I':
    {
      AskForNextPlayer(0);
    }
    case 'P':
    {
      PrintToChatAll("[GAMERIST] %s", str[1]); // this works apparently :O
    }
    case 'L':
    {
      new pointer = 1;
      new String:stopnow[2]; // '0' = no, '1' = yes, stop right now
      new String:index[4]; // plaintext
      new String:suid[24]; // Steam ID (18 characters, typically)
      new String:teamnumber[2]; // '2' = red, '3' = blue
      pointer = ReadStringUntil(str, stopnow, pointer, '|');
      pointer = ReadStringUntil(str, index, pointer, '|');
      new indexn = atoi(index, 10);
      pointer = ReadStringUntil(str, suid, pointer, '|');
      PrintToChatAll(suid);
      pointer = ReadStringUntil(str, teamnumber, pointer, '\0');
      
      Format(allowedids[indexn], MAXIDSIZE, suid);
      teamnumbers[indexn] = atoi(teamnumber, 10);
      PrintToServer("team number %d is %d", indexn, teamnumbers[indexn]);
      
      if(stopnow[0] == '0')
        AskForNextPlayer(atoi(index, 10) + 1);
    }
    case 'T':
    {
      KillServer(ERROR_SERVER_TIMED_OUT);
    }
    case 'A': // generic acknowledge
    {
    }
  }
}

ReadStringUntil(String:source[], String:destination[], pointer, div)
{
  new next = 0;
  new sid  = 0;
  while(next == 0)
  {
    if(source[pointer] == div)
      next = 1;
    else
    {
      destination[sid] = source[pointer];
      sid++;
      pointer++;
    }
  }
  return pointer + 1;
}

handleMsg(String:str[], lpointer)
{
  new pointer = lpointer;
  if(str[pointer] == 'A')
  {
  // received a new message
  // acknowledged our own message
    // GET THE IDENTIFIER FOR ACK
    PrintToChatAll(str);
    new String:msgn[8];
    pointer++;
    pointer = ReadStringUntil(str, msgn, pointer, '#');
    
    new stid = atoi(msgn, 10);
    if(stid != cmid)
    {
      KillServer(ERROR_MESSAGE_ACKS_OUT_OF_SYNC);
      return pointer + 1;
    }
    PrintToServer("Message %d acknowledged!", atoi(msgn, 10), pointer);
    clIndex = (clIndex + 1) % MQLIMIT;
    cmid++;
    
    // DEAL WITH THE MESSAGE BODY
    new String:msg[256];
    pointer = ReadStringUntil(str, msg, pointer, '\n');
    
    PrintToServer("Response was %s", msg);
    handleMsgBody(msg);
    waitingForResponse = 0;
    return pointer;
  }
}

public OnSocketReceive(Handle:socket, String:rdata[], const size, any:arg)
{
  new pointer = 0;
  while((pointer < strlen(rdata)) && serverKilled == 0)
  {
    pointer = handleMsg(rdata, pointer);
  }
  if(serverKilled == 0)
    TryToPushMessages();
}

public OnSocketDisconnected(Handle:socket, any:arg)
{
  PrintToServer("[GAMERIST] Socket has disconnected!");
  CloseHandle(socket);
  sharedSocket = 0;
  CreateTimer(5.0, RestartSocket);
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:arg)
{
  if(serverKilled == 0)
  {
    PrintToServer("[GAMERIST] Socket has disconnected!");
    CloseHandle(socket);
    sharedSocket = 0;
    CreateTimer(5.0, RestartSocket);
  }
}

TryToPushMessages()
{
  if(TEST_ALONE == 0)
  {
    if((nextmid - cmid) > MQLIMIT) {
      KillServer(ERROR_MESSAGES_NOT_BEING_RECEIVED); }
      
    if(waitingForResponse == 0 && serverKilled == 0 && killingServer == 0 && sharedSocket != 0)
    {
      PrintToServer("Trying to push messages... There are %d messages to be acknowledged", nextmid - cmid);
      if(!waitingForResponse && cmid < nextmid)
      {
        new String:fstring[256];
        PrintToServer("Pushing message %d#%s\n", cmid, messagequeue[clIndex]);
        Format(fstring, 256, "%d;%d#%s\n", GetConVarInt(FindConVar("hostport")), cmid, messagequeue[clIndex]);
        SocketSend(sharedSocket, fstring);
        waitingForResponse = 1;
      } 
    }
  }
}

PushMessage(String:message[], any:...)
{
  if(TEST_ALONE == 0)
  {
    if(serverKilled == 0)
    {
      if(nextmid > 4000000)
      {
        KillServer(ERROR_MESSAGE_LIMIT_REACHED);
        return 0;
      }
      VFormat(messagequeue[crIndex], MAX_MESSAGESIZE, message, 2);
      crIndex = (crIndex + 1) % MQLIMIT;
      nextmid = (nextmid + 1);
      TryToPushMessages();
    }
  }
}

