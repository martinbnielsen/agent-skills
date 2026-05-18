# Oracle Forms → APEX Concept Mapping

This document maps every Oracle Forms construct to its nearest APEX/APEXlang equivalent. Use this alongside `xml-structure.md` when translating a parsed form into `.apx` artifacts.

---

## Block → APEX Page / Region

| Forms Block Characteristics                                | APEX Pattern                                          |
|------------------------------------------------------------|-------------------------------------------------------|
| Single-record, `DatabaseBlock=true`                        | Form page with a Static Content region containing `pageItem` fields + DML process |
| Multi-record (`RecordsDisplayCount > 1`)                   | Interactive Grid region or Classic Report + form      |
| Top-level master block                                     | Dedicated form page (e.g. `p00010-orders.apx`)        |
| Detail block with `<Relation>` linking it to master        | Sub-region on the same page (Interactive Grid)        |
| `DatabaseBlock="false"` (control block)                    | Buttons and UI controls only — no data region needed  |
| Toolbar canvas block                                       | Navigation bar actions or region header buttons       |

### Page layout strategy for master-detail

```
Page N  (Master Form)
  ├── Region: Master (Static Content) → pageItem fields for master block
  ├── Region: Detail (Interactive Grid) → detail block, filtered by master PK
  └── Buttons: Save, Delete, Cancel
```

For deeply nested (3-level) master-detail: use separate pages with parent PK passed as a URL parameter.

---

## Item Type → APEXlang `pageItem` Type

| Forms `ItemType`                    | Forms `DataType` | APEXlang `type`    | Notes                                        |
|-------------------------------------|------------------|--------------------|----------------------------------------------|
| `Text Item`                         | `VARCHAR2`       | `textField`        | Default text input                           |
| `Text Item`                         | `Number`         | `numberField`      | Set `virtualKeyboard: number`                |
| `Text Item`                         | `Date`           | `datePicker`       | Use `formatMask: DD-MON-YYYY` or project mask|
| `Text Item` + `DatabaseItem="false"` | any             | `displayOnly`      | Non-DB derived display                       |
| `Text Item` + read-only flags       | any              | `displayOnly`      | `InsertAllowed=false` + `UpdateAllowed=false` |
| `Display Item`                      | any              | `displayOnly`      | Always display-only                          |
| `Push Button`                       | —                | `button` (region button or page-level button) | Separate from `pageItem` |
| `Check Box`                         | `VARCHAR2`       | `checkbox`         | Map `CheckedValue`/`UncheckedValue`          |
| `Radio Group`                       | `VARCHAR2`       | `radioGroup`       | Each `<RadioButton>` → a static LOV entry   |
| `List Item`                         | any              | `selectList`       | Attach shared LOV                            |
| `Image`                             | —                | skip or `fileUpload` | Rarely migrated directly                  |

### APEXlang `pageItem` skeleton

```apx
pageItem P10_COLUMN_NAME (
    type: textField
    label {
        label: Prompt Text
        alignment: left
    }
    layout {
        sequence: 10
        region: @region-name
        slot: regionBody
        startNewRow: true
    }
    appearance {
        template: @/required      -- or @/optional
        templateOptions: #DEFAULT#
        width: 30
    }
    source {
        type: databaseColumn
        databaseColumn: COLUMN_NAME
        used: always
    }
    validation {
        notNull: true             -- if Required="true"
        maxLength: 25             -- from MaximumLength
    }
    default {
        type: static
        staticValue: DEFAULT_VALUE
    }
)
```

---

## Item Attribute Mapping

| Forms attribute                          | APEXlang equivalent                                  |
|------------------------------------------|------------------------------------------------------|
| `Prompt`                                 | `label { label: ... }`                               |
| `Required="true"`                        | `validation { notNull: true }` + template `@/required` |
| `MaximumLength`                          | `validation { maxLength: N }`                        |
| `ColumnName`                             | `source { databaseColumn: COLUMN_NAME }`             |
| `DatabaseItem="false"`                   | `source { type: plsqlExpression }` or omit source    |
| `InsertAllowed="false"` + `UpdateAllowed="false"` | `type: displayOnly`                       |
| `InsertAllowed="false"` only             | Custom process guards or `source { used: onCreateOnly }` |
| `Visible="false"`                        | `type: hidden`                                       |
| `InitializeValue="$$date$$"`            | `default { type: function; expression: SYSDATE }`   |
| `InitializeValue="CASH"`               | `default { type: static; staticValue: CASH }`        |
| `CopyValueFromItem="Block.Item"`         | `default { type: item; item: PNN_ITEM_NAME }` or computation |
| `Formula=":A.X * :A.Y"`                 | `source { type: plsqlExpression; plsqlExpression: :PNN_X * :PNN_Y }` |
| `SummaryFunction="Sum"` of `SummaryItemName` | SQL SUM() in Interactive Grid column formula    |
| `FormatMask="999,990.99"`               | `appearance { formatMask: 999G990D99 }` (Oracle NLS) |
| `LovName`                               | `lov { type: sharedComponent; lov: @lov-name }`      |
| `CheckedValue`/`UncheckedValue`         | `lov { type: static }` with two entries              |

