# Java/Spring Boot Patterns

> Spring's convention-over-configuration philosophy makes it one of the best frameworks for AI-assisted development -- but the conventions must be spelled out.

## CLAUDE.md for Spring Boot

Spring projects need explicit build and test commands. The AI cannot guess your Maven wrapper path, active profiles, or module structure.

```markdown
# CLAUDE.md

## Project
Inventory management service. Spring Boot 3.3, Java 21, PostgreSQL.
Hexagonal architecture: core/, adapters/web/, adapters/persistence/.
Multi-module Maven project.

## Commands
- `./mvnw spring-boot:run -pl app -Dspring-boot.run.profiles=local` -- run locally
- `./mvnw test` -- all tests
- `./mvnw test -pl core` -- core module tests only
- `./mvnw test -Dtest=OrderServiceTest` -- single test class
- `./mvnw test -Dtest="OrderServiceTest#shouldCalculateTotal"` -- single method
- `./mvnw verify` -- full build with integration tests
- `./mvnw flyway:migrate -Dflyway.configFiles=flyway-local.conf` -- run migrations

## Profiles
- `local` -- H2 in-memory, no auth, debug logging
- `test` -- Testcontainers PostgreSQL, mocked external services
- `staging` -- real services, reduced rate limits

## Conventions
- Constructor injection only -- never @Autowired on fields
- All entities use builder pattern via @Builder (Lombok)
- DTOs are Java records in core/models/dto/
- Ports are interfaces in core/ports/, adapters implement them
- All controller parameters annotated with @Valid
- Mapper interfaces use MapStruct, located in adapters/web/mappers/

## Do NOT
- Use field injection
- Put JPA annotations on core domain objects -- only on persistence adapters
- Modify SecurityConfig without explicit approval
- Add new dependencies without discussing first
- Use @SpringBootTest when a slice test (@WebMvcTest, @DataJpaTest) suffices
```

Gradle projects need similar treatment. Replace `./mvnw` with `./gradlew` and specify task names:

```markdown
## Commands
- `./gradlew bootRun --args='--spring.profiles.active=local'` -- run locally
- `./gradlew test` -- all tests
- `./gradlew :core:test` -- core module only
- `./gradlew test --tests "com.example.OrderServiceTest"` -- single class
```

## Why Spring's Annotations Help AI

Spring's annotation system acts as a structured vocabulary the AI already understands. When it sees `@RestController`, `@Service`, `@Repository`, and `@Entity`, it knows the layering rules. This is a genuine advantage over less opinionated frameworks.

The AI knows that:
- `@RestController` handles HTTP -- it belongs in the web layer
- `@Service` holds business logic -- no HTTP concerns here
- `@Repository` talks to the database -- Spring Data conventions apply
- `@Transactional` on service methods, not on repositories or controllers

When your codebase follows these conventions consistently, the AI generates code that fits. When it deviates -- when a controller calls a repository directly, or a service returns `ResponseEntity` -- the AI picks up the bad pattern and repeats it.

## Controller/Service/Repository Generation

The layered prompt approach works best. Generate one layer at a time, review, then move to the next.

```
Create a REST controller at adapters/web/ProductController.java for products.

Endpoints:
- GET /api/v1/products -- list with pagination (Pageable)
- GET /api/v1/products/{id} -- get by ID
- POST /api/v1/products -- create
- PUT /api/v1/products/{id} -- full update
- DELETE /api/v1/products/{id} -- soft delete

Follow the same structure as adapters/web/OrderController.java.
Use ProductService (injected via constructor), not the repository directly.
Return ResponseEntity with proper HTTP status codes.
All request bodies validated with @Valid.
```

Then the service:

```
Create ProductService at core/services/ProductService.java.
Follow the same pattern as OrderService. Inject ProductPersistencePort
via constructor. Use the port interface -- no JPA calls in this class.

Methods:
- listProducts(Pageable): Page<Product>
- getProduct(UUID): Product (throw ResourceNotFoundException if missing)
- createProduct(CreateProductCommand): Product
- updateProduct(UUID, UpdateProductCommand): Product
- deleteProduct(UUID): void (soft delete via the port)
```

## JPA Entity Design

AI-friendly entity patterns use constructor injection and the builder pattern. Lombok's `@Builder` combined with `@AllArgsConstructor` and `@NoArgsConstructor(access = PROTECTED)` gives you immutability at the domain level and JPA compliance at the persistence level.

```java
@Entity
@Table(name = "products")
@Getter
@Builder
@AllArgsConstructor
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class ProductEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal price;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ProductStatus status;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "deleted_at")
    private Instant deletedAt;

    @PrePersist
    void onCreate() {
        this.createdAt = Instant.now();
    }
}
```

