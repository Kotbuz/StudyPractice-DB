-- Какой процент продаж занимает каждое блюдо из меню
select mi.name, SUM(od.price_fact * od.quantity) as total_price , SUM(od.price_fact * od.quantity)/SUM(SUM(od.price_fact * od.quantity)) OVER ()*100 as sell_percents from menu_items as mi 
join order_details as od on od.menu_item_id = mi.id join orders as o on o.id=od.order_id
WHERE o.order_status = 'Оплачен'
group by mi.name
ORDER by sell_percents DESC
