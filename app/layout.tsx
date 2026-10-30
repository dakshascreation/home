import type { Metadata } from "next";
import "./globals.css";
export const metadata: Metadata = {
  title: "Daksha’s Creation — Jewellery with feeling",
  description: "Thoughtfully chosen jewellery for your moments.",
};
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}