"use client";

import { usePathname } from "next/navigation";

function counterpartHref(pathname: string): {
  href: string;
  target: "zh" | "en";
} {
  if (pathname === "/en" || pathname.startsWith("/en/")) {
    return { href: "/zh" + pathname.slice(3), target: "zh" };
  }
  if (pathname === "/zh" || pathname.startsWith("/zh/")) {
    return { href: "/en" + pathname.slice(3), target: "en" };
  }
  // 法律頁等無語言前綴：英文內容，切換鈕導向中文首頁
  return { href: "/zh", target: "zh" };
}

export default function LocaleSwitch({ label }: { label: string }) {
  const pathname = usePathname();
  const { href, target } = counterpartHref(pathname || "/");
  return (
    <a
      className="nav__lang"
      href={href}
      onClick={() => {
        try {
          window.localStorage.setItem("lorescape_locale", target);
        } catch {
          /* ignore */
        }
      }}
    >
      {label}
    </a>
  );
}
