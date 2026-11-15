import { auth } from "@/auth";
import { prisma } from "@/lib/prisma";
import { env } from "@/lib/env";
import { queryPlayersDetailed } from "@/lib/sampquery";
import { formatCash, formatHours } from "@/lib/format";
import { getAccountExtras, getRecentActivity, getServerStats, timeAgo } from "@/lib/ucp-extra";
import Link from "next/link";

export const dynamic = "force-dynamic";

function formatUptime(seconds: number | null): string {
  if (seconds === null) return "—";
  const d = Math.floor(seconds / 86400);
  const h = Math.floor((seconds % 86400) / 3600);
  return d > 0 ? `${d}d ${h}h` : `${h}h`;
}

const skinSrc = (id: number) => `/img/skins/${Math.max(0, Math.min(311, id))}.png`;

export default async function UcpDashboard() {
  const session = await auth();
  const accountId = session!.user.id;

  const characters = await prisma.character.findMany({
    where: { account_id: accountId },
    orderBy: { player_logindate: "desc" },
  });
  const charIds = characters.map((c) => c.player_id);

  const [account, factions, players, serverStats, extras, activity] = await Promise.all([
    prisma.account.findUnique({
      where: { account_id: accountId },
      select: { account_name: true, account_quiz_passed: true, account_email_verified: true },
    }),
    prisma.faction.findMany({ select: { faction_id: true, faction_name: true } }),
    queryPlayersDetailed(env.sampQueryHost, env.rconPort, 2000).catch(() => null),
    getServerStats(),
    getAccountExtras(accountId, charIds),
    getRecentActivity(accountId, charIds, 6),
  ]);

  const online = players !== null;
  const factionName = Object.fromEntries(factions.map((f) => [f.faction_id, f.faction_name]));
  const displayName = account?.account_name ?? session!.user.name ?? "Player";

  const totalHours = characters.reduce((n, c) => n + c.player_hours, 0);
  const netWorth = characters.reduce((n, c) => n + c.player_cash + c.player_bankcash + c.player_savings, 0);
  const lastPlayed = characters[0];

  const needsEmail = !account?.account_email_verified;
  const needsQuiz = !account?.account_quiz_passed;

  return (
    <div className="ucp-stack">
      {/* Hero */}
      <section className="ucp-card ucp-hero">
        <div className="ucp-hero-bg" />
        <div className="ucp-hero-in">
          <span className={`ucp-chip ${online ? "ucp-chip-good" : "ucp-chip-bad"}`} style={{ width: "fit-content" }}>
            <i className="ucp-pulse" style={{ color: online ? "var(--good)" : "var(--bad)" }} /> Server {online ? "online" : "offline"}
          </span>
          <h1>
            Welcome back, <em>{displayName}</em>
          </h1>
          <p>
            {online
              ? `${players.length} player${players.length === 1 ? " is" : "s are"} on the server right now.`
              : "The server is currently offline."}
            {lastPlayed && (
              <>
                {" "}Your last character was <b style={{ color: "var(--text-1)" }}>{lastPlayed.player_name.replace(/_/g, " ")}</b>.
              </>
            )}
          </p>
          <div className="ucp-hero-actions">
            {online && (
              <a className="ucp-btn ucp-btn-primary" href={`samp://${env.sampQueryHost}:${env.rconPort}`}>
                <i className="fa-solid fa-play" /> Join Now
              </a>
            )}
            <Link className="ucp-btn ucp-btn-outline" href="/ucp/characters">
              <i className="fa-solid fa-person" /> My Characters
            </Link>
          </div>
        </div>
        <div className="ucp-hero-live">
          <div className="ucp-glass">
            <small>Players</small>
            <b>
              {online ? players.length : "—"}
              {serverStats.maxPlayers !== null && <span className="ucp-muted" style={{ fontSize: 14 }}>/{serverStats.maxPlayers}</span>}
            </b>
          </div>
          <div className="ucp-glass"><small>Uptime</small><b>{formatUptime(serverStats.uptimeSeconds)}</b></div>
          <div className="ucp-glass"><small>Peak today</small><b>{serverStats.peakToday ?? "—"}</b></div>
        </div>
      </section>

      {/* To-do callouts */}
      {needsQuiz && (
        <div className="ucp-todo ucp-todo-warn">
          <i className="fa-solid fa-triangle-exclamation" />
          <div>
            <b>Your account hasn&apos;t passed the rules quiz yet</b>
            <span>You need to pass it before you can create a character.</span>
          </div>
          <Link className="ucp-btn ucp-btn-primary" href="/ucp/quiz">Take the quiz</Link>
        </div>
      )}
      {needsEmail && (
        <div className="ucp-todo ucp-todo-warn">
          <i className="fa-solid fa-envelope" />
          <div>
            <b>Email address not verified</b>
            <span>Verify your email to enable password recovery.</span>
          </div>
          <Link className="ucp-btn ucp-btn-outline" href="/ucp/account">Account settings</Link>
        </div>
      )}

      {/* Stat tiles */}
      <div className="ucp-stats">
        <div className="ucp-card ucp-stat">
          <div className="ucp-stat-ic"><i className="fa-solid fa-clock" /></div>
          <small>Total playtime</small>
          <b>{formatHours(totalHours)}</b>
          <span className="ucp-stat-note">{extras.hoursThisWeek !== null ? `▲ ${extras.hoursThisWeek} h this week` : "Across all characters"}</span>
        </div>
        <div className="ucp-card ucp-stat">
          <div className="ucp-stat-ic"><i className="fa-solid fa-sack-dollar" /></div>
          <small>Net worth (all characters)</small>
          <b className="ucp-mono" style={{ fontSize: 24 }}>{formatCash(netWorth)}</b>
          <span className="ucp-stat-note">
            {extras.netWorth !== null
              ? `${extras.netWorth.delta >= 0 ? "▲" : "▼"} ${formatCash(Math.abs(extras.netWorth.delta))} in the last ${extras.netWorth.days} day${extras.netWorth.days === 1 ? "" : "s"}`
              : extras.cashFlowThisWeek !== null
                ? `${extras.cashFlowThisWeek >= 0 ? "▲" : "▼"} ${formatCash(Math.abs(extras.cashFlowThisWeek))} cash flow this week`
                : "Cash + bank + savings"}
          </span>
        </div>
        <div className="ucp-card ucp-stat">
          <div className="ucp-stat-ic"><i className="fa-solid fa-people-group" /></div>
          <small>Characters</small>
          <b>{characters.length}</b>
          <span className="ucp-stat-note">{characters.length === 0 ? "None created yet" : "On your account"}</span>
        </div>
        <div className="ucp-card ucp-stat">
          <div className="ucp-stat-ic"><i className="fa-solid fa-shield-halved" /></div>
          <small>Faction characters</small>
          <b className="ucp-mono" style={{ fontSize: 24 }}>{characters.filter(c => c.player_factionid > 0).length}</b>
          <span className="ucp-stat-note">Characters in a faction</span>
        </div>
      </div>

      <div className="ucp-cols">
        <div className="ucp-stack">
          {/* Characters */}
          <div className="ucp-card">
            <div className="ucp-card-head">
              <h2><i className="fa-solid fa-people-group" />Your characters</h2>
              <Link className="ucp-more" href="/ucp/characters">Manage all →</Link>
            </div>
            {characters.length === 0 ? (
              <p className="ucp-muted">You have no characters yet.</p>
            ) : (
              <div className="ucp-rows">
                {characters.slice(0, 4).map((c) => (
                  <Link key={c.player_id} href={`/ucp/characters/${c.player_id}`} className="ucp-row" style={{ textDecoration: "none" }}>
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img className="ucp-row-img" src={skinSrc(c.player_skinid)} alt="" />
                    <div>
                      <b>{c.player_name.replace(/_/g, " ")}</b>
                      <small>{c.player_factionid > 0 ? factionName[c.player_factionid] ?? "Faction" : "Civilian"}</small>
                    </div>
                    <div className="ucp-row-r">
                      <b className="ucp-mono">{formatCash(c.player_cash + c.player_bankcash)}</b>
                      <small>Lvl {c.player_level} · {c.player_hours} h</small>
                    </div>
                  </Link>
                ))}
              </div>
            )}
          </div>

        </div>

        <div className="ucp-stack">
          {/* Server status */}
          <div className="ucp-card">
            <div className="ucp-card-head">
              <h2><i className="fa-solid fa-signal" />Server status</h2>
              <span className={`ucp-chip ${online ? "ucp-chip-good" : "ucp-chip-bad"}`} style={{ marginLeft: "auto" }}>{online ? "Online" : "Offline"}</span>
            </div>
            <div className="ucp-kv">
              <div><small>Players</small><b>{online ? players.length : "—"}{serverStats.maxPlayers !== null ? ` / ${serverStats.maxPlayers}` : ""}</b></div>
              <div><small>Peak today</small><b>{serverStats.peakToday ?? "—"}</b></div>
              <div><small>Law on duty</small><b>{serverStats.lawOnDuty ?? "—"}</b></div>
              <div><small>Uptime</small><b>{formatUptime(serverStats.uptimeSeconds)}</b></div>
            </div>
            {online && serverStats.maxPlayers !== null && (
              <div className="ucp-bar"><i style={{ width: `${Math.min(100, (players.length / serverStats.maxPlayers) * 100)}%` }} /></div>
            )}
          </div>

          {/* Recent activity */}
          <div className="ucp-card">
            <div className="ucp-card-head"><h2><i className="fa-solid fa-bolt" />Recent activity</h2></div>
            {activity.length === 0 ? (
              <p className="ucp-muted">Nothing to show yet.</p>
            ) : (
              <div className="ucp-rows">
                {activity.map((a, i) => (
                  <div className="ucp-row" key={i}>
                    <div className="ucp-row-ico"><i className={`fa-solid ${a.icon}`} /></div>
                    <div>
                      <b>{a.title}</b>
                      <small>{a.detail ? `${a.detail} · ` : ""}{timeAgo(a.at)}</small>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Quick links */}
          <div className="ucp-card">
            <div className="ucp-card-head"><h2><i className="fa-solid fa-link" />Quick links</h2></div>
            <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>
              <Link className="ucp-btn ucp-btn-outline" href="/ucp/tools" style={{ padding: "6px 14px" }}><i className="fa-solid fa-toolbox" /> Tools</Link>
              <Link className="ucp-btn ucp-btn-outline" href="/ucp/quiz" style={{ padding: "6px 14px" }}><i className="fa-solid fa-scroll" /> Rules quiz</Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
