# Compact

A run of controls joined into one: square where they meet, rounded only at the
ends, and a single line between neighbours rather than two.

```dart
Compact(
  children: [
    Expanded(child: Input(placeholder: 'Search')),
    Button(
      color: ButtonColor.primary,
      variant: ButtonVariant.solid,
      icon: const Icon(Icons.search),
      onPressed: search,
    ),
  ],
)
```

| Field | What it does |
| --- | --- |
| `children` | The controls, in the order they are joined |
| `direction` | `Axis.horizontal` (the default) or `Axis.vertical` |
| `block` | Take the whole width and share it equally |

## The control draws its own corners

A group cannot reach inside a widget somebody else built and round its corners
differently, so it does not try. It puts a `CompactSlot` over each child saying
where that child stands, and the control looks up and asks:

```dart
borderRadius: CompactSlot.radiusOf(context, token.borderRadius),
```

`radiusOf` names its corners by start and end, so they take their sides when
the control is painted rather than when it is built: a run that reads the
other way needs nothing rebuilt, and a control that animates its decoration
does not morph its corners on the way. It hands back every corner where there
is no group, so a control that
asks it instead of building its own `BorderRadius` looks exactly as it always
did everywhere else. The kit's `Button`, `Input`, `InputNumber`, `Select`,
`DatePicker` and `TimePicker` ask; a widget of your own joins in by asking too,
and one that never heard of the group simply stands in the run unjoined.

A whole run joins in the same way — and closes its own seams the same way, by
overlapping, so its borders are drawn inside the box and it stands exactly as
tall as a button beside it: `RadioGroup(optionType: button)` asks for
its outer corners and divides them between its two end buttons, so a set of
joined buttons and the button that acts on them read as one control.

Asking by context rather than being handed a value is what lets a control sit
somewhere other than directly under the group — a `Button` inside a `Dropdown`
inside the run still finds its slot.

## One line, not two

Two bordered controls side by side draw two lines where they meet, which reads
as a thicker seam than the border anywhere else. Each control after the first is
pulled back onto its neighbour by the width of one line — **in the layout**, not
only in the painting, so the run is exactly that much narrower and ends where
the last control ends rather than a hairline past it.

The borders are left whole. A control that dropped the side it shares would have
a gap in its ring the moment it took focus, which is the one time the ring
matters most.

The later control is painted over the earlier, so at the seam its border is the
one you see. A focused control between two others therefore shows its focus
colour on the side it shares with the one before it, and the plain border of the
one after it on the other side.

The pull follows the reading direction too: across a run that reads right to
left the neighbour lies on the other side, and a control pulled the same way
regardless would part from it and draw two lines instead of one.

## Where the round corners go

Worked out from the reading direction, so a right-to-left layout keeps the
round corners on the outside without a control having to know: the first
control of such a run stands at the right, and keeps its right-hand corners.
Down a column the ends are top and bottom whichever way the words run.

## What the run needs from around it

Across a row nothing: the controls are centred, not stretched, so a run stands
in a `Wrap` or an unmeasured `Column` without asking for a height it has not
been given. They line up anyway — every control of a size is the same height.

Down a column the controls are stretched to the width of the run, since a
ragged edge is the one thing a joined run must not have; give such a run a
width, as you would a `Column`.

## A child that came with a flex

`Expanded(child: Input(...))` — a field that takes what is left of the row —
works as written. `Expanded` speaks only to the row directly above it, so the
group wraps the field *inside* it and puts the flex back on the outside.

`block: true` gives every child that did not say otherwise an equal share.

## Not here yet

**Nothing joins a control's addons.** An `Input` with an addon on one side and
a `Button` on the other joins the outer edges, but the addon and the button
still meet as two separate boxes.
