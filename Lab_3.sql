-- 1. Нарушение ссылочной целостности данных
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

INSERT INTO faculties (faculty_code, faculty_name, foundation_date, activity_type, max_students)
VALUES (50, 'Факультет биоинженерии', '2018-09-01', 'Биология', 150)
ON CONFLICT (faculty_code) DO NOTHING;

INSERT INTO departments (department_code, faculty_code, department_name, head_of_department, is_graduating, website, phone)
VALUES (99, 999, 'Кафедра квантовой оптики', 'Иванов И.И.', 'Да', 'optics.ru', '84951234567')
ON CONFLICT (department_code) DO NOTHING;

-- 2. Левостороннее соединение (условие 1: если на факультете нет кафедр, оставить NULL)
SELECT *
FROM faculties f
LEFT JOIN departments d ON f.faculty_code = d.faculty_code;

-- 3. Правостороннее соединение (условие 2: если кафедра относится к незарегистрированному факультету, оставить NULL)
SELECT *
FROM faculties f
RIGHT JOIN departments d ON f.faculty_code = d.faculty_code;

-- 4. Симметричное соединение (для сравнения результатов)
SELECT *
FROM faculties f
INNER JOIN departments d ON f.faculty_code = d.faculty_code;

-- 5. Выявление нарушения ссылочной целостности данных
SELECT d.*
FROM faculties f
RIGHT JOIN departments d ON f.faculty_code = d.faculty_code
WHERE f.faculty_code IS NULL;

-- 6. Восстановление ссылочной целостности данных (выполнять после проверки шагов 2-5)
DELETE FROM departments WHERE faculty_code = 999;

ALTER TABLE departments
ADD CONSTRAINT departments_faculty_code_fkey
FOREIGN KEY (faculty_code) REFERENCES faculties (faculty_code);
