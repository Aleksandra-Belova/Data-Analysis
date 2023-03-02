
-- ��� � ����������� � ������:

-- 1.�������� � �������� ������

-- ������� ������� � �������� (order_revenue)
-- �� ������ ������ ����� ������� ��� ��� �������� ������� (drop table), ���� ��� ���������� (if exists)
drop table if exists public.order_revenue

-- ������� ������� order_revenue � 5 ��������� (������������� ������, ���� ������, ����� ������, ������������� �������, ��� �������) 
create table public.order_revenue(
	order_id bigint
/*����� ����� ���� ��������� ��� ������, ������� � ���� ���� ����� �����������*/	
	,order_date date
	,order_sum int
	,client_id bigint
	,client_name text)

-- ���������, ��� ���������� ������� � ������ ����������
select * 
/*����� * �������� ������� ��� ������ � ������� �� ������� (* = all)*/
from public.order_revenue
	
-- ��������� � ������������ ������� �������� �������
insert into public.order_revenue(order_id, order_date, order_sum, client_id, client_name)
values(1, '2019-10-10', 7400, 1, 'Ivan')
/*� ������� ���������� ������ �������, �����, ����� ������� ��������� �������� �������� � �������� �������� � �������*/
, (2, '2020-01-13', 10500, 1, 'Ivan')
, (3, '2020-01-15', 13000, 2, 'Petr')
, (4, '2020-02-10', 4600, 3, 'Anna')	
,(5, '2020-05-25', 13000, 4, 'Maria')
, (6, '2020-06-17', 4700, 5, 'Egor')
, (7, '2021-01-11', 5650, 5,'Egor')

-- ���������, ��� ����������: ������ ������� �� ������
select * 
from public.order_revenue

-- ��������� ����� ����� ���� �������
select sum(order_sum)
/*������� ����� (sum) ���� ������� (order_sum)*/
from order_revenue
/*�� ������� ������� (order_revenue)*/
-- ���������: 58 850

-- ������� 5 ������ ����� �� ������� ������� (order_revenue)
select *
from order_revenue
limit 5

-- ������� ���� ������, ����� ������ � ��� ������� �� ������� ������� (order_revenue)
select order_date
, order_sum
, client_name
from order_revenue

-- ��������, ��� �������� �������� ������� ����������
select 5/3
-- ���������: 1

select 1/3
-- ���������: 0

-- 2. ������ ���� ������� ������� � ����� ����� �������

-- ��������, ��� ��� ������� �������� ��-�� �������� ����� ������ � ������� order_revenue (������ �3)
-- �� �� ������ � ��������� ������ ���������, ��� ����� ������������ � �������, ����� ���� ������ ������ �����
select distinct client_name
/*������� ��� �������*/
, sum(order_sum) as total_revenue
/*������� ����� (sum) ���� ������� (order_sum) � ������� ���� ������� total_revenue*/
, sum(order_sum)*100 / (
	select sum(order_sum) 
	from public.order_revenue
/*����� ����� �� ��������� ���������� - ����� ����� ���� �������,
 * �� ������������ ��� ���� - 58 850 ������*/
	) as precent_of_revenue
/*���������� �������: ����� ������� �������*100/����� ����� ���� �������*/
from public.order_revenue
group by 1
/*�� �������� ������ ������� (client_name) � ������� � ������������ �������� (total_revenue � precent_of_revenue).
 * ������� ��������� ��������� SQL, �� ������ ������� ��������� ������������. 
 * ��� ����� ���� ������� group. ��� ����� ����������� ������ �� ����� �������.
 * ������� ����� group by 1 - ������������ �� ������� ������� � select, �.�. ������� client_name*/

-- ��������� ���� ������� ������� � ����� ����� �������
-- ���� ������ ��������� � ��� ������� ������
select distinct client_name
, sum(order_sum) as total_revenue
, round(sum(order_sum)*100.0 / (
/*������� round ��������� ����� �� ������� �����, � ��� - �� ������ (0)*/
/*���������� �� 100.0 �� � ����� ���� ���������, ��� ��� ����� ����� ����� �������, ����������� �� �� �����*/
	select sum(order_sum) 
	from public.order_revenue
	),0) as precent_of_revenue
from order_revenue
group by 1

-- �������� ��������� ������� �������
-- ������� ��������� ������� � ����� ������� percent_revenue
drop table if exists public.percent_revenue

select distinct client_name
, sum(order_sum) as total_revenue
, sum(order_sum)*100 / (
	select sum(order_sum) 
	from public.order_revenue
	) as precent_of_revenue
into public.percent_revenue
/*������� ��������� ������� � ����� ������� - percent_revenue*/
from public.order_revenue
group by 1

-- ��������, ��� ��� ������ ����������
select * 
from public.percent_revenue

-- ������������ �������� �������
select sum(precent_of_revenue)
from public.percent_revenue
-- ���������: 98

-- 3. ����� ������� � ���������� ������ ������

-- ������� ������� � ���������� ������ ������ (������ 4)
-- ����������, ��� ������ ������������ ����� limit �����������, ��� ��� ���������� ���� ������� ����� ���� ���������
select client_name
, order_sum
from public.order_revenue
order by order_sum desc
/* ���������� �������� �� ����� ������ � ������� �������� (desc)
 *asc - �� �����������*/
limit 1
/* ������� ������ ������*/
-- ���������: Petr	13000

-- ������� ������� � ���������� ������ ������ ���������
select client_name
, order_sum
from public.order_revenue
where order_sum = (
/* ������� ����� ��������, � ������� ����� ������� �����������*/
select max(order_sum) 
from public.order_revenue
)
/* �� ���� ����� ��������� (max) ����� ���� ���� ������� �� �������*/
-- ���������: Petr 13 000, Maria 13 000

-- 4. �����: ����� ���� ���������� ������ ������� �������
select distinct client_name
, max(order_date) as last_order_date
from public.order_revenue
group by 1
order by 2 desc