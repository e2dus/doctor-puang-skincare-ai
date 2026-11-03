# 🧴 Puang - AI 스킨케어 어시스턴트

AI 기반 피부 분석 및 맞춤 스킨케어 제품 추천 Flutter 앱입니다.

## 📱 주요 기능

| 기능                | 설명                                            |
| ------------------- | ----------------------------------------------- |
| **AI 피부 분석**    | 설문을 통해 피부 타입을 분석하고 맞춤 제품 추천 |
| **제품 추천**       | Sephora 제품 중 피부 타입에 맞는 제품 추천      |
| **예산별 루틴**     | 예산에 맞는 스킨케어 루틴 제안                  |
| **스킨케어 캘린더** | 일일 스킨케어 루틴 기록 및 관리                 |
| **대시보드**        | 피부 관리 점수 및 친구 비교                     |

---

## 🏗️ 아키텍처 설명 (비전공자용)

### "Clean Architecture"란?

앱을 **레고 블록**처럼 만드는 방법입니다!

```
🏠 집을 짓는다고 생각해보세요:

1층 (Data)     = 재료 창고 📦 - 데이터를 가져오고 저장
2층 (Domain)   = 설계 도면 📐 - 비즈니스 규칙 정의
3층 (Presentation) = 인테리어 🎨 - 사용자가 보는 화면
```

### 왜 이렇게 나누나요?

| 장점            | 설명                                         |
| --------------- | -------------------------------------------- |
| **수정이 쉬움** | 화면 디자인을 바꿔도 데이터 로직에 영향 없음 |
| **테스트 용이** | 각 부분을 독립적으로 테스트 가능             |
| **협업 편리**   | 팀원끼리 다른 부분을 동시에 개발 가능        |
| **재사용성**    | 한 번 만든 코드를 다른 곳에서도 사용 가능    |

### 실생활 비유

```
🍕 피자 가게로 비유하면:

📦 Data (재료)
   └── 치즈, 토마토, 반죽 등을 창고에서 가져옴
   └── = 서버에서 데이터를 가져오거나 저장

📐 Domain (레시피)
   └── "피자는 이렇게 만든다"는 규칙
   └── = 앱이 어떻게 동작해야 하는지 정의

🎨 Presentation (서빙)
   └── 손님에게 예쁘게 피자를 내놓음
   └── = 사용자에게 화면을 보여줌
```

---

## 📁 폴더 구조

```
lib/
├── main.dart                    # 앱 시작점
├── api_keys.dart               # API 키 (비밀!)
│
├── core/                        # 🔧 공통 유틸리티
│   ├── constants/              # 상수 값들
│   ├── error/                  # 에러 처리
│   ├── network/                # 네트워크 설정
│   ├── theme/                  # 앱 테마 (색상, 글꼴)
│   └── usecases/               # UseCase 기본 클래스
│
└── features/                    # 📦 기능별 폴더
    ├── auth/                   # 🔐 로그인/회원가입
    ├── chat/                   # 💬 AI 챗봇
    ├── product/                # 🛍️ 제품 관리
    ├── dashboard/              # 📊 대시보드
    ├── skincare/               # 📅 캘린더
    ├── settings/               # ⚙️ 설정
    └── main/                   # 🏠 메인 화면
```

### 각 기능(Feature) 내부 구조

```
feature/
├── data/                        # 📦 데이터 레이어
│   ├── datasources/            # 데이터 출처 (API, 로컬저장)
│   ├── models/                 # 데이터 형태 정의
│   └── repositories/           # 저장소 구현체
│
├── domain/                      # 📐 도메인 레이어
│   ├── entities/               # 핵심 데이터 구조
│   ├── repositories/           # 저장소 인터페이스
│   └── usecases/               # 비즈니스 로직
│
└── presentation/                # 🎨 프레젠테이션 레이어
    ├── pages/                  # 화면 (Page)
    ├── viewmodels/             # 상태 관리 (Provider)
    └── widgets/                # 재사용 UI 컴포넌트
```

---

## 🎯 레이어별 역할

### 1. Data Layer (데이터 레이어) 📦

> **"데이터를 어디서 가져올까?"**

| 폴더            | 역할        | 예시                  |
| --------------- | ----------- | --------------------- |
| `datasources/`  | 데이터 출처 | 서버 API, 로컬 저장소 |
| `models/`       | 데이터 형태 | JSON → Dart 객체 변환 |
| `repositories/` | 저장소 구현 | 실제 데이터 CRUD 수행 |

### 2. Domain Layer (도메인 레이어) 📐

> **"앱이 어떻게 동작해야 할까?"**

| 폴더            | 역할          | 예시                      |
| --------------- | ------------- | ------------------------- |
| `entities/`     | 핵심 데이터   | User, Product 정의        |
| `repositories/` | 인터페이스    | "이런 기능이 필요해" 선언 |
| `usecases/`     | 비즈니스 로직 | 로그인, 제품 추천 로직    |

