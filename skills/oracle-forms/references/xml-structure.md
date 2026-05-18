# Oracle Forms XML Structure Reference

Oracle Forms modules exported to XML use the namespace `xmlns="http://xmlns.oracle.com/Forms"`. The root is `<Module>` and the primary child is `<FormModule>`.

---

## Root Elements

### `<Module>`
Outermost wrapper. Attributes: `version` (format version number).

### `<FormModule>`
The form itself. Key attributes:

| Attribute       | Meaning                                   |
|-----------------|-------------------------------------------|
| `Name`          | Internal module name (e.g. `CU_CUSTOMERS`) |
| `Title`         | Window title shown to users               |
| `MenuModule`    | Attached menu module name                 |
| `ConsoleWindow` | Name of the console/main window           |

---

## Layout Elements

### `<Coordinate>`
Defines coordinate system for position/size values.

| Attribute              | Meaning                                      |
|------------------------|----------------------------------------------|
| `CoordinateSystem`     | `Real` (points) or `Character`               |
| `RealUnit`             | `Point` or `Centimeter`                      |
| `CharacterCellWidth`   | Width of one character cell in real units    |
| `CharacterCellHeight`  | Height of one character cell in real units   |

### `<Window>`
A window frame. Attributes: `Name`, `Width`, `Height`.

### `<Canvas>`
A layout surface that items are placed on. Key attributes:

| Attribute        | Meaning                                                      |
|------------------|--------------------------------------------------------------|
| `Name`           | Canvas identifier                                            |
| `CanvasType`     | `Content` (main), `Tabbed`, `Stacked`, `Toolbar`            |
| `Width`/`Height` | Canvas dimensions                                            |
| `ViewportWidth`/`ViewportHeight` | Visible portion                              |

### `<Graphics>`
A visual decoration element (frames, labels). Key attributes:

| Attribute            | Meaning                                              |
|----------------------|------------------------------------------------------|
| `Name`               | Element name                                         |
| `GraphicsType`       | `Frame` (a labeled box), `Rectangle`, `Line`, `Text` |
| `FrameTitle`         | Label shown on a `Frame` — maps to APEX region title |
| `LayoutDataBlockName`| The block this frame visually groups                  |

---

## Data Block Elements

### `<Block>`
The central data unit. Each block maps to one table/view. Key attributes:

| Attribute                | Meaning                                                          |
|--------------------------|------------------------------------------------------------------|
| `Name`                   | Block identifier (used in `:BLOCK.ITEM` syntax)                  |
| `QueryDataSourceName`    | Table or view used for SELECT                                     |
| `DMLDataName`            | Table used for INSERT/UPDATE/DELETE (if different from query)    |
| `DatabaseBlock`          | `false` = control block (no DB), default `true`                  |
| `RecordsDisplayCount`    | Number of rows shown at once; `> 1` means tabular/multi-row      |
| `ShowScrollbar`          | `true` if a scrollbar is shown (confirms multi-row)              |
| `OrderByClause`          | SQL ORDER BY clause for the block query                          |
| `NavigationStyle`        | `Change Record` (tabular navigation style)                       |
| `QueryAllRecords`        | `true` = fetch all rows at once                                  |
| `InsertAllowed`/`UpdateAllowed`/`DeleteAllowed` | Block-level DML permission flags         |
| `QueryAllowed`           | `false` = block cannot be queried                                |

#### Block classification rules
- `DatabaseBlock="false"` → **Control block**: holds buttons/UI controls only; no direct DB counterpart.
- `RecordsDisplayCount > 1` → **Tabular block**: renders as a grid/repeating rows.
- `RecordsDisplayCount = 1` (default) → **Single-record block**: renders as a standard form.
- A block with a `<Relation>` naming it as `DetailBlock` → **Detail block** in a master-detail pair.

---

### `<DataSourceColumn>`
Declares a column that the block queries. Typically mirrors the `<Item>` column definitions.

| Attribute      | Meaning                                    |
|----------------|--------------------------------------------|
| `DSCName`      | Column name in the database                |
| `DSCType`      | SQL type: `NUMBER`, `VARCHAR2`, `DATE`     |
| `DSCLength`    | Max character length (for VARCHAR2)        |
| `DSCPrecision` | Numeric precision                          |
| `DSCScale`     | Numeric scale                              |
| `DSCMandatory` | `true` if NOT NULL at the DB level         |

---

### `<Item>`
A field or widget inside a block. Key attributes:

#### Identity & Binding
| Attribute          | Meaning                                                          |
|--------------------|------------------------------------------------------------------|
| `Name`             | Item name (used as `:BLOCK.ITEM`)                                |
| `ColumnName`       | Database column this item binds to                               |
| `ItemType`         | See **Item Types** below                                         |
| `DataType`         | `Number`, `Date`, `VARCHAR2` (default if omitted)               |
| `MaximumLength`    | Maximum input length                                             |

