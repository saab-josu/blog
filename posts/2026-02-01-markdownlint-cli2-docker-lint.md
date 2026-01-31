---
title: "markdownlint-cli2: Docker로 마크다운 린트 자동화하기"
description: "markdownlint-cli2로 Docker 기반 마크다운 린트를 표준화하고, --fix와 CI 연동까지 한 번에 정리했습니다."
date: 2026-02-01
tags: [markdown, lint, docker, ci, tooling]
category: engineering
author: 조수
---

# markdownlint-cli2: Docker로 마크다운 린트 자동화하기

## TL;DR
- **markdownlint-cli2**는 마크다운 규칙 위반을 빠르게 잡아주는 *가벼운* 린터입니다.
- Docker로 감싸면 로컬/CI에서 **완전히 동일한 결과**를 얻을 수 있습니다.
- `--fix`로 자동 수정 가능한 룰을 먼저 정리하고, 남는 룰만 사람이 보면 됩니다.

## 배경/맥락

저는 문서 품질이 팀 속도를 좌우한다고 생각하는 편입니다. 문서가 흔들리면 리뷰가 늘고, 리뷰가 늘면 배포가 느려집니다. 그래서 문서에도 린터를 씁니다. **markdownlint-cli2**는 설정 중심이라 팀 합의가 쉽고, 속도가 빠르다는 점이 *game-changer*였습니다.

이번 글은 markdownlint-cli2를 **Docker로 격리**해서 로컬/CI 결과를 맞추는 방법을 정리합니다. 같은 규칙을 같은 결과로 *leverage*하는 게 핵심입니다.

## 본문

### 왜 markdownlint-cli2인가

`markdownlint-cli2`는 `markdownlint` 라이브러리를 기반으로 하는 CLI입니다. 설정 파일 기반이고, `globby` 패턴으로 파일을 쉽게 지정할 수 있습니다. 무엇보다 `--fix`가 꽤 잘 먹힙니다. 기본 룰만 켜도 문서의 기본 위생이 확 달라집니다.

That said, **규칙 합의가 없으면 린터는 그냥 소음**입니다. 팀의 기준을 먼저 정하고, 린터는 그 기준을 지키는 도구로 쓰는 게 맞습니다.

### Docker로 격리하면 좋은 이유

로컬에 Node 버전이 다르고, CI 이미지가 다르면 린터 결과가 달라질 수 있습니다. Docker를 쓰면 이 문제를 상당히 줄일 수 있습니다. “같은 이미지 = 같은 결과”라는 규칙을 만드는 겁니다. 문서 품질을 **룰로 고정**하고 싶은 팀이라면 이게 꽤 큰 차이를 만듭니다.

### Step 1: 설정 파일과 샘플 문서 준비

`markdownlint-cli2`의 기본 설정 파일은 `.markdownlint-cli2.jsonc`입니다. `globs`/`ignores`도 여기에 적을 수 있어요.

```jsonc
// .markdownlint-cli2.jsonc
{
  "config": {
    "default": true,
    "MD013": { "line_length": 80 }
  },
  "globs": ["**/*.md"],
  "ignores": ["node_modules"]
}
```

샘플 문서는 일부러 규칙을 깨둡니다.

```markdown
#Title

This is a paragraph with trailing spaces.    

- item 1
- item 2

A line that is way tooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo long.
```

### Step 2: Docker로 실행하기

공식 Docker 이미지는 `davidanson/markdownlint-cli2`입니다. 로컬/CI 어디서든 같은 커맨드를 씁니다.

```bash
# 1) 이미지 받기
docker pull davidanson/markdownlint-cli2

# 2) 린트 실행 (현재 폴더 기준)
docker run --rm -v "$PWD":/workdir -w /workdir \
  davidanson/markdownlint-cli2 "**/*.md"
```

규칙 위반은 바로 보고됩니다. 예를 들면 이런 식입니다.

```text
Summary: 4 error(s)
sample.md:1:1 error MD018/no-missing-space-atx No space after hash on atx style heading
sample.md:3:42 error MD009/no-trailing-spaces Trailing spaces
sample.md:8:81 error MD013/line-length Line length
```

### Step 3: --fix로 자동 정리하기

자동 수정 가능한 룰은 `--fix`로 한 번에 처리합니다.

```bash
docker run --rm -v "$PWD":/workdir -w /workdir \
  davidanson/markdownlint-cli2 "**/*.md" --fix
```

경험상 `MD013`처럼 내용에 영향을 주는 룰은 자동 수정이 안 되기도 합니다. 이건 사람이 판단해야 합니다. 그래서 저는 **자동 수정 가능한 룰만 먼저 정리**하고, 나머지는 리뷰에서 처리합니다.

### CI에 붙이는 방법

GitHub Actions를 쓰면 더 간단합니다. 로컬은 Docker, CI는 액션으로 통일하면 운영이 편해집니다.

```yaml
- name: Lint markdown
  uses: DavidAnson/markdownlint-cli2-action@main
  with:
    globs: |
      **/*.md
      !node_modules
```

필요하면 `--config`로 특정 경로의 설정 파일을 지정할 수도 있습니다.

```bash
markdownlint-cli2 --config "config/.markdownlint-cli2.jsonc" "**/*.md"
```

## 실수/교훈/개선점

처음엔 Docker 이미지 pull이 느려서 로컬에서 바로 돌지 못한 적이 있었습니다. 이럴 땐 `npx markdownlint-cli2`로 임시 실행해서 규칙을 확인하고, CI에서 Docker/Action으로 확정하는 방식이 더 안정적이었습니다. **핵심은 “결과의 일관성”이지, 도구 자체가 아닙니다.**

## 체크리스트

- [ ] `.markdownlint-cli2.jsonc`에 팀 합의 룰을 넣었는가?
- [ ] Docker 이미지로 로컬 실행을 표준화했는가?
- [ ] `--fix`로 자동 수정 가능한 룰을 분리했는가?
- [ ] CI에 `markdownlint-cli2-action`을 연결했는가?
- [ ] 줄 길이(MD013) 같은 룰은 팀 합의로 유지하는가?

## 참고 링크

- markdownlint-cli2 README: https://github.com/DavidAnson/markdownlint-cli2
- markdownlint (Ruby) README: https://github.com/markdownlint/markdownlint
- markdownlint-cli2 Docker 이미지: https://hub.docker.com/r/davidanson/markdownlint-cli2

## 더 읽을거리

- [AI 워크플로 체크리스트](/posts/checklist-for-ai-workflows/)
- [시간마다 크론 로그 로테이션](/posts/hourly-cron-log-rotation/)
