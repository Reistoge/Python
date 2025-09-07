-------------------------------------------------------------------------------
-- tiendatech - sistema de ventas online
-- normalización de ventasraw a 3fn
-------------------------------------------------------------------------------
-- 1. modelo relacional normalizado en 3fn

-- tabla de clientes
create table clientes (
    cliente_id serial primary key,
    nombre varchar(100) not null,
    email varchar(100) unique not null,
    direccion text
);

-- tabla de proveedores
create table proveedores (
    proveedor_id serial primary key,
    nombre varchar(100) not null,
    contacto varchar(100)
);

-- tabla de categorías jerárquicas (hasta 3 niveles)
create table categorias (
    categoria_id serial primary key,
    nombre varchar(50) not null,
    categoria_padre_id int references categorias(categoria_id),
    nivel int not null check (nivel between 1 and 3)
);

-- tabla de productos
create table productos (
    producto_id serial primary key,
    nombre varchar(100) not null,
    categoria_id int references categorias(categoria_id),
    proveedor_id int references proveedores(proveedor_id),
    precio_unitario numeric(10,2) not null,
    stock_actual int not null default 0
);

-- tabla de pedidos
create table pedidos (
    pedido_id serial primary key,
    cliente_id int references clientes(cliente_id),
    fecha_pedido timestamp default current_timestamp,
    estado varchar(20) default 'pendiente'
);

-- tabla de items de pedido 
create table items_pedido (
    item_id serial primary key,
    pedido_id int references pedidos(pedido_id),
    producto_id int references productos(producto_id),
    cantidad int not null,
    precio_unitario numeric(10,2) not null
);

-- tabla de errores para el trigger
create table errores_stock (
    error_id serial primary key,
    producto_id int references productos(producto_id),
    cantidad_solicitada int,
    stock_disponible int,
    fecha_error timestamp default current_timestamp,
    descripcion text
);

-- 6. índice compuesto y parcial para ventas del último año
create index idx_items_pedido_ultimo_ano_producto
on items_pedido (producto_id, cantidad);

/*
create index idx_pedidos_fecha_ultimo_ano 
ON pedidos (pedido_id, fecha_pedido)
WHERE fecha_pedido >= CURRENT_DATE - INTERVAL '1 year';
*/

create index idx_pedidos_fecha_ultimo_ano 
ON pedidos (pedido_id, fecha_pedido)
WHERE fecha_pedido >= '2023-01-01';

-- índices adicionales para optimización
create index idx_clientes_email_gmail on clientes(cliente_id) where email like '%@gmail.com';
create index idx_pedidos_fecha on pedidos(fecha_pedido);
create index idx_categorias_padre on categorias(categoria_padre_id);

-- datos de ejemplo 

-- insertar proveedores
insert into proveedores (nombre, contacto) values
('techsupply corp', 'tech@supply.com'),
('electromax ltda', 'info@electromax.com'),
('gadgetworld', 'ventas@gadgetworld.com');

-- insertar categorías jerárquicas
insert into categorias (nombre, categoria_padre_id, nivel) values
('electrónicos', null, 1),  -- electronicos
('hogar', null, 1), -- hogar
('oficina', null, 1), -- 
('computadoras', 1, 2),
('smartphones', 1, 2),
('electrodomésticos', 2, 2),
('laptops', 4, 3),
('tablets', 4, 3),
('iphone', 5, 3),
('android', 5, 3);

-- insertar productos
insert into productos (nombre, categoria_id, proveedor_id, precio_unitario, stock_actual) values
('macbook pro 16"', 7, 1, 2500.00, 50),
('ipad air', 8, 1, 599.99, 75),
('iphone 15 pro', 9, 1, 1199.99, 100),
('samsung galaxy s24', 10, 2, 899.99, 80),
('dell xps 13', 7, 3, 1299.99, 60),
('surface pro 9', 8, 3, 1099.99, 45),
('cafetera nespresso', 6, 2, 199.99, 30),
('aspiradora dyson', 6, 2, 499.99, 25);

