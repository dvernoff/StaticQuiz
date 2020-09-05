		
		/////////////////////////////////////////////////
		// Это нечто прекрасное, и простое.			   //
		// Это Static Quiz 2.0 приятного использования.//
		/////////////////////////////////////////////////


#include morecolors

#undef REQUIRE_PLUGIN
#tryinclude <shop>
#undef REQUIRE_PLUGIN
#tryinclude <lvl_ranks>
#undef REQUIRE_PLUGIN
#tryinclude <vip_core>

bool				shop, 
					lvl,
                    vip, 
					dgame;

char                Vopros[256], 
                    Otvet[64], 
                    Type[16], 
                    TypeText[32],
					admin_flag[4]; 

int                 iNagrada,
					maxaward,
					blocked,
					adminclient;

static const char
                    PL_NAME[]	= "Static Quiz",
                    PL_VER[]	= "2.0";

public Plugin myinfo = 
{
	name = PL_NAME,
	author = "NULLED",
	description = "Ask a question and get an answer",
	version = PL_VER,
	url = "SPECIAL FOR HLMOD.RU"
};

public void OnPluginStart()
{
    ConVar cv;
    (cv = CreateConVar("sm_sq_admin_flag", "z", "EN: Flag for accessing the team || RU: Флаг администратора для доступа к команде")).AddChangeHook(Cvar_AdminFlag);
    cv.GetString(admin_flag, sizeof(admin_flag));
    (cv = CreateConVar("sm_sq_max_award", "30000", "EN: Maximum value in the Reward field || RU: Максимальная награда в аргументе Награда", _, true, 1.0, true, 1000000.0)).AddChangeHook(Cvar_MaxAward);
    maxaward = cv.IntValue;
    (cv = CreateConVar("sm_sq_against_suction", "0", "EN: 0 - Allow answering your own question / 1 - Prohibit answering your own question || RU: 0 - Разрешить отвечать на свой же вопрос / 1 - Запретить отвечать на свой же вопрос", _, true, 0.0, true, 1.0)).AddChangeHook(Cvar_Blocked);
    blocked = cv.IntValue;

    RegConsoleCmd("sm_squiz", r_Cmd);
    RegConsoleCmd("say", CommandSay);

    LoadTranslations("StaticQuiz");
    AutoExecConfig(true, "StaticQuiz");

    StopGame();
}

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int max)
{
	MarkNativeAsOptional("Shop_GiveClientCredits");
	MarkNativeAsOptional("LR_ChangeClientValue");
	MarkNativeAsOptional("VIP_IsValidVIPGroup");
	MarkNativeAsOptional("VIP_GiveClientVIP");
	
	return APLRes_Success;
}

public void Cvar_AdminFlag(ConVar cv, const char[] oldValue, const char[] newValue) 
{ 
	cv.GetString(admin_flag, sizeof(admin_flag)); 
}

public void Cvar_MaxAward(ConVar cv, const char[] oldValue, const char[] newValue) 
{ 
	maxaward = cv.IntValue; 
}

public void Cvar_Blocked(ConVar cv, const char[] oldValue, const char[] newValue) 
{ 
	blocked = cv.IntValue; 
}

public void OnLibraryAdded(const char[] name)
{
    if(StrEqual(name, "shop"))
    {
        shop = true;
    }
    if(StrEqual(name, "levelsranks"))
    {
        lvl = true;
    }
    if(StrEqual(name, "vip_core"))
    {
        vip = true;
    }
}

public void OnLibraryRemoved(const char[] name)
{
    if(StrEqual(name, "shop"))
    {
        shop = false;
    }
    if(StrEqual(name, "levelsranks"))
    {
        lvl = false;
    }
    if(StrEqual(name, "vip_core"))
    {
        vip = false;
    }
}


public Action CommandSay(int i, any args)
{
    if(dgame == true)
    {
        char Arg[64];
        GetCmdArg(1, Arg, sizeof(Arg));

        if(StrEqual(Arg, Otvet))
        {
			if(blocked == 1 && i == adminclient)
			{
				CPrintToChat(i, "%t %t", "CHAT_PREFIX", "CHAT_WRONG");
				return;
			}

			if(StrEqual(Type, "shop", false))
			{
				Shop_GiveClientCredits(i, iNagrada, CREDITS_BY_NATIVE);
				CPrintToChatAll("%t %t", "CHAT_PREFIX", "CHAT_PLAYER_WIN", i, iNagrada, TypeText, Otvet);
				StopGame();
			}
			else if(StrEqual(Type, "lvl", false))
			{
				LR_ChangeClientValue(i, iNagrada);
				CPrintToChatAll("%t %t", "CHAT_PREFIX", "CHAT_PLAYER_WIN", i, iNagrada, TypeText, Otvet);
				StopGame();
			}
			else if(StrEqual(Type, "vip", false))
			{
				if(VIP_IsClientVIP(i))
				{
					CPrintToChat(i, "%t %t", "CHAT_PREFIX", "CHAT_VIP_YES");
				}
				else
				{
					VIP_GiveClientVIP(1, i, iNagrada, TypeText, true);
					CPrintToChatAll("%t %t", "CHAT_PREFIX", "CHAT_PLAYER_VIPWIN", i, Type, TypeText, iNagrada, Otvet);
					StopGame();
				}
			}
			else
			{
				CPrintToChatAll("%t %t", "CHAT_PREFIX", "CHAT_ERRORFATAL");
				//FATAL ERROR
			}
        }
    }
}


