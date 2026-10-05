# ms-productos

Microservicio REST de catálogo (categorías y productos) para la plataforma de delivery de comida. Forma parte de la Evaluación Parcial N°2 del curso JVY0101 (Java: Diseño y Construcción de Soluciones nativas en Nube).

Cada categoría tiene muchos productos (`@OneToMany`) y cada producto pertenece a una categoría (`@ManyToOne`). El servicio usa su propia base de datos (`catalogo_db`), siguiendo el patrón Database per Service.

## Tecnologías

- Java 17
- Spring Boot 4.1.1 (Web, Data JPA, Validation)
- PostgreSQL 16
- Maven (Maven Wrapper incluido)

## Requisitos

- JDK 17 o superior
- Docker (para PostgreSQL) o PostgreSQL 16 instalado
- Git
- No necesitas instalar Maven: el proyecto incluye `mvnw`

## Cómo clonar

```powershell
git clone https://github.com/kodevlyu/jvy0101-tienda-ms-productos.git
cd jvy0101-tienda-ms-productos
git checkout develop
```

## Configuración de la base de datos

1. Levanta PostgreSQL con Docker:

```powershell
docker run --name pg-ms -e POSTGRES_PASSWORD=admin123 -p 5432:5432 -d postgres:16
```

2. Crea el usuario y la base de datos:

```powershell
docker exec -it pg-ms psql -U postgres -c "CREATE USER ms_user WITH PASSWORD 'ms_pass123';"
docker exec -it pg-ms psql -U postgres -c "CREATE DATABASE catalogo_db OWNER ms_user;"
```

Las tablas `categorias` y `productos` las crea Hibernate automáticamente al iniciar.

## Configuración de application.properties

Archivo `src/main/resources/application.properties`:

```properties
spring.application.name=ms-productos
server.port=8083
spring.datasource.url=jdbc:postgresql://localhost:5432/catalogo_db
spring.datasource.username=ms_user
spring.datasource.password=ms_pass123
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
spring.jpa.open-in-view=false
```

## Compilar y ejecutar

```powershell
.\mvnw clean package
java -jar target\ms-productos-0.0.1-SNAPSHOT.jar
```

El servicio queda disponible en `http://localhost:8083`.

## Endpoints

### Categorías (`/api/categorias`)

| Método | Ruta | Descripción | Código |
|--------|------|-------------|--------|
| POST | `/api/categorias` | Crea una categoría | 201 |
| GET | `/api/categorias` | Lista las categorías | 200 |
| GET | `/api/categorias/{id}` | Obtiene una categoría | 200 |
| PUT | `/api/categorias/{id}` | Actualiza una categoría | 200 |
| DELETE | `/api/categorias/{id}` | Elimina una categoría | 204 |

### Productos (`/api/productos`)

| Método | Ruta | Descripción | Código |
|--------|------|-------------|--------|
| POST | `/api/productos` | Crea un producto | 201 |
| GET | `/api/productos` | Lista los productos | 200 |
| GET | `/api/productos/{id}` | Obtiene un producto | 200 |
| PUT | `/api/productos/{id}` | Actualiza un producto | 200 |
| DELETE | `/api/productos/{id}` | Elimina un producto | 204 |

### Ejemplo de body

```json
{ "nombre": "Pizza Margarita", "precio": 8990, "stock": 20, "categoria": { "id": 1 } }
```

### Errores

- `404`: el recurso con ese id no existe.
- `400`: datos inválidos (nombre vacío, precio negativo, etc.). Responde con `mensaje`, `errores` y `status`.

## Pruebas

La colección de Postman `ms-productos` incluye casos de éxito (201, 200, 204) y de error (404, 400).