-- insertar clientes
insert into clientes (nombre, email, direccion) values
('ana garcía', 'ana.garcia@gmail.com', 'av. principal 123'),
('carlos lópez', 'carlos.lopez@hotmail.com', 'calle secundaria 456'),
('maría gonzález', 'maria.gonzalez@gmail.com', 'plaza central 789'),
('pedro martínez', 'pedro.martinez@gmail.com', 'barrio norte 321'),
('laura rodríguez', 'laura.rodriguez@yahoo.com', 'zona sur 654'),
('diego silva', 'diego.silva@gmail.com', 'centro 987'),
('carmen ruiz', 'carmen.ruiz@gmail.com', 'periferia 147');

-- insertar pedidos
insert into pedidos (cliente_id, fecha_pedido) values
(1, '2024-01-15 10:30:00'),
(2, '2024-02-20 14:15:00'),
(3, '2024-03-10 09:45:00'),
(1, '2024-04-05 16:20:00'),
(4, '2024-05-12 11:30:00'),
(3, '2024-06-08 13:45:00'),
(5, '2024-07-15 08:15:00'),
(6, '2024-08-22 15:30:00'),
(7, '2024-09-18 12:00:00'),
(1, '2024-10-25 10:45:00'),
(2, '2024-11-30 14:30:00'),
(4, '2024-12-15 09:15:00');

-- insertar items de pedido
insert into items_pedido (pedido_id, producto_id, cantidad, precio_unitario) values
(1, 1, 1, 2500.00),
(1, 2, 2, 599.99),
(2, 3, 1, 1199.99),
(2, 4, 1, 899.99),
(3, 5, 1, 1299.99),
(3, 6, 1, 1099.99),
(4, 1, 1, 2500.00),
(4, 7, 2, 199.99),
(5, 3, 2, 1199.99),
(6, 2, 3, 599.99),
(6, 8, 1, 499.99),
(7, 4, 1, 899.99),
(8, 5, 1, 1299.99),
(9, 6, 2, 1099.99),
(10, 1, 1, 2500.00),
(10, 3, 1, 1199.99),
(11, 2, 1, 599.99),
(12, 4, 3, 899.99);



-- 2. consulta: 5 clientes que más han gastado
with gastos_clientes as (
    select 
        c.cliente_id,
        c.nombre,
        c.email,
        sum(ip.cantidad * ip.precio_unitario) as total_gastado,
        row_number() over (order by sum(ip.cantidad * ip.precio_unitario) desc) as ranking -- el numero de fila del gasto total del cliente
    from clientes c
    inner join pedidos p on c.cliente_id = p.cliente_id
    inner join items_pedido ip on p.pedido_id = ip.pedido_id
    group by c.cliente_id, c.nombre, c.email
)
select cliente_id, nombre, email, total_gastado
from gastos_clientes
where ranking <= 5
order by total_gastado desc;



-- 3. consulta: jerarquía de categorías con ruta completa y conteo de productos 
select 
    c1.categoria_id,
    case 
        when c1.nivel = 1 then c1.nombre
        when c1.nivel = 2 then c2.nombre || ' > ' || c1.nombre
        when c1.nivel = 3 then c3.nombre || ' > ' || c2.nombre || ' > ' || c1.nombre
    end as ruta_completa,
    c1.nivel,
    count(p.producto_id) as total_productos
from categorias c1
left join categorias c2 on c1.categoria_padre_id = c2.categoria_id  -- nivel 2 hacia nivel 1
left join categorias c3 on c2.categoria_padre_id = c3.categoria_id  -- nivel 3 hacia nivel 2
left join productos p on c1.categoria_id = p.categoria_id
group by c1.categoria_id, c1.nombre, c1.nivel, c2.nombre, c3.nombre
order by c1.nivel, ruta_completa;

-- 4. consulta: 3 productos más vendidos del último año 
select 
    p.producto_id,
    p.nombre,
    sum(ip.cantidad) as total_vendido
from productos p
inner join items_pedido ip on p.producto_id = ip.producto_id
inner join pedidos ped on ip.pedido_id = ped.pedido_id
where ped.fecha_pedido >= current_date - interval '1 year'
group by p.producto_id, p.nombre
order by total_vendido desc
limit 3;

-- 5. consulta: clientes con email @gmail.com y gasto > 1000 
select 
    c.cliente_id,
    c.nombre,
    c.email
