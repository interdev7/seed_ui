# Form

A set of named fields, the values they hold, and the rules they answer to.

```dart
final form = FormController();

Form(
  controller: form,
  onFinish: (values) => save(values),
  child: Column(
    children: [
      FormItem<String>(
        name: 'email',
        label: const Text('Email'),
        rules: const [FormRule.required(), FormRule.email()],
        builder: (field) => Input(
          value: field.value ?? '',
          status: field.status,
          onChanged: field.didChange,
        ),
      ),
    ],
  ),
)
```

## The control is built, not handed over

`FormItem.builder` gets a handle and returns the control. It is not a `child`,
and that is deliberate: a form has to put the value *into* the control and take
changes back out, and Flutter gives nobody a way to reach into a widget
somebody else has already built. A kit that guessed — "if the child is an
`Input`, wire it up" — would work for the controls it had heard of and leave
you stranded on the first one it had not.

The handle carries what the field holds and what may be done to it:

| Field | What it is |
| --- | --- |
| `value` | What the field holds now, typed |
| `didChange` | Report a new value to the form |
| `error` / `warning` | What the rules made of it |
| `status` | The same, as an `InputStatus` — hand it straight to `Input`, `Select`, `InputNumber` or a picker and the border recolours itself |
| `disabled` | Whether the form or the field has barred it |
| `validate` | Ask the rules now, whatever the trigger says |

## Rules

```dart
rules: const [FormRule.required(), FormRule.min(8)]
```

| Rule | What it asks |
| --- | --- |
| `FormRule.required()` | Not null, not blank, not an empty list, not an unticked box |
| `FormRule.min(n)` / `.max(n)` | At least / at most `n` characters, items, or that number |
| `FormRule.pattern(re)` | Matches the expression |
| `FormRule.email()` / `.url()` | Looks like one |
| `FormRule.custom(fn)` | Anything you like, including something asked of a server |

Each carries the kit's own words in eleven languages, and `message:` puts your
own in their place. `warningOnly: true` makes a rule a caution rather than a
refusal: the field is marked and the form still submits.

Two decisions worth knowing. **The first refusal is the one shown** — a field
that lists everything wrong with a value at once reads as scolding. And **an
empty value is `required`'s business alone**: `email` and the rest pass on it,
so a field that may be left blank is not told its blank is a bad address.

`FormRule.custom` may return a `Future`, so a check that has to ask a server is
an ordinary rule rather than a special case. Two runs started on two keystrokes
may finish in either order, and the later value has the last word whichever
answer arrives last — otherwise a field shows a complaint about something the
reader has already changed.

## When the rules are asked

`trigger` on the form, or on one field where it differs:
`FormTrigger.change` (the default), `.blur`, or `.submit`.

Whatever it says, **a field that has been told off is watched from then on**:
leaving a red border under a value that has just been put right is the form
arguing with the reader.

## What submitting does besides validating

The keyboard goes away first, before anything is decided: a form that has been
sent is a form nobody is typing into, and on a phone a message that appears
behind a keyboard is a message nobody reads. `unfocusOnSubmit: false` keeps it
up, for a search bar somebody is refining.

## A field nobody may touch

A barred field's rules are not asked, and any message it had goes. A required
field the reader cannot type into would otherwise refuse the form for ever,
pointing at a box they are not allowed to touch. Bar a field with `disabled`
on it, or every field with `disabled` on the form.

Two fields may not share a name. The second would take the first's place —
only one of them validated, both writing to the same value — so the form says
so, after the frame rather than during it, since throwing while a field is
being attached leaves the tree half-built and the real message is lost.

## The controller

`FormController` holds the values and does the doing, and is made outside the
widget so a button anywhere — a dialog's footer, a page's app bar — can reach
it.

| Method | What it does |
| --- | --- |
| `value(name)` / `values` | What one field holds, or all of them |
| `setValue` / `setValues` | Put a value in, as though the reader had |
| `error(name)` / `errors` | What the rules said |
| `touched(name)` | Whether the reader has been at it |
| `validate()` / `validateField(name)` | Ask the rules; both return whether it passed |
| `reset()` | Back to the values it began with, and forget every message |
| `submit()` | Validate, then `onFinish` or `onFinishFailed` |

Left without one a form makes its own, which is enough where the only way out
is a button inside the form: `Form.controllerOf(context)` reaches it.

It is a `ChangeNotifier`, so anything that wants to follow a value — a summary
line, a button that is dead until the form is whole — can listen.

## What the form is told to start with

`Form.initialValues` names them by field; `FormItem.initialValue` fills in
where the form is quiet. The form has the say where both speak, since a form
loading a record knows more than a field describing itself. `reset()` goes back
to whatever the two settled on.

## Around a field

`label`, and `layout` deciding where it stands: `vertical` (the default),
`horizontal` beside the field, or `inline` for a search bar rather than a page
of questions. `labelWidth` lines the labels up into a column; without it each
takes the width it wants and the fields begin at different places.

`requiredMark` marks the fields that must be answered with a star, or — with
`FormRequiredMark.optional` — marks the ones that need not, for a form where
nearly everything is required and the exceptions are the news. Which fields are
marked is worked out from the rules, so a `FormRule.required()` needs no second
telling; `FormItem.required` overrides it either way.

`labelAlign` sits a label in its column, which only tells where `labelWidth`
has given the column a width to sit in. A label beside its field is centred
against the control itself — not against the control and whatever is written
under it, which would drag the label down the moment a message appeared, and
not by an amount reckoned from font metrics, which left the two a pixel or so
apart. `colon` puts one after every label.

`onValuesChanged` is called with the name that changed and every value the
form now holds — for a summary line beside the form, or a button that stays
dead until the form is worth submitting.

`help` puts a word under the field **in place of** whatever the rules would
say, for messages that come from somewhere else entirely. `extra` puts one
**beside** what the rules say, for a hint.

## Design tokens

A `token` on the form itself overrides these for that form alone; a
`ComponentsConfig(form: …)` on a `ConfigProvider` does it for every form under
it.

`FormToken` overrides this component's own tokens. Every field is an override;
an unset one falls back to the value derived from the global theme.

| Token | Default |
| --- | --- |
| `labelColor` | `colorText` |
| `labelFontSize` | `fontSize` |
| `errorColor` | `error.base` — the message that refuses, and the required mark |
| `warningColor` | `warning.base` |
| `extraColor` | `colorTextTertiary` — a hint, and the optional mark |
| `messageFontSize` | `fontSizeSM` |
| `labelGap` | `sizeXS` — between a label and what it labels |
| `messageGap` | `sizeXXS` — between a control and the message under it |
| `itemGap` | `size` — between one field and the next |

## Not here yet

**A field that repeats.** There is no way to say "and here is a list of
addresses, add another": you can build one out of a `FormItem` holding a list,
but nothing helps you.

**Fields that depend on one another** — a rule that has to look at another
field's value. `FormRule.custom` can read a value through a controller you hold
yourself, so it is possible, but the form does not re-check the dependent field
when the one it depends on changes.
