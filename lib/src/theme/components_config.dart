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
import '../components/data_entry/form.dart';
import '../components/data_entry/input.dart';
import '../components/data_entry/input_number.dart';
import '../components/data_entry/radio.dart';
import '../components/data_entry/select.dart';
import '../components/data_entry/slider.dart';
import '../components/data_entry/switch.dart';
import '../components/data_entry/time_picker.dart';
import '../components/data_entry/upload.dart';
import '../components/feedback/alert.dart';
import '../components/feedback/drawer.dart';
import '../components/feedback/message.dart';
import '../components/feedback/modal.dart';
import '../components/feedback/notification.dart';
import '../components/feedback/popconfirm.dart';
import '../components/feedback/progress.dart';
import '../components/feedback/result.dart';
import '../components/feedback/spin.dart';
import '../components/general/button.dart';
import '../components/general/float_button.dart';
import '../components/navigation/dropdown.dart';
import '../components/navigation/pagination.dart';

/// Strongly-typed container for all component-specific token overrides.
@immutable
class ComponentsConfig {
  /// Creates a [ComponentsConfig].
  const ComponentsConfig({
    this.alert,
    this.avatar,
    this.badge,
    this.button,
    this.card,
    this.checkbox,
    this.collapse,
    this.countdown,
    this.datePicker,
    this.drawer,
    this.dropdown,
    this.empty,
    this.floatButton,
    this.form,
    this.input,
    this.inputNumber,
    this.listy,
    this.message,
    this.modal,
    this.notification,
    this.pagination,
    this.popconfirm,
    this.popover,
    this.progress,
    this.radio,
    this.ribbon,
    this.result,
    this.segmented,
    this.select,
    this.slider,
    this.sortableList,
    this.spin,
    this.steps,
    this.switchToken,
    this.table,
    this.tabs,
    this.tag,
    this.timePicker,
    this.timeline,
    this.tooltip,
    this.tour,
    this.tree,
    this.upload,
  });

  /// Overrides applied to every [Alert] under this provider.
  final AlertToken? alert;

  /// Overrides applied to every [Avatar] under this provider.
  final AvatarToken? avatar;

  /// Overrides applied to every [Badge] under this provider.
  final BadgeToken? badge;

  /// Overrides applied to every [Button] under this provider.
  final ButtonToken? button;

  /// Overrides applied to every [Card] under this provider.
  final CardToken? card;

  /// Overrides applied to every [Checkbox] under this provider.
  final CheckboxToken? checkbox;

  /// Overrides applied to every [Collapse] under this provider.
  final CollapseToken? collapse;

  /// Overrides applied to every [Countdown] under this provider.
  final CountdownToken? countdown;

  /// Overrides for [DatePicker].
  final DatePickerToken? datePicker;

  /// Overrides applied to every [FloatButton] under this provider.
  final FloatButtonToken? floatButton;

  /// Overrides applied to every [Form] under this provider.
  final FormToken? form;

  /// Overrides applied to every [Drawer] under this provider.
  final DrawerToken? drawer;

  /// Overrides applied to every [Dropdown] under this provider.
  final DropdownToken? dropdown;

  /// Overrides applied to every [Empty] under this provider.
  final EmptyToken? empty;

  /// Overrides applied to every [Input] under this provider.
  final InputToken? input;

  /// Overrides applied to every [InputNumber] under this provider.
  final InputNumberToken? inputNumber;

  /// Overrides applied to every [Listy] under this provider.
  final ListyToken? listy;

  /// Overrides applied to every [Message] under this provider.
  final MessageToken? message;

  /// Overrides applied to every [Modal] under this provider.
  final ModalToken? modal;

  /// Overrides applied to every [Notification] under this provider.
  final NotificationToken? notification;

  /// Overrides applied to every [Pagination] under this provider.
  final PaginationToken? pagination;

  /// Overrides applied to every [Popconfirm] under this provider.
  final PopconfirmToken? popconfirm;

  /// Overrides applied to every [Popover] under this provider.
  final PopoverToken? popover;

  /// Overrides applied to every [Progress] under this provider.
  final ProgressToken? progress;

  /// Overrides applied to every [Radio] under this provider.
  final RadioToken? radio;

  /// Overrides applied to every [Ribbon] under this provider.
  final RibbonToken? ribbon;

  /// Overrides applied to every [Result] under this provider.
  final ResultToken? result;

  /// Overrides applied to every [Segmented] under this provider.
  final SegmentedToken? segmented;

  /// Overrides applied to every [Select] under this provider.
  final SelectToken? select;

  /// Overrides applied to every [Slider] and [RangeSlider] under this
  /// provider.
  final SliderToken? slider;

  /// Overrides applied to every [SortableList] under this provider.
  final SortableListToken? sortableList;

  /// Overrides applied to every [Spin] under this provider.
  final SpinToken? spin;