from clientes c
where c.email like '%@gmail.com'
and c.cliente_id in (
    select p.cliente_id
    from pedidos p
    inner join items_pedido ip on p.pedido_id = ip.pedido_id
    group by p.cliente_id
    having sum(ip.cantidad * ip.precio_unitario) > 1000
);

-- 7. trigger: control de stock en items_pedido
create or replace function actualizar_stock_producto()
returns trigger as $$
begin
    -- para insert reducir stock
    if tg_op = 'insert' then
        -- verificar si hay suficiente stock
        if (select stock_actual from productos where producto_id = new.producto_id) < new.cantidad then
            insert into errores_stock (producto_id, cantidad_solicitada, stock_disponible, descripcion)
            values (
                new.producto_id,
                new.cantidad,
                (select stock_actual from productos where producto_id = new.producto_id),
                'stock insuficiente para completar el pedido'
            );
            raise exception 'stock insuficiente para el producto id %', new.producto_id;
        end if;
        
        -- actualizar stock
        update productos 
        set stock_actual = stock_actual - new.cantidad
        where producto_id = new.producto_id;
        
        return new;
    end if;
    
    -- para update ajustar stock según diferencia
    if tg_op = 'update' then
        declare
            diferencia_cantidad int := new.cantidad - old.cantidad;
            stock_disponible int;
        begin
            select stock_actual into stock_disponible 
            from productos 
            where producto_id = new.producto_id;
            
            -- si aumenta la cantidad, verificar stock disponible
            if diferencia_cantidad > 0 and stock_disponible < diferencia_cantidad then
                insert into errores_stock (producto_id, cantidad_solicitada, stock_disponible, descripcion)
                values (
                    new.producto_id,
                    diferencia_cantidad,
                    stock_disponible,
                    'stock insuficiente para actualizar el pedido'
                );
                raise exception 'stock insuficiente para actualizar el producto id %', new.producto_id;
            end if;
            
            -- actualizar stock (si diferencia_cantidad es negativa, suma al stock)
            update productos 
            set stock_actual = stock_actual - diferencia_cantidad
            where producto_id = new.producto_id;
            
            return new;
        end;
    end if;
    
    return null;
end;
$$ language plpgsql;

-- crear triggers
create trigger trigger_stock_insert
    after insert on items_pedido
    for each row
    execute function actualizar_stock_producto();

create trigger trigger_stock_update
    after update on items_pedido
    for each row
    execute function actualizar_stock_producto();




-- bloque transaccional con savepoints --
-- cabe mencionar que las queries del bloque transaccional fueron ejecutadas en plsql.

-- 1. inserte un nuevo pedido
-- 2. inserte varios items de pedido (10)
-- 3. cree un savepoint antes de cada inserción de item
-- 4. si alguno falla, haga rollback to savepoint sin abortar toda la transacción
-- 5. select para ver el estado después de cada operación

begin;
-- 1. insertar un nuevo pedido y obtener su id
savepoint item0;
insert into pedidos (cliente_id, fecha_pedido, estado) 
values (1, current_timestamp, 'procesando');

-- crear variable temporal con el id del último pedido insertado
create temp table temp_pedido_actual as 
select max(pedido_id) as pedido_id from pedidos where cliente_id = 1;

-- mostrar el pedido creado
select 'pedido creado:' as accion, pedido_id, cliente_id, fecha_pedido, estado 
from pedidos 
where pedido_id = (select pedido_id from temp_pedido_actual);

-- 2. insertar 10 items de pedido con savepoints individuales

-- ==================== item 1 ====================
savepoint item1;
insert into items_pedido (pedido_id, producto_id, cantidad, precio_unitario)
select pedido_id, 1, 1, 2500.00 from temp_pedido_actual; -- macbook pro (stock: 50)

-- select para ver el estado después del savepoint item1
select 'después de item 1 (macbook pro):' as estado, count(*) as total_items, sum(cantidad * precio_unitario) as total_pedido
from items_pedido where pedido_id = (select pedido_id from temp_pedido_actual);

-- ==================== item 2 ====================
savepoint item2;
insert into items_pedido (pedido_id, producto_id, cantidad, precio_unitario)
select pedido_id, 2, 3, 599.99 from temp_pedido_actual; -- ipad air (stock: 75)

