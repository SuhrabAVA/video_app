# video_app (Flutter + Supabase)

Красивое приложение видеоплатформы с входом в систему, каталогом видео, поиском/фильтрами и ролевым добавлением контента.

## Что реализовано
- Вход в систему по логину (email) и паролю через Supabase Auth.
- Необычный дизайн (градиенты, glassmorphism, акцентные элементы).
- После входа: лента видео с карточками, где есть:
  - название,
  - описание,
  - категория,
  - просмотры,
  - лайки,
  - кнопки действий «Смотреть / Лайк / Поделиться» (как в видеосервисах).
- Поиск по названию/описанию.
- Фильтрация по категориям.
- Для ролей `technical_lead` и `cmm_specialist` доступна панель добавления:
  - новых категорий,
  - новых видео.
- Все данные хранятся в отдельных таблицах в той же базе: `video_categories`, `video_items`, `video_reactions`, `video_user_profiles`.

## Настройка БД (Supabase)
1. Откройте SQL Editor в Supabase.
2. Выполните файл `schema.sql`.
3. Назначьте роль пользователю в `video_user_profiles` (по умолчанию `viewer`).

Пример назначения роли:

```sql
insert into public.video_user_profiles (user_id, role)
values ('<USER_UUID>', 'technical_lead')
on conflict (user_id) do update set role = excluded.role;
```

## Запуск
```bash
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Web:
```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```
