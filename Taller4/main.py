import psycopg2
from psycopg2 import Error

NAME_TABLA_CLIENTES = "clientes"
NAME_TABLA_PROVEEDORES = "proveedores"
NAME_TABLA_CATEGORIAS = "categorias"
NAME_TABLA_PRODUCTOS = "productos"
NAME_TABLA_PEDIDOS = "pedidos"
NAME_TABLA_ITEMS_PEDIDO = "items_pedido"
NAME_TABLA_ERRORES_STOCK = "errores_stock"
 
connection = None # inicializa la conexion como none para asegurar que no se usa antes de establecerla.
cursor = None

def connect_to_postgres():
    """Connect to PostgreSQL database and execute sample queries with rollback support"""
    global connection, cursor
    
    try:
        # parametros de conexion
        connection_params = {
            'host': 'localhost',
            'database': 'taller4',
            'user': 'postgres',
            'password': 'postgres',
            'port': 5432
        }
        
        # Establish connection
        connection = psycopg2.connect(**connection_params) # unpacks the dictionary into keyword arguments
        cursor = connection.cursor()
        
        print("✅ Successfully connected to PostgreSQL database")
        
        # Print PostgreSQL version
        cursor.execute("SELECT version();")
        db_version = cursor.fetchone()
        print(f"📊 PostgreSQL version: {db_version[0]}")
        
        return True
        
    except Error as e:
        print(f"❌ Error while connecting to PostgreSQL: {e}")
        if connection:
            connection.rollback()
            print("🔙 Transaction rolled back due to error")
        return False
    
def jerarquia_categorias():
    try:
        cursor.execute("""
            SELECT 
                c1.categoria_id,
                CASE 
                    WHEN c1.nivel = 1 THEN c1.nombre
                    WHEN c1.nivel = 2 THEN c2.nombre || ' > ' || c1.nombre
                    WHEN c1.nivel = 3 THEN c3.nombre || ' > ' || c2.nombre || ' > ' || c1.nombre
                END AS ruta_completa,
                c1.nivel,
                COUNT(p.producto_id) as total_productos
            FROM categorias c1
            LEFT JOIN categorias c2 ON c1.categoria_padre_id = c2.categoria_id
            LEFT JOIN categorias c3 ON c2.categoria_padre_id = c3.categoria_id
            LEFT JOIN productos p ON c1.categoria_id = p.categoria_id
            GROUP BY c1.categoria_id, c1.nombre, c1.nivel, c2.nombre, c3.nombre
            ORDER BY c1.nivel, ruta_completa;
        """)
        results = cursor.fetchall()
       
        return results

    except Error as e:
        print(f"❌ Error al consultar categorías: {e}")
    
def productos_mas_vendidos():
    try:
        cursor.execute("""
            SELECT 
                p.producto_id,
                p.nombre,
                SUM(ip.cantidad) as total_vendido
            FROM productos p
            INNER JOIN items_pedido ip ON p.producto_id = ip.producto_id
            INNER JOIN pedidos ped ON ip.pedido_id = ped.pedido_id
            WHERE ped.fecha_pedido >= CURRENT_DATE - INTERVAL '1 year'
            GROUP BY p.producto_id, p.nombre
            ORDER BY total_vendido DESC
            LIMIT 3;
        """)
        results = cursor.fetchall()
        return results
    except Error as e:
                print(f"❌ Error al consultar productos: {e}")
def listar_tablas():
    try:         
        cursor.execute("""
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'public'
            AND table_type = 'BASE TABLE'
            ORDER BY table_name;
        """)
        results = cursor.fetchall()
        return results
    except Error as e:
        print(f"❌ Error al listar tablas: {e}")
def clientes_con_mas_gasto():
    try:
        cursor.execute("""
            WITH gastos_clientes AS (
                SELECT 
                    c.cliente_id,
                    c.nombre,
                    c.email,
                    SUM(ip.cantidad * ip.precio_unitario) as total_gastado,
                    ROW_NUMBER() OVER (ORDER BY SUM(ip.cantidad * ip.precio_unitario) DESC) as ranking
                FROM clientes c
                INNER JOIN pedidos p ON c.cliente_id = p.cliente_id
                INNER JOIN items_pedido ip ON p.pedido_id = ip.pedido_id
                GROUP BY c.cliente_id, c.nombre, c.email
            )
            SELECT cliente_id, nombre, email, total_gastado
            FROM gastos_clientes
            WHERE ranking <= 5
            ORDER BY total_gastado DESC;
        """)
        results = cursor.fetchall()
        return results

    except Error as e:
        print(f"❌ Error al consultar clientes: {e}")
