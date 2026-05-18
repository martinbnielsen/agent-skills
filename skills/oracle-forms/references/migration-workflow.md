# Oracle Forms → APEX Migration Workflow

End-to-end process for reading an Oracle Forms XML export and generating APEXlang `.apx` files. Combine this with the `apex` skill for the actual `.apx` generation and validation.

---

## Phase 1 — Parse the Forms XML

### 1.1 Read the XML file

Read the `.xml` file (or the `_fmb.xml` export). Confirm the namespace: `xmlns="http://xmlns.oracle.com/Forms"`.

### 1.2 Extract the inventory

Build a working model from the XML. Record:

**Module info**
- `FormModule/@Name` — module name
- `FormModule/@Title` — display title

**Blocks** (for each `<Block>`)
- Name, `QueryDataSourceName`, `DMLDataName` (if set), `DatabaseBlock`, `RecordsDisplayCount`, `ShowScrollbar`, `OrderByClause`
- Whether it appears as `DetailBlock` in any `<Relation>`

**Items** (for each `<Item>` within each block)
- Name, `ItemType`, `DataType`, `ColumnName`, `Prompt`, `Required`, `MaximumLength`
- `DatabaseItem`, `InsertAllowed`, `UpdateAllowed`, `Visible`, `CopyValueFromItem`
- `InitializeValue`, `Formula`, `LovName`, `CheckedValue`, `UncheckedValue`, `Label`
- `CanvasName` (to group items onto the right region)

**Relations** (for each `<Relation>`)
- Name, `DetailBlock`, `JoinCondition`, `DeleteRecord`, `AutoQuery`, `Deferred`
- The containing block is the **master**

**Triggers** (for each `<Trigger>`)
- Name, `TriggerText` (decode XML entities first: `&amp;#10;` → newline, `&lt;` → `<`, `&amp;` → `&`)
- Whether it is at module level, block level, or item level

**Canvases / Frames** (for each `<Canvas>` and `<Graphics GraphicsType="Frame">`)
- Canvas name, frame title (`FrameTitle`), `LayoutDataBlockName`

### 1.3 Identify block roles

Apply these rules to classify each block:

| Condition                                             | Role           |
|-------------------------------------------------------|----------------|
| `DatabaseBlock="false"`                               | Control block  |
| Is `DetailBlock` in a `<Relation>`                    | Detail block   |
| Has a `<Relation>` child pointing to another block    | Master block   |
| Neither master nor detail, single-record              | Standalone form|
| `RecordsDisplayCount > 1`                             | Tabular block  |

### 1.4 Decode and review triggers

Decode each `TriggerText`. Classify as:
- **Skip** (Forms boilerplate): `ON-POPULATE-DETAILS`, `ON-CHECK-DELETE-MASTER`, `ON-CLEAR-DETAILS`, `KEY-UP`, `KEY-DOWN`, `KEY-EXEQRY`, `KEY-ENTQRY`, `KEY-OTHERS`
- **Migrate as process**: `PRE-INSERT`, `PRE-UPDATE`, `PRE-DELETE`
- **Migrate as validation**: `WHEN-VALIDATE-ITEM`, `WHEN-VALIDATE-RECORD`
- **Migrate as dynamic action**: `WHEN-BUTTON-PRESSED`, `WHEN-CHECKBOX-CHANGED`, `WHEN-RADIO-CHANGED`
- **Incorporate into SQL**: `POST-QUERY` (often a lookup join), `PRE-QUERY` (default filter)
- **Convert to item default**: `WHEN-CREATE-RECORD`

---

## Phase 2 — Plan the APEX Application Structure

### 2.1 Determine the page map

Use this heuristic to decide which blocks become which pages:

```
For each top-level standalone or master block B:
  - Create a List page  (Interactive Report on QueryDataSourceName)
  - Create a Detail page (form with pageItems + DML process)
    - If B has detail blocks via <Relation>:
        Add an Interactive Grid sub-region on the Detail page
        for each immediate detail block

For deeply nested (>2 level) hierarchies:
  - Use separate pages linked by parent PK URL parameter
```

#### Suggested page numbering convention

| Page | Purpose                        | Example                   |
|------|--------------------------------|---------------------------|
| 1    | Home / Dashboard               | `p00001-home.apx`         |
| 10   | Master list (report)           | `p00010-orders.apx`       |
| 11   | Master detail (form)           | `p00011-order-detail.apx` |
| 20   | Second entity list             | `p00020-customers.apx`    |
| 21   | Second entity detail           | `p00021-customer-detail.apx` |

### 2.2 Map items to page item names

APEX page item names follow `PNN_COLUMN_NAME` where `NN` = page number, `COLUMN_NAME` = the Forms `ColumnName` (or `Name` if `ColumnName` is absent).

