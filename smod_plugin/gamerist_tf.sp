#define MAPS_NUMBER     3
#define MAPNAME_MAXSIZE 16

// Enums for winning modes
#define RULESET_ROUNDS_1 1
#define RULESET_ROUNDS_2 2
#define RULESET_ROUNDS_3 4
#define RULESET_FINAL    8 // like plr_pipeline/ctf_2fort - whoever wins the last round, wins
#define RULESET_RED      16 // like cp_dustbowl - if red wins any round, they win the game, otherwise blu

#define CURRENT_GAME 1

new String:mapdata_names[MAPS_NUMBER][MAPNAME_MAXSIZE] = {"ctf_2fort", "cp_dustbowl", "plr_pipeline"};
new mapdata_rulesets[MAPS_NUMBER] = {9, 20, 12};

#define WFP_MAX_TRIES   10
new wfptries = 1;

#include "gameristconstants.inc"
#include "utilities.inc"
#include "onpluginstart.inc"
#include "clientsmaps.inc"
#include "votecancel.inc"
#include "joingame.inc"
#include "endgame.inc"
#include "handlemsg.inc"

public Action:WaitingForPlayersReboot(Handle:timer)
{
  if(AreEnoughPlayers() == 0)
  {
    if(wfptries < WFP_MAX_TRIES)
    {
      wfptries++;
      PrintToServer("WFP RESTART");
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
  // CreateTimer(25.0, WaitingForPlayersReboot);
}

public TF2_OnWaitingForPlayersEnd()
{
  PrintToServer("WAITING FOR PLAYERS OVER");
  CheckPlayerCount(1);
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

