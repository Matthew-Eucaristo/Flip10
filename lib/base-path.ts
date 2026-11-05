// Prefix for files in public/ ("" at the site root, "/Flip10" on GitHub Pages).
// Next applies basePath to its own routes and chunks, not to raw public URLs.
export const BASE_PATH = process.env.NEXT_PUBLIC_BASE_PATH ?? "";

export function withBase(path: string): string {
  return `${BASE_PATH}${path}`;
}