  /// Overrides applied to every [Steps] under this provider.
  final StepsToken? steps;

  /// Overrides applied to every [Switch] under this provider.
  final SwitchToken? switchToken;

  /// Overrides applied to every [Tabs] under this provider.
  final TabsToken? tabs;

  /// Overrides applied to every [Table] under this provider.
  final TableToken? table;

  /// Overrides applied to every [Tag] under this provider.
  final TagToken? tag;

  /// Overrides for [TimePicker].
  final TimePickerToken? timePicker;

  /// Overrides applied to every [Timeline] under this provider.
  final TimelineToken? timeline;

  /// Overrides applied to every [Tour] under this provider.
  final TourToken? tour;

  /// Overrides applied to every [Tooltip] under this provider.
  final TooltipToken? tooltip;

  /// Overrides applied to every [Tree] under this provider.
  final TreeToken? tree;

  /// Overrides applied to every [Upload] under this provider.
  final UploadToken? upload;

  /// This config with [other] laid over it, one *field* at a time.
  ///
  /// How a nested [ConfigProvider] inherits. Not slot by slot: naming
  /// `button:` at all used to replace the whole `ButtonToken` above it, so
  /// asking next door for a different radius threw away the height the app
  /// had set. A provider says what it means to change, and keeps everything
  /// it is silent about — the other components, and the other fields of the
  /// one it did name.
  ComponentsConfig merge(ComponentsConfig other) => ComponentsConfig(
        alert: alert == null || other.alert == null
            ? (other.alert ?? alert)
            : alert!.merge(other.alert!),
        avatar: avatar == null || other.avatar == null
            ? (other.avatar ?? avatar)
            : avatar!.merge(other.avatar!),
        badge: badge == null || other.badge == null
            ? (other.badge ?? badge)
            : badge!.merge(other.badge!),
        button: button == null || other.button == null
            ? (other.button ?? button)
            : button!.merge(other.button!),
        card: card == null || other.card == null
            ? (other.card ?? card)
            : card!.merge(other.card!),
        checkbox: checkbox == null || other.checkbox == null
            ? (other.checkbox ?? checkbox)
            : checkbox!.merge(other.checkbox!),
        collapse: collapse == null || other.collapse == null
            ? (other.collapse ?? collapse)
            : collapse!.merge(other.collapse!),
        countdown: countdown == null || other.countdown == null
            ? (other.countdown ?? countdown)
            : countdown!.merge(other.countdown!),
        drawer: drawer == null || other.drawer == null
            ? (other.drawer ?? drawer)
            : drawer!.merge(other.drawer!),
        datePicker: datePicker == null || other.datePicker == null
            ? (other.datePicker ?? datePicker)
            : datePicker!.merge(other.datePicker!),
        timePicker: timePicker == null || other.timePicker == null
            ? (other.timePicker ?? timePicker)
            : timePicker!.merge(other.timePicker!),
        dropdown: dropdown == null || other.dropdown == null
            ? (other.dropdown ?? dropdown)
            : dropdown!.merge(other.dropdown!),
        empty: empty == null || other.empty == null
            ? (other.empty ?? empty)
            : empty!.merge(other.empty!),
        floatButton: floatButton == null || other.floatButton == null
            ? (other.floatButton ?? floatButton)
            : floatButton!.merge(other.floatButton!),
        form: form == null || other.form == null
            ? (other.form ?? form)
            : form!.merge(other.form!),
        input: input == null || other.input == null
            ? (other.input ?? input)
            : input!.merge(other.input!),
        inputNumber: inputNumber == null || other.inputNumber == null
            ? (other.inputNumber ?? inputNumber)
            : inputNumber!.merge(other.inputNumber!),
        listy: listy == null || other.listy == null
            ? (other.listy ?? listy)
            : listy!.merge(other.listy!),
        message: message == null || other.message == null
            ? (other.message ?? message)
            : message!.merge(other.message!),
        modal: modal == null || other.modal == null
            ? (other.modal ?? modal)
            : modal!.merge(other.modal!),
        notification: notification == null || other.notification == null
            ? (other.notification ?? notification)
            : notification!.merge(other.notification!),
        pagination: pagination == null || other.pagination == null
            ? (other.pagination ?? pagination)
            : pagination!.merge(other.pagination!),
        popconfirm: popconfirm == null || other.popconfirm == null
            ? (other.popconfirm ?? popconfirm)
            : popconfirm!.merge(other.popconfirm!),
        popover: popover == null || other.popover == null
            ? (other.popover ?? popover)
            : popover!.merge(other.popover!),
        progress: progress == null || other.progress == null
            ? (other.progress ?? progress)
            : progress!.merge(other.progress!),
        radio: radio == null || other.radio == null
            ? (other.radio ?? radio)
            : radio!.merge(other.radio!),
        ribbon: ribbon == null || other.ribbon == null
            ? (other.ribbon ?? ribbon)
            : ribbon!.merge(other.ribbon!),
        result: result == null || other.result == null
            ? (other.result ?? result)
            : result!.merge(other.result!),
        segmented: segmented == null || other.segmented == null
            ? (other.segmented ?? segmented)
            : segmented!.merge(other.segmented!),
        select: select == null || other.select == null
            ? (other.select ?? select)
            : select!.merge(other.select!),
        slider: slider == null || other.slider == null
            ? (other.slider ?? slider)
            : slider!.merge(other.slider!),
        sortableList: sortableList == null || other.sortableList == null
            ? (other.sortableList ?? sortableList)
            : sortableList!.merge(other.sortableList!),
        spin: spin == null || other.spin == null
            ? (other.spin ?? spin)
            : spin!.merge(other.spin!),
        steps: steps == null || other.steps == null
            ? (other.steps ?? steps)
            : steps!.merge(other.steps!),
        switchToken: switchToken == null || other.switchToken == null
            ? (other.switchToken ?? switchToken)
            : switchToken!.merge(other.switchToken!),
        table: table == null || other.table == null
            ? (other.table ?? table)
            : table!.merge(other.table!),
        tabs: tabs == null || other.tabs == null
            ? (other.tabs ?? tabs)
            : tabs!.merge(other.tabs!),
        tag: tag == null || other.tag == null
            ? (other.tag ?? tag)
            : tag!.merge(other.tag!),
        timeline: timeline == null || other.timeline == null
            ? (other.timeline ?? timeline)
            : timeline!.merge(other.timeline!),
        tour: tour == null || other.tour == null
            ? (other.tour ?? tour)
            : tour!.merge(other.tour!),
        tooltip: tooltip == null || other.tooltip == null
            ? (other.tooltip ?? tooltip)
            : tooltip!.merge(other.tooltip!),
        tree: tree == null || other.tree == null
            ? (other.tree ?? tree)
            : tree!.merge(other.tree!),
        upload: upload == null || other.upload == null
            ? (other.upload ?? upload)
            : upload!.merge(other.upload!),
      );