public Action r_Cmd(int i, any args)
{
	if(!CheckFlag(i, admin_flag))
	{
		char Arg[64];
		GetCmdArg(1, Arg, sizeof(Arg));

		if(StrEqual(Arg, "stop"))
		{
			if(dgame == true)
			{
				CPrintToChatAll("%t %t", "CHAT_PREFIX", "CHAT_ADMIN_CANCEL", i);
				StopGame();
			}
			else
			{
				CPrintToChat(i, "%t %t", "CHAT_PREFIX", "CHAT_INGAME");
			}
			return Plugin_Handled;
		}
		if(dgame == true)
		{
			CPrintToChatAll("%t %t", "CHAT_PREFIX", "CHAT_ADMIN_RETRY", i, Vopros, iNagrada, TypeText);
			return Plugin_Handled;
		}
		if(args > 4 || args < 4)
		{
			CPrintToChat(i, "%t %t", "CHAT_PREFIX", "CHAT_COMMAND_ERROR");
			return Plugin_Handled;
		}

		GetCmdArg(3, Vopros, sizeof(Vopros));
		int strl = strlen(Vopros);
			
		if(strl > 256)
		{
			CPrintToChat(i, "%t %t", "CHAT_PREFIX", "CHAT_MAXARGS");
			return Plugin_Handled;
		}
			
		GetCmdArg(4, Otvet, sizeof(Otvet));
		char Nagrada[64];
		GetCmdArg(2, Nagrada, sizeof(Nagrada));
		iNagrada = StringToInt(Nagrada);

		if(iNagrada < 1 || iNagrada > maxaward)
		{
			CPrintToChat(i, "%t %t", "CHAT_PREFIX", "CHAT_COMMAND_2ERROR", maxaward);
			return Plugin_Handled;
		}

		GetCmdArg(1, Type, sizeof(Type));
		if(StrEqual(Type, "lvl"))
		{
		   if(lvl == true)
		   {
			   TypeText = "очков опыта";
		   }
		   else
		   {
			   CPrintToChat(i, "%t %t", "CHAT_PREFIX", "CHAT_TYPE_LVL_ERROR");
			   return Plugin_Handled;
		   }
		}
		else if(StrEqual(Type, "shop"))
		{
		   if(shop == true)
		   {
				TypeText = "кредитов";
		   }
		   else
		   {
			   CPrintToChat(i, "%t %t", "CHAT_PREFIX", "CHAT_TYPE_SHOP_ERROR");
			   return Plugin_Handled;
		   }
		}
		else
		{
			int uti_puti = FindCharInString(Type, '|');
			if(uti_puti != -1)
			{
				if(vip == true)
				{
					strcopy(TypeText, sizeof(TypeText), Type[uti_puti+1]);
					
					if(VIP_IsValidVIPGroup(TypeText))
					{
						Type = "vip";
					}
					else
					{
						CPrintToChat(i, "%t %t", "CHAT_PREFIX", "CHAT_ERRVIPGR", TypeText);
						return Plugin_Handled;
					}
				}
				else
				{
					CPrintToChat(i, "%t %t", "CHAT_PREFIX", "CHAT_TYPE_VIP_ERROR");
					return Plugin_Handled;
				}
			}
			else
			{
				CPrintToChat(i, "%t %t", "CHAT_PREFIX", "CHAT_TYPE_ARG_ERROR");
				return Plugin_Handled;
			}
		}

		adminclient = i;

		if(StrEqual(Type, "vip"))
		{
			CPrintToChatAll("%t %t", "CHAT_PREFIX", "CHAT_START_VIPGAME", i, Vopros, Type, TypeText, iNagrada);
		}
		else
		{
		 	CPrintToChatAll("%t %t", "CHAT_PREFIX", "CHAT_START_GAME", i, Vopros, iNagrada, TypeText);
		}
		dgame = true;
	}
	else
	{
		PrintToChat(i, "%t %t", "CHAT_PREFIX", "CHAT_ERRACCESS");
	}
	return Plugin_Handled;
}

bool CheckFlag(int iClient, char[] CHARFLAG) 
{
	int INTOFLAG = GetUserFlagBits(iClient);
	if(INTOFLAG & ReadFlagString("z") || INTOFLAG & ReadFlagString(CHARFLAG)) return false;
	return true;
}

void StopGame()
{
                                                                                //Остановка игры | Stoppage of play
                                                                                Vopros = "";
                                                                                Otvet = "";
                                                                                iNagrada = 0;
                                                                                adminclient = 0;
                                                                                dgame = false;
}