### 3. Presentation Layer (프레젠테이션 레이어) 🎨

> **"사용자에게 어떻게 보여줄까?"**

| 폴더          | 역할      | 예시                   |
| ------------- | --------- | ---------------------- |
| `pages/`      | 화면      | 로그인 화면, 홈 화면   |
| `viewmodels/` | 상태 관리 | 로딩 상태, 데이터 관리 |
| `widgets/`    | UI 조각   | 버튼, 카드, 리스트     |

---

## 🛠️ 기술 스택

| 기술                       | 용도                  |
| -------------------------- | --------------------- |
| **Flutter**                | 크로스 플랫폼 앱 개발 |
| **Riverpod**               | 상태 관리             |
| **Dio**                    | HTTP 통신             |
| **Flutter Secure Storage** | 보안 저장소           |
| **Rive**                   | 애니메이션            |
| **Table Calendar**         | 캘린더 UI             |
| **OpenRouter API**         | AI 제품 추천          |

---

## 🚀 시작하기

### 1. 프로젝트 클론

```bash
git clone [repository-url]
cd mobileprogramming_groupproject_2025
```

### 2. 의존성 설치

```bash
flutter pub get
```

### 3. API 키 설정

`lib/api_keys.dart` 파일에 API 키를 설정하세요.

### 4. 앱 실행

```bash
flutter run
```

---

## 🤖 LLM을 위한 코드베이스 가이드

> 이 섹션은 AI/LLM이 이 프로젝트를 이해하고 수정할 때 참고하는 지침입니다.

### 📋 프로젝트 개요

```yaml
프로젝트명: Puang - AI Skincare Assistant
프레임워크: Flutter 3.x
언어: Dart
아키텍처: Clean Architecture (Feature-based)
상태관리: Riverpod 2.x (StateNotifier 패턴)
```

### 🗂️ 파일 네이밍 컨벤션

| 파일 타입              | 네이밍 규칙                               | 예시                          |
| ---------------------- | ----------------------------------------- | ----------------------------- |
| Page                   | `*_page.dart`                             | `login_page.dart`             |
| Widget                 | `*_widget.dart` 또는 설명적 이름          | `message_bubble.dart`         |
| ViewModel/Provider     | `*_viewmodel.dart` 또는 `*_provider.dart` | `auth_viewmodel.dart`         |
| Model                  | `*_model.dart`                            | `product_model.dart`          |
| Entity                 | `*_entity.dart`                           | `user_entity.dart`            |
| Repository (Interface) | `*_repository.dart`                       | `auth_repository.dart`        |
| Repository (Impl)      | `*_repository_impl.dart`                  | `auth_repository_impl.dart`   |
| UseCase                | `*_usecase.dart`                          | `sign_in_usecase.dart`        |
| DataSource             | `*_datasource.dart`                       | `auth_remote_datasource.dart` |

### 🔍 주요 파일 위치

```
새 기능 추가 시:
├── lib/features/{feature_name}/
│   ├── data/
│   │   ├── datasources/{feature}_remote_datasource.dart
│   │   ├── models/{feature}_model.dart
│   │   └── repositories/{feature}_repository_impl.dart
│   ├── domain/
│   │   ├── entities/{feature}_entity.dart
│   │   ├── repositories/{feature}_repository.dart
│   │   └── usecases/{action}_{feature}_usecase.dart
│   └── presentation/
│       ├── pages/{feature}_page.dart
│       ├── viewmodels/{feature}_viewmodel.dart
│       └── widgets/{feature}_widget.dart
```

### 📌 주요 진입점

| 파일                                                  | 설명                                  |
| ----------------------------------------------------- | ------------------------------------- |
| `lib/main.dart`                                       | 앱 진입점, ProviderScope 설정         |
| `lib/features/main/presentation/pages/main_page.dart` | 메인 네비게이션 (BottomNavigationBar) |
| `lib/core/theme/app_theme.dart`                       | 앱 전역 테마                          |
| `lib/core/constants/api_constants.dart`               | API 엔드포인트                        |

### 🔧 코드 수정 가이드

#### 새 화면 추가하기

1. `lib/features/{feature}/presentation/pages/` 에 `*_page.dart` 생성
2. 필요시 `viewmodels/` 에 상태 관리 파일 생성
3. `main_page.dart`의 `_screens` 리스트에 추가

#### 새 API 연동하기

1. `lib/core/constants/api_constants.dart`에 엔드포인트 추가
2. `data/datasources/`에 DataSource 생성
3. `data/repositories/`에 Repository 구현
4. `domain/usecases/`에 UseCase 생성

#### 상태 관리 패턴

```dart
// Riverpod 2.x StateNotifier 패턴
class MyNotifier extends StateNotifier<MyState> {
  MyNotifier() : super(MyState.initial());

  void updateData(String data) {
    state = state.copyWith(data: data);
  }
}

final myProvider = StateNotifierProvider<MyNotifier, MyState>(
  (ref) => MyNotifier(),
);
```

