# basalt_example — Flutter shop

![Flutter](https://img.shields.io/badge/Flutter-3.19%2B-02569B?logo=flutter&logoColor=white)
![State](https://img.shields.io/badge/state-cubit-6E4AA4)
![Part of](https://img.shields.io/badge/part_of-basalt__dart-informational)

A full **Flutter** application built on [basalt_dart](../README.md): an online shop with products,
categories, customers, orders and reviews. It's a showcase of basalt's harder features under a **clean
architecture** with **cubit** state management.

## What it demonstrates

| basalt feature | Where |
|---|---|
| **Belongs-to relations** (`@Relation`) | `ProductRow.category`, `OrderRow.customer`/`shippingAddress`, `ReviewRow.product`/`customer` |
| **Self-referential relation** | `CategoryRow.parent` (`categories.parent_id → categories.id`) |
| **Nested relations with `depth`** | `OrderItemRow.product` (`depth: 2`) loads the product *and* its category in one query |
| **One-to-many loading** (no N+1) | `loadGroupedByFk` for a customer's addresses; batched item loading in `order_items_loader.dart` |
| **Many-to-many** | orders ↔ products through the `order_items` junction |
| **Transactions + `RETURNING`** | `OrderRepositoryImpl.placeOrder` — insert order, insert items, decrement stock, all atomic |
| **Typed aggregates + `GROUP BY`** | product rating (`AVG`/`COUNT`), per-category product counts, low-stock query |
| **Raw-SQL escape hatch** | `AnalyticsRepositoryImpl` — revenue & top customers (`SUM(quantity * unit_price)`) |
| **Migrations** | `migrations/` applied by the CLI (dev) and by the app at startup (bundled assets) |
| **Codegen** | `@Queryable`/`@Insertable`/`@AsChangeset` derive readers, queries and `toInsert()`/`toUpdate()` |
| **Read/write model split** | separate `*Row` (read, with relations) and `*Write` (flat insert/update) classes; `CustomerRow` keeps all three derives on one class as the simple combined example |

## Architecture

```
lib/
  core/          # database bootstrap, asset migration runner, seed, DI, formatters
    database/    #   schema.dart (generated) · app_database · asset_migration_source · seed_data
    di/          #   get_it service locator
  domain/        # pure entities (rich DateTime/enum/bool types) + repository interfaces  — no basalt
    entities/    #   Product, Order, Review, … + view models (ProductWithStats, OrderSummary, …)
    repositories/#   abstract interfaces
  data/          # basalt-facing layer
    models/      #   *Row (read: @Queryable + @Relation) + *Write (@Insertable/@AsChangeset) + generated *.g.dart
                 #   CustomerRow keeps all three derives on one class — the simple "combined" example
    mappers/     #   Row -> Entity (int↔bool, epoch↔DateTime, text↔enum)
    repositories/#   basalt-backed implementations of the domain interfaces
  presentation/  # cubits + states + Flutter pages (catalogue, product detail, cart, orders, customers, analytics)
```

The **layers only depend inwards**: presentation → domain ← data. The presentation layer never imports
`basalt`; it talks to repository *interfaces* resolved from `get_it`. The mapper layer exists because SQLite
stores booleans as `0/1`, dates as epoch millis and enums as text — the generated `schema.dart` types those
as `int`/`String`, and the mappers turn them into rich domain types.

## Run it

```bash
cd example
flutter pub get

# (dev only) apply migrations to a throwaway example.db and regenerate the typed schema:
dart run basalt_cli:basalt migration run
dart run basalt_cli:basalt generate-schema          # -> lib/core/database/schema.dart

# generate the row readers / insert / changeset code:
dart run build_runner build

flutter run -d macos                                 # or your device of choice
```

On first launch the app opens a database in the app documents directory, applies the bundled migrations and
seeds demo data. Data persists across restarts; delete the app's `basalt_shop.db` to re-seed.

> This app is **not** a member of the root Dart pub workspace (Flutter apps can't be). It resolves on its own
> via `flutter pub get`, using `dependency_overrides` to point the `basalt` packages at their local paths.

## Tests

```bash
flutter test
```

`test/` runs the repository layer against an in-memory `SqliteConnection` (migrations applied from disk, then
seeded) — covering nested relations, aggregate ratings, and transactional order creation with stock
decrements.

## Notes

- SQLite comes from `sqlite3_flutter_libs` (native lib for macOS/iOS/Android). The primary target here is
  `-d macos`; Linux/Windows desktop would additionally need a system `sqlite3`.
- The "current shopper" for writing reviews and the checkout customer are chosen in-app for demo simplicity.