Tell the AI about your entity conventions explicitly. Without guidance, it will mix patterns -- using `@Setter` on some entities, public no-arg constructors on others, `Long` IDs on some and `UUID` on others.

## Spring Security Configuration

This is the one area where you must review every line the AI produces. Security configurations are subtle, and a single misconfigured matcher can expose endpoints.

```
Review the SecurityConfig change you just made. For each security rule, explain:
1. Which endpoints it matches
2. What authentication/authorization it requires
3. Why the order matters (Spring Security evaluates top to bottom)
```

Common AI mistakes with Spring Security:

```java
// WRONG: permitAll before authenticated -- order matters
http.authorizeHttpRequests(auth -> auth
    .anyRequest().permitAll()                    // This matches everything first
    .requestMatchers("/api/admin/**").hasRole("ADMIN")  // Never reached
);

// CORRECT: specific matchers first, then default
http.authorizeHttpRequests(auth -> auth
    .requestMatchers("/api/public/**").permitAll()
    .requestMatchers("/api/admin/**").hasRole("ADMIN")
    .requestMatchers("/api/**").authenticated()
    .anyRequest().denyAll()
);
```

Put this in your CLAUDE.md:

```markdown
## Security
- SecurityConfig changes require human review -- always explain each rule
- Matcher order: most specific first, .anyRequest().denyAll() last
- Never use .permitAll() on a broad pattern
- CSRF disabled only for stateless API endpoints (JWT-based)
```

## Test Slicing

Spring Boot's test slices load only the relevant parts of the context. The AI defaults to `@SpringBootTest` for everything -- which is slow and hides dependency problems. Be explicit.

```
Write a test for ProductController using @WebMvcTest (not @SpringBootTest).
Mock ProductService with @MockBean. Test:
- GET /api/v1/products returns 200 with paginated results
- GET /api/v1/products/{id} returns 404 when not found
- POST /api/v1/products returns 400 when name is blank
- POST /api/v1/products returns 201 with Location header

Follow the test style in OrderControllerTest.java.
```

```java
@WebMvcTest(ProductController.class)
class ProductControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private ProductService productService;

    @Test
    void shouldReturn404WhenProductNotFound() throws Exception {
        when(productService.getProduct(any(UUID.class)))
            .thenThrow(new ResourceNotFoundException("Product not found"));

        mockMvc.perform(get("/api/v1/products/{id}", UUID.randomUUID()))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.message").value("Product not found"));
    }
}
```

For repository tests:

```
Write a test for ProductRepository using @DataJpaTest.
Use Testcontainers PostgreSQL (we have a base class: AbstractRepositoryTest).
Test that soft-deleted products are excluded from findAll queries.
```

```java
@DataJpaTest
@Import(TestcontainersConfig.class)
class ProductRepositoryTest extends AbstractRepositoryTest {

    @Autowired
    private ProductRepository repository;

    @Test
    void shouldExcludeSoftDeletedProducts() {
        var active = repository.save(ProductEntity.builder()
            .name("Active").price(BigDecimal.TEN).status(ProductStatus.ACTIVE).build());
        var deleted = repository.save(ProductEntity.builder()
            .name("Deleted").price(BigDecimal.ONE).status(ProductStatus.ACTIVE)
            .deletedAt(Instant.now()).build());

        var results = repository.findAllActive();

        assertThat(results).containsExactly(active);
    }
}
```

## Common AI Mistakes

**Field injection instead of constructor injection.** The AI falls back to `@Autowired` on fields when it sees it anywhere in the codebase. Put "constructor injection only" in CLAUDE.md and enforce it.

```java
// AI default -- avoid this
@Service
public class ProductService {
    @Autowired
    private ProductRepository repo;  // untestable without Spring context
}

// What you want
@Service
@RequiredArgsConstructor
public class ProductService {
    private final ProductRepository repo;  // injectable in unit tests
}
```

**Missing @Transactional.** The AI forgets `@Transactional` on service methods that perform multiple writes. State it: "All service methods that write to the database must be @Transactional."

**Wrong bean scope.** The AI sometimes marks beans as `@Scope("prototype")` or `@RequestScope` without understanding the implications. Spring beans are singletons by default -- that is almost always correct.

**Returning entities from controllers.** The AI skips the DTO layer and returns JPA entities directly, exposing internal fields and lazy-loading proxies. Enforce the boundary: "Controllers return DTOs, never entities."

## Migration Generation

Flyway and Liquibase migrations are excellent candidates for AI generation -- they are repetitive and follow strict patterns.

```
Generate a Flyway migration for the products table.
File: db/migration/V005__create_products_table.sql
Follow the naming pattern of existing migrations in that directory.

Columns:
- id: UUID primary key (gen_random_uuid())
- name: varchar(255) not null
- price: numeric(10,2) not null
- status: varchar(50) not null default 'ACTIVE'
- created_at: timestamptz not null default now()
- deleted_at: timestamptz nullable
- created_by: UUID references users(id)

Include index on status for active product queries.
```