### 📂 Feature별 상세 구조

#### 🔐 Auth (인증)

```
features/auth/
├── data/
│   ├── datasources/
│   │   ├── auth_remote_datasource.dart  # 서버 로그인/회원가입
│   │   └── auth_local_datasource.dart   # 토큰 저장
│   ├── models/
│   │   └── auth_tokens_model.dart       # JWT 토큰 모델
│   └── repositories/
│       └── auth_repository_impl.dart    # 인증 저장소 구현
├── domain/
│   ├── entities/
│   │   ├── user_entity.dart             # 사용자 엔티티
│   │   └── auth_tokens_entity.dart      # 토큰 엔티티
│   ├── repositories/
│   │   └── auth_repository.dart         # 인증 저장소 인터페이스
│   └── usecases/
│       ├── sign_in_usecase.dart         # 로그인 로직
│       ├── sign_up_usecase.dart         # 회원가입 로직
│       ├── sign_out_usecase.dart        # 로그아웃 로직
│       └── check_auth_status_usecase.dart # 인증 상태 확인
└── presentation/
    ├── pages/
    │   ├── login_page.dart              # 로그인 화면
    │   └── signup_page.dart             # 회원가입 화면
    └── viewmodels/
        └── auth_viewmodel.dart          # 인증 상태 관리
```

#### 💬 Chat (AI 챗봇)

```
features/chat/
├── data/
│   └── models/
│       └── message_model.dart           # 채팅 메시지 모델
└── presentation/
    ├── pages/
    │   ├── chat_bot_page.dart           # 챗봇 메인 (3가지 옵션)
    │   ├── chat_survey_page.dart        # 피부 타입 설문
    │   ├── chat_find_skincare_page.dart # AI 제품 추천
    │   └── chat_budget_routine_page.dart # 예산별 루틴 추천
    ├── viewmodels/
    │   ├── typing_provider.dart         # 타이핑 상태
    │   ├── chat_bot_state_provider.dart # 챗봇 상태
    │   ├── survey_data_provider.dart    # 설문 데이터
    │   ├── survey_message_provider.dart # 설문 메시지
    │   ├── recommend_message_provider.dart # AI 추천 메시지
    │   ├── budget_message_provider.dart # 예산 추천 메시지
    │   └── skin_types_data.dart         # 피부 타입 데이터
    └── widgets/
        ├── message_bubble.dart          # 메시지 버블 (선택 옵션 포함)
        ├── typing_indicator.dart        # 타이핑 인디케이터
        ├── product_recommendation_carousel.dart # 제품 캐러셀
        └── chat_input_field.dart        # 입력 필드
```

#### 🛍️ Product (제품)

```
features/product/
├── data/
│   ├── datasources/
│   │   ├── product_remote_datasource.dart # 제품 API
│   │   └── product_local_datasource.dart  # 좋아요/차단 로컬 저장
│   ├── models/
│   │   └── product_model.dart           # 제품 모델
│   └── repositories/
│       └── product_repository_impl.dart # 제품 저장소 구현
├── domain/
│   ├── entities/
│   │   └── product_entity.dart          # 제품 엔티티
│   ├── repositories/
│   │   └── product_repository.dart      # 제품 저장소 인터페이스
│   └── usecases/
│       ├── get_ranking_products_usecase.dart    # 랭킹 조회
│       ├── manage_cart_usecase.dart             # 장바구니 관리
│       ├── manage_liked_products_usecase.dart   # 좋아요 관리
│       └── manage_blocked_products_usecase.dart # 차단 관리
└── presentation/
    ├── pages/
    │   └── home_page.dart               # 홈 화면 (제품 목록)
    ├── viewmodels/
    │   ├── ranking_viewmodel.dart       # 랭킹 상태
    │   ├── cart_viewmodel.dart          # 장바구니 상태
    │   ├── liked_products_viewmodel.dart # 좋아요 상태
    │   ├── blocked_products_viewmodel.dart # 차단 상태
    │   └── no_recommend_viewmodel.dart  # 비추천 상태
    └── widgets/
        └── product_grid_item.dart       # 제품 그리드 아이템
```

### ⚠️ 주의사항

1. **Import 경로**: 항상 패키지 경로 사용

   ```dart
   // ✅ Good
   import 'package:mobileprogramming_groupproject_2025/features/...';

   // ❌ Bad
   import '../../../features/...';
   ```

2. **상태 관리**: Riverpod 2.x의 `StateNotifier` 패턴 사용

   - `Notifier` (3.x 스타일) 사용 금지

3. **API 키**: `api_keys.dart`는 git에 커밋하지 않음

4. **레이어 규칙**:
   - Presentation → Domain ✅
   - Domain → Data ❌ (의존성 역전)
   - Data → Domain ✅

---

## 👥 팀원

- Mobile Programming Group Project 2025

## 📄 라이선스

This project is licensed under the MIT License.