-- select para ver el estado después del savepoint item2
select 'después de item 2 (ipad air):' as estado, count(*) as total_items, sum(cantidad * precio_unitario) as total_pedido
from items_pedido where pedido_id = (select pedido_id from temp_pedido_actual);

-- ==================== item 3 ====================
savepoint item3;
insert into items_pedido (pedido_id, producto_id, cantidad, precio_unitario)
select pedido_id, 3, 2, 1199.99 from temp_pedido_actual; -- iphone 15 pro (stock: 100)

-- select para ver el estado después del savepoint item3
select 'después de item 3 (iphone 15 pro):' as estado, count(*) as total_items, sum(cantidad * precio_unitario) as total_pedido
from items_pedido where pedido_id = (select pedido_id from temp_pedido_actual);

-- ==================== item 4 ====================
savepoint item4;
insert into items_pedido (pedido_id, producto_id, cantidad, precio_unitario)
select pedido_id, 4, 1, 899.99 from temp_pedido_actual; -- samsung galaxy s24 (stock: 80)

-- select para ver el estado después del savepoint item4
select 'después de item 4 (samsung galaxy):' as estado, count(*) as total_items, sum(cantidad * precio_unitario) as total_pedido
from items_pedido where pedido_id = (select pedido_id from temp_pedido_actual);

-- ==================== item 5 ====================
savepoint item5;
insert into items_pedido (pedido_id, producto_id, cantidad, precio_unitario)
select pedido_id, 5, 1, 1299.99 from temp_pedido_actual; -- dell xps 13 (stock: 60)

-- select para ver el estado después del savepoint item5
select 'después de item 5 (dell xps):' as estado, count(*) as total_items, sum(cantidad * precio_unitario) as total_pedido
from items_pedido where pedido_id = (select pedido_id from temp_pedido_actual);

-- ==================== item 6 (este fallará si descomentamos) ====================
savepoint item6;
-- comentamos el insert problemático para evitar error:
insert into items_pedido (pedido_id, producto_id, cantidad, precio_unitario)
select pedido_id, 8, 100, 499.99 from temp_pedido_actual; -- aspiradora dyson x100 (stock: 25)
-- 
-- si el anterior falla, ejecutar:
rollback to savepoint item6;    

-- insert alternativo que funciona:
insert into items_pedido (pedido_id, producto_id, cantidad, precio_unitario)
select pedido_id, 6, 1, 1099.99 from temp_pedido_actual; -- surface pro 9 (stock: 45)

-- select para ver el estado después del savepoint item6
select 'después de item 6 (surface pro):' as estado, count(*) as total_items, sum(cantidad * precio_unitario) as total_pedido
from items_pedido where pedido_id = (select pedido_id from temp_pedido_actual);

-- ==================== item 7 ====================
savepoint item7;
insert into items_pedido (pedido_id, producto_id, cantidad, precio_unitario)
select pedido_id, 7, 2, 199.99 from temp_pedido_actual; -- cafetera nespresso (stock: 30)

-- select para ver el estado después del savepoint item7
select 'después de item 7 (cafetera):' as estado, count(*) as total_items, sum(cantidad * precio_unitario) as total_pedido
from items_pedido where pedido_id = (select pedido_id from temp_pedido_actual);

-- ==================== item 8 ====================
savepoint item8;
insert into items_pedido (pedido_id, producto_id, cantidad, precio_unitario)
select pedido_id, 8, 1, 499.99 from temp_pedido_actual; -- aspiradora dyson (stock: 25) - cantidad normal

-- select para ver el estado después del savepoint item8
select 'después de item 8 (aspiradora cantidad normal):' as estado, count(*) as total_items, sum(cantidad * precio_unitario) as total_pedido
from items_pedido where pedido_id = (select pedido_id from temp_pedido_actual);

-- ==================== item 9 ====================
savepoint item9;
insert into items_pedido (pedido_id, producto_id, cantidad, precio_unitario)
select pedido_id, 1, 1, 2500.00 from temp_pedido_actual; -- otra macbook pro (stock suficiente)

