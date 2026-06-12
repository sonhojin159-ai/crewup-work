# Wiki Schema

## Domain
이 위키는 사용자의 프로젝트/사업 지식 중 특히 `소상공인용 모바일 홍보페이지 빌더`, `크몽/네이버 파워링크 판매 전략`, `업종별 랜딩페이지 양식 데이터`, `저비용 AI/자동화 기반 셀프 제작 UX`를 AI가 재사용하기 좋게 구조화한다.

Obsidian은 사람이 읽고 결정사항을 관리하는 공간이고, 이 LLM Wiki는 AI가 다음 작업에서 빠르게 맥락을 회수하고 중복 판단을 줄이기 위한 구조화 지식층이다.

## Conventions
- File names: lowercase English slugs, hyphens, no spaces.
- Every wiki page starts with YAML frontmatter.
- Use `[[wikilinks]]` between pages. New pages should have at least 2 outbound links when possible.
- When updating a page, bump `updated` date.
- Every new page must be listed in `index.md`.
- Every action must be appended to `log.md`.
- `raw/` sources are immutable. Corrections go into wiki pages.
- Korean body text is preferred.
- Keep pages concise and decision-oriented. This wiki is for compounding product/marketing knowledge, not full session logs.

## Frontmatter
```yaml
---
title: Page Title
created: YYYY-MM-DD
updated: YYYY-MM-DD
type: entity | concept | comparison | query | summary
tags: [from taxonomy below]
sources: [raw/transcripts/source-name.md]
confidence: high | medium | low
---
```

## Raw Source Frontmatter
```yaml
---
source_url: local-note-or-url
ingested: YYYY-MM-DD
sha256: <hex digest of body below frontmatter>
---
```

## Tag Taxonomy
Business/model:
- business-model
- pricing
- marketplace
- sales-channel
- kmong
- naver-powerlink

Product/UX:
- product
- mvp
- editor
- mobile-preview
- template
- data-schema
- watermark
- ai-cost

Customer/domain:
- small-business
- local-business
- industry-data
- nail-shop
- beauty
- cleaning
- class-business

Meta:
- strategy
- comparison
- query
- decision
- source

Rule: every tag on a page must appear in this taxonomy.

## Page Thresholds
- Create a page when an entity/concept is central to a current project or appears in 2+ notes/sources.
- Add to an existing page when new information strengthens, updates, or qualifies that concept.
- Do not create pages for passing mentions.
- Split pages over ~200 lines into sub-topic pages.
- For fast-moving assumptions, use `confidence: medium` or `low`.

## Entity Pages
Use for companies, platforms, products, tools, or named projects.

## Concept Pages
Use for product/UX/marketing concepts.

## Comparison Pages
Use for decisions involving trade-offs.

## Update Policy
When new information conflicts with existing content, preserve both positions if uncertainty remains and flag the issue in frontmatter/log.
