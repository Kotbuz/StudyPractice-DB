-- Какой процент продаж занимает каждое блюдо из меню
select mi.name, SUM(od.price_fact * od.quantity) as total_price , SUM(od.price_fact * od.quantity)/SUM(SUM(od.price_fact * od.quantity)) OVER ()*100 as sell_percents from menu_items as mi 
join order_details as od on od.menu_item_id = mi.id join orders as o on o.id=od.order_id
WHERE o.order_status = 'Оплачен'
group by mi.name
ORDER by sell_percents DESC



-- Поиск свободных столиков на определенную дату и время
select t.table_number, t.capacity, z.name from tables as t 
join zones as z on t.zone_id = z.id 
join reservations as r on r.table_id = t.id 
WHERE not (r.reservation_date + r.start_time, r.reservation_date + r.end_time_estimated) 
OVERLAPS (DATE '2026-10-25' + TIME '18:00:00', DATE '2026-10-25' + TIME '20:00:00');