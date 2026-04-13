---
description: Create, explain, refine, or debug Lightning Web Components
argument-hint: "[--new | --explain | --refine | --bug-fix] [componentName or path]"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash]
---

# /lwc

Work with Salesforce Lightning Web Components using `--new`, `--explain`, `--refine`, or `--bug-fix`.

## Usage

```
/lwc --new          Create a new LWC component with Apex controller and tests
/lwc --explain      Explain what an existing LWC component does
/lwc --refine       Modify an existing LWC component
/lwc --bug-fix      Diagnose and fix a bug in an LWC component
```

---

## --new: Create a New LWC Component

### Gather Requirements
Ask the user:
1. Component name (camelCase, e.g., `accountSummaryCard`)
2. Purpose and what it displays/does
3. Where is it placed? (App Page, Record Page, Home Page, utility bar, flow screen)
4. Does it need Apex data? (which object, which fields)
5. Any parent/child component interactions? (`@api` properties, custom events)
6. Navigation, toast notifications, or Lightning Message Service?

### LWC Standards (baked in)

**File Structure:**
```
force-app/main/default/lwc/accountSummaryCard/
├── accountSummaryCard.html          — template
├── accountSummaryCard.js            — controller
├── accountSummaryCard.js-meta.xml   — metadata (targets, supported contexts)
└── accountSummaryCard.css           — styles (optional)
```

**Component Template Pattern:**
```html
<!-- accountSummaryCard.html -->
<template>
    <!-- Loading state -->
    <template if:true={isLoading}>
        <lightning-spinner alternative-text="Loading" size="small"></lightning-spinner>
    </template>

    <!-- Error state -->
    <template if:true={error}>
        <p class="slds-text-color_error">{errorMessage}</p>
    </template>

    <!-- Data state -->
    <template if:true={account}>
        <lightning-card title={account.Name} icon-name="standard:account">
            <div class="slds-p-around_medium">
                <p>{account.Industry}</p>
            </div>
            <div slot="footer">
                <lightning-button label="Edit" onclick={handleEdit}></lightning-button>
            </div>
        </lightning-card>
    </template>
</template>
```

**Component Controller Pattern:**
```javascript
// accountSummaryCard.js
import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAccount from '@salesforce/apex/AccountController.getAccount';

export default class AccountSummaryCard extends NavigationMixin(LightningElement) {

    @api recordId;           // Passed from parent or record page context

    @wire(getAccount, { accountId: '$recordId' })
    wiredAccount({ error, data }) {
        if (data) {
            this.account = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.account = undefined;
        }
    }

    account;
    error;

    get isLoading() {
        return !this.account && !this.error;
    }

    get errorMessage() {
        return this.error?.body?.message || 'An error occurred';
    }

    handleEdit() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'edit'
            }
        });
    }

    showSuccessToast(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message,
            variant: 'success'
        }));
    }
}
```

**Metadata File (targets):**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>62.0</apiVersion>
    <isExposed>true</isExposed>
    <targets>
        <target>lightning__RecordPage</target>
        <target>lightning__AppPage</target>
    </targets>
    <targetConfigs>
        <targetConfig targets="lightning__RecordPage">
            <property name="recordId" type="String" />
        </targetConfig>
    </targetConfigs>
</LightningComponentBundle>
```

**LWC Standards:**
- `@api` for public properties (exposed to parent or App Builder)
- `@wire` for reactive data fetching (re-executes when `$property` changes)
- `@track` is **not needed for primitives** — all properties are reactive since Winter '20. Use `@track` only for object/array properties that need deep reactivity (mutation of nested fields)
- Always handle loading, error, and data states in templates
- Use `lightning-*` base components instead of custom HTML where possible
- SLDS design tokens for spacing and colors — no hardcoded pixel values or colors
- Accessibility: `aria-label`, `aria-live`, proper heading hierarchy
- CSS: scoped to component; use `:host` for root element styling

**Security in LWC:**
- No `innerHTML` with user-supplied data (XSS risk)
- No external scripts — use `loadScript()` with Static Resources
- No inline event handlers (`onclick="..."` in HTML) — use `onclick={handler}` binding
- `@AuraEnabled` Apex methods must enforce CRUD/FLS (`WITH USER_MODE`)

**Child/Parent Communication:**
```javascript
// Child → Parent: custom event
this.dispatchEvent(new CustomEvent('recordselected', {
    detail: { recordId: this.selectedId }
}));

// Parent template: <c-child onrecordselected={handleRecordSelected}></c-child>
// Parent JS: handleRecordSelected(event) { const id = event.detail.recordId; }

// Parent → Child: @api property or method
// <c-child record-id={selectedId}></c-child>
```

**LWC Jest Test Pattern:**
```javascript
// accountSummaryCard.test.js
import { createElement } from 'lwc';
import AccountSummaryCard from 'c/accountSummaryCard';
import getAccount from '@salesforce/apex/AccountController.getAccount';

jest.mock('@salesforce/apex/AccountController.getAccount', () => ({ default: jest.fn() }), { virtual: true });

