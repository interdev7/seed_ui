import 'package:flutter/foundation.dart';

import '../components/data_display/avatar.dart';
import '../components/data_display/badge.dart';
import '../components/data_display/card.dart';
import '../components/data_display/collapse.dart';
import '../components/data_display/countdown.dart';
import '../components/data_display/empty.dart';
import '../components/data_display/listy.dart';
import '../components/data_display/popover.dart';
import '../components/data_display/segmented.dart';
import '../components/data_display/sortable_list.dart';
import '../components/data_display/steps.dart';
import '../components/data_display/table.dart';
import '../components/data_display/tabs.dart';
import '../components/data_display/tag.dart';
import '../components/data_display/timeline.dart';
import '../components/data_display/tooltip.dart';
import '../components/data_display/tour.dart';
import '../components/data_display/tree.dart';
import '../components/data_entry/checkbox.dart';
import '../components/data_entry/date_picker.dart';
import '../components/data_entry/date_range_picker.dart';
import '../components/data_entry/form.dart';
import '../components/data_entry/input.dart';
import '../components/data_entry/input_number.dart';
import '../components/data_entry/multi_date_picker.dart';
import '../components/data_entry/radio.dart';
import '../components/data_entry/select.dart';
import '../components/data_entry/slider.dart';
import '../components/data_entry/switch.dart';
import '../components/data_entry/time_picker.dart';
import '../components/data_entry/upload.dart';
import '../components/feedback/alert.dart';
import '../components/feedback/popconfirm.dart';
import '../components/feedback/progress.dart';
import '../components/feedback/spin.dart';
import '../components/general/button.dart';
import '../components/general/float_button.dart';
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
    this.table,
    this.tabs,
    this.tree,
    this.datePicker,
    this.dropdown,
    this.empty,
    this.floatButton,
    this.input,
    this.popconfirm,
    this.popover,
    this.select,
    this.tag,
    this.timePicker,
    this.tooltip,
    this.tour,
    this.dateRangePicker,
    this.multiDatePicker,
    this.badge,
    this.checkbox,
    this.form,
    this.listy,
    this.radio,
    this.spin,
    this.switchControl,
    this.multiRangeSlider,
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

  /// Props applied to every [FloatButton] and [FloatButtonGroup].
  final FloatButtonDefaults? floatButton;

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

  /// Props applied to every [Table].
  final TableDefaults? table;

  /// Applied to every [DateRangePicker] under this provider.
  final DateRangePickerDefaults? dateRangePicker;

  /// Applied to every [MultiDatePicker] under this provider.
  final MultiDatePickerDefaults? multiDatePicker;

  /// Applied to every [Badge] under this provider.
  final BadgeDefaults? badge;

  /// Applied to every [Checkbox] under this provider.
  final CheckboxDefaults? checkbox;

  /// Applied to every [Form] under this provider.
  final FormDefaults? form;

  /// Applied to every [Listy] under this provider.
  final ListyDefaults? listy;

  /// Applied to every [Radio] under this provider.
  final RadioDefaults? radio;

  /// Applied to every [Spin] under this provider.
  final SpinDefaults? spin;

  /// Applied to every [Switch] under this provider.
  final SwitchDefaults? switchControl;

  /// Applied to every [MultiRangeSlider] under this provider.
  final MultiRangeSliderDefaults? multiRangeSlider;

  /// This set with [other] laid over it, one *field* at a time.
  ///
  /// Not slot by slot: a nested provider that names `button:` at all used to
  /// replace the whole `ButtonDefaults` above it, so asking next door for a
  /// round button threw away the size and the variant named for the app —
  /// and the buttons came back white-on-white and tiny. A provider says what
  /// it means to change, and keeps everything it is silent about.
  ComponentDefaults merge(ComponentDefaults other) => ComponentDefaults(
        button: button == null || other.button == null
            ? (other.button ?? button)
            : button!.merge(other.button!),
        avatar: avatar == null || other.avatar == null
            ? (other.avatar ?? avatar)
            : avatar!.merge(other.avatar!),
        checkboxGroup: checkboxGroup == null || other.checkboxGroup == null
            ? (other.checkboxGroup ?? checkboxGroup)
            : checkboxGroup!.merge(other.checkboxGroup!),
        radioGroup: radioGroup == null || other.radioGroup == null
            ? (other.radioGroup ?? radioGroup)
            : radioGroup!.merge(other.radioGroup!),
        ribbon: ribbon == null || other.ribbon == null
            ? (other.ribbon ?? ribbon)
            : ribbon!.merge(other.ribbon!),
        sortableList: sortableList == null || other.sortableList == null
            ? (other.sortableList ?? sortableList)
            : sortableList!.merge(other.sortableList!),
        timeline: timeline == null || other.timeline == null
            ? (other.timeline ?? timeline)
            : timeline!.merge(other.timeline!),
        upload: upload == null || other.upload == null
            ? (other.upload ?? upload)
            : upload!.merge(other.upload!),
        alert: alert == null || other.alert == null
            ? (other.alert ?? alert)
            : alert!.merge(other.alert!),
        card: card == null || other.card == null
            ? (other.card ?? card)
            : card!.merge(other.card!),
        checkableTagGroup:
            checkableTagGroup == null || other.checkableTagGroup == null
                ? (other.checkableTagGroup ?? checkableTagGroup)
                : checkableTagGroup!.merge(other.checkableTagGroup!),
        collapse: collapse == null || other.collapse == null
            ? (other.collapse ?? collapse)
            : collapse!.merge(other.collapse!),
        countdown: countdown == null || other.countdown == null
            ? (other.countdown ?? countdown)
            : countdown!.merge(other.countdown!),
        inputNumber: inputNumber == null || other.inputNumber == null
            ? (other.inputNumber ?? inputNumber)
            : inputNumber!.merge(other.inputNumber!),
        pagination: pagination == null || other.pagination == null
            ? (other.pagination ?? pagination)
            : pagination!.merge(other.pagination!),
        progress: progress == null || other.progress == null
            ? (other.progress ?? progress)
            : progress!.merge(other.progress!),
        segmented: segmented == null || other.segmented == null
            ? (other.segmented ?? segmented)
            : segmented!.merge(other.segmented!),
        slider: slider == null || other.slider == null
            ? (other.slider ?? slider)
            : slider!.merge(other.slider!),
        steps: steps == null || other.steps == null
            ? (other.steps ?? steps)
            : steps!.merge(other.steps!),
        table: table == null || other.table == null
            ? (other.table ?? table)
            : table!.merge(other.table!),
        tabs: tabs == null || other.tabs == null
            ? (other.tabs ?? tabs)
            : tabs!.merge(other.tabs!),
        tree: tree == null || other.tree == null
            ? (other.tree ?? tree)
            : tree!.merge(other.tree!),
        datePicker: datePicker == null || other.datePicker == null
            ? (other.datePicker ?? datePicker)
            : datePicker!.merge(other.datePicker!),
        dropdown: dropdown == null || other.dropdown == null
            ? (other.dropdown ?? dropdown)
            : dropdown!.merge(other.dropdown!),
        empty: empty == null || other.empty == null
            ? (other.empty ?? empty)
            : empty!.merge(other.empty!),
        floatButton: floatButton == null || other.floatButton == null
            ? (other.floatButton ?? floatButton)
            : floatButton!.merge(other.floatButton!),
        input: input == null || other.input == null
            ? (other.input ?? input)
            : input!.merge(other.input!),
        select: select == null || other.select == null
            ? (other.select ?? select)
            : select!.merge(other.select!),
        popconfirm: popconfirm == null || other.popconfirm == null
            ? (other.popconfirm ?? popconfirm)
            : popconfirm!.merge(other.popconfirm!),
        popover: popover == null || other.popover == null
            ? (other.popover ?? popover)
            : popover!.merge(other.popover!),
        tag: tag == null || other.tag == null
            ? (other.tag ?? tag)
            : tag!.merge(other.tag!),
        timePicker: timePicker == null || other.timePicker == null
            ? (other.timePicker ?? timePicker)
            : timePicker!.merge(other.timePicker!),
        tooltip: tooltip == null || other.tooltip == null
            ? (other.tooltip ?? tooltip)
            : tooltip!.merge(other.tooltip!),
        tour: tour == null || other.tour == null
            ? (other.tour ?? tour)
            : tour!.merge(other.tour!),
        dateRangePicker:
            dateRangePicker == null || other.dateRangePicker == null
                ? (other.dateRangePicker ?? dateRangePicker)
                : dateRangePicker!.merge(other.dateRangePicker!),
        multiDatePicker:
            multiDatePicker == null || other.multiDatePicker == null
                ? (other.multiDatePicker ?? multiDatePicker)
                : multiDatePicker!.merge(other.multiDatePicker!),
        badge: badge == null || other.badge == null
            ? (other.badge ?? badge)
            : badge!.merge(other.badge!),
        checkbox: checkbox == null || other.checkbox == null
            ? (other.checkbox ?? checkbox)
            : checkbox!.merge(other.checkbox!),
        form: form == null || other.form == null
            ? (other.form ?? form)
            : form!.merge(other.form!),
        listy: listy == null || other.listy == null
            ? (other.listy ?? listy)
            : listy!.merge(other.listy!),
        radio: radio == null || other.radio == null
            ? (other.radio ?? radio)
            : radio!.merge(other.radio!),
        spin: spin == null || other.spin == null
            ? (other.spin ?? spin)
            : spin!.merge(other.spin!),
        switchControl: switchControl == null || other.switchControl == null
            ? (other.switchControl ?? switchControl)
            : switchControl!.merge(other.switchControl!),
        multiRangeSlider:
            multiRangeSlider == null || other.multiRangeSlider == null
                ? (other.multiRangeSlider ?? multiRangeSlider)
                : multiRangeSlider!.merge(other.multiRangeSlider!),
      );

  /// Fast lookup for a specific defaults type [T].
  T? of<T>() {
    if (T == TableDefaults && table != null) return table as T;
    if (T == ButtonDefaults && button != null) return button as T;
    if (T == EmptyDefaults && empty != null) return empty as T;
    if (T == FloatButtonDefaults && floatButton != null) {
      return floatButton as T;
    }
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
    if (T == DateRangePickerDefaults && dateRangePicker != null) {
      return dateRangePicker as T;
    }
    if (T == MultiDatePickerDefaults && multiDatePicker != null) {
      return multiDatePicker as T;
    }
    if (T == BadgeDefaults && badge != null) {
      return badge as T;
    }
    if (T == CheckboxDefaults && checkbox != null) {
      return checkbox as T;
    }
    if (T == FormDefaults && form != null) {
      return form as T;
    }
    if (T == ListyDefaults && listy != null) {
      return listy as T;
    }
    if (T == RadioDefaults && radio != null) {
      return radio as T;
    }
    if (T == SpinDefaults && spin != null) {
      return spin as T;
    }
    if (T == SwitchDefaults && switchControl != null) {
      return switchControl as T;
    }
    if (T == MultiRangeSliderDefaults && multiRangeSlider != null) {
      return multiRangeSlider as T;
    }
    return null;
  }
}
