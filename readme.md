# 1. INTRODUCCIÓN

Las funciones agregadas y analíticas le permiten hacer un cálculo en muchas filas. Las funciones agregadas reducen la salida a una fila por grupo. Por ejemplo, lo siguiente cuenta el total de filas en la tabla. Devuelve una fila:

```sql
select count(*) from bricks;
```

Agregar la cláusula de **over** lo convierte en una analítica. Esto devuelve seis registros con el total de seis en cada una de las filas:

```sql
select count(*) from bricks;
```

Esto le permite ver los valores de todas las otras columnas, **sin tener que usar _group by_**:

```sql
select b.*, 
       count(*) over () total_count 
from   bricks b;
```

# 2. PARTITION BY

La cláusula group by divide filas en grupos del mismo valor. Por ejemplo, los siguientes obtienen el número de filas y el peso total para cada color:

```sql
select colour, count(*), sum ( weight )
from   bricks
group  by colour;
```

Puede _dividir_ la entrada a una función analítica como esta con la cláusula **partition by**. A continuación, se muestra el peso total y el recuento de filas de cada color. Incluye todas las filas:

```sql
SELECT
	B.*,
	COUNT(*) OVER (PARTITION BY COLOUR) BRICKS_PER_COLOUR,
	SUM(WEIGHT) OVER (PARTITION BY COLOUR) WEIGHT_PER_COLOUR
FROM
	BRICKS B;
```

BRICK_ID |COLOUR |SHAPE   |WEIGHT |BRICKS_PER_COLOUR |WEIGHT_PER_COLOUR |
---------|-------|--------|-------|------------------|------------------|
2        |blue   |pyramid |2      |2                 |3                 |
1        |blue   |cube    |1      |2                 |3                 |
6        |green  |pyramid |1      |1                 |1                 |
5        |red    |pyramid |3      |3                 |6                 |
4        |red    |cube    |2      |3                 |6                 |
3        |red    |cube    |1      |3                 |6                 |

La siguiente consulta para devolver el recuento y el peso promedio de los ladrillos para cada forma:

```sql
SELECT B.*,
       COUNT(*) OVER () BRICKS_PER_SHAPE,
       MEDIAN ( WEIGHT ) OVER () MEDIAN_WEIGHT_PER_SHAPE
FROM   BRICKS B;
```

BRICK_ID |COLOUR |SHAPE   |WEIGHT |BRICKS_PER_SHAPE |MEDIAN_WEIGHT_PER_SHAPE |
---------|-------|--------|-------|-----------------|------------------------|
1        |blue   |cube    |1      |6                |1.5                     |
3        |red    |cube    |1      |6                |1.5                     |
6        |green  |pyramid |1      |6                |1.5                     |
4        |red    |cube    |2      |6                |1.5                     |
2        |blue   |pyramid |2      |6                |1.5                     |
5        |red    |pyramid |3      |6                |1.5                     |

# 4. ORDER BY

La cláusula order by le permite _calcular totales acumulados_. Por ejemplo, la siguiente consulta ordena las filas por brick_id. Luego muestra el número total de filas y la suma de los pesos para las filas con un brick_id menor o igual que el de la fila actual:

```sql
SELECT B.*, 
       COUNT(*) OVER (ORDER BY BRICK_ID ) RUNNING_TOTAL, 
       SUM (WEIGHT) OVER (ORDER BY BRICK_ID) RUNNING_WEIGHT
FROM   BRICKS B;
```

BRICK_ID |COLOUR |SHAPE   |WEIGHT |RUNNING_TOTAL |RUNNING_WEIGHT |
---------|-------|--------|-------|--------------|---------------|
1        |blue   |cube    |1      |1             |1              |
2        |blue   |pyramid |2      |2             |3              |
3        |red    |cube    |1      |3             |4              |
4        |red    |cube    |2      |4             |6              |
5        |red    |pyramid |3      |5             |9              |
6        |green  |pyramid |1      |6             |10             |

