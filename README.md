# cameraRequests

iOS-приложение для команды (1–3 человек), которое принимает заявки с сайта и шлёт пуш-уведомления — включая повторные напоминания, если заявку не обработали.

- **iOS:** SwiftUI, iOS 17+, Firebase iOS SDK.
- **Backend:** Vercel serverless functions (free Hobby plan) + Firebase Firestore/Auth/FCM (бесплатный Spark-план).
- Telegram-бот, который сейчас принимает заявки, **остаётся в параллель** — приложение не заменяет его, а дополняет.

Backend на Vercel, потому что Firebase Cloud Functions требуют платный план Blaze (карта), а Render теперь требует карту даже для free-тарифа. Vercel Hobby — бесплатно и без карты. Firestore, Auth и FCM работают на бесплатном Spark-плане.

---

## Архитектура

```
[Сайт: форма] ──┬──► Telegram bot (как сейчас, не трогаем)
                │
                └──► POST /api/ingestLead ─► Vercel (serverless)
                                                │ пишет в Firestore (Admin SDK)
                                                │ шлёт FCM push, потом отвечает
                                                ▼
                                           Firestore (leads/)
                                                │
                                                └──► realtime listener ──► iOS app

[cron-job.org] ──каждые 5 мин──► POST /api/cron/remind ─► Vercel
                                                            └─► FCM push для new-лидов
                                                                старше 20 мин (до смены статуса)
```

- **`POST /api/ingestLead`** — принимает заявку, пишет в Firestore, шлёт пуш «Новая заявка». Защищён заголовком `X-Ingest-Secret`.
- **`POST /api/cron/remind`** — внешний планировщик (cron-job.org) дёргает каждые 5 мин; шлёт напоминания. Защищён `X-Cron-Secret`.
- Пуши учитывают per-user настройки (тихие часы, вкл/выкл) — см. `users/{uid}/notificationSettings`.

---

## Первый запуск: пошагово

### 1. Firebase проект (бесплатный Spark-план — карта НЕ нужна)

1. https://console.firebase.google.com → **Add project**.
2. Включить: **Firestore Database** (production mode), **Authentication** (Email/Password), **Cloud Messaging**. Cloud Functions включать НЕ нужно.
3. Регион Firestore — `eur3` или `europe-west`.
4. Project settings → General → **Add app → iOS**:
   - Bundle ID — как у Xcode-таргета (Xcode → Target → General).
   - Скачать **`GoogleService-Info.plist`** → положить в `cameraRequests/GoogleService-Info.plist` (уже в `.gitignore`).
5. APNs key: Apple Developer → Keys → новый key с галкой APNs (.p8) → Firebase Project settings → Cloud Messaging → Apple app configuration → загрузить ключ + Key ID + Team ID.

### 2. Аккаунты пользователей

Firebase → Authentication → Users → **Add user** — завести 1–3 аккаунта (email + пароль). Регистрации из приложения нет по дизайну.

Документ `users/{uid}` создаётся **автоматически** при первом логине (когда регистрируется FCM-токен) — руками создавать не обязательно.

### 3. Xcode

1. Открыть `cameraRequests.xcodeproj`.
2. **Файлы в проекте**: папки `Auth/ Leads/ Settings/ Push/ Shared/` должны быть в Project navigator (target `cameraRequests`).
3. **SPM-зависимость**: File → Add Package Dependencies → `https://github.com/firebase/firebase-ios-sdk` → продукты: **FirebaseAuth**, **FirebaseFirestore**, **FirebaseMessaging**. (FirebaseInAppMessaging НЕ добавлять — не используется.)
4. **Capabilities** (Target → Signing & Capabilities → +):
   - **Push Notifications**.
   - **Background Modes** → **Remote notifications**.
5. **`GoogleService-Info.plist`** подключён к target.
6. Build & Run **на реальном iPhone** (push на симуляторе не работают).

### 4. Firestore rules + indexes (бесплатно, Blaze не нужен)

```bash
cd cameraRequests        # корень репозитория
firebase login
firebase use <project-id>          # см. firebase projects:list
firebase deploy --only firestore:rules,firestore:indexes
```

Либо вставить `firestore.rules` вручную в Firebase Console → Firestore → Rules → Publish.

### 5. Service account для backend

Backend пишет в Firestore и шлёт FCM от имени сервера — нужен service-account ключ:

1. Firebase Console → ⚙️ Project settings → **Service accounts** → **Generate new private key** → скачается JSON.
2. Закодировать в base64 (чтобы удобно положить в одну env-переменную):
   ```bash
   base64 -i ~/Downloads/serviceAccount.json | pbcopy
   ```
   (значение теперь в буфере обмена)

### 6. Деплой backend на Vercel (free Hobby — карта НЕ нужна)

1. Запушить репозиторий на GitHub (если ещё не там).
2. https://vercel.com → зарегистрироваться через GitHub (карта не требуется).
3. **Add New… → Project** → выбрать репозиторий `cameraRequests`.
4. На экране настройки проекта:
   - **Root Directory** → нажать **Edit** → выбрать **`server`**. ← важно: код backend в подпапке.
   - Framework Preset — оставить **Other** (Vercel сам найдёт функции в `server/api/`).
   - Build/Output settings — ничего менять не нужно.