#### Behavior
| Attribute           | Meaning                                                         |
|---------------------|-----------------------------------------------------------------|
| `Required`          | `true` = NOT NULL enforced at the form level                    |
| `DatabaseItem`      | `false` = not a DB column (derived, display-only)               |
| `InsertAllowed`     | `false` = field cannot be inserted                              |
| `UpdateAllowed`     | `false` = field cannot be updated (read-only after insert)      |
| `QueryAllowed`      | `false` = field is not included in query WHERE                  |
| `KeyboardNavigable` | `false` = not reachable by Tab (display only)                   |

#### Display
| Attribute              | Meaning                                             |
|------------------------|-----------------------------------------------------|
| `Prompt`               | Label shown to the user                             |
| `XPosition`/`YPosition`| Layout position (points from canvas origin)        |
| `Width`/`Height`       | Size of the item                                    |
| `PromptAttachmentEdge` | Where the label is: `Top`, `Start`, `End`           |
| `Justification`        | Text alignment: `Start`, `Center`, `End`, `Right`  |
| `FormatMask`           | Oracle format mask (e.g. `999,990.99` for numbers)  |
| `Visible`              | `false` = item is hidden                            |

#### Default & Derived Values
| Attribute              | Meaning                                             |
|------------------------|-----------------------------------------------------|
| `InitializeValue`      | Default value; `$$date$$` means SYSDATE             |
| `CopyValueFromItem`    | Populates from `Block.Item` of a parent block       |
| `Formula`              | Calculated expression: `:Block.Item1 * :Block.Item2`|
| `CalculateMode`        | `Formula` or `Summary`                              |
| `SummaryFunction`      | `Sum`, `Count`, `Avg`, etc.                         |
| `SummaryItemName`      | Source item for summary                             |
| `SummaryBlockName`     | Source block for summary                            |

#### LOV & Special
| Attribute            | Meaning                                               |
|----------------------|-------------------------------------------------------|
| `LovName`            | Attached List of Values name                          |
| `CheckedValue`       | Value stored when checkbox is checked                 |
| `UncheckedValue`     | Value stored when checkbox is unchecked               |
| `Label`              | Button label or checkbox label                        |
| `AccessKey`          | Keyboard shortcut letter                              |
| `Iconic`             | `true` = icon-only button                             |
| `IconFilename`       | Icon file for iconic buttons                          |

---

#### Item Types

| `ItemType` value   | Forms widget                            | Notes                                    |
|--------------------|-----------------------------------------|------------------------------------------|
| `Text Item`        | Text input                              | Default; type varies by `DataType`       |
| `Display Item`     | Read-only text display                  | Always `DatabaseItem="false"`            |
| `Push Button`      | Clickable button                        | Has `WHEN-BUTTON-PRESSED` trigger        |
| `Check Box`        | Boolean checkbox                        | Uses `CheckedValue`/`UncheckedValue`     |
| `Radio Group`      | Group of radio buttons                  | Contains `<RadioButton>` children        |
| `Image`            | Image display area                      | Rarely migrated directly                 |
| `List Item`        | Drop-down or combo box                  | Backed by an LOV                         |

---

### `<RadioButton>`
A single option within a `Radio Group` item. Key attributes:

| Attribute          | Meaning                             |
|--------------------|-------------------------------------|
| `Name`             | Button identifier                   |
| `Label`            | Display text                        |
| `RadioButtonValue` | Value stored when this button is selected |

---

## Relationships

### `<Relation>`
Defines a master-detail link between two blocks. Always a child of the **master** block.

| Attribute                    | Meaning                                                    |
|------------------------------|------------------------------------------------------------|
| `Name`                       | Relation identifier                                        |
| `DetailBlock`                | Name of the child/detail block                             |
| `JoinCondition`              | Link condition: `Detail.FK_COL = Master.PK_COL`            |
| `DeleteRecord`               | `Non Isolated` (prevent orphan delete), `Isolated`, `Cascading` |
| `AutoQuery`                  | `true` = detail queries automatically when master changes  |
| `Deferred`                   | `true` = delay coordination until user navigates           |
| `PreventMasterlessOperations`| `true` = detail cannot insert without a master record      |

**Reading the JoinCondition**: The condition uses block aliases or block names. Example:  
`EMP.DEPT_ID = DEPT.ID` means the `EMP` block's `DEPT_ID` column equals the `DEPT` block's `ID` column.  
`Items.ORD_ID = Orders.ID` means the `S_ITEM` block (aliased "Items") FK links to the `S_ORD` block (aliased "Orders") PK.

---

## PL/SQL Elements

### `<Trigger>`
Inline PL/SQL attached to a block, item, or form module.

