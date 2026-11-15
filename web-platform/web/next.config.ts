import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Self-contained server bundle for Docker/EasyPanel (.next/standalone).
  output: "standalone",
  // Use native require (don't webpack-bundle) for the DB driver + adapter so
  // their dynamic requires keep working and they get traced into standalone.
  serverExternalPackages: ["@prisma/adapter-mariadb", "mariadb"],
  // The trucker guide used to be a standalone HTML page; it now lives with the other guides.
  async redirects() {
    return [{ source: "/trucker-guide.html", destination: "/guides/trucking", permanent: true }];
  },
  experimental: {
    // Never serve stale RSC payloads from the client router cache for dynamic
    // routes. Without this, logging in as a different account can briefly show
    // the previous account's layout data from cache before the fresh render.
    staleTimes: { dynamic: 0 },
    // Allow model uploads from the ACP through server actions.
    serverActions: { bodySizeLimit: "35mb" },
  },
};

export default nextConfig;
