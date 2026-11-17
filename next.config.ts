import type { NextConfig } from "next";

const basePath = process.env.PAGES_BASE_PATH?.replace(/\/+$/, "") ?? "";

const nextConfig: NextConfig = {
  output: "export",
  images: { unoptimized: true },
  agentRules: false,
  ...(basePath ? { basePath, assetPrefix: basePath } : {}),
  env: { NEXT_PUBLIC_BASE_PATH: basePath },
};

export default nextConfig;
