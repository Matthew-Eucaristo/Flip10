import type { Metadata, Viewport } from "next";
import { Fraunces, Outfit } from "next/font/google";
import "./globals.css";
import { withBase } from "@/lib/base-path";

const display = Fraunces({ subsets: ["latin"], variable: "--font-display" });
const body = Outfit({ subsets: ["latin"], variable: "--font-body" });

const title = "Flip10 - Shut the Box";
const description = "A focused offline Shut the Box dice game. Roll, choose, shut the box.";

// Absolute URL of the deployed site, set only by the GitHub Pages workflow.
// Social cards and the canonical link need it; other builds omit them.
const siteUrl = process.env.PAGES_SITE_URL?.replace(/\/*$/, "/");

export const metadata: Metadata = {
  title,
  description,
  applicationName: "Flip10",
  manifest: withBase("/manifest.webmanifest"),
  icons: {
    icon: [
      { url: withBase("/favicon.svg"), type: "image/svg+xml" },
      { url: withBase("/favicon.png"), type: "image/png" },
    ],
    apple: withBase("/icons/Icon-192.png"),
  },
  ...(siteUrl
    ? {
        metadataBase: new URL(siteUrl),
        alternates: { canonical: siteUrl },
        openGraph: {
          type: "website",
          siteName: "Flip10",
          title,
          description,
          url: siteUrl,
          images: [
            {
              url: new URL("og.png", siteUrl).href,
              width: 1200,
              height: 630,
              alt: "The Flip10 board: ten ivory tiles and two dice on green felt in a wooden box",
            },
          ],
        },
        twitter: { card: "summary_large_image", title, description, images: [new URL("og.png", siteUrl).href] },
      }
    : {}),
  appleWebApp: {
    capable: true,
    title: "Flip10",
    statusBarStyle: "black",
  },
};

export const viewport: Viewport = {
  themeColor: "#116B47",
  colorScheme: "dark",
  width: "device-width",
  initialScale: 1,
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" className={`${display.variable} ${body.variable}`}>
      <body>{children}</body>
    </html>
  );
}
