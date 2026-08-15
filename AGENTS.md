# AGENTS.md

Flutter app **Green Market** (vegetable import/export & wholesale management). Git repo root is this `frontend/` folder; the Flutter app lives in `green_market/`.

## Hard rules (non-negotiable)

1. **On session start:** read `project_state.md` for all project context. Do NOT re-explore the repo; only open specific files if `project_state.md` is missing info you actually need.
2. **Scope:** work on the **frontend only** (`green_market/`). The backend (`../backend/`, FastAPI) is a separate repo and out of scope — never read it for context, never edit it.
3. **After EVERY change** (any file edit): update `project_state.md` to reflect the change, then commit to git with a clear message. This prevents data loss. If multiple small edits belong to one logical change, make one update + one commit for the group.
4. Commit frequently — a change is not "done" until `project_state.md` is updated and the commit is made.

## Commands (run from `green_market/`)

- Analyze: `flutter analyze` — currently clean (3 info-level lints, no errors)
- Tests: `flutter test` (only `test/widget_test.dart` exists)
- Run: `flutter run` (uses `.env`, backend expected at `http://127.0.0.1:8000`)
- Get deps: `flutter pub get`

## Architecture

Clean architecture, one folder per layer under `lib/`:
- `core/` — config (`app_config.dart`, `routes.dart`, `theme.dart`), network (`api_client.dart`, interceptors), error, utils
- `data/` — models, `datasources/remote/*_ds.dart`, `repositories/*.dart`
- `domain/` — entities + usecases (thin; most logic lives in providers)
- `presentation/` — pages, `providers/*.dart` (Riverpod StateNotifiers), shared widgets

Data flow: Page → Riverpod provider → Repository → RemoteDatasource → `ApiClient`/Dio.

## Key non-obvious facts

- **No codegen.** Models are hand-written plain classes. JSON is **snake_case** (`business_id`) with defensive fallbacks (both `snake_case` and `camelCase` accepted). Do NOT introduce freezed/json_serializable/build_runner.
- **API envelope:** responses are wrapped in a `data` key — read `data['data']`, never `data` directly (see `batch_remote_ds.dart`).
- **Auth:** tokens/session live in `flutter_secure_storage` under keys `access_token`, `refresh_token`, `user_id`, `business_id`, `needs_onboarding`. `AuthInterceptor` auto-refreshes on 401 via `POST /auth/refresh-token` and wipes storage on failure.
- **Routing:** `go_router` with a `redirect` (splash `/` → login/signup/onboarding/dashboard) and a `ShellRoute` with bottom nav. Routes are defined in `core/config/routes.dart`; every feature page must be registered there.
- **Offline/local DB are STUBS:** `AppDatabase` (`data/datasources/local/app_database.dart`) is empty and `SyncRepository.processQueue()` is a no-op. Do not assume offline/caching works.
- `.env` is loaded in `main.dart` via `flutter_dotenv`. `API_BASE_URL` defaults to `http://127.0.0.1:8000/api/v1`.
- `MISSING_FEATURES.md` is **stale** (June 2026) — many files it lists as missing now exist. Trust `project_state.md` and the code over that file.
- Backend API contract reference: `BACKEND_API_DOCUMENTATION.md` (repo root of GreenMarket, outside this git repo) — read only if a frontend task truly needs the endpoint shape.

## Conventions

- State: `flutter_riverpod` 2.x, `StateNotifier` + `StateNotifierProvider` (one provider per feature, `lib/presentation/providers/`). `dioProvider` supplies the shared `Dio`.
- Currency via `core/utils/currency_formatter.dart`; dates via `date_formatter.dart` (intl).
- Reuse shared widgets in `lib/presentation/widgets/` (GreenCard, AmountText, StatusPill, PartnerChip, EmptyState, ConfirmDialog, etc.) instead of inline UI.
- Follow existing file organization; register new pages in `routes.dart`.