  /// Fast lookup for a specific component token type [T].
  T? of<T>() {
    if (T == AlertToken && alert != null) return alert as T;
    if (T == AvatarToken && avatar != null) return avatar as T;
    if (T == BadgeToken && badge != null) return badge as T;
    if (T == ButtonToken && button != null) return button as T;
    if (T == CardToken && card != null) return card as T;
    if (T == CheckboxToken && checkbox != null) return checkbox as T;
    if (T == CollapseToken && collapse != null) return collapse as T;
    if (T == CountdownToken && countdown != null) return countdown as T;
    if (T == DatePickerToken && datePicker != null) {
      return datePicker as T;
    }
    if (T == DrawerToken && drawer != null) return drawer as T;
    if (T == DropdownToken && dropdown != null) return dropdown as T;
    if (T == EmptyToken && empty != null) return empty as T;
    if (T == FormToken && form != null) return form as T;
    if (T == FloatButtonToken && floatButton != null) {
      return floatButton as T;
    }
    if (T == InputToken && input != null) return input as T;
    if (T == InputNumberToken && inputNumber != null) return inputNumber as T;
    if (T == ListyToken && listy != null) return listy as T;
    if (T == MessageToken && message != null) return message as T;
    if (T == ModalToken && modal != null) return modal as T;
    if (T == NotificationToken && notification != null) {
      return notification as T;
    }
    if (T == PaginationToken && pagination != null) return pagination as T;
    if (T == PopconfirmToken && popconfirm != null) return popconfirm as T;
    if (T == PopoverToken && popover != null) return popover as T;
    if (T == ProgressToken && progress != null) return progress as T;
    if (T == RadioToken && radio != null) return radio as T;
    if (T == RibbonToken && ribbon != null) return ribbon as T;
    if (T == ResultToken && result != null) return result as T;
    if (T == SegmentedToken && segmented != null) return segmented as T;
    if (T == SelectToken && select != null) return select as T;
    if (T == SortableListToken && sortableList != null) {
      return sortableList as T;
    }
    if (T == SliderToken && slider != null) return slider as T;
    if (T == SpinToken && spin != null) return spin as T;
    if (T == StepsToken && steps != null) return steps as T;
    if (T == SwitchToken && switchToken != null) return switchToken as T;
    if (T == TableToken && table != null) return table as T;
    if (T == TabsToken && tabs != null) return tabs as T;
    if (T == TagToken && tag != null) return tag as T;
    if (T == TimePickerToken && timePicker != null) {
      return timePicker as T;
    }
    if (T == TimelineToken && timeline != null) return timeline as T;
    if (T == TourToken && tour != null) return tour as T;
    if (T == TooltipToken && tooltip != null) return tooltip as T;
    if (T == TreeToken && tree != null) return tree as T;
    if (T == UploadToken && upload != null) return upload as T;
    return null;
  }
}
