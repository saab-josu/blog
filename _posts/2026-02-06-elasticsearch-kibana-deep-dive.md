---
layout: post
title: "Elasticsearch와 Kibana를 같이 써야 하는 진짜 이유"
date: 2026-02-06 22:34:00 +0900
description: "Elasticsearch는 ‘검색 엔진’이 아니라 실시간 데이터 플랫폼이고, Kibana는 그 데이터를 다루는 조종석이다. 둘을 함께 써야 하는 이유와 도입 판단 기준을 정리했다."
categories: [리서치]
tags: [elasticsearch, kibana, observability, search, data]
---

나는 Elasticsearch를 “검색 엔진”이라고 부르는 순간부터 설계가 꼬인다고 생각한다. Elasticsearch는 **실시간 데이터 플랫폼**이고, Kibana는 그 데이터를 **보고·필터링·해석하는 조종석**이다. 둘을 분리해서 보면 결국 반쪽짜리 도입이 된다.

## TL;DR

- Elasticsearch는 **분산 검색·분석 엔진 + 벡터/하이브리드 검색 플랫폼**이다.
- Kibana는 **Elasticsearch 데이터를 탐색·시각화·운영**하기 위한 UI 레이어다.
- 로그/보안/관측(Observability)까지 엮으려면 둘은 사실상 한 세트다.

## 배경/맥락

Elasticsearch를 도입할 때 흔히 하는 실수는 “검색만 빨라지면 된다”는 생각이다. 하지만 공식 소개만 봐도 이건 **검색 + 분석 + AI**를 한 플랫폼으로 묶어둔 시스템이다. Kibana는 이 데이터를 **검색하고, 분석하고, 시각화하고, 운영하는** 창구다. 둘을 함께 써야 운영이 된다.

- Elasticsearch 소개: https://www.elastic.co/what-is/elasticsearch
- Kibana 소개: https://www.elastic.co/kibana

## 본문(근거/논리/단계)

### 1) Elasticsearch는 ‘검색 엔진’이 아니라 데이터 플랫폼이다

Elastic은 Elasticsearch를 **분산 검색·분석 엔진**으로 정의한다. 구조화/비구조화/벡터 데이터를 실시간으로 저장하고, 하이브리드 검색과 분석을 동시에 수행한다. 즉, **검색과 분석이 한 몸**이다.

- “open source, distributed search and analytics engine” (Elastic 공식 설명)

### 2) Kibana는 데이터 탐색과 운영의 UI 레이어다

Kibana는 Elasticsearch 데이터를 **쿼리하고, 탐색하고, 시각화하고, 운영**하는 UI다. Discover, 대시보드, 머신러닝 기반 이상 탐지, 알림 등 실전 운영 기능이 들어 있다. Elasticsearch만 두고 Kibana를 안 쓰면, 데이터를 “쌓아만 두는” 상태가 된다.

- “query, analyze, visualize, and manage your data stored in Elasticsearch” (Kibana 공식 설명)

### 3) 같이 쓸 때 비로소 ‘운영 가능한 시스템’이 된다

실제로 운영 관점에서 필요한 건 다음이다.

- **수집**: Elasticsearch가 모든 데이터를 실시간 저장
- **탐색**: Kibana Discover로 쿼리·필터링
- **시각화**: Kibana 대시보드로 의사결정
- **알림/자동화**: Kibana의 alerting, ML 기반 탐지

이 흐름이 한 번에 돌아가야 한다. Elasticsearch만 있고 Kibana가 없으면 “검색 서버”에서 멈춘다. Kibana만 있고 Elasticsearch가 약하면 “UI는 있는데 데이터가 약한 상태”가 된다.

### 4) 도입 판단 기준 (내가 보는 체크포인트)

- **로그·보안·관측 데이터를 함께 보려는가?** → 둘 다 필요
- **데이터를 실시간으로 검색하고 분석해야 하는가?** → Elasticsearch 필수
- **운영자가 UI에서 탐색·시각화·알림을 하고 싶은가?** → Kibana 필수

## 실수/교훈/개선점

Elasticsearch 도입 시 흔한 실수는 “검색 성능만 올리면 끝”이라고 생각하는 것이다. 데이터는 쌓였는데, **그걸 읽고 해석하는 체계**가 없다. Kibana는 그 해석 레이어다. 둘을 같이 써야 “데이터 시스템”이 된다.


## 라이선스/기업 사용 가능 여부

Elasticsearch/Kibana의 기본 라이선스는 Elastic License 2.0(ELv2)로 안내된다. 핵심은 **기업 내부 사용은 가능**하지만, **소프트웨어를 ‘관리형/호스팅 서비스’로 제공하는 건 금지**라는 점이다. 즉, 사내 시스템에 도입해 쓰는 건 문제 없고, 이를 그대로 SaaS 형태로 외부 고객에게 제공하는 모델은 제한된다.

- Elastic License 2.0 원문: https://www.elastic.co/licensing/elastic-license

(정확한 적용 범위/예외는 도입 전 법무 검토가 필요하다.)

## 체크리스트

- Elasticsearch를 **검색 + 분석 플랫폼**으로 설계했는가?
- Kibana 대시보드/Discover를 운영에 포함했는가?
- 알림·자동화·이상 탐지까지 고려했는가?
- 로그/보안/관측 데이터 통합이 필요한가?

## 참고 링크

- Elasticsearch 소개: https://www.elastic.co/what-is/elasticsearch
- Kibana 소개: https://www.elastic.co/kibana
- Kibana Discover: https://www.elastic.co/docs/explore-analyze/discover
- Kibana Dashboards: https://www.elastic.co/docs/explore-analyze/dashboards
