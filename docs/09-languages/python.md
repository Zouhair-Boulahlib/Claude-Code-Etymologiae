# Python Patterns for AI-Assisted Development

> Python's flexibility is its strength and its trap. Type hints, strict linting, and a well-written CLAUDE.md turn Claude Code from a wild guesser into a precise code generator.

## Python-Specific CLAUDE.md

Python projects need more CLAUDE.md guidance than typed languages because the runtime catches almost nothing at write time.

```markdown
## Project
Inventory management API. FastAPI, SQLAlchemy 2.0, PostgreSQL. Python 3.12, async throughout.

## Commands
- `uv run fastapi dev` -- start dev server with auto-reload
- `uv run pytest` -- run all tests
- `uv run pytest --cov=src --cov-report=term-missing` -- coverage
- `uv run ruff check . && uv run ruff format .` -- lint and format
- `uv run mypy src` -- type check

## Python Conventions
- ALL functions must have type hints for parameters and return values.
- `from __future__ import annotations` at the top of every file.
- Imports: stdlib, then third-party, then local. Blank line between groups.
- Pydantic v2 with `Annotated[str, Field(...)]` syntax for all schemas.
- Async by default. Never bare `except:`. Use pathlib.Path, not os.path.
```

The explicit command list matters. AI cannot guess whether you use pytest, unittest, uv, poetry, or pip. Tell it.

## Type Hints and Better AI Output

Type hints are the single highest-leverage improvement for AI-generated Python.

```python
# Without hints -- AI guesses wrong
def process_order(order, user, options=None): ...

# With hints -- AI generates correct code on the first try
async def process_order(
    order: Order, user: User, options: ProcessingOptions | None = None,
) -> Result[CompletedOrder, OrderError]: ...
```

Give the AI Protocol classes and TypeAliases to work with:

```python
from typing import TypeVar, Protocol, TypeAlias

T = TypeVar("T")
ID = TypeVar("ID")

class Repository(Protocol[T, ID]):
    async def get(self, id: ID) -> T | None: ...
    async def list(self, limit: int = 50, offset: int = 0) -> Sequence[T]: ...
    async def create(self, entity: T) -> T: ...
    async def delete(self, id: ID) -> bool: ...
```

## FastAPI/Django Patterns with AI

### Generating a CRUD Module

This is where AI shines -- if you give it the right constraints.

```
Create a CRUD module for "Inventory Item" with fields:
- sku: str unique 3-50 chars, name: str 1-200, quantity: int >= 0
- unit_price: Decimal > 0, category: enum ("electronics","clothing","food","other")
Generate: Pydantic schemas (Create, Update, Response), FastAPI routes, service layer.
Follow patterns in the existing product module.
```

The AI generates schemas like:

```python
from pydantic import BaseModel, Field, ConfigDict
from typing import Annotated

class ItemCategory(StrEnum):
    ELECTRONICS = "electronics"
    CLOTHING = "clothing"
    FOOD = "food"
    OTHER = "other"

class ItemCreate(BaseModel):
    sku: Annotated[str, Field(min_length=3, max_length=50)]
    name: Annotated[str, Field(min_length=1, max_length=200)]
    quantity: Annotated[int, Field(ge=0)]
    unit_price: Annotated[Decimal, Field(gt=0, decimal_places=2)]
    category: ItemCategory

class ItemResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    sku: str
    name: str
    quantity: int
    unit_price: Decimal
    category: ItemCategory
    created_at: datetime
```

And route handlers with proper dependency injection, status codes, and error handling:

```python
router = APIRouter(prefix="/items", tags=["items"])

@router.post("/", response_model=ItemResponse, status_code=status.HTTP_201_CREATED)
async def create_item(
    body: ItemCreate, service: ItemService = Depends(get_item_service),
) -> ItemResponse:
    return ItemResponse.model_validate(await service.create(body))

@router.get("/{item_id}", response_model=ItemResponse)
async def get_item(
    item_id: UUID, service: ItemService = Depends(get_item_service),
) -> ItemResponse:
    item = await service.get_by_id(item_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Item not found")
    return ItemResponse.model_validate(item)
```

For **Django**, swap your CLAUDE.md conventions: "Use DRF ViewSets, ModelSerializer for CRUD, always `select_related`/`prefetch_related`, business logic in services not views, signals are banned."

## Pydantic Model Generation

One of the highest-value prompt patterns. Describe the shape, get validated models back.

```python
from pydantic import BaseModel, Field, model_validator
from typing import Annotated, Self

class Address(BaseModel):
    street: str
    city: str
    state: str
    zip_code: Annotated[str, Field(pattern=r"^\d{5}(-\d{4})?$")]
    country: Annotated[str, Field(min_length=2, max_length=2)] = "US"

class ShippingLabel(BaseModel):
    sender: Address
    recipient: Address
    length_cm: Annotated[float, Field(gt=0)]
    width_cm: Annotated[float, Field(gt=0)]
    height_cm: Annotated[float, Field(gt=0)]
    weight_kg: Annotated[float, Field(gt=0, le=70)]
    service_level: Literal["standard", "express", "overnight"]

    @model_validator(mode="after")
    def validate_dimensions_for_service(self) -> Self:
        if self.service_level == "standard":
            if any(d > 150 for d in [self.length_cm, self.width_cm, self.height_cm]):
                raise ValueError("Standard service rejects packages over 150cm")
        return self
```

## Testing with Pytest

Tell the AI your testing patterns explicitly. Default AI output often uses raw setup instead of fixtures.

