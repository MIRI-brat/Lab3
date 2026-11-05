-- =====================================================================
-- ШАГ 2. НАРУШЕНИЕ ССЫЛОЧНОЙ ЦЕЛОСТНОСТИ ДАННЫХ
-- =====================================================================

-- 1) Автоматически отключаем внешний ключ (FOREIGN KEY) у таблицы departments, 
-- чтобы база разрешила добавить кафедру с несуществующим факультетом:
DO $$ 
DECLARE 
    r RECORD;
BEGIN
    FOR r IN (
        SELECT constraint_name 
        FROM information_schema.table_constraints 
        WHERE table_name = 'departments' AND constraint_type = 'FOREIGN KEY'
    ) 
    LOOP
        EXECUTE 'ALTER TABLE departments DROP CONSTRAINT ' || quote_ident(r.constraint_name);
    END LOOP;
END $$;

-- 2) Добавляем новый факультет (код 50), на котором нет ни одной кафедры (для 1-го условия варианта 10):
INSERT INTO faculties (faculty_code, faculty_name, foundation_date, activity_type, max_students)
VALUES (50, 'Факультет биоинженерии', '2018-09-01', 'Биология', 150)
ON CONFLICT (faculty_code) DO NOTHING;

-- 3) Добавляем кафедру с кодом факультета 999, которого нет в базе (нарушаем целостность для 2-го условия):
INSERT INTO departments (department_code, faculty_code, department_name, head_of_department, is_graduating, website, phone)
VALUES (99, 999, 'Кафедра квантовой оптики', 'Иванов И.И.', 'Да', 'optics.ru', '84951234567')
ON CONFLICT (department_code) DO NOTHING;


-- =====================================================================
-- ШАГ 3. ЗАПРОС С ЛЕВОСТОРОННИМ СОЕДИНЕНИЕМ (LEFT JOIN)
-- Условие 1: если на факультете нет ни одной кафедры, оставить пустое поле (NULL)
-- =====================================================================
SELECT *
FROM faculties f
LEFT JOIN departments d ON f.faculty_code = d.faculty_code;


-- =====================================================================
-- ШАГ 4. ЗАПРОС С ПРАВОСТОРОННИМ СОЕДИНЕНИЕМ (RIGHT JOIN)
-- Условие 2: если кафедра относится к незарегистрированному факультету, оставить пустое поле (NULL)
-- =====================================================================
SELECT *
FROM faculties f
RIGHT JOIN departments d ON f.faculty_code = d.faculty_code;


-- =====================================================================
-- ШАГ 5. ВЫЯВЛЕНИЕ НАРУШЕНИЯ ССЫЛОЧНОЙ ЦЕЛОСТНОСТИ
-- Запрос выводит только те кафедры, которые ссылаются на несуществующий факультет
-- =====================================================================
SELECT d.*
FROM faculties f
RIGHT JOIN departments d ON f.faculty_code = d.faculty_code
WHERE f.faculty_code IS NULL;


-- =====================================================================
-- ШАГ 6. ВОССТАНОВЛЕНИЕ ССЫЛОЧНОЙ ЦЕЛОСТНОСТИ (ПО ЧЕК-ЛИСТУ)
-- ВНИМАНИЕ: Запускайте этот шаг ТОЛЬКО ПОСЛЕ того, как проверите и заскрините Шаги 3, 4 и 5!
-- =====================================================================
DELETE FROM departments WHERE faculty_code = 999;

ALTER TABLE departments
ADD CONSTRAINT departments_faculty_code_fkey
FOREIGN KEY (faculty_code) REFERENCES faculties (faculty_code);