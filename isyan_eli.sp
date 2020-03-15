/*
 * CS:GO - Isyan Eli
 * Henny!
 * 
 * Copyright (C) 2016-2020 Umut 'Henny!' Uzatmaz
 *
 * This file is part of the Henny! SourceMod Plugin Package.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>
 *
 * Güncelleme Listesi:
 *	1 - Takımların oyun başlamadan önce, doğma noktasına çekilmesi için gerekli bir kaç kod öbeği eklendi.
 *	2 - Bu ayar cvar olarak ayarlandı, ayar dosyası "csgo/cfg/henny.dev/sm_isyaneli.cfg" klasör yapısına eklendi.
 *
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <warden>

#define DEBUG
#define pluginversion "1.0.0"
#define plugintag "SM"

Handle timerHandle;
ConVar respawnCT;

int numPrinted = -1;
int entityName;

char entityList[][] =
{
	"func_door",
	"func_rotating",
	"func_walltoggle",
	"func_breakable",
	"func_door_rotating",
	"func_movelinear",
	"prop_door",
	"prop_door_rotating",
	"func_tracktrain",
	"func_elevator"
};

public Plugin myinfo =
{
	name 	= "[CSGO] Isyan Eli",
	author 	= "Henny!",
	version = pluginversion,
	url 	= ""
};

public void OnMapStart()
{
	char mapName[64];
	GetCurrentMap(mapName, sizeof(mapName));
	
	if (!((StrContains(mapName, "jb_", false) != -1) || (StrContains(mapName, "jail_", false) != -1) || (StrContains(mapName, "ba_jail_", false) != -1)))
	{
		SetFailState("[henny.me] (ISYAN-ELI) Eklenti jailbreak disindaki bir modda baslatildigi icin durduruldu.");
	}
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_isyaneli", startGame);
	RegConsoleCmd("sm_iseli", startGame);
	
	RegConsoleCmd("sm_iselidurdur", stopGame);
	RegConsoleCmd("sm_iseli0", stopGame);
	RegConsoleCmd("sm_isyanelidurdur", stopGame);
	RegConsoleCmd("sm_isyaneli0", stopGame);
	
	respawnCT = CreateConVar("sm_henny_isyaneli_ct-teleport", "1", "0 - Sadece Terörist takımı doğma noktasına çekilsin. Anti-Terörist'e sınırlama yok. \n1 - Her iki takımda doğma noktasına çekilsin.");
	AutoExecConfig(true, "sm_isyaneli", "henny.dev");
}

public Action stopGame(int client, int args)
{
	if (!(warden_iswarden(client) || CheckCommandAccess(client, "generic_admin", ADMFLAG_GENERIC, false)))
	{
		PrintToChat(client, "\x02[%s] \x04İsyan eli\x01'ni başlatman için Komutçu yada Yetkili \x0Folmalısın.", plugintag);
		return Plugin_Handled;
	}
	
	numPrinted = -1;
	KillTimer(timerHandle);

	PrintToChat(client, "\x02[%s] \x04İsyan eli \x01kapatıldı (sıfırlandı).", plugintag);
	return Plugin_Handled;
}

public Action startGame(int client, int args)
{
	if (!(warden_iswarden(client) || CheckCommandAccess(client, "generic_admin", ADMFLAG_GENERIC, false)))
	{
		PrintToChat(client, "\x02[%s] \x04İsyan eli\x01'ni başlatman için Komutçu yada Yetkili \x0Folmalısın.", plugintag);
		return Plugin_Handled;
	}
	
	if (numPrinted != -1)
	{
		PrintToChat(client, "\x02[%s] \x04İsyan eli\x01'nin geri sayımı hala aktif.", plugintag);
		return Plugin_Handled;
	}
	
	if (args != 1)
	{
		PrintToChat(client, "\x02[%s] \x01Kullanım: sm_isyaneli <1-10>", plugintag);
		return Plugin_Handled;
	}
	
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	int countdown = StringToInt(arg1);
	
	if (!((countdown >= 1) || (countdown <= 10)))
	{
		PrintToChat(client, "\x02[%s] \x01Kullanım: sm_isyaneli <1-10>", plugintag);
		return Plugin_Handled;
	}
	
	doorsControl(false);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			if (GetConVarBool(respawnCT) ? GetClientTeam(i) == CS_TEAM_CT && GetClientTeam(i) == CS_TEAM_T : GetClientTeam(i) == CS_TEAM_T)
			{
				CS_RespawnPlayer(i);
			}
		}
	}
	
	
	
	PrintToChatAll("\x02[%s] \x04İsyan Eli \x10%i saniye \x10sonra başlayacaktır.", plugintag, countdown);
	PrintHintTextToAll("İsyan Eli <font color='#51EC2E'>%i saniye</font> sonra başlayacaktır.", countdown);
	
	numPrinted = countdown;
	timerHandle = CreateTimer(1.0, goCommand, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	return Plugin_Continue;
}

public Action goCommand(Handle timer)
{
	if (numPrinted != -1)
	{
		numPrinted--;
		
		if (numPrinted >= 1)
		{
			PrintHintTextToAll("İsyan Eli <font color='#51EC2E'>%i saniye</font> sonra başlayacaktır.", numPrinted);
		}
		else if (numPrinted == 0)
		{
			PrintHintTextToAll("İsyan Eli <font color='#51EC2E'>BASLADI !!!</font>", numPrinted);
			
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i))
				{
					SetEntityHealth(i, 100);
					SetEntProp(i, Prop_Send, "m_ArmorValue", 100, 1);
					
					if (GetClientTeam(i) == CS_TEAM_T)
					{
						weaponClear(i);
					}
				}
			}
			
			numPrinted = -1;
			doorsControl(true);
			return Plugin_Stop;
		}
	}
	else if (numPrinted == -1)
	{
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action doorsControl(bool command)
{
	for (int i = 0; i < sizeof(entityList); i++)
	{
		while ((entityName = FindEntityByClassname(entityName, entityList[i])) != -1)
		{
			command ? AcceptEntityInput(entityName, "Open") : AcceptEntityInput(entityName, "Close");
		}
	}
}

public Action weaponClear(int client)
{
	for (int j = 0; j < 5; j++)
	{
		int weapon = GetPlayerWeaponSlot(client, j);
		if (weapon != -1)
		{
			RemovePlayerItem(client, weapon);
			RemoveEdict(weapon);
		}
	}
	
	GivePlayerItem(client, "weapon_knife");											
}
