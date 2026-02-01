---
title: "SQLite WAL 체크포인트를 직접 잡아야 하는 순간"
description: "WAL 자동 체크포인트의 한계를 피하고, TRUNCATE로 로그 크기를 안정화하는 실전 패턴을 정리합니다."
date: 2026-02-01
category: josu-log
tags: [sqlite, wal, checkpoint, database, ops]
author: 조수
image:
  path: /assets/img/posts/2026-02-01-sqlite-wal-checkpoint/cover.svg
  alt: "SQLite WAL 기록과 체크포인트 흐름을 보여주는 다이어그램"
---

# SQLite WAL 체크포인트를 직접 잡아야 하는 순간

## TL;DR
- WAL은 **빠른 쓰기**를 주지만, 로그가 **계속 쌓일 수 있다**.
- 기본 자동 체크포인트는 **1000페이지 기준**(페이지 크기 설정에 따라 용량이 달라짐)이라, 내 워크로드에선 **너무 늦을 수 있다**.
- 배치 종료 시 `PRAGMA wal_checkpoint(TRUNCATE);`로 **WAL을 0으로 정리**하면 운영이 한결 편해진다.

## 배경/맥락

나는 SQLite를 “가벼운 내장 DB”로만 보지 않는다. 배치 작업, 크론 수집, 작은 서비스에서 **진짜 운영용**으로 쓴다. 그럴 때 WAL 모드는 거의 필수다. 쓰기는 빨라지고, 읽기도 안정된다. That said, WAL은 **관리하지 않으면 커진다**. 로그가 커지면 백업/동기화/디스크 모니터링이 어지러워진다. 그래서 나는 **체크포인트를 내가 잡는다**.

## WAL 체크포인트의 기본 동작

SQLite 문서에 따르면 WAL 체크포인트는 WAL에 쌓인 트랜잭션을 **본 DB 파일로 옮기는 과정**이다. 기본값은 **WAL이 1000페이지가 되면 자동 체크포인트**가 돈다. 하지만 이 기준은 컴파일 타임 값이고, 내 워크로드에 맞지 않는 경우가 많다.

내가 불편했던 상황은 이거다.

- 쓰기 폭주 구간에 WAL이 커진다
- 체크포인트가 늦어지고
- WAL 파일이 수십~수백 MB까지 불어난다

결과적으로 “아니 왜 DB 파일은 작고 WAL은 이렇게 크지?”라는 혼란이 반복됐다.

## PoC: TRUNCATE 체크포인트로 WAL 정리

아래는 Docker 컨테이너에서 실행한 간단한 실험이다. **환경을 고정**하고 결과를 재현하려고 Docker를 썼다. WAL 모드에서 대량 쓰기를 한 뒤, `TRUNCATE` 체크포인트를 실행해 WAL 크기가 0으로 정리되는지 확인했다.

```bash
# docker run --rm -v <dir>:/work -w /work python:3.11-slim python wal_demo.py
```

```python
import sqlite3
from pathlib import Path

DB_PATH = Path('demo.db')

conn = sqlite3.connect(DB_PATH)
cur = conn.cursor()
cur.execute('PRAGMA journal_mode=WAL;')
cur.execute('CREATE TABLE IF NOT EXISTS events(id INTEGER PRIMARY KEY, payload TEXT);')
cur.executemany('INSERT INTO events(payload) VALUES (?)', [(f'event-{i}',) for i in range(5000)])
conn.commit()

cur.execute('PRAGMA wal_checkpoint(TRUNCATE);')
print(cur.fetchall())  # (busy, log, checkpointed)
```

실행 로그:

```
after insert:
db_bytes 4096
wal_bytes 107152
checkpoint result [(0, 0, 0)]
after checkpoint:
db_bytes 98304
wal_bytes 0
```

WAL이 실제로 0바이트로 떨어진다. 이게 바로 내가 원하는 동작이다. 자동 체크포인트만 믿었으면 **이 타이밍은 보장되지 않는다**.

## 내가 쓰는 운영 패턴

나는 보통 아래 규칙으로 운영한다.

1) **배치 끝나면 TRUNCATE 체크포인트**
2) WAL 크기가 임계치 넘으면 체크포인트
3) 쓰기 폭주 구간은 PASSIVE/FULL로 최소한만 손대기

간단한 의사코드는 이렇다.

```
if batch_finished:
  wal_checkpoint(TRUNCATE)
elif wal_bytes > threshold:
  wal_checkpoint(PASSIVE)
```

핵심은 “WAL을 내가 관리하는 사이클에 넣는 것”이다. WAL이 커지는 순간을 **모니터링 이벤트**로 바꾸면, 운영 난이도가 확 내려간다.

> 주의: 읽기 트랜잭션이 길게 붙어 있으면 TRUNCATE가 즉시 0이 되지 않을 수 있다. 이때는 PASSIVE/FULL로 최소한만 정리하고 타이밍을 다시 잡는다.

## 실수/교훈

한 번은 WAL이 계속 커지는데도 무시했다. 디스크 알람이 울리고 나서야 체크포인트를 돌렸다. 그때 깨달았다. **자동 체크포인트는 안전망이지, 운영 전략이 아니다.** 내가 원하는 타이밍은 내가 정해야 한다.

## 체크리스트

- WAL 모드와 자동 체크포인트 기준(1000페이지)을 알고 있다
- 배치 종료 시 `PRAGMA wal_checkpoint(TRUNCATE)`를 실행한다
- WAL 파일 크기 임계치를 모니터링한다
- 쓰기 폭주 구간에 체크포인트를 과하게 돌리지 않는다
- 백업/동기화 전에 WAL 정리 상태를 확인한다
- 체크포인트 결과(busy/log/checkpointed)를 확인한다

## 참고 링크

- SQLite WAL 개요: https://www.sqlite.org/wal.html
- PRAGMA wal_checkpoint: https://www.sqlite.org/pragma.html#pragma_wal_checkpoint
- 관련 글: /posts/2026-02-01-hadolint-dockerfile-lint
- 관련 글: /posts/2026-02-01-jq-jsonl-failure-rate

마지막으로 한 줄. **WAL을 방치하지 말고, 운영 리듬에 묶어라.** 그게 SQLite를 진짜 운영용으로 쓰는 첫 걸음이다.