```python
@pytest.fixture
def valid_address() -> Address:
    return Address(street="123 Main St", city="Portland", state="OR", zip_code="97201")

class TestShippingLabel:
    @pytest.mark.parametrize("weight,should_pass", [
        (0.1, True), (70.0, True), (70.1, False), (0, False), (-1, False),
    ])
    def test_weight_boundaries(self, valid_address, weight, should_pass):
        kwargs = dict(sender=valid_address, recipient=valid_address,
                      length_cm=30, width_cm=20, height_cm=15,
                      weight_kg=weight, service_level="standard")
        if should_pass:
            assert ShippingLabel(**kwargs).weight_kg == weight
        else:
            with pytest.raises(ValueError):
                ShippingLabel(**kwargs)
```

For service-layer tests, use `AsyncMock` with `spec=` to keep mocks type-safe:

```python
@pytest.fixture
def mock_repo() -> AsyncMock:
    return AsyncMock(spec=ItemRepository)

@pytest.fixture
def service(mock_repo: AsyncMock) -> ItemService:
    return ItemService(repository=mock_repo)

class TestItemService:
    async def test_get_by_id(self, service, mock_repo):
        mock_repo.get.return_value = Item(id=uuid4(), sku="ABC-123", name="Widget")
        result = await service.get_by_id(mock_repo.get.return_value.id)
        assert result is not None
        assert result.sku == "ABC-123"
        mock_repo.get.assert_awaited_once()
```

## Common AI Mistakes in Python

**Wrong indentation context.** When editing a method mid-class, the AI resets indentation to module level. Prevent it: "Edit the `process_payment` method in PaymentService. Keep the existing class structure."

**Mixing sync and async.** The AI forgets `await` constantly. Add to CLAUDE.md: `Every call to an async function must be awaited.`

```python
# Bug -- returns a coroutine, not a User
async def get_user(user_id: int) -> User:
    return db.get(user_id)  # missing await!
```

**Import ordering.** Specify: `from __future__ import annotations` first, then stdlib, third-party, local.

**Mutable default arguments.** AI still writes `def add_item(tags: list[str] = [])`. Always use `None` default with explicit initialization.

## Dependency Management

Put the package manager command in CLAUDE.md. The AI uses whatever you tell it to.

```markdown
## Dependencies
- `uv add <package>` for dependencies, `uv add --dev <package>` for dev
- Never edit pyproject.toml dependency lists manually
```

Same principle for Poetry (`poetry add`) or pip (`pip install && pip freeze`).

## Data Science Workflows

AI generates good pandas code when you give it column names and dtypes.

```
DataFrame `df` columns: order_id (int), customer_id (int), quantity (int),
unit_price (float), order_date (datetime).
Return per-customer summary: total_orders, total_spent, avg_order_value.
```

```python
def customer_summary(df: pd.DataFrame) -> pd.DataFrame:
    df = df.assign(line_total=df["quantity"] * df["unit_price"])
    order_totals = df.groupby(["customer_id", "order_id"])["line_total"].sum().reset_index()
    summary = order_totals.groupby("customer_id").agg(
        total_orders=("order_id", "nunique"),
        total_spent=("line_total", "sum"),
        avg_order_value=("line_total", "mean"),
    )
    dates = df.groupby("customer_id")["order_date"].agg(first_order="min", last_order="max")
    return summary.join(dates).sort_values("total_spent", ascending=False).reset_index()
```

## CLI Tool Generation with Typer

AI generates excellent CLI tools when you specify the interface upfront.

```python
import typer
from pathlib import Path
from typing import Annotated

app = typer.Typer(help="Database migration management.")

@app.command()
def init() -> None:
    """Initialize migrations directory."""
    Path("migrations").mkdir(exist_ok=True)
    config = Path("migrations/config.toml")
    if config.exists():
        typer.echo("Already initialized.")
        raise typer.Exit(code=1)
    config.write_text('[migrations]\ndirectory = "migrations"\n')
    typer.echo("Migrations initialized.")

@app.command()
def create(name: Annotated[str, typer.Argument(help="Migration name")]) -> None:
    """Create a new migration file."""
    from datetime import datetime, timezone
    ts = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    path = Path("migrations") / f"{ts}_{name}.sql"
    path.write_text(f"-- Migration: {name}\n\n-- UP\n\n-- DOWN\n")
    typer.echo(f"Created: {path.name}")

@app.command()
def status() -> None:
    """Show applied and pending migrations."""
    import asyncio
    from src.db import get_connection
    async def _run() -> None:
        async with get_connection() as conn:
            applied = {r["name"] for r in await conn.fetch("SELECT name FROM migrations")}
        for f in sorted(Path("migrations").glob("*.sql")):
            typer.echo(f"  {'[x]' if f.stem in applied else '[ ]'} {f.name}")
    asyncio.run(_run())
```

## Workflow Summary

1. **Type everything.** Type hints are the single most effective improvement. Use `mypy --strict`.
2. **Spell out your tools.** AI cannot guess your package manager, test runner, or linter.
3. **Use Pydantic for all data shapes.** Compile-time-like feedback at runtime.
4. **Ban dangerous patterns.** Bare `except`, mutable defaults, bare `assert` -- ban them in CLAUDE.md.
5. **Specify async or sync.** Mixed codebases confuse the AI. Pick one default.
6. **Run ruff + mypy after every AI edit.** They catch what Python's runtime never will.

Python's permissiveness is the enemy when working with AI. The more constraints you add, the better the output gets.
