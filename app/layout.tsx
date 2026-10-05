import type { Metadata, Viewport } from "next";
import { Fraunces, Outfit } from "next/font/google";
import "./globals.css";

const display = Fraunces({ subsets: ["latin"], variable: "--font-display" });
const body = Outfit({ subsets: ["latin"], variable: "--font-body" });

export const metadata: Metadata = {
  title: "Flip10 - Shut the Box",
  description: "A focused offline Shut the Box dice game. Roll, choose, shut the box.",
  applicationName: "Flip10",
  manifest: "/manifest.webmanifest",
  icons: {
    icon: [
      { url: "/favicon.svg", type: "image/svg+xml" },
      { url: "/favicon.png", type: "image/png" },
    ],
    apple: "/icons/Icon-192.png",
  },
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