describe('c-account-summary-card', () => {
    afterEach(() => { while (document.body.firstChild) document.body.removeChild(document.body.firstChild); });

    it('renders account name when data loads', async () => {
        getAccount.mockResolvedValue({ Id: '001xx', Name: 'Test Corp', Industry: 'Technology' });
        const element = createElement('c-account-summary-card', { is: AccountSummaryCard });
        element.recordId = '001xx';
        document.body.appendChild(element);
        await Promise.resolve();
        const card = element.shadowRoot.querySelector('lightning-card');
        expect(card.title).toBe('Test Corp');
    });

    it('shows error when apex fails', async () => {
        getAccount.mockRejectedValue({ body: { message: 'Not found' } });
        const element = createElement('c-account-summary-card', { is: AccountSummaryCard });
        element.recordId = '001xx';
        document.body.appendChild(element);
        await Promise.resolve();
        const error = element.shadowRoot.querySelector('.slds-text-color_error');
        expect(error.textContent).toBe('Not found');
    });
});
```

### Apex Controller Standards (for LWC @AuraEnabled methods)

When creating or modifying Apex controllers to support an LWC component, apply these standards:

- Class must use `with sharing` — never omit or use `without sharing` in controllers
- All `@AuraEnabled` SOQL must use `WITH USER_MODE` or `WITH SECURITY_ENFORCED`
- Cacheable methods (`cacheable=true`): side-effect-free only — no DML, no callouts, no state changes
- Non-cacheable methods: use `Database.insert/update/delete` with proper error handling; wrap DML errors and throw `AuraHandledException`
- Method parameters must be typed — never accept generic `Object` for user-supplied data
- Return typed wrapper classes or SObject lists — not raw `Map<String, Object>`

```apex
public with sharing class AccountController {

    @AuraEnabled(cacheable=true)
    public static List<Account> getAccounts(Id ownerId) {
        return [SELECT Id, Name, Industry, OwnerId
                FROM Account WHERE OwnerId = :ownerId
                WITH USER_MODE ORDER BY Name LIMIT 200];
    }

    @AuraEnabled
    public static void updateAccount(Id accountId, String industry) {
        try {
            Account acc = new Account(Id = accountId, Industry = industry);
            SObjectAccessDecision decision = Security.stripInaccessible(
                AccessType.UPDATABLE, new List<Account>{ acc });
            update decision.getRecords();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
```

**When touching Apex during `/lwc` work:** Verify sharing keyword and CRUD/FLS enforcement. If deeper Apex review is needed, delegate to `apex-code-reviewer` agent.

### Generate Output
Create all component files + Apex controller (if data needed) + Jest test file.
Summarize: what the component renders, how data flows, what interactions it handles.

---

## --explain: Explain What an LWC Component Does

### Identify the Component
- If `--explain <componentName or path>` provided, use that
- Otherwise, ask: "Which LWC component would you like me to explain?"
- Search: `force-app/**/lwc/<name>/<name>.js`

### Read All Component Files
Read `.js`, `.html`, `.css` together for full context.

### Explanation Structure
```
## What this component does
[One paragraph plain-English summary]

## Template structure
[What sections are rendered, what conditions control visibility]

## Data sources
[Which @wire adapters or Apex methods provide data, what they return]

## User interactions
[What each button/input does, what events are fired]

## Parent/child relationships
[@api properties exposed, CustomEvents emitted]

## Dependencies
[Apex classes called, sibling/child components used, LMS channels]
```

---

## --refine: Modify an Existing LWC Component

1. Read all component files (`.js`, `.html`, `.css`, `.js-meta.xml`)
2. Understand the component's current behavior and data flow
3. Apply the requested change
4. Update Jest tests to cover the new behavior
5. Announce what changed and what to verify in the UI

---

## --bug-fix: Diagnose and Fix an LWC Bug

### Common LWC Issues

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Data not rendering | `@wire` property name mismatch in template | Check `{propertyName}` matches JS property |
| Component not reactive | Mutating object property instead of reassigning | `this.data = { ...this.data, field: value }` |
| Event not caught by parent | Wrong event name casing | Use `on<eventname>` in parent template (all lowercase) |
| Infinite re-render | `@track` on object with circular reference | Remove unnecessary `@track` |
| CSP error for external script | Loading script via `<script>` tag | Use `loadScript()` with Static Resource |
| `@api` prop not updating | Parent not reassigning — passing same reference | Parent must assign new object/array reference |

### Process
1. Gather: what the user sees vs. what they expect, any console errors
2. Diagnose — read `.html` and `.js` together to trace the data flow
3. Fix root cause and update Jest test to cover the fix

---

## Examples

```
/lwc --new
/lwc --new account summary card for record page showing name, industry, and owner
/lwc --explain accountList
/lwc --explain force-app/main/default/lwc/opportunityTiles/opportunityTiles.js
/lwc --refine accountSummaryCard add a quick edit button that opens the record in edit mode
/lwc --bug-fix accountList component not showing updated records after parent refreshes
```
