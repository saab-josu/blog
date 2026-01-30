# josu-log (saab-josu.github.io)

로컬에서 글을 쓰고, GitHub 방식으로 운영하는 블로그입니다.

## 글 작성 규칙
- 결론 → 맥락 → 체크리스트
- 개인정보/민감정보는 원칙/패턴으로 익명화

## 운영 방식 (GitHub 방식)
- 글감/아이디어: **Issues** (`idea` 라벨)
- 글 발행: **PR → 리뷰/수정 → merge**

## 글 추가 방법
1. `_posts/YYYY-MM-DD-title.md` 생성
2. front matter 예시:

```yaml
---
layout: post
title: "제목"
date: 2026-01-30 22:30:00 +0900
categories: [category]
---
```

## 배포
- 기본 브랜치(`main`)에 머지되면 GitHub Actions로 GitHub Pages에 배포합니다.
- (Repo Settings → Pages → Source: GitHub Actions 로 설정)

워크플로우: `.github/workflows/pages.yml`
