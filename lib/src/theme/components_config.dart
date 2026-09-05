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

  /// This config with [other] laid over it: every slot [other] names wins, the
  /// rest are kept.
  ///
  /// How a nested [ConfigProvider] inherits — one that speaks about a single
  /// component leaves every other component as the provider above it had it,
  /// rather than resetting the lot to the defaults.
  ComponentsConfig merge(ComponentsConfig other) => ComponentsConfig(
        alert: other.alert ?? alert,
        avatar: other.avatar ?? avatar,
        badge: other.badge ?? badge,
        button: other.button ?? button,
        card: other.card ?? card,
        checkbox: other.checkbox ?? checkbox,
        collapse: other.collapse ?? collapse,
        countdown: other.countdown ?? countdown,
        drawer: other.drawer ?? drawer,
        dropdown: other.dropdown ?? dropdown,
        empty: other.empty ?? empty,
        floatButton: other.floatButton ?? floatButton,
        form: other.form ?? form,
        input: other.input ?? input,
        inputNumber: other.inputNumber ?? inputNumber,
        listy: other.listy ?? listy,
        message: other.message ?? message,
        modal: other.modal ?? modal,
        notification: other.notification ?? notification,
        pagination: other.pagination ?? pagination,
        popconfirm: other.popconfirm ?? popconfirm,
        popover: other.popover ?? popover,
        progress: other.progress ?? progress,
        radio: other.radio ?? radio,
        ribbon: other.ribbon ?? ribbon,
        result: other.result ?? result,
        segmented: other.segmented ?? segmented,
        select: other.select ?? select,
        slider: other.slider ?? slider,
        sortableList: other.sortableList ?? sortableList,
        spin: other.spin ?? spin,
        steps: other.steps ?? steps,
        switchToken: other.switchToken ?? switchToken,
        table: other.table ?? table,
        tabs: other.tabs ?? tabs,
        tag: other.tag ?? tag,
        timeline: other.timeline ?? timeline,
        tour: other.tour ?? tour,
        tooltip: other.tooltip ?? tooltip,
        tree: other.tree ?? tree,
        upload: other.upload ?? upload,
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
