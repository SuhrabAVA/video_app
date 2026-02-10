# video_app (Flutter)

Отдельное приложение на **Dart + Flutter** в папке `video_app`.

## Функциональность
- Вход и регистрация через Supabase Auth.
- Красивый необычный дизайн: тёмный градиент, glassmorphism-карточки, стильная лента видео.
- После входа показывается каталог видео с:
  - названием,
  - описанием,
  - превью,
  - кнопками действий как на YouTube (`Смотреть`, `Лайк`, `Поделиться`).
- Поисковик и фильтр по категориям.
- Отдельная панель добавления контента (категории + видео) только для ролей:
  - `technical_lead`
  - `cmm_specialist`
- Все данные хранятся в той же БД, но в отдельных таблицах `video_*`.

## База данных
1. Выполните SQL из `video_app/schema.sql` в Supabase SQL Editor.
2. Назначайте роль пользователям в `video_user_profiles`.

## Запуск
```bash
cd video_app
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Для Web:
```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```