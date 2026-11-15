// ============================================================================
// File: money/snapshots.pwn
// Hourly snapshots of each recently active character's cash, bank and savings into the
// character_daily_stats table, used for economy tracking.
// ============================================================================

// ---------------------------------------------------------------------------
// Money snapshots (table `character_daily_stats`)
//
// Once an hour every recently active character's cash / bank / savings is written to
// today's row. The row for a day therefore ends up holding that day's closing balance,
// which the UCP compares with today's balance to show "net worth change this week".
// ---------------------------------------------------------------------------

task Money_DailySnapshot[3600000]() {

	new query[512];

	mysql_format(mysql, query, sizeof(query),
		"INSERT INTO `character_daily_stats` (`character_id`, `day`, `cash`, `bank`, `savings`) \
		 SELECT `player_id`, CURDATE(), `player_cash`, `player_bankcash`, `player_savings` FROM `characters` \
		 WHERE `player_logindate` >= UNIX_TIMESTAMP() - 2592000 \
		 ON DUPLICATE KEY UPDATE `cash` = VALUES(`cash`), `bank` = VALUES(`bank`), `savings` = VALUES(`savings`)");
	mysql_tquery(mysql, query);
}