5. **Environment Variables** — добавить три:
   | Key | Value |
   |---|---|
   | `INGEST_SECRET` | длинная случайная строка (`openssl rand -hex 32`) |
   | `CRON_SECRET` | другая случайная строка |
   | `FIREBASE_SERVICE_ACCOUNT` | base64 из шага 5 |
6. **Deploy**. Через минуту получишь URL вида `https://camera-requests-xxxx.vercel.app`.
7. Эндпоинты: `https://<твой>.vercel.app/api/ingestLead` и `/api/cron/remind`.

### 7. Планировщик напоминаний (cron-job.org, бесплатно)

1. https://cron-job.org → регистрация → **Create cronjob**.
2. **URL:** `https://<твой>.vercel.app/api/cron/remind`
3. **Schedule:** каждые 5 минут (`*/5 * * * *`).
4. **Request method:** POST.
5. **Headers:** добавить `X-Cron-Secret` = значение `CRON_SECRET` из шага 6.
6. Save.

### 8. Сквозной тест

```bash
curl -X POST 'https://<твой>.vercel.app/api/ingestLead' \
  -H 'Content-Type: application/json' \
  -H 'X-Ingest-Secret: <INGEST_SECRET>' \
  -d '{"name":"Тест","phone":"+375291234567","message":"проверка"}'
```

Ожидаем:
- Ответ `{"leadId":"...","deduped":false}`.
- В Firestore коллекции `leads` появился документ.
- На iPhone прилетел push «Новая заявка · Тест · +375 (29) 123-45-67».
- Тап по push → приложение → bottom sheet с заявкой.

---

## Структура

### iOS

```
cameraRequests/
├── cameraRequestsApp.swift     // entry, FirebaseApp.configure(), routing
├── ContentView.swift           // RootView: SignIn vs LeadsList
├── cameraRequests.entitlements // APNs
├── Auth/         AuthService, SignInView
├── Leads/        Lead, LeadStatus, LeadsRepository, LeadsListView(+VM), LeadDetailSheet
├── Settings/     NotificationSettings, SettingsRepository, SettingsView(+VM)
├── Push/         AppDelegate (APNs+FCM+deep link), PushService (токены)
└── Shared/       PhoneFormatter, ContactActions (tel: / t.me)
```

### Backend (`server/`) — Vercel serverless functions

```
server/
├── package.json
├── tsconfig.json
├── vercel.json         // region fra1
├── .env.example
├── api/                // каждый файл = эндпоинт
│   ├── ingestLead.ts       → POST /api/ingestLead
│   └── cron/
│       └── remind.ts       → POST /api/cron/remind
└── src/                // общая логика
    ├── firebase.ts     // Admin SDK init из FIREBASE_SERVICE_ACCOUNT
    ├── pushService.ts  // sendEachForMulticast + чистка мёртвых токенов
    ├── userFilter.ts   // отбор адресатов по notificationSettings
    ├── quietHours.ts   // luxon-based isQuietForUser
    ├── phone.ts        // нормализация → +375...
    └── types.ts
```

---

## Модель данных

`leads/{leadId}` — name, phone, message, source, pageUrl, status (`new`/`in_progress`/`closed`), createdAt, updatedAt, lastRemindedAt, reminderCount, rawPayload.

`users/{uid}` — displayName, role, fcmTokens, notificationSettings (newLeadEnabled, remindersEnabled, quietHoursEnabled, quietStartHour, quietEndHour, timezone, soundEnabled).

Создание лидов с клиента **запрещено rules'ами** — пишет только backend через Admin SDK. Клиент (iOS) читает `leads` и меняет только `status`/`updatedAt`/`assignedTo`.

---

## Сайт-форма (`site/`)

Готовая форма приёма заявок — `site/index.html` (имя+фамилия, телефон в белорусском формате `+375`).
Перед использованием в `<script>` → блок `CONFIG` вписать:
- `ENDPOINT` — `https://<твой>.vercel.app/api/ingestLead`
- `INGEST_SECRET` — то же значение, что в Vercel.

Хостить можно где угодно (GitHub Pages, Netlify) или просто открыть `index.html` локально.

### Интеграция в существующий сайт

В обработчик формы добавить второй fetch (параллельно с тем, что шлёт в Telegram):

```js
fetch("https://<твой>.vercel.app/api/ingestLead", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "X-Ingest-Secret": "<тот_же_INGEST_SECRET>"
  },
  body: JSON.stringify({
    name: nameField.value,
    phone: phoneField.value,
    message: messageField.value,
    pageUrl: location.href
  })
});
```

---

## Тесты

```bash
cd server
npm install
npm test          # jest
npm run typecheck # tsc
```

Покрыто: `normalizePhone` (белорусские форматы номеров), `isQuietHourRange` / `isQuietForUser` (окна с пересечением полуночи, таймзоны).
