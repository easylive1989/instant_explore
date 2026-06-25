const detect = `(function(){try{var s=localStorage.getItem('lorescape_locale');if(s==='zh'||s==='en'){location.replace('/'+s);return;}}catch(e){}var l=(navigator.language||'').toLowerCase();location.replace(l.indexOf('zh')===0?'/zh':'/en');})();`;

export default function RootRedirect() {
  return (
    <html lang="zh-Hant">
      <head>
        <meta httpEquiv="refresh" content="0;url=/zh" />
        <script dangerouslySetInnerHTML={{ __html: detect }} />
      </head>
      <body />
    </html>
  );
}
