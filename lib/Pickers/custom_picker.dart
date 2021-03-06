import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:perceive_slidable/sliding_sheet.dart';
import 'package:piky/Pickers/imager_picker.dart';
import 'package:piky/Pickers/picker.dart';
import 'package:piky/configuration_delegates/custom_picker_config_delegate.dart';
import 'package:piky/util/functions.dart';

class CustomPicker extends StatefulWidget {

  /// Sliding sheet controller
  final PerceiveSlidableController sheetController;

  /// Sheet sizing extents
  final double initialExtent;
  final double expandedExtent;
  final double mediumExtent;
  final double minExtent;

  /// Delegate for this widget
  final CustomPickerConfigDelegate delegate;

  /// Allows the picker to see the sheetstate
  final Function(double extent) listener;

  /// If the custom picker is in a locked state
  final ConcreteCubit<PickerType?> openType;
  
  const CustomPicker({ 
    Key? key, 
    required this.sheetController,
    required this.delegate,
    required this.listener,
    required this.openType,
    this.initialExtent = 0.55,
    this.minExtent = 0.2,
    this.mediumExtent = 0.55,
    this.expandedExtent = 1.0,
  }) : super(key: key);

  @override
  _CustomPickerState createState() => _CustomPickerState();
}

class _CustomPickerState extends State<CustomPicker> with SingleTickerProviderStateMixin {

  late final FocusNode focusNode = FocusNode()..addListener(() {
    //Expands the sheet if the focus node has focus
    if(focusNode.hasFocus && widget.sheetController.extent != widget.expandedExtent){
      widget.sheetController.snapTo(widget.expandedExtent, duration: Duration(milliseconds: 300));
    }
  });

  TextEditingController searchFieldController = TextEditingController();

  void sheetListener(double extent){
    if(extent <= widget.initialExtent/3 && widget.openType.state == PickerType.Custom){
      if(extent == 0){
        Future.delayed(Duration(milliseconds: 100)).then((value){
          widget.sheetController.snapTo(widget.initialExtent);
        });
      }
      else{
        widget.sheetController.snapTo(widget.initialExtent);
      }
    }
    widget.listener(extent);
  }

  @override
  Widget build(BuildContext context) {

    return PerceiveSlidable(
      controller: widget.sheetController,
      staticSheet: true,
      closeOnBackdropTap: false,
      isBackgroundIntractable: false,
      doesPop: false,
      additionalSnappings: [widget.initialExtent],
      initialExtent: 0,
      minExtent: widget.minExtent,
      mediumExtent: widget.mediumExtent,
      expandedExtent: widget.expandedExtent,
      extentListener: sheetListener,
      delegate: _CustomPickerSheetController(
        (context, spacer, borderRadius) => widget.delegate.headerBuilder(context, spacer, focusNode, searchFieldController, borderRadius) ?? Container(),
        (context, extent, scrollController, scrollLock, footerHeight) => widget.delegate.bodyBuilder(context, extent, scrollController, scrollLock, footerHeight) ?? Container(),
      )
    );

  }
}

class CustomPickerController extends ChangeNotifier {
  _CustomPickerState? _state;

  CustomPickerController();

  /// Bind to state
  void _bind(_CustomPickerState bind) => _state = bind;

  /// Notify listeners
  void update() => _state != null ? notifyListeners() : null;

  /// Get the current state of the [ImagePicker]
  PikyOption? get type => _state != null ? type : null;

  //Disposes of the controller
  @override
  void dispose() {
    _state = null;
  }
}

class _CustomPickerSheetController extends ScrollablePerceiveSlidableDelegate {

  final Widget Function(BuildContext context, Widget spacer, double borderRadius) header;

  final Widget Function(BuildContext context, double extent, ScrollController scrollController, bool scrollLock, double footerHeight) body;

  _CustomPickerSheetController(this.header, this.body) : super(pageCount: 1, staticScrollModifier: 0.01);

  @override
  Widget headerBuilder(BuildContext context, pageObj, Widget spacer, double borderRadius) {
    return header.call(context, spacer, borderRadius);
  }

  @override
  Widget scrollingBodyBuilder(BuildContext context, SheetState? state, ScrollController scrollController, int pageIndex, bool scrollLock, double footerHeight) {
    if(state == null){
      return Container();
    }
    return body.call(context, state.extent, scrollController, scrollLock, footerHeight);
  }

}