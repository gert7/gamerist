#define MAPS_NUMBER     2
#define MAPNAME_MAXSIZE 16

// Enums for winning modes
#define RULESET_ROUNDS_6 1
#define RULESET_ROUNDS_11 2
#define RULESET_ROUNDS_16 4
#define RULESET_FINAL 8
#define RULESET_BESTOF 16

#define CURRENT_GAME 2

new String:mapdata_names[MAPS_NUMBER][MAPNAME_MAXSIZE] = {"de_dust", "cs_office"};
new mapdata_rulesets[MAPS_NUMBER] = {2, 2};

#include "gameristconstants.inc"
#include "utilities.inc"
#include "onpluginstart.inc"
#include "clientsmaps.inc"
#include "votecancel.inc"
#include "joingame.inc"
#include "endgame.inc"
#include "handlemsg.inc"

public Action:Event_TeamplayRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
  if(gameStarted == 1) {
    new ruleset = MapListEnum();
    globalRoundsPlayed++;
    new roundsMax;
    if(ruleset & RULESET_ROUNDS_6) roundsMax = 6;
    else if(ruleset & RULESET_ROUNDS_11) roundsMax = 11;
    else if(ruleset & RULESET_ROUNDS_16) roundsMax = 16;
    
    if(ruleset & RULESET_FINAL) { // THE TEAM WHO WINS THE LAST ROUND WINS THE GAME
      if(globalRoundsPlayed == roundsMax)
        DeclareWinners(GetEventInt(event, "team"));
      else
        PrintToChatAll("[GAMERIST] Round over! Next round begins in %d seconds", GetConVarInt(FindConVar("mp_bonusroundtime"))); }
    else if(ruleset & RULESET_BESTOF) { // THE TEAM WHO IS GUARANTEED TO HAVE THE MOST POINTS AT THE END WINS IMMEDIATELY
      new rwinningTeam = GetEventInt(event, "team");
      if(GetTeamScore(rwinningTeam) > (roundsMax - globalRoundsPlayed))
        DeclareWinners(rwinningTeam);
      else
        PrintToChatAll("[GAMERIST] Round over! Next round begins in %d seconds", GetConVarInt(FindConVar("mp_bonusroundtime"))); }
    else
      KillServer(ERROR_UNRECOGNIZED_MAP); }
  else
    ServerCommand("mp_restartgame");
  return Plugin_Handled;
}

