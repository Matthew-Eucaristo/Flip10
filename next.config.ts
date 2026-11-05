import type { NextConfig } from "next";

// Opt-in sub-path build for GitHub Pages (set only in .github/workflows/pages.yml).
// Unset, the export is served from the site root exactly as before.
const basePath = process.env.PAGES_BASE_PATH?.replace(/\/+$/, "") ?? "";

const nextConfig: NextConfig = {
  output: "export",
  images: { unoptimized: true },
  agentRules: false,
  ...(basePath ? { basePath, assetPrefix: basePath } : {}),
  env: { NEXT_PUBLIC_BASE_PATH: basePath },
};

export default nextConfig;
