---
name: db-data-dictionary
description: Generate or refresh a project-root DATABASE.md data dictionary for an Oracle schema using the SQLcl MCP server and APEX_DB_DICTIONARY.GET_METADATA/FORMAT_METADATA. Use when the user asks to dump, document, refresh, update, or regenerate the database datamodel, data model, schema dictionary, table/view metadata, or DATABASE.md from a named SQLcl saved connection.
---

# DB Data Dictionary

Create `DATABASE.md` in the project root with detailed Markdown metadata for every table and view in the connected schema.

## Workflow

1. Identify the SQLcl saved connection name from the user prompt.
   - If the prompt does not specify one, call `mcp__sqlcl.connections_list` and ask the user which saved connection to use.
   - Connection names are case-sensitive. Do not infer credentials or schema from the connection name.
2. Connect with `mcp__sqlcl.connect`.
3. Immediately call `mcp__sqlcl.schema_information` with `level: "BRIEF"` as required by the SQLcl MCP server. Use this only as connection context, not as the source for `DATABASE.md`.
4. Resolve the project root:
   - Prefer `git rev-parse --show-toplevel`.
   - If not in a Git repo, use the current working directory.
5. Resolve the schema:
   - If the prompt names a schema, use that exact schema name after validating it exists.
   - Otherwise use `sys_context('USERENV','CURRENT_SCHEMA')` from the connected session.
6. Generate Markdown with `APEX_DB_DICTIONARY.GET_METADATA` and `APEX_DB_DICTIONARY.FORMAT_METADATA`.
7. Write the result to `<project-root>/DATABASE.md`.
   - Create the file if it does not exist.
   - If it already exists, overwrite only when the user asked to refresh/regenerate/update the datamodel or `DATABASE.md`. Otherwise ask before overwriting.
8. Verify that the number of documented objects matches the number of tables/views discovered.

## Object Discovery

Use `mcp__sqlcl.sql_run` for SQL. First resolve the schema:

```sql
select sys_context('USERENV','CURRENT_SCHEMA') as schema_name
from dual
```

If the user provided a schema, validate it before using it:

```sql
select sys.dbms_assert.schema_name('<SCHEMA_NAME>') as schema_name
from dual
```

List tables and views from the validated schema:

```sql
select object_type, object_name
from (
  select 'TABLE' as object_type, table_name as object_name
  from all_tables
  where owner = '<SCHEMA_NAME>'
    and nested = 'NO'
    and secondary = 'N'
    and dropped = 'NO'
  union all
  select 'VIEW' as object_type, view_name as object_name
  from all_views
  where owner = '<SCHEMA_NAME>'
)
order by case object_type when 'TABLE' then 1 else 2 end, object_name
```

Use the exact `object_name` and `object_type` values returned by this query for metadata calls.

## Metadata Query

For each table or view, call:

```sql
select apex_db_dictionary.format_metadata(
         p_json => apex_db_dictionary.get_metadata(
                     p_name        => '<OBJECT_NAME>',
                     p_schema      => '<SCHEMA_NAME>',
                     p_object_type => '<OBJECT_TYPE>',
                     p_level       => 'ALL'),
         p_include_constraints     => true,
         p_include_indexes         => true,
         p_include_comments        => true,
         p_include_annotations     => true,
         p_include_domains         => true,
         p_include_virtual_columns => true
       ) as metadata_markdown
from dual
```

Do not pass `apex_db_dictionary.c_markdown` from plain SQL; some databases expose the default Markdown format but not the package constant in SQL. Omitting `p_format` uses Markdown.

If the JSON overload is not selected correctly on Oracle Database 21c or later, use this CLOB fallback:

```sql
select apex_db_dictionary.format_metadata(
         p_json => json_serialize(
                     apex_db_dictionary.get_metadata(
                       p_name        => '<OBJECT_NAME>',
                       p_schema      => '<SCHEMA_NAME>',
                       p_object_type => '<OBJECT_TYPE>',
                       p_level       => 'ALL') returning clob),
         p_include_constraints     => true,
         p_include_indexes         => true,
         p_include_comments        => true,
         p_include_annotations     => true,
         p_include_domains         => true,
         p_include_virtual_columns => true
       ) as metadata_markdown
from dual
```

## DATABASE.md Format

Assemble the file locally from the MCP query results. Do not try to make the database write files.

Use this structure:

```markdown
# Database Data Dictionary

- Connection: <connection-name>
- Schema: <schema-name>
- Generated: <local timestamp with timezone>
- Source: APEX_DB_DICTIONARY.GET_METADATA p_level ALL formatted with APEX_DB_DICTIONARY.FORMAT_METADATA
- Objects: <n> tables, <n> views

## Object Index

| Type | Name |
|---|---|
| TABLE | CUSTOMERS |
| VIEW | CUSTOMER_ORDER_PRODUCTS |

## Tables

---

<formatted metadata for each table>

## Views

---

<formatted metadata for each view>
```

Preserve the formatted metadata content returned by `FORMAT_METADATA`. Add separators between objects if the returned Markdown does not already separate them clearly.

## Large Schemas

If the MCP response is truncated or the schema is large:

- Fetch metadata one object at a time or in small batches.
- Append each object's formatted Markdown locally in object-list order.
- Keep an in-memory checklist of completed object names.
- Continue until every discovered table and view is represented in `DATABASE.md`.

## Failure Handling

- If `APEX_DB_DICTIONARY` is missing or invalid, report that the database/APEX installation does not support the requested API and stop. Do not silently substitute a hand-written data dictionary query unless the user approves.
- If a metadata call fails for one object, include a short failure section for that object in `DATABASE.md`, continue with the remaining objects, and tell the user which objects failed.
- If the connected user cannot see the requested schema, ask for a connection or schema with the required privileges.

## Validation

Before finishing:

1. Count discovered objects from the object discovery query.
2. Count documented object headings in `DATABASE.md`.
3. Confirm `DATABASE.md` is in the project root.
4. Report the connection, schema, table count, view count, output path, and any failed objects.

Reference: Oracle APEX 26.1 `APEX_DB_DICTIONARY.GET_METADATA` and `FORMAT_METADATA`.
