# Архитектура БД «Автоматизация работы ресторана/кафе»

---

## 1. Анализ предметной области и сущностей

Архитектура системы строится вокруг пяти ключевых бизнес-сущностей:
1. **Зал и Столы**  — физическое пространство ресторана, разделенное на зоны.
2. **Меню**  — каталог блюд и напитков, доступных для заказа, с разделением по категориям.
3. **Персонал**  — сотрудники заведения, разделенные по ролям (администраторы, официанты, повара).
4. **Заказы**  — операционная деятельность. Фиксация того, что, кем, когда и на каком столике было заказано и оплачено.
5. **Бронирование**  — планирование будущих визитов гостей, предотвращение конфликтов посадки и сбор клиентской базы.

---

## 2. Схема и структура таблиц

### Блок «Пространство ресторана»

#### Таблица: `Zones` (Зоны зала)
Хранит информацию о локациях внутри заведения.
* `id` (Primary Key, INT, Auto Increment)
* `name` (VARCHAR)

#### Таблица: `Tables` (Столы)
Содержит реестр столов и их текущие характеристики.
* `id` (Primary Key, INT, Auto Increment)
* `table_number` (INT, Unique)
* `capacity` (INT)
* `zone_id` (Foreign Key -> `Zones.id`)
* `current_status` (ENUM) — текущее состояние (`Свободен`, `Занят`, `Забронирован`).

### Блок «Меню»

#### Таблица: `Categories` (Категории меню)
* `id` (Primary Key, INT, Auto Increment)
* `name` (VARCHAR)

#### Таблица: `Menu_Items` (Блюда и напитки)
* `id` (Primary Key, INT, Auto Increment)
* `category_id` (Foreign Key -> `Categories.id`)
* `name` (VARCHAR)
* `description` (TEXT)
* `price` (DECIMAL(10,2))
* `weight_volume` (INT)
* `is_available` (BOOLEAN)

### Блок «Персонал»

#### Таблица: `Employees` (Сотрудники)
* `id` (Primary Key, INT, Auto Increment)
* `first_name` (VARCHAR)
* `last_name` (VARCHAR)
* `role` (ENUM)
* `phone` (VARCHAR)
* `password_hash` (VARCHAR)
* `is_active` (BOOLEAN)

### Блок «Управление заказами»

#### Таблица: `Orders` (Заказы)
* `id` (Primary Key, INT, Auto Increment)
* `table_id` (Foreign Key -> `Tables.id`)
* `employee_id` (Foreign Key -> `Employees.id`)
* `created_at` (TIMESTAMP)
* `closed_at` (TIMESTAMP, Nullable)
* `order_status` (ENUM) — статус (`Новый`, `Готовится`, `Подан`, `Оплачен`, `Отменен`).
* `total_amount` (DECIMAL(10,2), Default: 0.00)

#### Таблица: `Order_Details` (Позиции заказа)
Реализует связь «многие-ко-многим» между заказами и меню.
* `id` (Primary Key, INT, Auto Increment)
* `order_id` (Foreign Key -> `Orders.id` On Delete Cascade)
* `menu_item_id` (Foreign Key -> `Menu_Items.id`)
* `quantity` (INT)
* `price_fact` (DECIMAL(10,2))
* `cooking_comment` (VARCHAR, Nullable) — пожелания гостя

### Блок «Система бронирования»

#### Таблица: `Guests` (База клиентов)
Позволяет идентифицировать постоянных гостей при резерве.
* `id` (Primary Key, INT, Auto Increment)
* `name` (VARCHAR)
* `phone` (VARCHAR, Unique)
* `email` (VARCHAR, Nullable)

#### Таблица: `Reservations` (Бронирование столов)
* `id` (Primary Key, INT, Auto Increment)
* `guest_id` (Foreign Key -> `Guests.id`)
* `table_id` (Foreign Key -> `Tables.id`)
* `employee_id` (Foreign Key -> `Employees.id`)
* `reservation_date` (DATE)
* `start_time` (TIME)
* `end_time_estimated` (TIME)
* `guest_count` (INT)
* `reservation_status` (ENUM) — статус (`Ожидается`, `Гости пришли`, `Отменено`, `Не явились`).
* `special_notes` (VARCHAR, Nullable) — комментарии гостя

---

## 3. Скрипты и Хранимые процедуры (Бизнес-логика)

Для автоматизации рутинных действий интерфейса и инкапсуляции SQL-запросов создаются следующие процедуры:

1. **`CreateReservation(guest_phone, guest_name, table_id, res_date, res_time, guest_count, emp_id)`**
   * Ищет гостя по телефону. Если его нет в `Guests`, автоматически создает новую карточку.
   * Проверяет, не занят ли выбранный `table_id` на указанное время другими бронями.
   * Если стол свободен, создает запись в `Reservations` со статусом `Ожидается`.

2. **`OpenOrderFromReservation(reservation_id, waiter_id)`**
   * Срабатывает, когда забронировавшие гости приходят в ресторан.
   * Меняет статус в `Reservations` на `Гости пришли`.
   * Автоматически открывает новый чек в таблице `Orders` (привязывает выбранный стол и официанта).
   * Меняет статус стола в `Tables` на `Занят`.

3. **`CloseOrderAndReleaseTable(order_id)`**
   * Рассчитывает заказ, проставляя текущее время в `closed_at` и статус `Оплачен`.
   * Меняет статус соответствующего стола в `Tables` на `Свободен`.

---

## 4. Триггеры (Автоматизация и Безопасность данных)

Триггеры обеспечивают целостность данных на уровне СУБД, защищая логику от ошибок приложений-клиентов.

* **Триггер: `Check_Stop_List_Before_Insert` (Контроль доступности меню)**
  * *Событие:* `BEFORE INSERT` на таблицу `Order_Details`.
  * *Логика:* Проверяет поле `is_available` в таблице `Menu_Items` для добавляемого блюда. Если флаг равен `FALSE`, триггер прерывает транзакцию (`ROLLBACK`) и выбрасывает ошибку: *"Блюдо находится в стоп-листе"*.

* **Триггер: `Recalculate_Order_Total` (Автоматический расчет чека)**
  * *Событие:* `AFTER INSERT`, `AFTER UPDATE`, `AFTER DELETE` на таблицу `Order_Details`.
  * *Логика:* При любом изменении состава заказа триггер пересчитывает сумму всех его позиций `SUM(quantity * price_fact)` и обновляет поле `total_amount` в родительской таблице `Orders`.

* **Триггер: `Prevent_Overbooking` (Защита от двойного бронирования)**
  * *Событие:* `BEFORE INSERT` на таблицу `Reservations`.
  * *Логика:* Проверяет пересечение временных интервалов. Если на выбранную дату и время (`start_time` — `end_time_estimated`) для данного `table_id` уже существует активная бронь, транзакция отклоняется с ошибкой: *"Данный стол уже забронирован на это время"*.

* **Триггер: `Lock_Paid_Orders` (Финансовая безопасность)**
  * *Событие:* `BEFORE UPDATE` или `BEFORE DELETE` на таблицы `Orders` и `Order_Details`.
  * *Логика:* Проверяет текущий статус заказа. Если `order_status = 'Оплачен'`, любые попытки уменьшить количество блюд, удалить позиции или изменить итоговую сумму блокируются. Это исключает махинации с выручкой со стороны персонала.
