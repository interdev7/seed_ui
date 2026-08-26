import 'package:flutter/foundation.dart';

import '../components/data_display/avatar.dart';
import '../components/data_display/badge.dart';
import '../components/data_display/card.dart';
import '../components/data_display/collapse.dart';
import '../components/data_display/countdown.dart';
import '../components/data_display/empty.dart';
import '../components/data_display/popover.dart';
import '../components/data_display/segmented.dart';
import '../components/data_display/sortable_list.dart';
import '../components/data_display/steps.dart';
import '../components/data_display/tabs.dart';
import '../components/data_display/tag.dart';
import '../components/data_display/timeline.dart';
import '../components/data_display/tooltip.dart';
import '../components/data_display/tour.dart';
import '../components/data_display/tree.dart';
import '../components/data_entry/checkbox.dart';
import '../components/data_entry/date_picker.dart';
import '../components/data_entry/input.dart';
import '../components/data_entry/input_number.dart';
import '../components/data_entry/radio.dart';
import '../components/data_entry/select.dart';
import '../components/data_entry/slider.dart';
import '../components/data_entry/time_picker.dart';
import '../components/data_entry/upload.dart';
import '../components/feedback/alert.dart';
import '../components/feedback/popconfirm.dart';
import '../components/feedback/progress.dart';
import '../components/general/button.dart';
import '../components/navigation/dropdown.dart';
import '../components/navigation/pagination.dart';

/// Default props for components under a `ConfigProvider`.
///
/// The second half of configuring a component, beside `ThemeData.components`.
/// That one carries **tokens** — the numbers and colours a component draws
/// with. This one carries the component's **own props**, applied wherever a
/// widget does not name one for itself.
///
/// ```dart
/// ConfigProvider(
///   theme: ThemeData(
///     // how a button is drawn
///     components: ComponentsConfig(button: ButtonToken(borderRadius: 16)),
///   ),
///   // what a button is, unless it says otherwise
///   defaults: ComponentDefaults(
///     button: ButtonDefaults(shape: ButtonShape.round),
///   ),
///   child: ...,
/// )
/// ```
///
/// A widget's own prop always wins, and these are inherited like the rest of
/// the configuration: a nested provider silent about a component leaves it as
/// the provider above had it.
@immutable
class ComponentDefaults {
  /// Creates a [ComponentDefaults].
  const ComponentDefaults({
    this.button,
    this.avatar,
    this.checkboxGroup,
    this.radioGroup,
    this.ribbon,
    this.sortableList,
    this.timeline,
    this.upload,
    this.alert,
    this.card,
    this.checkableTagGroup,
    this.collapse,
    this.countdown,
    this.inputNumber,
    this.pagination,
    this.progress,
    this.segmented,
    this.slider,
    this.steps,
    this.tabs,
    this.tree,
    this.datePicker,
    this.dropdown,
    this.empty,
    this.input,
    this.popconfirm,
    this.popover,
    this.select,
    this.tag,
    this.timePicker,
    this.tooltip,
    this.tour,
  });

  /// Applied to every [Button] under this provider.
  final ButtonDefaults? button;

  /// Applied to every [Alert] under this provider.
  final AlertDefaults? alert;

  /// Applied to every [Card] under this provider.
  final CardDefaults? card;

  /// Applied to every [CheckableTagGroup] under this provider.
  final CheckableTagGroupDefaults? checkableTagGroup;

  /// Applied to every [Collapse] under this provider.
  final CollapseDefaults? collapse;

  /// Applied to every [Countdown] under this provider.
  final CountdownDefaults? countdown;

  /// Applied to every [InputNumber] under this provider.
  final InputNumberDefaults? inputNumber;

  /// Applied to every [Pagination] under this provider.
  final PaginationDefaults? pagination;

  /// Applied to every [Progress] under this provider.
  final ProgressDefaults? progress;

  /// Applied to every [Segmented] under this provider.
  final SegmentedDefaults? segmented;

  /// Applied to every [Slider] under this provider.
  final SliderDefaults? slider;

  /// Applied to every [Steps] under this provider.
  final StepsDefaults? steps;

  /// Applied to every [Tabs] under this provider.
  final TabsDefaults? tabs;

  /// Applied to every [Tree] under this provider.
  final TreeDefaults? tree;

  /// Applied to every [Avatar] under this provider.
  final AvatarDefaults? avatar;

  /// Applied to every [CheckboxGroup] under this provider.
  final CheckboxGroupDefaults? checkboxGroup;

  /// Applied to every [RadioGroup] under this provider.
  final RadioGroupDefaults? radioGroup;

  /// Applied to every [Ribbon] under this provider.
  final RibbonDefaults? ribbon;

  /// Applied to every [SortableList] under this provider.
  final SortableListDefaults? sortableList;

  /// Applied to every [Timeline] under this provider.
  final TimelineDefaults? timeline;

  /// Applied to every [Upload] under this provider.
  final UploadDefaults? upload;

  /// Applied to every [DatePicker] under this provider.
  final DatePickerDefaults? datePicker;

