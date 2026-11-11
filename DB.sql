-- 1. Создание перечисляемых типов (ENUM)

CREATE TYPE table_status_enum AS ENUM ('Свободен', 'Занят', 'Забронирован');

CREATE TYPE employee_role_enum AS ENUM ('Администратор', 'Официант', 'Повар', 'Бармен', 'Хостес');

CREATE TYPE order_status_enum AS ENUM ('Новый', 'Готовится', 'Подан', 'Оплачен', 'Отменен');

CREATE TYPE reservation_status_enum AS ENUM ('Ожидается', 'Гости пришли', 'Отменено', 'Не явились');


-- 2. Блок «Пространство ресторана»

CREATE TABLE zones (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE tables (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_number INT NOT NULL UNIQUE,
    capacity INT NOT NULL CHECK (capacity > 0),
    zone_id INT NOT NULL REFERENCES zones(id) ON DELETE RESTRICT,
    current_status table_status_enum NOT NULL DEFAULT 'Свободен'
);

-- 3. Блок «Меню»

CREATE TABLE categories (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE menu_items (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_id INT NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
    weight_volume INT CHECK (weight_volume > 0),
    is_available BOOLEAN NOT NULL DEFAULT TRUE
);

-- 4. Блок «Персонал»

CREATE TABLE employees (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role employee_role_enum NOT NULL,
    phone VARCHAR(20) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- 5. Блок «Управление заказами»

CREATE TABLE orders (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_id INT NOT NULL REFERENCES tables(id) ON DELETE RESTRICT,
    employee_id INT NOT NULL REFERENCES employees(id) ON DELETE RESTRICT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP,
    order_status order_status_enum NOT NULL DEFAULT 'Новый',
    total_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00 CHECK (total_amount >= 0)
);

CREATE TABLE order_details (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id INT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    menu_item_id INT NOT NULL REFERENCES menu_items(id) ON DELETE RESTRICT,
    quantity INT NOT NULL CHECK (quantity > 0),
    price_fact DECIMAL(10, 2) NOT NULL CHECK (price_fact >= 0),
    cooking_comment VARCHAR(255)
);

-- 6. Блок «Система бронирования»

CREATE TABLE guests (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(150)
);

CREATE TABLE reservations (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    guest_id INT NOT NULL REFERENCES guests(id) ON DELETE RESTRICT,
    table_id INT NOT NULL REFERENCES tables(id) ON DELETE RESTRICT,
    employee_id INT NOT NULL REFERENCES employees(id) ON DELETE RESTRICT,
    reservation_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time_estimated TIME NOT NULL,
    guest_count INT NOT NULL CHECK (guest_count > 0),
    reservation_status reservation_status_enum NOT NULL DEFAULT 'Ожидается',
    special_notes VARCHAR(255)
);