```
Block DEPT, Page 11
  Item NAME  (ColumnName: NAME)   →  P11_NAME
  Item ID    (ColumnName: ID)     →  P11_ID (hidden primary key)
  Item REGION_ID                  →  P11_REGION_ID
```

For detail block items in an Interactive Grid, column names are used directly (no `PNN_` prefix; the grid handles row context).

### 2.3 Identify regions from canvas frames

Each `<Graphics GraphicsType="Frame">` with a `FrameTitle` and `LayoutDataBlockName` maps to one APEX region:

```
Frame "Departments" (LayoutDataBlockName="DEPT")  →  region departments (name: Departments)
Frame "Employees"   (LayoutDataBlockName="EMP")   →  region employees   (name: Employees, type: interactiveGrid)
```

---

## Phase 3 — Generate APEXlang Artifacts

Work file-by-file. Use the `apex` skill to validate syntax while writing.

### 3.1 `application.apx`

```apx
app MODULE_NAME (
    name: Module Title
    version: 26.1.0
    authentication {
        scheme: @apex-accounts
    }
    -- add navigation, theme, etc. from project conventions
)
```

### 3.2 List page (`p000NN-{entity}-list.apx`)

```apx
page NN (
    name: Entity List
    alias: ENTITY-LIST

    region breadcrumbs ( ... )

    region entity-list (
        name: Entity List
        type: interactiveReport
        source {
            sqlQuery:
                ```sql
                SELECT id, column1, column2
                FROM source_table
                ORDER BY column1
                ```
        }
        layout {
            sequence: 10
            slot: body
        }
        ...
        columns {
            column ID (
                type: hidden
            )
            column COLUMN1 (
                label: Column 1 Label
                link {
                    url: f?p=&APP_ID.:NN+1:&SESSION.::&DEBUG.::P{NN+1}_ID:\#ID#\
                }
            )
        }
    )

    button CREATE (
        label: Create
        layout {
            sequence: 10
            region: @entity-list
            slot: rightOfSearchBar
        }
        behavior {
            action: redirect
            url: f?p=&APP_ID.:NN+1:&SESSION.::&DEBUG.::P{NN+1}_ID:\
        }
    )
)
```

### 3.3 Form page (`p000NN-{entity}-detail.apx`)

```apx
page NN (
    name: Entity Detail
    alias: ENTITY-DETAIL

    region breadcrumbs ( ... )

    region entity-details (
        name: Entity Details
        type: staticContent
        layout {
            sequence: 10
            slot: body
        }
        appearance {
            template: @/standard
            templateOptions: [#DEFAULT# t-Region--scrollBody t-Form--stretchInputs]
        }
    )

    -- Hidden primary key
    pageItem PNN_ID (
        type: hidden
        source {
            type: databaseColumn
            databaseColumn: ID
            used: always
        }
        security {
            sessionStateProtection: checksumRequiredSessionLevel
        }
    )

    -- One pageItem per mapped Forms item
    pageItem PNN_COLUMN_NAME (
        type: textField           -- from ItemType mapping
        label {
            label: Prompt Text    -- from Forms Prompt attribute
            alignment: left
        }
        layout {
            sequence: 10
            region: @entity-details
            slot: regionBody
            startNewRow: true
        }
        appearance {
            template: @/required  -- required or optional based on Required="true"
            templateOptions: #DEFAULT#
            width: 30
        }
        validation {
            notNull: true         -- if Required="true"
            maxLength: 25         -- from MaximumLength
        }
        source {
            type: databaseColumn
            databaseColumn: COLUMN_NAME
            used: always
        }
    )

    -- If block has detail: add Interactive Grid for each detail block
    region detail-block-items (
        name: Detail Items
        type: interactiveGrid
        source {
            sqlQuery:
                ```sql
                SELECT fk_col, col1, col2
                FROM detail_table
                WHERE master_fk = :PNN_MASTER_ID
                ORDER BY col1
                ```
            primaryKeyColumnNames: [FK_COL, COL1]
            dmlTable: DETAIL_TABLE
        }
        layout {
            sequence: 20
            slot: body
        }
    )

    -- Automatic Row Processing (DML)
    process SAVE_ENTITY (
        type: dmlFromPageItems
        source {
            table: SOURCE_TABLE
            primaryKeyItems: [PNN_ID]
        }
        when {
            button: [SAVE, CREATE]
        }
        runPoint: afterSubmit
    )

    process DELETE_ENTITY (
        type: dmlFromPageItems
        source {
            table: SOURCE_TABLE
            primaryKeyItems: [PNN_ID]
        }
        when {
            button: DELETE
        }
        runPoint: afterSubmit
    )

    -- Buttons
    button SAVE ( ... )
    button CREATE ( ... )
    button DELETE (
        behavior {
            action: submit
            requestValue: DELETE
            confirmation: Do you want to delete this record?
        }
    )
    button CANCEL (
        behavior {
            action: redirect
            url: f?p=&APP_ID.:NN-1:&SESSION.:::
        }
    )
)
```