  /// Applied to every [Dropdown] under this provider.
  final DropdownDefaults? dropdown;

  /// Applied to every [Empty] under this provider.
  final EmptyDefaults? empty;

  /// Applied to every [Input] under this provider.
  final InputDefaults? input;

  /// Applied to every [Select] under this provider.
  final SelectDefaults? select;

  /// Applied to every [Popconfirm] under this provider.
  final PopconfirmDefaults? popconfirm;

  /// Applied to every [Popover] under this provider.
  final PopoverDefaults? popover;

  /// Applied to every [Tag] under this provider.
  final TagDefaults? tag;

  /// Applied to every [TimePicker] under this provider.
  final TimePickerDefaults? timePicker;

  /// Applied to every [Tooltip] under this provider.
  final TooltipDefaults? tooltip;

  /// Applied to every [Tour] under this provider.
  final TourDefaults? tour;

  /// This set with [other] laid over it: every slot [other] names wins, the
  /// rest are kept.
  ComponentDefaults merge(ComponentDefaults other) => ComponentDefaults(
        button: other.button ?? button,
        avatar: other.avatar ?? avatar,
        checkboxGroup: other.checkboxGroup ?? checkboxGroup,
        radioGroup: other.radioGroup ?? radioGroup,
        ribbon: other.ribbon ?? ribbon,
        sortableList: other.sortableList ?? sortableList,
        timeline: other.timeline ?? timeline,
        upload: other.upload ?? upload,
        alert: other.alert ?? alert,
        card: other.card ?? card,
        checkableTagGroup: other.checkableTagGroup ?? checkableTagGroup,
        collapse: other.collapse ?? collapse,
        countdown: other.countdown ?? countdown,
        inputNumber: other.inputNumber ?? inputNumber,
        pagination: other.pagination ?? pagination,
        progress: other.progress ?? progress,
        segmented: other.segmented ?? segmented,
        slider: other.slider ?? slider,
        steps: other.steps ?? steps,
        tabs: other.tabs ?? tabs,
        tree: other.tree ?? tree,
        datePicker: other.datePicker ?? datePicker,
        dropdown: other.dropdown ?? dropdown,
        empty: other.empty ?? empty,
        input: other.input ?? input,
        select: other.select ?? select,
        popconfirm: other.popconfirm ?? popconfirm,
        popover: other.popover ?? popover,
        tag: other.tag ?? tag,
        timePicker: other.timePicker ?? timePicker,
        tooltip: other.tooltip ?? tooltip,
        tour: other.tour ?? tour,
      );

  /// Fast lookup for a specific defaults type [T].
  T? of<T>() {
    if (T == ButtonDefaults && button != null) return button as T;
    if (T == EmptyDefaults && empty != null) return empty as T;
    if (T == InputDefaults && input != null) return input as T;
    if (T == SelectDefaults && select != null) return select as T;
    if (T == TagDefaults && tag != null) return tag as T;
    if (T == DatePickerDefaults && datePicker != null) {
      return datePicker as T;
    }
    if (T == DropdownDefaults && dropdown != null) return dropdown as T;
    if (T == PopconfirmDefaults && popconfirm != null) {
      return popconfirm as T;
    }
    if (T == PopoverDefaults && popover != null) return popover as T;
    if (T == TimePickerDefaults && timePicker != null) {
      return timePicker as T;
    }
    if (T == TooltipDefaults && tooltip != null) return tooltip as T;
    if (T == TourDefaults && tour != null) return tour as T;
    if (T == AvatarDefaults && avatar != null) return avatar as T;
    if (T == CheckboxGroupDefaults && checkboxGroup != null) {
      return checkboxGroup as T;
    }
    if (T == RadioGroupDefaults && radioGroup != null) return radioGroup as T;
    if (T == RibbonDefaults && ribbon != null) return ribbon as T;
    if (T == SortableListDefaults && sortableList != null) {
      return sortableList as T;
    }
    if (T == TimelineDefaults && timeline != null) return timeline as T;
    if (T == UploadDefaults && upload != null) return upload as T;
    if (T == AlertDefaults && alert != null) return alert as T;
    if (T == CardDefaults && card != null) return card as T;
    if (T == CheckableTagGroupDefaults && checkableTagGroup != null) {
      return checkableTagGroup as T;
    }
    if (T == CollapseDefaults && collapse != null) return collapse as T;
    if (T == CountdownDefaults && countdown != null) return countdown as T;
    if (T == InputNumberDefaults && inputNumber != null) {
      return inputNumber as T;
    }
    if (T == PaginationDefaults && pagination != null) return pagination as T;
    if (T == ProgressDefaults && progress != null) return progress as T;
    if (T == SegmentedDefaults && segmented != null) return segmented as T;
    if (T == SliderDefaults && slider != null) return slider as T;
    if (T == StepsDefaults && steps != null) return steps as T;
    if (T == TabsDefaults && tabs != null) return tabs as T;
    if (T == TreeDefaults && tree != null) return tree as T;
    return null;
  }
}
