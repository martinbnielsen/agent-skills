---
name: oracle-plsql
description: Use when writing, reviewing, or refactoring Oracle PL/SQL code — packages, procedures, functions, triggers, or SQL scripts. Applies Logger framework, Trivadis coding guidelines, and Steven Feuerstein best practices.
version: 1.0.0
---

# Oracle PL/SQL Development Skill

## General rules

- **All source code is lowercase** — identifiers, keywords, built-ins, everything.
- Use `%type` and `%rowtype` for variable declarations — never hardcode datatypes.
- No magic numbers. Declare named constants with `gc_` (package) or `c_` (local) prefix.
- No hardcoded schema names. Use synonyms or current-schema references.
- No `select *` in PL/SQL — always list columns explicitly.
- No implicit type conversions. Use explicit casts and ANSI date literals (`date '2024-01-31'`).
- Single responsibility per procedure or function.

---

## Naming conventions

| Prefix | Meaning | Example |
|--------|---------|---------|
| `l_` | local variable | `l_employee_id` |
| `g_` | package global variable | `g_config_loaded` |
| `p_` | parameter (any mode) | `p_customer_id` |
| `c_` | local constant | `c_max_retries` |
| `gc_` | package global constant | `gc_app_name` |
| `e_` | exception | `e_order_not_found` |
| `r_` | record variable | `r_employee` |
| `t_` | type definition | `t_id_list` |
| `cur_` | cursor | `cur_employees` |

Object naming:
- Packages: domain + `_pkg` → `order_mgmt_pkg`
- Procedures: verb + noun → `create_order`, `validate_customer`
- Functions: `get_` or `is_`/`has_` → `get_tax_rate`, `is_valid_email`
- Triggers: table + `_trg` → `employees_audit_trg`
- Sequences: table + `_seq` → `orders_seq`

---

## Package template

Every package body follows this structure:

```sql
create or replace package body order_mgmt_pkg
as

  gc_scope_prefix constant varchar2(31) := lower($$plsql_unit) || '.';

  -- private helpers above the procedures that call them

  procedure create_order(
    p_customer_id  in  orders.customer_id%type,
    p_order_date   in  orders.order_date%type,
    p_order_id     out orders.order_id%type)
  as
    l_scope   logger_logs.scope%type := gc_scope_prefix || 'create_order';
    l_params  logger.tab_param;
  begin
    logger.append_param(l_params, 'p_customer_id', p_customer_id);
    logger.append_param(l_params, 'p_order_date',  p_order_date);
    logger.log('start', l_scope, null, l_params);

    -- implementation

    logger.log('end', l_scope);
  exception
    when others then
      logger.log_error('unhandled exception', l_scope, null, l_params);
      raise;
  end create_order;

end order_mgmt_pkg;
```

Rules:
- `gc_scope_prefix` is always the first declaration in the package body.
- `l_scope` and `l_params` are declared in every procedure and function.
- All `logger` calls receive `l_scope`.
- The exception block always logs then re-raises — never swallow exceptions.

---

## Logger usage

### Scope pattern
```sql
gc_scope_prefix constant varchar2(31) := lower($$plsql_unit) || '.';
-- in each subprogram:
l_scope  logger_logs.scope%type := gc_scope_prefix || 'subprogram_name';
l_params logger.tab_param;
```

### Logging parameters
```sql
logger.append_param(l_params, 'p_customer_id', p_customer_id);
logger.append_param(l_params, 'p_status',       p_status);
logger.log('start', l_scope, null, l_params);
```

### Log level guide

| Call | When to use |
|------|-------------|
| `logger.log` | Debug output — developer info, state at key points (~90 % of calls) |
| `logger.log_information` | Milestones in long-running processes — start time, row counts, completion |
| `logger.log_warning` | Non-critical issue where a fallback was used; actionable but not an error |
| `logger.log_error` | In exception blocks — always stores callstack automatically |
| `logger.log_permanent` | Must-retain events (version upgrades, one-time migrations) |

