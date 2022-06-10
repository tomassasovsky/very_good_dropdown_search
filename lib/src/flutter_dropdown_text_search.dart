import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DropdownTextSearch<T> extends StatefulWidget {
  const DropdownTextSearch({
    Key? key,
    this.overlayHeight,
    required this.items,
    required this.itemBuilder,
    required this.itemToString,
    this.filterFnc,
    this.onChange,
    this.controller,
    this.decorator,
    this.node,
    this.hoverColor,
    this.highlightColor,
    this.tileColor,
    this.noItemFoundText,
    this.textFieldStyle,
  }) : super(key: key);

  final TextEditingController? controller;
  final InputDecoration? decorator;
  final String? noItemFoundText;
  final Color? hoverColor;
  final Color? highlightColor;
  final Color? tileColor;
  final FocusScopeNode? node;
  final bool Function(String text, T item)? filterFnc;
  final double? overlayHeight;
  final Function(T item)? onChange;
  final List<T> items;
  final TextStyle? textFieldStyle;
  final Widget Function(T item) itemBuilder;
  final String Function(T item) itemToString;

  @override
  _DropdownTextSearch createState() => _DropdownTextSearch<T>();
}

class _DropdownTextSearch<T> extends State<DropdownTextSearch<T>> {
  late final ScrollController scrollController;
  late List<T> sourceData;
  late final FocusNode focusNode;
  final layerLink = LayerLink();
  OverlayEntry? entry;
  int _selectedItem = 0;

  @override
  void initState() {
    scrollController = ScrollController();
    sourceData = widget.items.cast<T>();
    focusNode = FocusNode();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {});

    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        showOverlay();
      } else {
        hideOverlay();
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    focusNode.dispose();
    entry?.dispose();
    super.dispose();
  }

  void showOverlay() {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    entry = OverlayEntry(
      builder: (BuildContext context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 10),
          child: buildOverlay(),
        ),
      ),
    );

    if (entry != null) {
      overlay?.insert(entry!);
    }
  }

  void hideOverlay() {
    entry?.remove();
    entry = null;
  }

  Widget buildOverlay() {
    return Material(
        elevation: 10,
        child: SizedBox(
          height: widget.overlayHeight,
          child: sourceData.isNotEmpty
              ? ListView.builder(
                  shrinkWrap: true,
                  controller: scrollController,
                  itemBuilder: (context, index) => GestureDetector(
                    onTap: () {
                      widget.controller?.text = widget.itemToString.call(sourceData[index]);
                      widget.onChange?.call(sourceData[index]);
                      focusNode.unfocus();
                    },
                    child: widget.itemBuilder.call(sourceData[index]),
                  ),
                  itemCount: sourceData.length,
                )
              : Center(child: Text(widget.noItemFoundText ?? "No Item Found")),
        ));
  }

  void scrollFun() {
    double perBlockHeight = scrollController.position.maxScrollExtent / (sourceData.length - 1);
    double _position = _selectedItem * perBlockHeight;
    scrollController.jumpTo(
      _position,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: focusNode,
      onKey: (RawKeyEvent key) {
        if (key.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
          _selectedItem = _selectedItem < sourceData.length - 1 ? _selectedItem + 1 : _selectedItem;
          scrollFun();
        } else if (key.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
          _selectedItem = _selectedItem > 0 ? _selectedItem - 1 : _selectedItem;
          scrollFun();
        } else if (key.isKeyPressed(LogicalKeyboardKey.escape)) {
          widget.controller?.clear();
          focusNode.unfocus();
        }
        entry?.markNeedsBuild();
      },
      child: CompositedTransformTarget(
        link: layerLink,
        child: TextFormField(
          controller: widget.controller,
          autofocus: false,
          onFieldSubmitted: (bg) {
            widget.controller?.text = widget.itemToString.call(sourceData[_selectedItem]);
            widget.onChange?.call(sourceData[_selectedItem]);
            focusNode.unfocus();
          },
          onEditingComplete: widget.node?.nextFocus,
          cursorColor: Colors.black,
          style: widget.textFieldStyle,
          onChanged: (text) {
            if (text.isNotEmpty) {
              sourceData = widget.items.where((T item) => widget.filterFnc?.call(text, item) ?? text == item).toList();
            } else {
              sourceData = widget.items;
            }
            _selectedItem = 0;
            setState(() {});
          },
          decoration: widget.decorator,
        ),
      ),
    );
  }
}
