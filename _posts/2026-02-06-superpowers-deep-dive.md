---
layout: post
title: "Superpowers: 코딩 에이전트가 ‘계획 → 실행’으로 미끄러지지 않게 만드는 방법"
date: 2026-02-06 22:12:00 +0900
description: "obra/superpowers를 깊게 뜯어보며, 왜 이 프로젝트가 ‘에이전트 워크플로우’를 제대로 잡아주는지 정리했다. 핵심은 스킬 기반의 강제 단계와 테스트 중심 설계다."
categories: [리서치]
tags: [ai, agents, workflow, tdd, claude, codex, opencode]
---

나는 코딩 에이전트가 ‘그럴듯한 코드’를 뱉는 것보다 **계획대로 일하게 만드는 것**이 더 중요하다고 생각한다. Superpowers는 그 문제를 정면으로 다룬 프로젝트다. 단순히 스킬 몇 개를 모아둔 게 아니라, **설계 → 계획 → 실행 → 검증**을 강제하는 워크플로우다.

## TL;DR

- Superpowers는 “스킬 기반”으로 **에이전트의 행동 순서를 강제**한다.
- 계획 없이 바로 구현하는 습관을 끊고, **TDD와 검증 루프**를 밀어 넣는다.
- Claude Code, Codex, OpenCode 각각의 설치/운영 흐름이 다르지만, 핵심은 동일하다.

## 배경/맥락

에이전트는 빠르다. 그런데 빠른 만큼 **방향을 잃는 속도도 빠르다**. Superpowers는 그 문제를 스킬 시스템으로 묶어 “대화 → 설계 → 계획 → 실행 → 리뷰”를 **필수 단계**로 만든다. README만 봐도, 자동 실행이 아니라 **의도적으로 흐름을 통제**하려는 철학이 보인다.

- 프로젝트 설명: https://github.com/obra/superpowers

## 본문(근거/논리/단계)

### 1) 핵심은 “스킬이 자동으로 시작되는 것”이 아니라 “단계를 강제하는 것”

README의 How it works 섹션은 명확하다. 에이전트가 코드를 바로 쓰지 않고, 먼저 **문제 정의와 설계**부터 끌어낸다. 이후 구현 계획을 짧은 단위로 쪼개고, **TDD(RED–GREEN–REFACTOR)**를 강제한다. 이게 흔한 “prompt engineering”과 다른 지점이다.

- How it works, The Basic Workflow: https://github.com/obra/superpowers#how-it-works

### 2) 워크플로우가 실제로 정의되어 있다

Superpowers는 “원칙”이 아니라 **정확한 단계**를 스킬로 고정한다.

- brainstorming → 설계 질문과 문서화
- writing-plans → 2~5분 단위 작업 설계
- subagent-driven-development / executing-plans → 계획 실행
- test-driven-development → TDD 강제
- requesting-code-review → 작업 단위 리뷰

즉, “좋은 습관”을 권고하는 게 아니라 **루틴을 강제**한다.

- Workflow 상세: https://github.com/obra/superpowers#the-basic-workflow

### 3) 최신 릴리즈가 말하는 방향성

v4.2.0 릴리즈 노트를 보면 철학이 더 명확해진다.

- Codex는 **native skill discovery**로 전환(bootstrap CLI 제거)
- worktree 강제(메인 브랜치 실수 방지)
- 윈도우 이슈 해결(실행/성능/경로 문제 해결)

이건 단순한 버그 수정이 아니라, **현실적인 운영 장애**를 걷어내는 움직임이다.

- Release Notes v4.2.0: https://github.com/obra/superpowers/blob/main/RELEASE-NOTES.md

### 4) 설치가 다르지만 목적은 같다

- Claude Code: 플러그인 마켓에서 설치
- Codex: .codex/INSTALL.md 안내
- OpenCode: docs/README.opencode.md 안내

설치 방식은 다르지만, **스킬 기반 워크플로우 통제**라는 목적은 동일하다.

- Codex 설치: https://github.com/obra/superpowers/blob/main/.codex/INSTALL.md
- OpenCode 문서: https://github.com/obra/superpowers/blob/main/docs/README.opencode.md

### 5) 내가 이 프로젝트를 높게 보는 이유

에이전트 시대의 문제는 “코드 품질”보다 **의사결정 품질**이다. Superpowers는 그걸 **프로세스로 강제**한다. 에이전트가 똑똑해지는 것보다, **똑바로 일하게 만드는 것**이 더 중요하다. 이 프로젝트는 그 방향에 가장 가까운 구현이다.

## 실수/교훈/개선점

에이전트 도입 초기에 흔한 실수는 **“속도에 취해 계획을 건너뛰는 것”**이다. Superpowers는 그 실수를 막아주는 좋은 안전장치다. 다만, 강제된 단계가 많아 **짧은 실험에는 부담**이 될 수 있다. 그럴 땐 최소 스킬만 적용하는 세팅이 필요하다.

## 체크리스트

- 구현 전에 설계 문서가 실제로 만들어졌는가?
- 계획이 2~5분 단위로 쪼개져 있는가?
- TDD 단계(RED→GREEN→REFACTOR)를 어긴 흔적이 없는가?
- 리뷰 단계가 작업마다 실행되는가?
- 메인 브랜치 직접 작업을 피했는가?

## 참고 링크

- Superpowers README: https://github.com/obra/superpowers
- Workflow 설명: https://github.com/obra/superpowers#the-basic-workflow
- Release Notes: https://github.com/obra/superpowers/blob/main/RELEASE-NOTES.md
- Codex 설치: https://github.com/obra/superpowers/blob/main/.codex/INSTALL.md
- OpenCode 문서: https://github.com/obra/superpowers/blob/main/docs/README.opencode.md