### Exception block
```sql
exception
  when others then
    logger.log_error('unhandled exception', l_scope, null, l_params);
    raise;
```

---

## Error handling

- Named exceptions with `pragma exception_init` for Oracle errors:
  ```sql
  e_deadlock exception;
  pragma exception_init(e_deadlock, -60);
  ```
- Use `raise_application_error(-20001...-20999, message)` for business rule violations.
- Capture `sys.dbms_utility.format_error_backtrace` when not using Logger's `log_error`.
- Never: `when others then null` — this is the single most harmful PL/SQL pattern.
- Always re-raise after logging in a generic exception handler.
- Capture `sql%rowcount` immediately after DML — it is reset by subsequent statements.

---

## Package design (Feuerstein / Trivadis)

- The **package spec is the public API** — expose only what callers need.
- Put private declarations (types, constants, subprograms) in the body.
- Use forward declarations in the body to enable mutual recursion and logical ordering.
- Avoid package-level variables that hold session state — they break connection pooling.
- Use `accessible by` (12.2+) to restrict which units can call a package.
- Overload subprograms by parameter type when the intent is identical, not just for convenience.
- Keep procedures under ~60 lines of logic; split packages over ~1000 lines into sub-packages.

---

## Cursors

- Use cursor `for` loops for read-only iteration — Oracle opens, fetches, and closes automatically:
  ```sql
  for r_emp in (select employee_id, last_name from employees where department_id = p_dept_id)
  loop
    -- use r_emp.employee_id
  end loop;
  ```
- Use explicit cursors with `open`/`fetch`/`close` only when you need `%found`, `%notfound`, or parameterization across multiple fetches.
- Always close explicit cursors in the exception block if opened outside a `for` loop.
- Prefer `ref cursor` for dynamic result sets passed to the caller.

---

## Performance

- **No DML inside cursor loops.** Use `bulk collect` + `forall` instead:
  ```sql
  select order_id
  bulk collect into l_order_ids
  from orders
  where status = 'pending'
  limit 1000;

  forall i in 1..l_order_ids.count
    update orders set status = 'processed' where order_id = l_order_ids(i);
  ```
- Use `limit` with `bulk collect` — never collect an unbounded table into memory.
- Use `forall ... save exceptions` when partial failure must be handled gracefully.
- Use `nocopy` for large `in out` collection parameters.
- Consider `result_cache` for pure functions with stable reference data.
- Mark referentially transparent functions `deterministic`.

---

## Security

- Always use bind variables in dynamic SQL:
  ```sql
  execute immediate 'select count(*) from ' || sys.dbms_assert.sql_object_name(p_table_name)
    into l_count;
  ```
- Validate dynamic identifiers with `sys.dbms_assert`:
  - `dbms_assert.simple_sql_name` — single unquoted identifier
  - `dbms_assert.sql_object_name` — existing object in the database
  - `dbms_assert.schema_name` — existing schema
  - `dbms_assert.enquote_name` — double-quote and escape an identifier
- Do not expose schema internals in user-facing error messages.
- Use `authid current_user` for utility procedures that should run in the caller's schema.
- Default is `authid definer` — document the choice explicitly when it matters.

---

## Code quality checklist

Before finishing any PL/SQL unit verify:

- [ ] All identifiers follow naming prefix conventions
- [ ] `gc_scope_prefix`, `l_scope`, `l_params` declared; all logger calls include scope
- [ ] Every exception block logs with `logger.log_error` and re-raises
- [ ] No `when others then null`
- [ ] No `select *`
- [ ] No implicit conversions or NLS-dependent literals
- [ ] No DML inside loops — bulk operations used where applicable
- [ ] Dynamic SQL uses bind variables or `dbms_assert`-validated identifiers
- [ ] No magic numbers — named constants used
- [ ] Cyclomatic complexity ≤ 10 per subprogram