La siguiente consulta obtiene el peso promedio actual, ordenado por brick_id:

```sql
SELECT B.BRICK_ID, B.WEIGHT,
       ROUND (AVG(WEIGHT) OVER(), 2) RUNNING_AVERAGE_WEIGHT
FROM   BRICKS B;
```

BRICK_ID |WEIGHT |RUNNING_AVERAGE_WEIGHT |
---------|-------|-----------------------|
1        |1      |1.67                   |
2        |2      |1.67                   |
3        |1      |1.67                   |
4        |2      |1.67                   |
5        |3      |1.67                   |
6        |1      |1.67                   |

# 5. PARTITION BY + ORDER BY

Puede combinar las cláusulas **partition by** con **order by** para obtener **_totales acumulados dentro de un grupo_**. Por ejemplo, la siguiente consulta divide las filas por color. Y a continuación, obtiene el recuento y el peso de las filas para cada color, ordenados por brick_id:

```sql
SELECT
	B.*,
	COUNT(*) OVER(PARTITION BY COLOUR ORDER BY BRICK_ID) RUNNING_TOTAL,
	SUM(WEIGHT) OVER(PARTITION BY COLOUR ORDER BY BRICK_ID) RUNNING_WEIGHT
FROM
	BRICKS B;
```

BRICK_ID |COLOUR |SHAPE   |WEIGHT |RUNNING_TOTAL |RUNNING_WEIGHT |
---------|-------|--------|-------|--------------|---------------|
1        |blue   |cube    |1      |1             |1              |
2        |blue   |pyramid |2      |2             |3              |
6        |green  |pyramid |1      |1             |1              |
3        |red    |cube    |1      |1             |1              |
4        |red    |cube    |2      |2             |3              |
5        |red    |pyramid |3      |3             |6              |

# 6. WINDOWING CLAUSE

Cuando utiliza order by, la base de datos agrega una cláusula de ventana predeterminada de:

```sql
RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
```

Esto significa que incluya todas las filas con un **valor** menor o igual al de la fila actual.

Esto puede llevar a la función incluya valores de filas después de la fila actual

Por ejemplo, hay varias filas con el mismo peso. Entonces, cuando ordena por el peso, todas las filas con el mismo peso tienen el mismo conteo y peso:

```sql
SELECT
	B.*,
	COUNT(*) OVER(ORDER BY WEIGHT) RUNNING_TOTAL,
	SUM(WEIGHT) OVER(ORDER BY WEIGHT) RUNNING_WEIGHT
FROM
	BRICKS B
ORDER BY WEIGHT;
```

BRICK_ID |COLOUR |SHAPE   |WEIGHT |RUNNING_TOTAL |RUNNING_WEIGHT |
---------|-------|--------|-------|--------------|---------------|
1        |blue   |cube    |1      |3             |3              |
3        |red    |cube    |1      |3             |3              |
6        |green  |pyramid |1      |3             |3              |
4        |red    |cube    |2      |5             |7              |
2        |blue   |pyramid |2      |5             |7              |
5        |red    |pyramid |3      |6             |10             |

Por lo general, esto no es lo que quieres. Normalmente, los totales acumulados solo deben incluir valores de filas anteriores en el conjunto de datos.

To do this, you must specify a windowing clause of

Para hacer esto, debe especificar una cláusula de ventana de

```sql
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
```

Quedándose la consulta como:

```sql
SELECT
	B.*,
	COUNT(*) OVER (ORDER BY WEIGHT ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) RUNNING_TOTAL,
	SUM(WEIGHT) OVER (ORDER BY WEIGHT ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) RUNNING_WEIGHT
FROM
	BRICKS B
ORDER BY
	WEIGHT;
```
BRICK_ID |COLOUR |SHAPE   |WEIGHT |RUNNING_TOTAL |RUNNING_WEIGHT |
---------|-------|--------|-------|--------------|---------------|
1        |blue   |cube    |1      |1             |1              |
3        |red    |cube    |1      |2             |2              |
6        |green  |pyramid |1      |3             |3              |
4        |red    |cube    |2      |4             |5              |
2        |blue   |pyramid |2      |5             |7              |
5        |red    |pyramid |3      |6             |10             |