---

## Button Mapping

Forms `Push Button` items become APEX buttons. Buttons in a block's canvas frame become region-level or page-level buttons.

```apx
button SAVE (
    label: Save
    layout {
        sequence: 10
        region: @region-name
        slot: regionBody
        alignment: left
    }
    appearance {
        template: @/hot
        templateOptions: #DEFAULT#
    }
    behavior {
        action: submit
        executeValidations: true
        requestValue: SAVE
    }
)
```

For toolbar buttons that navigate blocks: use Dynamic Actions with Execute JavaScript Code or Navigate to URL actions.

---

## Trigger → APEX Equivalent

### Validation Triggers

| Forms Trigger            | APEXlang validation                                 |
|--------------------------|-----------------------------------------------------|
| `WHEN-VALIDATE-ITEM`     | `validation` block on the `pageItem`                |
| `WHEN-VALIDATE-RECORD`   | Page-level `validation` block                       |

```apx
pageItem P10_CUSTOMER_ID (
    ...
    validation {
        notNull: true
    }
)

-- Or for complex PL/SQL validation:
validation CHECK_CUSTOMER (
    type: plsql
    expression:
        ```plsql
        -- converted trigger body here
        -- Replace :BLOCK.ITEM with :P10_ITEM
        -- Replace MESSAGE('...') with APEX_ERROR.ADD_ERROR(...)
        -- Replace RAISE FORM_TRIGGER_FAILURE with RETURN FALSE or error
        NULL; -- validation passes when no error is raised
        ```
    whenButtonPressed: @save
    associatedItems: P10_CUSTOMER_ID
    errorMessage: Invalid Customer Id!
)
```

### Process Triggers

| Forms Trigger       | APEXlang process                                              |
|---------------------|---------------------------------------------------------------|
| `PRE-INSERT`        | Before Submit process, conditioned on `REQUEST = 'CREATE'`   |
| `PRE-UPDATE`        | Before Submit process, conditioned on `REQUEST = 'SAVE'`     |
| `PRE-DELETE`        | Before Submit process, conditioned on `REQUEST = 'DELETE'`   |
| `POST-QUERY`        | Incorporate into region SQL as JOIN, or an After Refresh computation |
| `WHEN-CREATE-RECORD`| Item default value or Before Insert process                   |

```apx
process ASSIGN_ID (
    type: plsql
    sequence: 10
    source:
        ```plsql
        SELECT S_ORD_ID.nextval INTO :P10_ID FROM DUAL;
        ```
    when {
        button: CREATE
    }
    runPoint: beforeHeaderAndFooter
)
```

**Note on sequence assignment**: Modern Oracle (12c+) uses identity columns. If the target table already has an identity column, skip `PRE-INSERT` sequence triggers entirely.

### Dynamic Action Triggers

| Forms Trigger            | APEXlang dynamic action                                     |
|--------------------------|-------------------------------------------------------------|
| `WHEN-BUTTON-PRESSED`    | Dynamic Action on button `Click`                            |
| `WHEN-CHECKBOX-CHANGED`  | Dynamic Action on checkbox `Change`                         |
| `WHEN-RADIO-CHANGED`     | Dynamic Action on radio group `Change`                      |

```apx
dynamicAction ON_PAYMENT_TYPE_CHANGE (
    event: change
    items: P10_PAYMENT_TYPE
    true {
        action: execute
        plsql {
            code:
                ```plsql
                -- Converted WHEN-RADIO-CHANGED trigger body
                ```
        }
    }
)
```

### Navigation Triggers (do not migrate directly)

`ON-POPULATE-DETAILS`, `ON-CHECK-DELETE-MASTER`, `ON-CLEAR-DETAILS` are Forms boilerplate for master-detail coordination. **Skip these** — APEX handles master-detail refresh automatically via the Interactive Grid parent-item configuration.

`KEY-UP`, `KEY-DOWN`, `KEY-EXEQRY`, `KEY-ENTQRY` are navigation shortcuts — **skip** in APEX (built-in).

---

## Relation → APEX Master-Detail

