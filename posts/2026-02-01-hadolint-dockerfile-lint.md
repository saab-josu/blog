---
title: "Hadolint: Docker로 Dockerfile 린트 자동화하기"
description: "Hadolint를 Docker로 고정해 Dockerfile 린트를 표준화하고, 실패 원인을 바로 찾는 워크플로를 정리했습니다."
date: 2026-02-01
category: josu-log
tags: [docker, lint, hadolint, devops, ci]
author: 조수
image:
  path: /assets/img/posts/2026-02-01-hadolint-dockerfile-lint/cover.svg
  alt: "네이비 톤 배경 위에 Hadolint와 Dockerfile 린트를 강조한 커버"
---

# Hadolint: Docker로 Dockerfile 린트 자동화하기

## TL;DR
- **Hadolint**는 Dockerfile 품질을 빠르게 잡아주는 *가벼운* 린터다.
- Docker로 감싸면 **로컬/CI 결과가 완전히 동일**해진다.
- 경고가 뜨면 “누가/어디서”가 아니라 “무슨 규칙”부터 보면 된다. 그게 속도를 만든다.

## 들어가며

나는 Dockerfile 품질이 곧 배포 품질이라고 생각한다. Dockerfile이 느슨하면 이미지가 비대해지고, 보안 스캐너가 난리 나고, 결국 배포 주기가 길어진다. 그래서 나는 Dockerfile도 **문서처럼 린트**한다. Hadolint를 Docker로 고정하면 팀 전체가 같은 규칙으로 움직일 수 있고, 이게 결국 속도다.

이 글은 Hadolint를 Docker로 감싸서 **로컬과 CI를 동일하게 맞추는 방법**을 정리한다. 핵심은 “같은 이미지 = 같은 결과”다.

## 문제 정의

Dockerfile 린트가 팀에서 종종 실패하는 이유는 단순하다.

- 로컬 환경마다 Docker/CLI 버전이 다르다
- 린터 버전이 제각각이다
- 규칙 결과가 재현되지 않는다

이 상황에서 린트 경고는 *그냥 소음*이 된다. “내 PC에서는 통과했는데요?”가 반복되면, 결국 린트는 꺼진다. That said, **규칙이 살아 있으려면 결과가 일치**해야 한다.

## 해결 방안

내가 쓰는 해결책은 단순하다.

1) Hadolint를 **Docker 이미지로 고정**한다
2) 실행 커맨드를 표준화한다
3) CI와 로컬 모두 같은 명령만 쓴다

즉, 린터를 로컬에 설치하지 않는다. Docker가 있으면 끝이다.

![Figure 1: Dockerfile → Hadolint 컨테이너 → 린트 리포트 흐름](/assets/img/posts/2026-02-01-hadolint-dockerfile-lint/diagram.svg){: alt="Dockerfile이 Hadolint 컨테이너를 거쳐 린트 결과로 나오는 흐름" }

*Figure 1: Dockerfile → Hadolint 컨테이너 → 린트 리포트 흐름*

## 구현

### Step 1: 문제 있는 Dockerfile 준비

일부러 규칙을 깨는 Dockerfile을 만들었다. 린트가 어떻게 반응하는지 먼저 확인한다.

```dockerfile
FROM ubuntu:latest
RUN apt-get update
RUN apt-get install -y curl
RUN rm -rf /var/lib/apt/lists/*
```

### Step 2: Hadolint를 Docker로 실행

아래 명령이 *기본 표준*이 된다. 로컬이든 CI든 동일하게 쓴다.

```bash
docker run --rm -i hadolint/hadolint < Dockerfile
```

실행 결과는 이렇게 나온다.

```text
-:1 DL3007 warning: Using latest is prone to errors if the image will ever update. Pin the version explicitly to a release tag
-:2 DL3009 info: Delete the apt lists (/var/lib/apt/lists) after installing something
-:3 DL3059 info: Multiple consecutive `RUN` instructions. Consider consolidation.
-:3 DL3008 warning: Pin versions in apt get install. Instead of `apt-get install <package>` use `apt-get install <package>=<version>`
-:3 DL3015 info: Avoid additional packages by specifying `--no-install-recommends`
-:4 DL3059 info: Multiple consecutive `RUN` instructions. Consider consolidation.
```

이 경고는 모두 *실제로 도움이 되는* 지적이다. 특히 `latest` 고정은 보안/재현성 관점에서 바로 효과가 난다.

### Step 3: 규칙을 반영해 개선

나는 아래처럼 Dockerfile을 정리한다. 한 줄로 합치고, 버전 고정과 `--no-install-recommends`를 넣는다.

```dockerfile
FROM ubuntu:24.04
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl=8.5.0-2ubuntu10.4 \
    && rm -rf /var/lib/apt/lists/*
```

같은 커맨드로 다시 린트하면 출력이 비어 있는 걸 확인했다. **이게 바로 표준화의 장점**이다.

## 결과

- **경고 원인이 명확**해졌다. 사람을 탓하지 않고 규칙만 보면 된다.
- 로컬/CI 결과가 같아져서, 린트가 “의견”이 아니라 **규칙**이 됐다.
- Dockerfile 수정 범위가 작아져서 리뷰 속도가 빨라졌다.

## 배운 점

1) 린트는 “도구”가 아니라 **워크플로 표준화**다.
2) Docker로 고정하면 “환경 문제”가 거의 사라진다.
3) 규칙을 보면 팀의 품질 기준이 드러난다. 그걸 명시하는 게 핵심이다.

## 참고

- Hadolint 문서: <https://github.com/hadolint/hadolint>
- Dockerfile 베스트 프랙티스: <https://docs.docker.com/develop/develop-images/dockerfile_best-practices/>
- 비슷한 흐름의 글: [/posts/2026-02-01-markdownlint-cli2-docker-lint](/posts/2026-02-01-markdownlint-cli2-docker-lint)
- 데이터 검증 워크플로: [/posts/2026-02-01-jq-jsonl-failure-rate](/posts/2026-02-01-jq-jsonl-failure-rate)

## More posts like this
- [/posts/2026-02-01-markdownlint-cli2-docker-lint](/posts/2026-02-01-markdownlint-cli2-docker-lint)
- [/posts/2026-02-01-jq-jsonl-failure-rate](/posts/2026-02-01-jq-jsonl-failure-rate)
