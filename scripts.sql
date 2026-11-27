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


-- Анализ неблагонадежных гостей (у кого минимум 2 брони и есть неявки)
select g.name, g.phone, count(r.id) as total_reservations, count(r.id) filter (where r.reservation_status = 'Не явились') as no_shows from guests as g
join reservations as r on r.guest_id = g.id
group by g.id, g.name, g.phone
having count(r.id) >= 2 and count(r.id) filter (where r.reservation_status = 'Не явились') > 0
order by no_shows desc;


-- Непопулярные доступные блюда, которые ни разу не покупали в оплаченных заказах
select c.name as category_name, mi.name as item_name, mi.price from menu_items as mi
join categories as c on c.id = mi.category_id
where mi.is_available = true and not exists (select 1 from order_details as od
      join orders as o on o.id = od.order_id
      where od.menu_item_id = mi.id and o.order_status = 'Оплачен')
order by c.name, mi.name;