# 7. SLIDING WINDOWS

Además de ejecutar totales hasta ahora, puede cambiar la cláusula de ventana para que sea un subconjunto de las filas previas.

A continuación se muestra el peso total de: 
1. La fila actual + la fila anterior 
2. Todas las filas con el mismo peso que la actual + todas las filas con un peso menos que el actual

```sql
SELECT
	B.*,
	SUM(WEIGHT) OVER (ORDER BY WEIGHT ROWS BETWEEN 1 PRECEDING AND CURRENT ROW) RUNNING_ROW_WEIGHT,
	SUM(WEIGHT) OVER (ORDER BY WEIGHT RANGE BETWEEN 1 PRECEDING AND CURRENT ROW) RUNNING_VALUE_WEIGHT
FROM
	BRICKS B
ORDER BY
	WEIGHT,
	BRICK_ID;
```
BRICK_ID |COLOUR |SHAPE   |WEIGHT |RUNNING_ROW_WEIGHT |RUNNING_VALUE_WEIGHT |
---------|-------|--------|-------|-------------------|---------------------|
1        |blue   |cube    |1      |1                  |3                    |
3        |red    |cube    |1      |2                  |3                    |
6        |green  |pyramid |1      |2                  |3                    |
2        |blue   |pyramid |2      |3                  |7                    |
4        |red    |cube    |2      |4                  |7                    |
5        |red    |pyramid |3      |5                  |7                    |

También puede cambiar **current row** a filas o valores después de la actual. Haga esto especificando un número **following**. Por ejemplo, esta consulta calcula las ponderaciones deslizantes, incluidas las filas o los valores a cada lado de la fila actual:

¡También puede compensar la ventana, por lo que excluye la fila actual! Puedes hacer esto a cada lado de la fila actual.

Por ejemplo, la siguiente consulta tiene dos conteos.

1. El primero muestra el número de filas con un peso uno o dos menos que el actual.
2. El segundo cuenta aquellos con pesos mayores que el actual.

Así que si el peso actual = 2, el primer conteo incluye filas con el peso 0 o 1. Las segundas filas con el peso 3 o 4:

```sql
SELECT B.*, 
       COUNT (*) OVER (ORDER BY WEIGHT RANGE BETWEEN 2 PRECEDING AND 1 PRECEDING) COUNT_2_LOWER_THAN_CURRENT, 
       COUNT (*) OVER (ORDER BY WEIGHT RANGE BETWEEN 1 FOLLOWING AND 2 FOLLOWING) COUNT_2_GREATER_THAN_CURRENT
FROM   BRICKS B
ORDER  BY WEIGHT;
```

BRICK_ID |COLOUR |SHAPE   |WEIGHT |COUNT_2_LOWER_THAN_CURRENT |COUNT_2_GREATER_THAN_CURRENT |
---------|-------|--------|-------|---------------------------|-----------------------------|
1        |blue   |cube    |1      |0                          |3                            |
3        |red    |cube    |1      |0                          |3                            |
6        |green  |pyramid |1      |0                          |3                            |
4        |red    |cube    |2      |3                          |1                            |
2        |blue   |pyramid |2      |3                          |1                            |
5        |red    |pyramid |3      |5                          |0                            |

Por último devolver el color mínimo de las dos filas antes de la actual El recuento de filas con el mismo peso que el actual y un valor siguiente

```sql
SELECT B.*, 
       MIN (COLOUR) OVER (ORDER BY BRICK_ID) FIRST_COLOUR_TWO_PREV, 
       COUNT (*) OVER (ORDER BY WEIGHT) COUNT_VALUES_THIS_AND_NEXT
FROM   BRICKS B
ORDER  BY WEIGHT;
```

