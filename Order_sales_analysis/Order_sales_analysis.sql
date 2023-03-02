
-- Код с пояснениями к статье:

-- 1.Создание и проверка таблиц

-- Создаем таблицу с заказами (order_revenue)
-- На случай ошибок сразу добавим код для удаления таблицы (drop table), если она существует (if exists)
drop table if exists public.order_revenue

-- Создаем таблицу order_revenue с 5 столбцами (идентификатор заказа, дата заказа, сумма заказа, идентификатор клиента, имя клиента) 
create table public.order_revenue(
	order_id bigint
/*после имени поля указываем тип данных, которые в этом поле будут содержаться*/	
	,order_date date
	,order_sum int
	,client_id bigint
	,client_name text)

-- Проверяем, что получилось таблица с нужной структурой
select * 
/*здесь * означает выбрать все строки и столбцы из таблицы (* = all)*/
from public.order_revenue
	
-- Вставляем в получившуюся таблицу значения заказов
insert into public.order_revenue(order_id, order_date, order_sum, client_id, client_name)
values(1, '2019-10-10', 7400, 1, 'Ivan')
/*в скобках содержатся строки таблицы, важно, чтобы порядок введенных значений совпадал с порядком столбцов в таблице*/
, (2, '2020-01-13', 10500, 1, 'Ivan')
, (3, '2020-01-15', 13000, 2, 'Petr')
, (4, '2020-02-10', 4600, 3, 'Anna')	
,(5, '2020-05-25', 13000, 4, 'Maria')
, (6, '2020-06-17', 4700, 5, 'Egor')
, (7, '2021-01-11', 5650, 5,'Egor')

-- Проверяем, что получилось: первая таблица из статьи
select * 
from public.order_revenue

-- Посчитаем общую сумму всех заказов
select sum(order_sum)
/*выберем сумму (sum) всех заказов (order_sum)*/
from order_revenue
/*из таблицы заказов (order_revenue)*/
-- Результат: 58 850

-- Выберем 5 первых строк из таблицы заказов (order_revenue)
select *
from order_revenue
limit 5

-- Выберем дату заказа, сумму заказа и имя клиента из таблицы заказов (order_revenue)
select order_date
, order_sum
, client_name
from order_revenue

-- Убедимся, что проблема нецелыми числами существует
select 5/3
-- Результат: 1

select 1/3
-- Результат: 0

-- 2. Расчет доли каждого клиента в общей сумме заказов

-- Напомним, что это решение ошибочно из-за неверных типов данных в таблице order_revenue (ошибка №3)
-- Но по логике и структуре пример корректен, его можно использовать в случаях, когда типы данных заданы верно
select distinct client_name
/*выберем имя клиента*/
, sum(order_sum) as total_revenue
/*выберем сумму (sum) всех заказов (order_sum) и назовем этот столбец total_revenue*/
, sum(order_sum)*100 / (
	select sum(order_sum) 
	from public.order_revenue
/*здесь делим на результат подзапроса - общую сумму всех заказов,
 * мы рассчитывали его выше - 58 850 рублей*/
	) as precent_of_revenue
/*рассчитаем процент: сумма заказов клиента*100/общая сумма всех заказов*/
from public.order_revenue
group by 1
/*Мы выбирали просто столбцы (client_name) и столбцы с агрегирующей функцией (total_revenue и precent_of_revenue).
 * Поэтому требуется объяснить SQL, по какому столбцу проводить суммирование. 
 * Для этого есть функция group. Нам нужно суммировать заказы по имени клиента.
 * Поэтому пишем group by 1 - группировать по первому столбцу в select, т.е. столбцу client_name*/

-- Посчитаем долю каждого клиента в общей сумме заказов
-- Этот пример корректен и для текущих данных
select distinct client_name
, sum(order_sum) as total_revenue
, round(sum(order_sum)*100.0 / (
/*функция round округляем числа до нужного знака, у нас - до целого (0)*/
/*умножением на 100.0 мы в явном виде указываем, что нам нужны знаки после запятой, отбрасывать их не нужно*/
	select sum(order_sum) 
	from public.order_revenue
	),0) as precent_of_revenue
from order_revenue
group by 1

-- Проверим результат первого расчета
-- Добавим результат запроса в новую таблицу percent_revenue
drop table if exists public.percent_revenue

select distinct client_name
, sum(order_sum) as total_revenue
, sum(order_sum)*100 / (
	select sum(order_sum) 
	from public.order_revenue
	) as precent_of_revenue
into public.percent_revenue
/*добавим результат расчета в новую таблицу - percent_revenue*/
from public.order_revenue
group by 1

-- Проверим, что все строки добавились
select * 
from public.percent_revenue

-- Просуммируем проценты выручки
select sum(precent_of_revenue)
from public.percent_revenue
-- Результат: 98

-- 3. Выбор клиента с наибольшей суммой заказа

-- Выберем клиента с наибольшей суммой заказа (Ошибка 4)
-- Напоминаем, что жестко ограничивать выбор limit неправильно, так как одинаковых сумм заказов может быть несколько
select client_name
, order_sum
from public.order_revenue
order by order_sum desc
/* тсортируем клиентов по сумме заказа в порядке убывания (desc)
 *asc - по возрастанию*/
limit 1
/* выберем первую строку*/
-- Результат: Petr	13000

-- Выберем клиента с наибольшей суммой заказа корректно
select client_name
, order_sum
from public.order_revenue
where order_sum = (
/* выберем таких клиентов, у которых сумма заказов максимальна*/
select max(order_sum) 
from public.order_revenue
)
/* то есть равно максимуму (max) среди всех сумм заказов из таблицы*/
-- Результат: Petr 13 000, Maria 13 000

-- 4. Бонус: выбор даты последнего заказа каждого клиента
select distinct client_name
, max(order_date) as last_order_date
from public.order_revenue
group by 1
order by 2 desc