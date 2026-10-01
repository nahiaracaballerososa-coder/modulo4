-- ============================================================
-- PRE-ENTREGA MÓDULO 4
-- Consultas multicapa para análisis de negocio
-- ============================================================


-- ============================================================
-- CONSULTA 1: RENTABILIDAD POR CATEGORÍA
--
-- Problema de negocio:
-- Permite identificar qué categorías generan mayor volumen
-- de unidades vendidas e ingresos. Se establece un umbral
-- de 2 unidades vendidas para concentrar el análisis en
-- categorías con un nivel mínimo de movimiento.
-- ============================================================

SELECT
    cat.nombre AS categoria,
    SUM(v.cantidad) AS unidades_vendidas,
    SUM(v.cantidad * v.precio_unitario) AS ingreso_total
FROM ventas AS v
INNER JOIN productos AS p
    ON v.id_producto = p.id_producto
INNER JOIN categorias AS cat
    ON p.categoria = cat.nombre
GROUP BY cat.nombre
HAVING SUM(v.cantidad) > 2
ORDER BY ingreso_total DESC;


-- ============================================================
-- CONSULTA 2: CLIENTES SIN COMPRAS
--
-- Problema de negocio:
-- Permite identificar clientes registrados que todavía
-- no realizaron ninguna compra. Esta información puede
-- utilizarse para campañas de activación o seguimiento.
-- COALESCE permite representar la ausencia de compras
-- como 0.
-- ============================================================

SELECT
    c.id_cliente,
    c.nombre,
    c.apellido,
    COALESCE(COUNT(v.id_venta), 0) AS cantidad_compras
FROM clientes AS c
LEFT JOIN ventas AS v
    ON c.id_cliente = v.id_cliente
GROUP BY
    c.id_cliente,
    c.nombre,
    c.apellido
HAVING COUNT(v.id_venta) = 0;


-- ============================================================
-- CONSULTA 3: TOP DE COMPRAS POR CLIENTE
--
-- Problema de negocio:
-- Permite conocer cuál es el producto que cada cliente
-- compró con mayor frecuencia y cuándo realizó su última
-- transacción. Esta información puede utilizarse para
-- personalizar campañas y recomendaciones comerciales.
-- ============================================================

WITH compras_por_producto AS (
    SELECT
        c.id_cliente,
        c.nombre,
        c.apellido,
        p.id_producto,
        p.nombre AS producto,
        SUM(v.cantidad) AS unidades_compradas,
        MAX(v.fecha_venta) AS ultima_transaccion
    FROM clientes AS c
    INNER JOIN ventas AS v
        ON c.id_cliente = v.id_cliente
    INNER JOIN productos AS p
        ON v.id_producto = p.id_producto
    GROUP BY
        c.id_cliente,
        c.nombre,
        c.apellido,
        p.id_producto,
        p.nombre
),
ranking_productos AS (
    SELECT
        id_cliente,
        nombre,
        apellido,
        producto,
        unidades_compradas,
        ultima_transaccion,
        ROW_NUMBER() OVER (
            PARTITION BY id_cliente
            ORDER BY unidades_compradas DESC, ultima_transaccion DESC
        ) AS posicion
    FROM compras_por_producto
)
SELECT
    nombre,
    apellido,
    producto,
    unidades_compradas,
    ultima_transaccion
FROM ranking_productos
WHERE posicion = 1
ORDER BY id_cliente;
