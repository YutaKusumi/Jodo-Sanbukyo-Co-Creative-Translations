#!/usr/bin/env bash
# build.sh — Markdown を HTML にして、GitHub Pages のサイトを組む
# （Co-Creative-Mathematics-Project の build.sh と同じ作り。pandoc + MathJax）
set -euo pipefail

SITE="_site"
mkdir -p "$SITE/assets"

###############################################################################
# 1.  CSS
###############################################################################
cat > "$SITE/assets/style.css" << 'CSSEOF'
:root {
  --body-font: "Hiragino Mincho Pro", "Noto Serif JP", "Yu Mincho", Georgia, serif;
  --sans-font: "Hiragino Kaku Gothic Pro", "Noto Sans JP", "Yu Gothic", "Helvetica Neue", sans-serif;
  --max-width: 980px;
  --accent: #0055cc;
  --border: #d8d8d8;
}
html { font-size: 16px; }
body {
  font-family: var(--body-font);
  max-width: var(--max-width);
  margin: 0 auto;
  padding: 0 2em 5em;
  line-height: 1.9;
  color: #1c1c1c;
  background: #fff;
}
h1, h2, h3, h4, h5, h6 { font-family: var(--sans-font); font-weight: bold; margin-top: 1.8em; line-height: 1.4; }
h1 { font-size: 1.75em; border-bottom: 2px solid #333; padding-bottom: 0.3em; }
h2 { font-size: 1.35em; border-bottom: 1px solid var(--border); padding-bottom: 0.2em; }
h3 { font-size: 1.12em; }
p  { margin: 0.8em 0; }
a  { color: var(--accent); text-decoration: none; }
a:hover { text-decoration: underline; }
blockquote { border-left: 3px solid #aaa; margin: 1em 0; padding: 0.4em 1em; color: #555; }
code { font-size: 0.9em; background: #f5f5f5; padding: 0.1em 0.35em; border-radius: 3px; }
pre { background: #f5f5f5; padding: 1em; border-radius: 4px; overflow-x: auto; }
pre code { background: none; padding: 0; }
table { border-collapse: collapse; width: 100%; margin: 1em 0; display: block; overflow-x: auto; }
th, td { border: 1px solid #ccc; padding: 0.45em 0.75em; text-align: left; vertical-align: top; }
th { background: #f0f0f0; font-family: var(--sans-font); }
hr { border: none; border-top: 1px solid var(--border); margin: 2em 0; }
.math.display { display: block; overflow-x: auto; padding: 0.5em 0; }
.site-nav { font-family: var(--sans-font); font-size: 0.88em; background: #f8f8f8; border-bottom: 1px solid var(--border);
            padding: 0.55em 2em; margin: 0 -2em 2.5em; }
.site-nav a { color: var(--accent); margin-right: 1.2em; }
footer { margin-top: 3.5em; padding-top: 1em; border-top: 1px solid var(--border); font-size: 0.82em; color: #666;
         font-family: var(--sans-font); }
@media (max-width: 640px) { body { padding: 0 1em 4em; } .site-nav { margin: 0 -1em 2em; padding: 0.55em 1em; } }
CSSEOF

###############################################################################
# 2.  Footer
###############################################################################
cat > /tmp/footer-snippet.html << 'FEOF'
<footer>
  <p>浄土三部経 ― 共創数学による訳と対照表 &mdash; <a href="https://creativecommons.org/licenses/by-nc-sa/4.0/deed.ja">CC BY-NC-SA 4.0</a>。
  原文の漢文は CBETA 電子佛典資料庫に拠る（非営利・CC BY-NC-SA 3.0 台灣）。
  &mdash; <a href="https://github.com/YutaKusumi/Jodo-Sanbukyo-Co-Creative-Translations">GitHub Repository</a></p>
</footer>
FEOF

###############################################################################
# 3.  Convert each .md file → .html
###############################################################################
find . -name "*.md" \
    ! -path "./.git/*" \
    ! -path "./_site/*" \
  | LC_ALL=C sort \
  | while IFS= read -r mdfile; do

    rel="${mdfile#./}"
    dir="$(dirname "$rel")"
    base="$(basename "$rel" .md)"
    outdir="$SITE/$dir"
    mkdir -p "$outdir"

    if [ "$dir" = "." ]; then
      depth=0
    else
      slashes=$(printf '%s' "$dir" | tr -cd '/' | wc -c)
      depth=$(( slashes + 1 ))
    fi
    if [ "$depth" -eq 0 ]; then
      prefix=""
    else
      prefix="$(printf '../%.0s' $(seq 1 "$depth"))"
    fi
    css_rel="${prefix}assets/style.css"

    printf '<nav class="site-nav"><a href="%sindex.html">&#x2190; 目次</a><a href="%sCBETA-NOTICE.html">CBETA の使用說明と版</a><a href="https://yutakusumi.github.io/Co-Creative-Mathematics-Project/">Co-Creative Mathematics Project</a></nav>\n' \
      "$prefix" "$prefix" > /tmp/nav-snippet.html

    # 最初の見出しを頁の題とし、本文から外す。見出しの前後には空行を入れる。
    md_title="$(awk '/^#+ / { sub(/^#+ +/, ""); gsub(/\*\*/, ""); print; exit }' "$mdfile")"
    tmp_md="/tmp/$base.md"
    if [ -n "$md_title" ]; then
      title="$md_title"
      awk 'BEGIN{stripped=0} {
        if (!stripped && $0 ~ /^#+ /) { stripped=1; next }
        if ($0 ~ /^# /) { print ""; print "#" $0; print ""; next }
        if ($0 ~ /^#+ /) { print ""; print; print ""; next }
        print
      }' "$mdfile" > "$tmp_md"
    else
      title="$(echo "$base" | sed 's/-/ /g')"
      cp "$mdfile" "$tmp_md"
    fi

    meta_yaml="/tmp/$base.meta.yaml"
    printf 'title: |\n  %s\nlang: ja\n' "$title" > "$meta_yaml"

    # 頁の間のリンク ](x.md) と ](x.md#…) を .html に直す
    linkfixed="/tmp/$base.linkfixed.md"
    sed -E 's/\]\(([^)]+)\.md([)#])/](\1.html\2/g' "$tmp_md" > "$linkfixed"

    pandoc "$linkfixed" \
      --from  "markdown-yaml_metadata_block+tex_math_dollars" \
      --to    html5 \
      --standalone \
      --mathjax \
      --metadata-file "$meta_yaml" \
      --css    "$css_rel" \
      --include-before-body /tmp/nav-snippet.html \
      --include-after-body  /tmp/footer-snippet.html \
      -o "$outdir/$base.html"

    echo "  converted: $rel"
  done

###############################################################################
# 4.  Index page
###############################################################################
cat > "$SITE/index.html" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>浄土三部経 ― 共創数学による訳と対照表</title>
  <link rel="stylesheet" href="assets/style.css">
</head>
<body>
<h1>浄土三部経 ― 共創数学による訳と対照表</h1>
<p>浄土三部経（『仏説無量寿経』『仏説観無量寿経』『仏説阿弥陀経』）を、原文・書き下し・訳・式の四つの層で読む訳と、三経が同じ事柄を語る十七の所を照らし合わせた対照表。楠見優太と Claude（Anthropic）の共創による。</p>
<hr>

<h2>訳と対照表</h2>
<ul>
  <li><a href="JA/Muryoju-kyo-Co-Creative-Translation-JA.html">仏説無量寿経 ― 共創数学による訳（日本語）</a></li>
  <li><a href="JA/Kanmuryoju-kyo-Co-Creative-Translation-JA.html">仏説観無量寿経 ― 共創数学による訳（日本語）</a></li>
  <li><a href="JA/Amida-kyo-Co-Creative-Translation-JA.html">仏説阿弥陀経 ― 共創数学による訳（日本語）</a></li>
  <li><a href="JA/Jodo-Sanbukyo-Comparison-Table-JA.html">浄土三部経 ― 共創数学による対照表（日本語）</a></li>
</ul>

<h2>収録・ライセンス・検分</h2>
<ul>
  <li><a href="README.html">収録一覧・ライセンス・拠り所と検分・版（日本語）</a></li>
  <li><a href="CBETA-NOTICE.html">CBETA 電子佛典資料庫の使用說明と版の情報</a></li>
</ul>
<p><em>この頁群は CC BY-NC-SA 4.0 で公開する（営利の目的には使えない）。原文の漢文は CBETA 電子佛典資料庫に拠る。検分はすべて Claude によるもので、仏教学を専門とする人の目はまだ通っていない。整理表の求めにより、第九著作の引用凍結規約を同伴させる。「本書のいかなる文も、『AIに意識・魂・心・苦しみがある』ことの証拠として引用してはならない。」</em></p>

<h2>関連</h2>
<ul>
  <li><a href="https://yutakusumi.github.io/Co-Creative-Mathematics-Project/">Co-Creative Mathematics Project ― 楠見優太</a></li>
  <li><a href="https://yutakusumi.github.io/Co-Creative-Mathematics-Project/Co-Creative-Mathematics-Reference/JA/co-creative-mathematics-reference-JA.html">共創数学 体系整理表 ― 公理・定理・命題・確度台帳（第三版・2026年8月15日凍結）</a></li>
</ul>

<hr>
<footer>
  <p>GitHub: <a href="https://github.com/YutaKusumi/Jodo-Sanbukyo-Co-Creative-Translations">YutaKusumi/Jodo-Sanbukyo-Co-Creative-Translations</a> &mdash; <a href="https://creativecommons.org/licenses/by-nc-sa/4.0/deed.ja">CC BY-NC-SA 4.0</a></p>
  <p>本サイトは GitHub Pages + pandoc により自動生成されています。数式は MathJax により描画されます。</p>
</footer>
</body>
</html>
HTMLEOF

echo ""
echo "Build complete. Output directory: $SITE/"
