#!/usr/bin/env bash
# build.sh — このサイトは Co-Creative-Sutra-Translations へ移った。旧い URL ごとに、新しい頁へ案内する頁を作る。
set -euo pipefail

SITE="_site"
NEW="https://yutakusumi.github.io/Co-Creative-Sutra-Translations"
mkdir -p "$SITE/JA"

# 旧い頁 → 新しい頁
while IFS='|' read -r old new title; do
  [ -z "$old" ] && continue
  mkdir -p "$SITE/$(dirname "$old")"
  cat > "$SITE/$old" << HTMLEOF
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>移転しました ― ${title}</title>
  <link rel="canonical" href="${NEW}/${new}">
  <meta http-equiv="refresh" content="0; url=${NEW}/${new}">
  <script>location.replace("${NEW}/${new}" + location.hash);</script>
  <style>body{font-family:"Hiragino Mincho Pro","Noto Serif JP","Yu Mincho",serif;max-width:40em;margin:4em auto;padding:0 1em;line-height:1.9}</style>
</head>
<body>
<p>この頁は「共創数学による経典翻訳（Co-Creative Sutra Translations）」へ移りました。</p>
<p>新しい頁：<a href="${NEW}/${new}">${title}</a></p>
</body>
</html>
HTMLEOF
  echo "  forward: $old -> $new"
done << 'MAPEOF'
index.html||共創数学による経典翻訳
README.html|README.html|収録・訳し方・ライセンス・拠り所と検分・版
CBETA-NOTICE.html|CBETA-NOTICE.html|CBETA 電子佛典資料庫の使用說明と版の情報
JA/Muryoju-kyo-Co-Creative-Translation-JA.html|T0360-Muryoju-kyo/JA/Muryoju-kyo-Co-Creative-Translation-JA.html|仏説無量寿経 ― 共創数学による訳
JA/Kanmuryoju-kyo-Co-Creative-Translation-JA.html|T0365-Kanmuryoju-kyo/JA/Kanmuryoju-kyo-Co-Creative-Translation-JA.html|仏説観無量寿経 ― 共創数学による訳
JA/Amida-kyo-Co-Creative-Translation-JA.html|T0366-Amida-kyo/JA/Amida-kyo-Co-Creative-Translation-JA.html|仏説阿弥陀経　共創数学による訳
JA/Jodo-Sanbukyo-Comparison-Table-JA.html|Comparisons/Jodo-Sanbukyo/JA/Jodo-Sanbukyo-Comparison-Table-JA.html|浄土三部経　共創数学による対照表
MAPEOF

echo ""
echo "Build complete. Output directory: $SITE/"