### Interactive Grid approach (recommended)

In the detail Interactive Grid region:

```apx
region order-items (
    name: Order Items
    type: interactiveGrid
    source {
        sqlQuery:
            ```sql
            SELECT item_id, product_id, price, quantity, quantity_shipped
            FROM s_item
            WHERE ord_id = :P10_ID
            ORDER BY item_id
            ```
        primaryKeyColumnNames: [ITEM_ID]
        dmlTable: S_ITEM
    }
    layout {
        sequence: 20
        slot: body
    }
    ...
    columns {
        column ITEM_ID ( ... )
        column PRODUCT_ID ( ... )
        ...
    }
)
```

The master PK (`ORD_ID` in the detail table) is bound via `:P10_ID` (master form item). This replaces the Forms `<Relation>` + `ON-POPULATE-DETAILS` trigger.

### `DeleteRecord` mapping

| Forms `DeleteRecord` | APEX equivalent                                                    |
|----------------------|--------------------------------------------------------------------|
| `Non Isolated`       | DB foreign key constraint (raises error on master delete)          |
| `Cascading`          | `ON DELETE CASCADE` on FK, or before-delete process                |
| `Isolated`           | No constraint; detail rows remain (orphan records allowed)         |

---

## Alerts → APEX Confirmations

Forms `<Alert>` with `SHOW_ALERT('delete_alert')` maps to:

```apx
button DELETE (
    behavior {
        action: submit
        requestValue: DELETE
        confirmation: Do you want to delete this order?
    }
)
```

---

## PL/SQL Code Transformations

When converting trigger body PL/SQL, apply these systematic substitutions:

### Bind variable syntax
```
:BLOCK.ITEM         →  :PNN_ITEM_NAME
:S_ORD.customer_id  →  :P10_CUSTOMER_ID
:GLOBAL.variable    →  :APP_GLOBAL_ITEM  (app-level item)
:System.xxx         →  (remove; use APEX session context)
```

### Error handling
```
MESSAGE('text');                    →  apex_error.add_error(p_message => 'text', p_display_location => apex_error.c_inline_in_notification);
RAISE FORM_TRIGGER_FAILURE;         →  RAISE; -- after apex_error.add_error
Message('Invalid!'); RAISE ...      →  (combine into apex_error pattern)
```

### Commits
```
COMMIT_FORM;    →  (remove; APEX handles DML via Automatic Row Processing)
```

### Navigation
```
GO_BLOCK('block');   →  (remove or redirect page)
GO_ITEM('block.item'); →  (remove; client-side focus management if needed)
```

### SELECT INTO patterns
```
SELECT name INTO :BLOCK.field FROM table WHERE ...;
→  Move to POST-QUERY join in region SQL:
   SELECT t.*, ref.name AS derived_name FROM source_table t
   LEFT JOIN ref_table ref ON ref.id = t.fk_col
   WHERE ...
```

---

## Canvas Frame → APEX Region

Forms `<Graphics Name="..." GraphicsType="Frame" FrameTitle="Departments">` becomes an APEX region name.

```
FrameTitle="Departments"     →   region departments (name: Departments ...)
FrameTitle="Employees"       →   region employees (name: Employees ...)
LayoutDataBlockName="DEPT"   →   region contains items/grid from the DEPT block
```

---

## Navigation Menu

A Forms module typically has one window with multiple canvases (tabs or stacked). In APEX:
- Each logical section (canvas/frame) can be a separate region on the same page.
- Tabbed canvases → Tab regions or Tab container.
- Stacked canvases → Inline Dialog regions or Conditional Server-Side-Condition visibility.
- Multiple separate windows → Multiple APEX pages.

---

## LOV Migration

| Forms construct                         | APEX equivalent                                     |
|-----------------------------------------|-----------------------------------------------------|
| `<LOV>` with static values              | Shared LOV (static entries)                         |
| `<LOV>` backed by SQL record group      | Shared LOV with SQL query                           |
| `LovName` on an Item                    | `lov { type: sharedComponent; lov: @lov-name }`     |
| `<RadioButton>` entries in Radio Group  | `lov { type: static; entries: [...] }`              |
| `CheckedValue`/`UncheckedValue`         | Checkbox item with Y/N display (APEX native)        |

---

## Attached Libraries

| Forms library usage                      | APEX equivalent                                    |
|------------------------------------------|----------------------------------------------------|
| `CALENDAR` (date picker library)         | APEX native `datePicker` item type                 |
| Custom utility library procedures        | PL/SQL package in the database schema              |
| Menu generation libraries                | Navigation lists in APEX shared components         |