### 3.4 Converted processes (from PRE-INSERT triggers)

```apx
process ASSIGN_PK (
    type: plsql
    sequence: 5
    source:
        ```plsql
        -- Converted PRE-INSERT trigger body
        -- Replace :BLOCK.ITEM with :PNN_ITEM
        -- Remove RAISE FORM_TRIGGER_FAILURE; use APEX error API if needed
        SELECT sequence_name.nextval INTO :PNN_ID FROM DUAL;
        ```
    when {
        button: CREATE
    }
    runPoint: afterSubmit
)
```

### 3.5 Converted validations (from WHEN-VALIDATE-ITEM triggers)

```apx
validation CHECK_CUSTOMER_ID (
    type: plsql
    sequence: 10
    expression:
        ```plsql
        -- Return TRUE if valid, FALSE if invalid
        -- Or raise an exception with apex_error.add_error
        DECLARE
          l_count NUMBER;
        BEGIN
          SELECT COUNT(1) INTO l_count
          FROM s_customer
          WHERE id = :P10_CUSTOMER_ID;
          RETURN l_count > 0;
        END;
        ```
    errorMessage: Invalid Customer Id!
    associatedItems: P10_CUSTOMER_ID
    whenButtonPressed: @save
)
```

### 3.6 Converted dynamic actions (from WHEN-BUTTON-PRESSED triggers)

```apx
dynamicAction ON_STOCK_BUTTON_CLICK (
    event: click
    items: STOCK_BUTTON        -- or button: @stock-button
    true {
        action: submit
        requestValue: GO_INVENTORY
    }
)
```

For complex trigger PL/SQL that cannot be simplified: use `action: executePlsql` in the dynamic action's true branch.

---

## Phase 4 — Review and Validate

### 4.1 Completeness checklist

- [ ] Every block with `DatabaseBlock != false` has a corresponding APEX region or page
- [ ] Every `Required="true"` item has `notNull: true` in its `pageItem` validation block
- [ ] Every `<Relation>` is represented by an Interactive Grid with a `:PNN_MASTER_PK` bind variable in the WHERE clause
- [ ] `PRE-INSERT` sequence triggers are either migrated or confirmed unnecessary (identity column exists)
- [ ] `POST-QUERY` lookup joins are folded into the region SQL query
- [ ] Every `WHEN-BUTTON-PRESSED` trigger is represented by a Dynamic Action or process
- [ ] `WHEN-VALIDATE-ITEM` and `WHEN-VALIDATE-RECORD` triggers are represented as validations
- [ ] Boilerplate triggers (`ON-POPULATE-DETAILS`, `ON-CHECK-DELETE-MASTER`, etc.) are intentionally skipped
- [ ] Items with `CopyValueFromItem` are given a `default` or are pre-populated via URL parameter
- [ ] Items with `Visible="false"` are typed `hidden` in APEX
- [ ] Primary key items have `sessionStateProtection: checksumRequiredSessionLevel`

### 4.2 PL/SQL bind variable audit

Before finalising any converted PL/SQL, confirm that every `:BLOCK.ITEM` reference has been rewritten to `:PNN_ITEM_NAME` using the page-item name mapping built in Phase 2.2.

### 4.3 Validate with the `apex` skill

Hand the generated `.apx` files to the `apex` skill for APEXlang compiler validation:
```
apex validate -input <file.apx>
```

Fix any `INVALID_PROPERTY`, `MISSING_REQUIRED_PROPERTY`, or `MINIMUM_COMPONENTS_ERROR` errors before import.

---

## Common Pitfalls

| Pitfall                                | Resolution                                               |
|----------------------------------------|----------------------------------------------------------|
| Forgetting to decode `&amp;#10;` in trigger text | Always decode before reading PL/SQL         |
| Migrating boilerplate relation triggers | Skip `ON-POPULATE-DETAILS` and similar; APEX is automatic |
| Using `:BLOCK.ITEM` syntax in APEX PL/SQL | Rewrite all binds to `:PNN_ITEM_NAME`                  |
| Assuming Forms sequence triggers are needed | Check for identity columns first                    |
| Putting control block items as `pageItem` with DB source | Control blocks have no DB source; use `type: hidden` or buttons |
| Missing `primaryKeyColumnNames` on Interactive Grid | Causes DML to fail; always specify the PK          |
| Hardcoding `f?p=` URLs with wrong page numbers | Derive page numbers from the planned page map        |
