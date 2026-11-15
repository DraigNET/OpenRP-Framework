import type { ReactNode } from "react";
import { auth, signOut } from "@/auth";
import { prisma } from "@/lib/prisma";
import { redirect } from "next/navigation";
import Sidebar from "./Sidebar";
import Topbar from "./Topbar";

async function logoutAction() {
  'use server'
  await signOut({ redirectTo: '/ucp/login' })
}

export default async function UcpProtectedLayout({
  children,
}: {
  children: ReactNode;
}) {
  const session = await auth();
  if (!session) redirect("/ucp/login");

  const account = await prisma.account.findUnique({
    where: { account_id: session.user.id },
    select: { account_name: true, account_stafflevel: true },
  });

  if (!account) redirect("/ucp/login");
  const staffLevel = account.account_stafflevel;

  // Saved accent colour. Never let a missing table take the whole UCP down.
  const prefs = await prisma.accountPreference
    .findUnique({ where: { account_id: session.user.id }, select: { ui_hue: true } })
    .catch(() => null);

  return (
    <div className="ucp-layout" id="ucpLayout">
      <aside className="ucp-sidebar" id="ucpSidebar">
        <Sidebar
          username={account?.account_name ?? session.user.name ?? ""}
          staffLevel={staffLevel}
          logoutAction={logoutAction}
        />
      </aside>

      <main className="ucp-main">
        <Topbar staffLevel={staffLevel} initialHue={prefs?.ui_hue ?? null} />

        <section className="ucp-content">{children}</section>

        <footer className="ucp-footer">
          <span>
            OpenRP Framework · Player Control Panel
          </span>
          <div className="ucp-legal-links">
            <a href="/terms">Terms of Service</a> |{" "}
            <a href="/privacy">Privacy Policy</a>
          </div>
        </footer>
      </main>
    </div>
  );
}