Always specify the version number. The AI cannot see your migration history and will guess wrong.

For Liquibase:

```
Generate a Liquibase changeset in db/changelog/changes/005-create-products.yaml.
Use YAML format matching existing changesets.
Include rollback instructions for each change.
```

## DTO/Mapper Generation with MapStruct

MapStruct interfaces are pure boilerplate -- perfect for AI generation.

```
Create a MapStruct mapper at adapters/web/mappers/ProductMapper.java.
Follow the pattern in OrderMapper.java.

Mappings:
- ProductEntity -> ProductResponse (map deletedAt != null to boolean "archived")
- CreateProductRequest -> Product domain object
- Product domain object -> ProductEntity

Use @Mapper(componentModel = "spring").
```

```java
@Mapper(componentModel = "spring")
public interface ProductMapper {

    @Mapping(target = "archived", expression = "java(entity.getDeletedAt() != null)")
    ProductResponse toResponse(ProductEntity entity);

    Product toDomain(CreateProductRequest request);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "deletedAt", ignore = true)
    ProductEntity toEntity(Product domain);
}
```

Define your DTOs as records. They are concise, immutable, and the AI handles them well:

```java
public record CreateProductRequest(
    @NotBlank String name,
    @NotNull @Positive BigDecimal price,
    @NotNull ProductStatus status
) {}

public record ProductResponse(
    UUID id,
    String name,
    BigDecimal price,
    ProductStatus status,
    boolean archived,
    Instant createdAt
) {}
```

## Hexagonal Architecture Prompts

The magic phrase: "Create a port interface and adapter for X." This maps directly to hexagonal architecture and the AI understands the boundary.

```
Create a port interface at core/ports/NotificationPort.java with methods:
- sendOrderConfirmation(Order order, Customer customer)
- sendShippingUpdate(Order order, TrackingInfo tracking)

Then create an adapter at adapters/notification/EmailNotificationAdapter.java
that implements NotificationPort using our existing EmailService.

The port is in core -- no framework dependencies.
The adapter is in adapters -- it can use Spring annotations.
```

## Real Example: Complete CRUD Endpoint

Here is the full prompt sequence for generating a product feature with hexagonal architecture. Each step builds on the previous one.

**Step 1 -- Domain model and port:**

```
Create the Product domain object at core/domain/Product.java.
Fields: id (UUID), name, price (BigDecimal), status (ProductStatus enum).
No JPA annotations -- this is a pure domain object.

Create ProductPersistencePort at core/ports/ProductPersistencePort.java with:
- save(Product): Product
- findById(UUID): Optional<Product>
- findAll(Pageable): Page<Product>
- softDelete(UUID): void
```

**Step 2 -- Service:**

```
Create ProductService at core/services/ProductService.java.
Inject ProductPersistencePort via constructor.
Implement create, get, list, delete. Throw ResourceNotFoundException
from core/exceptions/ when product not found.
Add @Transactional on write methods.
```

**Step 3 -- Persistence adapter:**

```
Create ProductEntity at adapters/persistence/entities/ProductEntity.java.
Create ProductJpaRepository at adapters/persistence/repositories/.
Create ProductPersistenceAdapter at adapters/persistence/ProductPersistenceAdapter.java
    implementing ProductPersistencePort.
Include a ProductPersistenceMapper (MapStruct) for entity <-> domain conversion.
Follow the same pattern as OrderPersistenceAdapter.
```

**Step 4 -- Web adapter:**

```
Create ProductController at adapters/web/ProductController.java.
Create request/response DTOs as records.
Create ProductWebMapper (MapStruct) for DTO <-> domain conversion.
Follow OrderController patterns. All methods return ResponseEntity.
Include OpenAPI @Operation annotations.
```

**Step 5 -- Tests:**

```
Create tests for each layer:
1. ProductServiceTest -- unit test with mocked port (@ExtendWith(MockitoExtension.class))
2. ProductControllerTest -- @WebMvcTest with mocked service
3. ProductPersistenceAdapterTest -- @DataJpaTest with Testcontainers
4. ProductIntegrationTest -- @SpringBootTest, full stack, happy path only

Follow existing test patterns. Use AssertJ for assertions.
```

This sequence produces a complete, properly layered feature in five focused steps. Each step is small enough to review carefully before moving on.

## Next Steps

- [Testing Strategies](../04-architecture/testing.md) -- Framework-agnostic testing patterns
- [Writing Code](../02-workflows/writing-code.md) -- General code generation techniques
- [The CLAUDE.md File](../01-foundations/claude-md.md) -- Configure project-wide conventions