| Attribute        | Meaning                                                    |
|------------------|------------------------------------------------------------|
| `Name`           | Trigger type (see table below)                             |
| `TriggerText`    | PL/SQL body, XML-encoded: `&amp;#10;` = newline, `&lt;` = `<`, `&amp;` = `&` |
| `ExecuteHierarchy` | `After` = run after inherited trigger                    |
| `FireInQuery`    | `false` = skip trigger when in ENTER_QUERY mode            |

#### Common Trigger Names

| Trigger Name             | When it fires                            | APEX equivalent                              |
|--------------------------|------------------------------------------|----------------------------------------------|
| `WHEN-BUTTON-PRESSED`    | Button click                             | Dynamic Action on button Click               |
| `WHEN-VALIDATE-ITEM`     | After user leaves an item                | Item Validation (PL/SQL)                     |
| `WHEN-VALIDATE-RECORD`   | Before block record is saved             | Page-level Validation                        |
| `WHEN-CHECKBOX-CHANGED`  | Checkbox toggled                         | Dynamic Action on checkbox Change            |
| `WHEN-RADIO-CHANGED`     | Radio group selection changes            | Dynamic Action on radio group Change         |
| `WHEN-NEW-RECORD-INSTANCE` | New record navigation               | Before Header / After Refresh process        |
| `WHEN-CREATE-RECORD`     | New record created                       | Before Insert process or item Default        |
| `PRE-QUERY`              | Before a query executes                  | WHERE condition in region SQL / filter       |
| `POST-QUERY`             | After each row is fetched                | SQL join in region query or computation      |
| `PRE-INSERT`             | Before a row is inserted                 | Before Submit process (PL/SQL)               |
| `PRE-UPDATE`             | Before a row is updated                  | Before Submit process (PL/SQL)               |
| `PRE-DELETE`             | Before a row is deleted                  | Before Submit process (PL/SQL)               |
| `KEY-COMMIT`             | Commit/save action                       | Standard APEX submit (built-in)              |
| `KEY-DELREC`             | Delete record action                     | Delete button + Confirmation dialog          |
| `KEY-DUPREC`             | Duplicate record action                  | Rarely needed; custom process if required    |
| `KEY-EXEQRY`             | Execute Query action                     | Built-in APEX report refresh                 |
| `KEY-ENTQRY`             | Enter Query mode action                  | Built-in APEX search/filter                  |
| `KEY-UP`/`KEY-DOWN`      | Navigate previous/next record            | Built-in APEX pagination                     |
| `ON-POPULATE-DETAILS`    | Propagate master changes to detail       | Handled by APEX master-detail automatically  |
| `ON-CHECK-DELETE-MASTER` | Prevent master delete when detail exists | DB-level FK constraint or before-delete process |
| `ON-CLEAR-DETAILS`       | Clear detail when master changes         | Handled by APEX master-detail automatically  |

### `<ProgramUnit>`
A module-level PL/SQL procedure or function.

| Attribute          | Meaning                                         |
|--------------------|-------------------------------------------------|
| `Name`             | Procedure/function name                         |
| `ProgramUnitType`  | `Procedure`, `Function`, `Package`, `PackageBody` |
| `ProgramUnitText`  | PL/SQL source, XML-encoded                      |

Common generated program units (`CHECK_PACKAGE_FAILURE`, `QUERY_MASTER_DETAILS`, `CLEAR_ALL_MASTER_DETAILS`) are Forms relation-management boilerplate — **do not migrate these**; APEX handles master-detail coordination natively.

---

## Supporting Elements

### `<Alert>`
A modal dialog definition.

| Attribute        | Meaning                              |
|------------------|--------------------------------------|
| `Name`           | Alert identifier (used in SHOW_ALERT) |
| `AlertMessage`   | Static alert text                    |
| `AlertStyle`     | `Stop`, `Caution`, `Note`            |
| `Button1Label`   | Primary button text (usually "Yes")  |
| `Button2Label`   | Secondary button text (usually "No") |
| `Title`          | Alert window title                   |

### `<LOV>`
A List of Values definition. References a record group or static list used to populate List Item items. Migrate as a Shared LOV in APEX.

### `<AttachedLibrary>`
A Forms PL/SQL library attached to the module. Usually contains shared utilities (e.g. `calendar`). These do not migrate directly; identify which functionality is used in triggers and re-implement in APEX processes or plug-ins.

---

## Decoding Trigger Text

`TriggerText` values are XML-encoded. When reading them, apply these substitutions:

| XML encoding   | Actual character |
|----------------|-----------------|
| `&amp;#10;`    | newline (`\n`)  |
| `&amp;`        | `&`             |
| `&lt;`         | `<`             |
| `&gt;`         | `>`             |
| `&quot;`       | `"`             |

PL/SQL bind variables use the `:BLOCK.ITEM` syntax (e.g. `:S_ORD.CUSTOMER_ID`). In APEX these become `:PNN_ITEM_NAME` where `PNN` is the page number and `ITEM_NAME` is the derived item name.