BRICK_ID |COLOUR |SHAPE   |WEIGHT |FIRST_COLOUR_TWO_PREV |COUNT_VALUES_THIS_AND_NEXT |
---------|-------|--------|-------|----------------------|---------------------------|
1        |blue   |cube    |1      |blue                  |3                          |
3        |red    |cube    |1      |blue                  |3                          |
6        |green  |pyramid |1      |blue                  |3                          |
4        |red    |cube    |2      |blue                  |5                          |
2        |blue   |pyramid |2      |blue                  |5                          |
5        |red    |pyramid |3      |blue                  |6                          |

# 9. FILTERING

A menudo quiere filtrar filas usando el resultado de un agregado. Por ejemplo, para encontrar todos los colores tienes dos o más ladrillos de. Puedes hacer esto con un grupo usando la cláusula having:

```sql
SELECT COLOUR FROM BRICKS
GROUP  BY COLOUR
HAVING COUNT(*) >= 2;
```

COLOUR |
-------|
red    |
blue   |

¡Pero no puedes ver las otras columnas! Una forma de incluir estos es dividir el recuento por color. Pero **la base de datos procesa las funciones analíticas después de la cláusula where**. Entonces no puedes usar esto en donde. Lo siguiente plantea un **ERROR**:

```sql
SELECT COLOUR FROM BRICKS
WHERE  COUNT(*) OVER ( PARTITION BY COLOUR ) >= 2;
```

_ORA-00934: group function is not allowed here_

Para resolver esto, debe usar la analítica en una subconsulta. Luego, filtrar en la consulta externa. Por ejemplo:

```sql
SELECT * FROM (
  SELECT B.*,
         COUNT(*) OVER ( PARTITION BY COLOUR ) COLOUR_COUNT
  FROM   BRICKS B
)
WHERE  COLOUR_COUNT >= 2;
```

BRICK_ID |COLOUR |SHAPE   |WEIGHT |COLOUR_COUNT |
---------|-------|--------|-------|-------------|
2        |blue   |pyramid |2      |2            |
1        |blue   |cube    |1      |2            |
5        |red    |pyramid |3      |3            |
4        |red    |cube    |2      |3            |
3        |red    |cube    |1      |3            |

La siguiente consulta para encontrar las filas donde El peso total de la forma El peso corriente por brick_id son ambos mayores que cuatro:

```sql
WITH TOTALS AS (
  SELECT B.*,
         SUM (WEIGHT) OVER (PARTITION BY SHAPE) WEIGHT_PER_SHAPE,
         SUM (WEIGHT) OVER (ORDER BY BRICK_ID) RUNNING_WEIGHT_BY_ID
  FROM   BRICKS B
)
  SELECT * FROM TOTALS
  WHERE  WEIGHT_PER_SHAPE > 4 AND RUNNING_WEIGHT_BY_ID > 4
```

BRICK_ID |COLOUR |SHAPE   |WEIGHT |WEIGHT_PER_SHAPE |RUNNING_WEIGHT_BY_ID |
---------|-------|--------|-------|-----------------|---------------------|
5        |red    |pyramid |3      |6                |9                    |
6        |green  |pyramid |1      |6                |10                   |


# 11. OTRAS FUNCIONES ANALÍTICAS

Puede agregar la cláusula de **over** para agregar funciones para que sean analíticas. Pero hay muchas funciones que necesitan la cláusula de **over**.

## Row numbering

El rango de funciones analíticas, **dense_rank** y **row_number** devuelven un contador creciente, comenzando en uno.

* **RANK**: las filas con el mismo valor en el orden tienen el mismo rango. La siguiente fila después de un empate tiene el valor N, donde N es su posición en el conjunto de datos.

* **DENSE_RANK** - Filas con el mismo valor en el orden por tener el mismo rango, pero no hay lagunas en los rangos

* **ROW_NUMBER** - cada fila tiene un nuevo valor