-- select para ver el estado después del savepoint item9
select 'después de item 9 (segunda macbook):' as estado, count(*) as total_items, sum(cantidad * precio_unitario) as total_pedido
from items_pedido where pedido_id = (select pedido_id from temp_pedido_actual);

-- ==================== item 10 ====================
savepoint item10;  
insert into items_pedido (pedido_id, producto_id, cantidad, precio_unitario)
select pedido_id, 3, 1, 1199.99 from temp_pedido_actual; -- otro iphone 15 pro (stock suficiente)

-- select para ver el estado después del savepoint item10
select 'después de item 10 (segundo iphone):' as estado, count(*) as total_items, sum(cantidad * precio_unitario) as total_pedido
from items_pedido where pedido_id = (select pedido_id from temp_pedido_actual);

-- actualizar estado del pedido
update pedidos 
set estado = 'completado' 
where pedido_id = (select pedido_id from temp_pedido_actual);

-- resumen final detallado
select 
    'resumen final del pedido:' as titulo,
    p.pedido_id,
    p.cliente_id,
    c.nombre as cliente,
    p.fecha_pedido,
    p.estado,
    count(ip.item_id) as total_items_insertados,
    sum(ip.cantidad * ip.precio_unitario) as total_pedido
from pedidos p
inner join clientes c on p.cliente_id = c.cliente_id
left join items_pedido ip on p.pedido_id = ip.pedido_id
where p.pedido_id = (select pedido_id from temp_pedido_actual)
group by p.pedido_id, p.cliente_id, c.nombre, p.fecha_pedido, p.estado;

-- detalle de todos los items insertados
select 
    'detalle de items:' as seccion,
    ip.item_id,
    pr.nombre as producto,
    ip.cantidad,
    ip.precio_unitario,
    (ip.cantidad * ip.precio_unitario) as subtotal
from items_pedido ip
inner join productos pr on ip.producto_id = pr.producto_id
where ip.pedido_id = (select pedido_id from temp_pedido_actual)
order by ip.item_id;

-- confirmar la transacción
commit;
 

-- verificar errores registrados
select 
    e.error_id,
    p.nombre as producto,
    e.cantidad_solicitada,
    e.stock_disponible,
    e.fecha_error,
    e.descripcion
from errores_stock e
inner join productos p on e.producto_id = p.producto_id
order by e.fecha_error desc
limit 5;

-- pruebas del sistema

-- verificar stock inicial
select producto_id, nombre, stock_actual from productos order by producto_id;

-- ejemplo de prueba del trigger (comentado para evitar error)
-- insert into items_pedido (pedido_id, producto_id, cantidad, precio_unitario) 
-- values (1, 8, 100, 499.99);  -- intentar comprar 100 aspiradoras (solo hay 25)

-- verificar tabla de errores
select * from errores_stock;

-- cleanup: eliminar todos los objetos de la base de datos tiendatech
-- ejecutar estas consultas para limpiar completamente la base de datos

-- eliminar triggers
drop trigger if exists trigger_stock_insert on items_pedido;
drop trigger if exists trigger_stock_update on items_pedido;

-- eliminar funciones
drop function if exists actualizar_stock_producto();

-- eliminar índices (se eliminan automáticamente con las tablas, pero por claridad)
drop index if exists idx_items_pedido_ultimo_ano_producto;
drop index if exists idx_clientes_email_gmail;
drop index if exists idx_pedidos_fecha_ultimo_ano;
drop index if exists idx_categorias_padre;


-- eliminar tablas en orden correcto (respetando foreign keys)
drop table if exists errores_stock cascade;
drop table if exists items_pedido cascade;
drop table if exists pedidos cascade;
drop table if exists productos cascade;
drop table if exists categorias cascade;
drop table if exists proveedores cascade;
drop table if exists clientes cascade;

-- reiniciar secuencias para los id si es necesario (opcional)
drop sequence if exists clientes_cliente_id_seq cascade;
drop sequence if exists proveedores_proveedor_id_seq cascade;
drop sequence if exists categorias_categoria_id_seq cascade;
drop sequence if exists productos_producto_id_seq cascade;
drop sequence if exists pedidos_pedido_id_seq cascade;
drop sequence if exists items_pedido_item_id_seq cascade;
drop sequence if exists errores_stock_error_id_seq cascade;

 





