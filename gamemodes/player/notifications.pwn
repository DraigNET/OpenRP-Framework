// ============================================================================
// File: player/notifications.pwn
// Notify_Character(): queues a row in the `notifications` table for the account that owns a
// character, for a website/UCP to display.
// ============================================================================

// ---------------------------------------------------------------------------
// UCP notifications (table `notifications`)
//
// Notify_Character() queues a row for the account that owns a character. Works for
// offline characters too, because the account is looked up inside the INSERT.
// The website shows these under the bell in the UCP header.
// ---------------------------------------------------------------------------

stock Notify_Character(character_id, const type[], const title[], const body[], const link[] = "")
{
	if (character_id <= 0) {
		return false;
	}

	new query[640];

	mysql_format(mysql, query, sizeof(query),
		"INSERT INTO `notifications` (`account_id`, `type`, `title`, `body`, `link`, `created_at`) \
		 SELECT `account_id`, '%e', '%e', '%e', NULLIF('%e', ''), %d FROM `characters` WHERE `player_id` = %d",
		type, title, body, link, gettime(), character_id);
	mysql_tquery(mysql, query);

	return true;
}
