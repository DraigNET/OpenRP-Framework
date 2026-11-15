#include <a_samp>
#include <a_mysql>
#include <YSI_Extra\y_inline_mysql>

new MySQL:mysql;
MySQL_Init()
{
    mysql = mysql_connect_file();

    if (mysql_errno(mysql) != 0) {
        printf("[FATAL] MySQL connection failed (%d). Configure mysql.ini and import database/schema.sql.", mysql_errno(mysql));
        return 0;
    }

    // Charset fix
    mysql_set_charset("latin1", mysql);

    print(" * [SQL] Connected to database ");
	
	return 1;
}

public OnQueryError(errorid, const error[], const callback[], const query[], MySQL:handle)
{
	new string[128], strQuery[256], strCallback[128];
	format(string, sizeof(string), "[SEND TO DEV TEAM]: SQL ERROR (%s)", error);
	format(strQuery, sizeof(strQuery), "[QUERY]: %s", query);
	format(strCallback, sizeof(strCallback), "[CALLBACK]: %s", callback);

	SendDevMessage(string, 0xff00bdFF, true);
	SendDevMessage(strQuery, 0x1e00ffFF, true);
	SendDevMessage(strCallback, 0xff00bdFF, true);

	switch(errorid)
	{
		case CR_SERVER_GONE_ERROR:
		{
			printf(" * [SQL] Lost connection to server, trying reconnect...");
		}
		case ER_SYNTAX_ERROR:
		{
			printf(" * [SQL] Something is wrong in your syntax, query: %s",query);
		}
	}
	return 1;
}