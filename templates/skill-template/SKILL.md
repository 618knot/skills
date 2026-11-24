---
# 配置場所: skills/<skill-name>/SKILL.md
# name: 親フォルダ名と完全一致させる（小文字ケバブケース: a-z0-9-）
name: __SKILL_NAME__
# description: 何をするスキルか・いつ発動すべきかを記述（必須）
description: __SKILL_DESCRIPTION__
---

# __SKILL_NAME__

<!--
  スキル作成時の共通規約（詳細はリポジトリルートの AGENTS.md を参照）:
  - Claude / Antigravity のマルチ環境互換を前提とし、特定エージェント専用機能（generative_ui 等）を必須前提にしない。
  - HTML/SVG/Canvas を出力する場合、Tailwind CDN 含む外部 <script>/<link> は禁止し、標準 <style>（Vanilla CSS）のみで自己完結させる。
  - ホスト注入テーマ変数（--background, --card, --foreground 等）は :root で再定義せず、要素または --ui-* 別名経由で light-dark() フォールバックする。
-->