def clientes_gmail_con_gasto_mayor_a_1000():
    try:
        cursor.execute("""
            SELECT 
                c.cliente_id,
                c.nombre,
                c.email
            FROM clientes c
            WHERE c.email LIKE '%@gmail.com'
            AND c.cliente_id IN (
                SELECT p.cliente_id
                FROM pedidos p
                INNER JOIN items_pedido ip ON p.pedido_id = ip.pedido_id
                GROUP BY p.cliente_id
                HAVING SUM(ip.cantidad * ip.precio_unitario) > 1000
            );
        """)
        results = cursor.fetchall()
        return results
    except Error as e:
        print(f"❌ Error al consultar clientes Gmail: {e}")
def stock_productos():
            try:
                cursor.execute("""
                    SELECT producto_id, nombre, stock_actual 
                    FROM productos 
                    ORDER BY stock_actual ASC;
                """)
                results = cursor.fetchall()
                return results
            

            except Error as e:
                print(f"❌ Error al consultar stock: {e}")
    
def menu():
    """Display a simple menu for user interaction"""
    global cursor, connection
    
    while True:
        print("\n" + "="*50)
        print("TIENDATECH - SISTEMA DE GESTIÓN")
        print("="*50)
        print("1. Listar tablas")
        print("2. Mostrar top 5 clientes con mayor gasto")
        print("3. Mostrar jerarquía de categorías")
        print("4. Mostrar productos más vendidos")
        print("5. Mostrar clientes Gmail con gasto > 1000")
        print("6. Verificar stock de productos")
        print("7. Salir")
        print("="*50)
        
        choice = input("Ingrese su opción: ")

        if choice == '1':
            print("\n📊 Listando tablas...")
            results = listar_tablas()
            if results:
                print("\nTablas en la base de datos:")
                for table in results:
                    print(f"  • {table[0]}")     
        elif choice == '2':
            print("\n💰 Top 5 clientes con mayor gasto...")
            results = clientes_con_mas_gasto()
            for i, row in enumerate(results, 1):
                print(f"  {i}. {row[1]} ({row[2]}) - ${row[3]:,.2f}") 
        elif choice == '3':
            print("\n🏷️  Jerarquía de categorías...")
          
            result = jerarquia_categorias()
            if result:
                for row in results:
                    print(f"  Nivel {row[2]}: {row[1]} ({row[3]} productos)")
        elif choice == '4':
            
            print("\n🔥 Productos más vendidos del último año...")
            results = productos_mas_vendidos()
            if results:
                print("\nTop 3 productos más vendidos:")
                for i, row in enumerate(results, 1):
                    print(f"  {i}. {row[1]} - {row[2]} unidades vendidas")
        elif choice == '5':
            print("\n📧 Clientes Gmail con gasto > $1000...")
            results = clientes_gmail_con_gasto_mayor_a_1000()
            if results:
                print("\nClientes Gmail con gasto mayor a $1000:")
                for row in results:
                    print(f"  • {row[1]} ({row[2]})")     
        elif choice == '6':
            print("\n📦 Stock de productos...")
            results = stock_productos()
            if results:
                for row in results:
                    status = "⚠️ BAJO" if row[2] < 30 else "✅ OK"
                    print(f"  {row[1]}: {row[2]} unidades {status}")
        elif choice == '8':
            print("\n👋 Cerrando conexión y saliendo...")
            if cursor:
                cursor.close()
            if connection:
                connection.close()
            print("✅ Conexión cerrada correctamente")
            break
            
        else:
            print("❌ Opción inválida, por favor intente nuevamente.")


def close_connection():
    """Close database connections"""
    global cursor, connection
    try:
        if cursor:
            cursor.close()
        if connection:
            connection.close()
        print("✅ Database connections closed successfully")
    except Error as e:
        print(f"❌ Error closing connections: {e}")
            

if __name__ == "__main__":
    print("🚀 Starting TiendaTech PostgreSQL System")
    print("=" * 50)
    
    # Intentar conectar a la base de datos
    if connect_to_postgres():
        print("✅ Conexión establecida correctamente")
        menu()
    else:
        print("❌ No se pudo establecer la conexión. Programa terminado.")
    
    # Cleanup al final
    close_connection()