```sql
SELECT BRICK_ID, WEIGHT, 
       ROW_NUMBER() OVER (ORDER BY WEIGHT) RN, 
       RANK() OVER (ORDER BY WEIGHT) RK, 
       DENSE_RANK() OVER (ORDER BY WEIGHT) DR
FROM   BRICKS;
```

BRICK_ID |WEIGHT |RN |RK |DR |
---------|-------|---|---|---|
1        |1      |1  |1  |1  |
3        |1      |2  |1  |1  |
6        |1      |3  |1  |1  |
4        |2      |4  |4  |2  |
2        |2      |5  |4  |2  |
5        |3      |6  |6  |3  |

## Previous and Next Values

**Lag** y **lead** le permiten obtener valores de filas hacia atrás y hacia adelante en sus resultados.

```sql
SELECT B.*,
       LAG (SHAPE) OVER (ORDER BY BRICK_ID) PREV_SHAPE,
       LEAD (SHAPE) OVER (ORDER BY BRICK_ID) NEXT_SHAPE
FROM   BRICKS B;
```

BRICK_ID |COLOUR |SHAPE   |WEIGHT |PREV_SHAPE |NEXT_SHAPE |
---------|-------|--------|-------|-----------|-----------|
1        |blue   |cube    |1      |           |pyramid    |
2        |blue   |pyramid |2      |cube       |cube       |
3        |red    |cube    |1      |pyramid    |cube       |
4        |red    |cube    |2      |cube       |pyramid    |
5        |red    |pyramid |3      |cube       |pyramid    |
6        |green  |pyramid |1      |pyramid    |           |

## First and Last Values

Puede obtener el primer o último valor en un conjunto ordenado con **first_value** y **last_value**:

```sql
SELECT B.*,
       FIRST_VALUE (WEIGHT) OVER (ORDER BY BRICK_ID) FIRST_WEIGHT_BY_ID,
       LAST_VALUE (WEIGHT) OVER (ORDER BY BRICK_ID) LAST_WEIGHT_BY_ID
FROM   BRICKS B;
```

BRICK_ID |COLOUR |SHAPE   |WEIGHT |FIRST_WEIGHT_BY_ID |LAST_WEIGHT_BY_ID |
---------|-------|--------|-------|-------------------|------------------|
1        |blue   |cube    |1      |1                  |1                 |
2        |blue   |pyramid |2      |1                  |2                 |
3        |red    |cube    |1      |1                  |1                 |
4        |red    |cube    |2      |1                  |2                 |
5        |red    |pyramid |3      |1                  |3                 |
6        |green  |pyramid |1      |1                  |1                 |

Nota el resultado de **first_value** permanece igual. Pero para **last_value** cambia para cada fila. Esto se debe a que la cláusula de ventana predeterminada se detiene en la fila actual. Para buscar el valor de la última fila del conjunto de datos, cambie el final de la ventana a  **unbounded following**. Por ejemplo:

```sql
SELECT B.*,
       FIRST_VALUE (WEIGHT) OVER (ORDER BY BRICK_ID) FIRST_WEIGHT_BY_ID,
       LAST_VALUE (WEIGHT) OVER (ORDER BY BRICK_ID RANGE BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) LAST_WEIGHT_BY_ID
FROM   BRICKS B;
```

BRICK_ID |COLOUR |SHAPE   |WEIGHT |FIRST_WEIGHT_BY_ID |LAST_WEIGHT_BY_ID |
---------|-------|--------|-------|-------------------|------------------|
1        |blue   |cube    |1      |1                  |1                 |
2        |blue   |pyramid |2      |1                  |1                 |
3        |red    |cube    |1      |1                  |1                 |
4        |red    |cube    |2      |1                  |1                 |
5        |red    |pyramid |3      |1                  |1                 |
6        |green  |pyramid |1      |1                  |1                 |

Para ampliar información dirigirse a:

[Oracle Analytic Functions](https://docs.oracle.com/en/database/oracle/oracle-database/18/sqlrf/Analytic-Functions.html#GUID-527832F7-63C0-4445-8C16-307FA5084056)