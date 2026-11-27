-- Какой процент продаж занимает каждое блюдо из меню
select mi.name, SUM(od.price_fact * od.quantity) as total_price , SUM(od.price_fact * od.quantity)/SUM(SUM(od.price_fact * od.quantity)) OVER ()*100 as sell_percents from menu_items as mi 
join order_details as od on od.menu_item_id = mi.id join orders as o on o.id=od.order_id
WHERE o.order_status = 'Оплачен'
group by mi.name
ORDER by sell_percents DESC



-- Поиск свободных столиков на определенную дату время и вместимость
select t.table_number, t.capacity, z.name as zone_name from tables as t
join zones as z on t.zone_id = z.id
where t.capacity >= 2 and not exists (select 1 from reservations as r
      where r.table_id = t.id and r.reservation_date = DATE '2026-10-25' 
	  and r.reservation_status in ('Ожидается', 'Гости пришли')
      and (r.start_time, r.end_time_estimated) 
	  overlaps (TIME '18:00:00', TIME '20:00:00'))
order by t.table_number;

-- Рейтинг эффективности официантов (выручка, количество заказов и средний чек)
select e.first_name || ' ' || e.last_name as waiter_name, count(o.id) as orders_count, coalesce(sum(o.total_amount), 0) as total_revenue, coalesce(avg(o.total_amount), 0) as avg_check from employees as e
left join orders as o on o.employee_id = e.id and o.order_status = 'Оплачен'
where e.role = 'Официант' and e.is_active = true
group by e.id, e.first_name, e.last_name
order by total_revenue desc;