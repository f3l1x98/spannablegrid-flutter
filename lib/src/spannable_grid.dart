import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'spannable_grid_cell_data.dart';
import 'spannable_grid_cell_view.dart';
import 'spannable_grid_delegate.dart';
import 'spannable_grid_empty_cell_view.dart';
import 'spannable_grid_options.dart';

/// A grid widget that allows its items to span columns and rows and supports
/// editing.
///
/// Widget layouts its children (defined in [cells]) in a grid of fixed [columns]
/// and [rows].
/// The gaps between grid cells is defined by optional [spacing] parameter.
/// The [SpannableGrid] is sized to fit its parent widget width.
///
/// The widget supports editing mode in which user can move selected cell to
/// available places withing the grid. User enter the editing mode by long
/// press on the cell. In the editing mode the editing cell is highlighted
/// while other cells are faded. All grid structure becomes visible. User exit
/// the editing mode by click on editing cell. Updated [SpannableGridCellData]
/// object is returned in the [onCellChanged] callback.
///
/// ```dart
/// SpannableGrid(
///   columns: 4,
///   rows: 4,
///   cells: cells,
///   spacing: 2.0,
///   onCellChanged: (cell) { print('Cell ${cell.id} changed'); },
/// ),
/// ```
///
/// See also:
/// - [SpannableGridCellData]
/// - [SpannableGridEditingStrategy]
/// - [SpannableGridStyle]
/// - [SpannableGridSize]
/// - [SpannableGridCompactingStrategy]
///
class SpannableGrid extends StatefulWidget {
  SpannableGrid({
    Key? key,
    required this.scrollController,
    required this.cells,
    required this.columns,
    required this.rows,
    this.editingStrategy = const SpannableGridEditingStrategy(),
    this.style = const SpannableGridStyle(),
    this.emptyCellView,
    this.gridSize = SpannableGridSize.parentWidth,
    this.onCellChanged,
    this.showGrid = false,
    this.compactingStrategy = SpannableGridCompactingStrategy.none,
  }) : super(key: key);

  final ScrollController scrollController;

  /// Items data
  ///
  /// A list of [SpannableGridCellData] objects, containing item's id, position,
  /// size and content widget
  final List<SpannableGridCellData> cells;

  /// Number of columns
  final int columns;

  /// Number of rows
  final int rows;

  /// How an editing mode should work.
  ///
  /// Defines if the editing mode is supported and what actions are recognized to
  /// enter and exit the editing mode.
  ///
  /// Default strategy is to allow the editing mode, enter it by long tap and exit by tap.
  ///
  final SpannableGridEditingStrategy editingStrategy;

  /// Appearance of the grid.
  ///
  /// Contain parameters to style cells and grid layout in both view and editing modes.
  ///
  final SpannableGridStyle style;

  /// A widget to display in empty cells.
  ///
  /// Also it is used as a background for all cells in the editing mode.
  /// If it is not set, the [emptyCellColor] is used to display empty cell.
  ///
  final Widget? emptyCellView;

  /// How a grid size is determined.
  ///
  /// When it is [SpannableGridSize.parent], grid is sized to fully fit parent's constrains.
  /// This means that grid cell's aspect ratio will be the same as the grid's one.
  /// If it is [SpannableGridSize.parentWidth] or [SpannableGridSize.parentHeight],
  /// then grid's height or width respectively will be equal the opposite side.
  /// Consequently, in this case grid cell's aspect ratio is 1 (grid cells are square).
  ///
  /// Defaults to [SpannableGridSize.parentWidth].
  ///
  final SpannableGridSize gridSize;

  /// A callback, that called when a cell position is changed by the user
  final Function(SpannableGridCellData?)? onCellChanged;

  /// When set to 'true', the grid structure is always visible.
  ///
  /// In this case the [emptyCellView] or [emptyCellColor] is used to display empty cells.
  ///
  /// Defaults to 'false'.
  ///
  final bool showGrid;

  /// How the grid should be compacted.
  ///
  /// Defines how the grid should be compacted and if yes, in what order.
  ///
  /// Default strategy is to not compact at all.
  ///
  final SpannableGridCompactingStrategy compactingStrategy;

  @override
  _SpannableGridState createState() => _SpannableGridState();
}

class _SpannableGridState extends State<SpannableGrid> {
  final _availableCells = <List<bool>>[];

  final _cells = <Object, SpannableGridCellData>{};

  final _children = <Widget>[];

  Size? _cellSize;

  bool _isEditing = false;

  SpannableGridCellData? _editingCell;

  // When dragging started, contains a relative position of the pointer in the
  // dragging widget
  Offset? _dragLocalPosition;

  // TODO currently scroll one 50 pixel the second
  double pixelPerSecond = 50.0;
  double _scrollStartOffset =
      20.0; // TODO adjust delta (MAYBE MAKE THIS CONFIGURABLE)
  bool _isScrolling = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.compactingStrategy != SpannableGridCompactingStrategy.none) {
      _compactCells();
    }
    _updateCellsAndChildren();
  }

  @override
  void didUpdateWidget(SpannableGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.compactingStrategy != SpannableGridCompactingStrategy.none) {
      _compactCells();
    }
    _updateCellsAndChildren();
  }

  @override
  Widget build(BuildContext context) {
    return _constrainGrid(
      child: CustomMultiChildLayout(
        delegate: SpannableGridDelegate(
            cells: _cells,
            columns: widget.columns,
            rows: widget.rows,
            spacing: widget.style.spacing,
            gridSize: widget.gridSize,
            onCellSizeCalculated: (size) {
              _cellSize = size;
            }),
        children: _children,
      ),
    );
  }

  Widget _constrainGrid({required Widget child}) {
    switch (widget.gridSize) {
      case SpannableGridSize.parent:
        return child;
      case SpannableGridSize.parentWidth:
      case SpannableGridSize.parentHeight:
        return AspectRatio(
          aspectRatio: widget.columns / widget.rows,
          child: child,
        );
    }
  }

  void _onEnterEditing(SpannableGridCellData cell) {
    setState(() {
      _isEditing = true;
      _editingCell = _cells[cell.id];
      _updateCellsAndChildren();
    });
  }

  void _onExitEditing() {
    setState(() {
      widget.onCellChanged?.call(_editingCell);
      _isEditing = false;
      _editingCell = null;

      if (widget.compactingStrategy != SpannableGridCompactingStrategy.none) {
        _compactCells();
      }
      _updateCellsAndChildren();
    });
  }

  void _updateCellsAndChildren() {
    _cells.clear();
    _children.clear();
    if (_isEditing || widget.showGrid) {
      _addEmptyCellsAndChildren();
    }
    _addContentCells();
    _calculateAvailableCells();
    _addContentChildren();
  }

  void _compactRow() {
    for (SpannableGridCellData cell in widget.cells) {
      int currentCellRowStart =
          (cell.row - 1); // -1 because cell.row starts with 1
      int currentCellColumnStart =
          (cell.column - 1); // -1 because cell.row starts with 1
      /// Exclusive end
      int currentCellRowEnd = currentCellRowStart + cell.rowSpan;

      /// Exclusive end
      int currentCellColumnEnd = currentCellColumnStart + cell.columnSpan;

      if (currentCellRowStart > 0) {
        // Check space above for column span
        for (int rowAbove = currentCellRowStart - 1;
            rowAbove >= 0;
            rowAbove--) {
          // Check if above has the space for this cell including its columnSpan
          bool rowOccupied = _availableCells[rowAbove]
              .getRange(currentCellColumnStart, currentCellColumnEnd)
              .any((element) => element == false);
          if (!rowOccupied) {
            // Move cell up (update _availableCells and cell.row)
            for (int i = currentCellColumnStart;
                i < currentCellColumnEnd;
                i++) {
              _availableCells[rowAbove][i] = false;
              // Mark row below as available
              _availableCells[currentCellRowEnd - 1][i] = true;
            }
            cell.row--;
            // Update currentCellRow start and end
            currentCellRowStart = (cell.row - 1);
            currentCellRowEnd = currentCellRowStart + cell.rowSpan;
          } else {
            // Row above is occupied -> this cell cannot be further compacted
            break;
          }
        }
      }
    }
  }

  void _compactColumn() {
    for (SpannableGridCellData cell in widget.cells) {
      int currentCellRowStart =
          (cell.row - 1); // -1 because cell.row starts with 1
      int currentCellColumnStart =
          (cell.column - 1); // -1 because cell.row starts with 1
      /// Exclusive end
      int currentCellRowEnd = currentCellRowStart + cell.rowSpan;

      /// Exclusive end
      int currentCellColumnEnd = currentCellColumnStart + cell.columnSpan;

      if (currentCellColumnStart > 0) {
        // Check space above for column span
        for (int columnLeft = currentCellColumnStart - 1;
            columnLeft >= 0;
            columnLeft--) {
          // Check if above has the space for this cell including its columnSpan
          bool columnOccupied = _availableCells
              .getRange(currentCellRowStart, currentCellRowEnd)
              .any((element) => element[columnLeft] == false);
          if (!columnOccupied) {
            // Move cell left (update _availableCells and cell.column)
            for (int i = currentCellRowStart; i < currentCellRowEnd; i++) {
              _availableCells[i][columnLeft] = false;
              // Mark row below as available
              _availableCells[i][currentCellColumnEnd - 1] = true;
            }
            cell.column--;
            // Update currentCellColumn start and end
            currentCellColumnStart = (cell.column - 1);
            currentCellColumnEnd = currentCellColumnStart + cell.columnSpan;
          } else {
            // Column left is occupied -> this cell cannot be further compacted
            break;
          }
        }
      }
    }
  }

  void _compactCells() {
    // Clear current state
    _cells.clear();
    _children.clear();
    _addContentCells();
    _calculateAvailableCells();

    if (widget.compactingStrategy == SpannableGridCompactingStrategy.rowOnly ||
        widget.compactingStrategy == SpannableGridCompactingStrategy.rowFirst) {
      // Sort by rows (then columns)
      // Sorting required due to otherwise compacting missing cell (because it tries to compact this cell before cell above/left of it)
      widget.cells.sort((cell1, cell2) {
        int rowCompare = cell1.row.compareTo(cell2.row);
        return rowCompare == 0
            ? cell1.column.compareTo(cell2.column)
            : rowCompare;
      });
      // Compact rows
      _compactRow();
      if (widget.compactingStrategy ==
          SpannableGridCompactingStrategy.rowFirst) {
        // Compact columns
        _compactColumn();
      }
    }
    if (widget.compactingStrategy ==
            SpannableGridCompactingStrategy.columnOnly ||
        widget.compactingStrategy ==
            SpannableGridCompactingStrategy.columnFirst) {
      // Sort by columns (then rows)
      // Sorting required due to otherwise compacting missing cell (because it tries to compact this cell before cell above/left of it)
      widget.cells.sort((cell1, cell2) {
        int colCompare = cell1.column.compareTo(cell2.column);
        return colCompare == 0 ? cell1.row.compareTo(cell2.row) : colCompare;
      });
      // Compact columns
      _compactColumn();
      if (widget.compactingStrategy ==
          SpannableGridCompactingStrategy.columnFirst) {
        // Compact rows
        _compactRow();
      }
    }
  }

  void _addEmptyCellsAndChildren() {
    for (int column = 1; column <= widget.columns; column++) {
      for (int row = 1; row <= widget.rows; row++) {
        String id = 'SpannableCell-$column-$row';
        _cells[id] = SpannableGridCellData(
            id: id, child: null, column: column, row: row);
        _children.add(LayoutId(
          id: id,
          child: SpannableGridEmptyCellView(
            data: _cells[id]!,
            style: widget.style,
            content: widget.emptyCellView,
            isEditing: _isEditing,
            onAccept: (data) {
              setState(() {
                if (_cellSize != null) {
                  int dragColumnOffset =
                      _dragLocalPosition!.dx ~/ _cellSize!.width;
                  int dragRowOffset =
                      _dragLocalPosition!.dy ~/ _cellSize!.height;
                  data.column = column - dragColumnOffset;
                  data.row = row - dragRowOffset;
                  _updateCellsAndChildren();
                }
              });
            },
            onWillAccept: (data) {
              if (_dragLocalPosition != null && _cellSize != null) {
                int dragColumnOffset =
                    _dragLocalPosition!.dx ~/ _cellSize!.width;
                int dragRowOffset = _dragLocalPosition!.dy ~/ _cellSize!.height;
                final minY = row - dragRowOffset;
                final maxY = row - dragRowOffset + _editingCell!.rowSpan - 1;
                for (int y = minY; y <= maxY; y++) {
                  final minX = column - dragColumnOffset;
                  final maxX =
                      column - dragColumnOffset + _editingCell!.columnSpan - 1;
                  for (int x = minX; x <= maxX; x++) {
                    if (y - 1 < 0 ||
                        y > widget.rows ||
                        x - 1 < 0 ||
                        x > widget.columns) {
                      return false;
                    }
                    if (!_availableCells[y - 1][x - 1]) {
                      return false;
                    }
                  }
                }
                return true;
              }
              return false;
            },
          ),
        ));
      }
    }
  }

  void _addContentCells() {
    for (SpannableGridCellData cell in widget.cells) {
      _cells[cell.id] = cell;
    }
  }

  void _addContentChildren() {
    for (SpannableGridCellData cell in widget.cells) {
      Widget child = SpannableGridCellView(
        data: cell,
        editingStrategy: widget.editingStrategy,
        style: widget.style,
        isEditing: _isEditing,
        isSelected: cell.id == _editingCell?.id,
        canMove: widget.editingStrategy.moveOnlyToNearby
            ? _canMoveNearby(cell)
            : true,
        onDragStarted: (localPosition) => _dragLocalPosition = localPosition,
        onDragUpdated: (details) {
          // TODO both local and globalPosition return global position (on whole screen including appbar etc)
          // scrollController.position.viewportDimension gives the height of the scrollable container
          // -> Somehow we need to get size of content above grid (appbar and other widgets)
          //    FOR TESTING: AppBar: 80, BigGridBtn: 64
          // TODO for this we need context of scrollView:
          // -> Convert localPos to global
          // -> Convert this new global to scrollviewContext.globalToLocal()
          RenderObject? renderBox = context.findRenderObject();
          Offset localPosition =
              (renderBox! as RenderBox).globalToLocal(details.globalPosition);
          //print("LOCAL POS: ${localPosition.dy}");
          //print(widget.scrollController.offset);
          //print(widget.scrollController.position.extentBefore);
          //print(widget.scrollController.position.viewportDimension);
          //print("localPosition: ${localPosition.dy}");
          // TODO THIS HAS ONE ISSUE AND ONE OPTIMIZATION:
          // ISSUE: This stops when no longer dragging (-> need to "wiggle" to continue scrolling)
          // OPTIMIZATION: Scroll faster the closer to edge
          //    -> map range [widget.scrollController.position.viewportDimension - _scrollStartOffset, widget.scrollController.position.viewportDimension] to [0, 1]
          //    -> scale scrollSpeed depending on this
          // f(x) = (x - input_start) / (input_end - input_start) * (output_end - output_start) + output_start
          // TODO +64.0 DUE TO BigGridBTN IN DEMO -> MOVING SingleChildScrollView INSIDE HERE WOULD FIX THIS (BTN NO LONGER CONTAINED)
          if (localPosition.dy + 64.0 >=
              widget.scrollController.position.viewportDimension -
                  _scrollStartOffset) {
            // TODO THIS IMMEDIATELY SCROLLS DOWN WHEN STARTING IN THE MIDDLE OF THE SCROLL
            // TODO investigate changing this to use a timer triggering every X ms that jumpsTo a little bit down
            //  (this method cancels timer and creates new, while stopping simply cancels it)
            print("SCROLL DOWN");
            // Start/Continue scrolling
            if (!_isScrolling) {
              // Scroll to bottom of scrollbar with calculated velocity
              double toTravel =
                  widget.scrollController.position.maxScrollExtent -
                      widget.scrollController.offset;
              widget.scrollController.animateTo(
                widget.scrollController.position.maxScrollExtent,
                duration:
                    Duration(seconds: (toTravel / pixelPerSecond).round()),
                curve: Curves.linear,
              );
              setState(() {
                _isScrolling = true;
              });
            }
          } else if (localPosition.dy + 64.0 <= // TODO handle scroll up
              widget.scrollController.position.extentBefore +
                  _scrollStartOffset) {
            // TODO investigate changing this to use a timer triggering every X ms that jumpsTo a little bit down
            //  (this method cancels timer and creates new, while stopping simply cancels it)
            print("SCROLL UP");
            // Scroll to bottom of scrollbar with calculated velocity
            double toTravel = widget.scrollController.offset -
                widget.scrollController.position.minScrollExtent;
            widget.scrollController.animateTo(
              widget.scrollController.position.minScrollExtent,
              duration: Duration(seconds: (toTravel / pixelPerSecond).round()),
              curve: Curves.linear,
            );
            setState(() {
              _isScrolling = true;
            });
          } else {
            print("SCROLL STOP");
            // Stop scrolling (if still scrolling)
            // TODO exitEditing also has to stop scrolling
            if (_isScrolling) {
              widget.scrollController.position.hold(() {});
              setState(() {
                _isScrolling = false;
              });
            }
          }
        },
        onEnterEditing: () => _onEnterEditing(cell),
        onExitEditing: _onExitEditing,
        size: _cellSize == null
            ? const Size(0.0, 0.0)
            : Size(
                cell.columnSpan * _cellSize!.width - widget.style.spacing * 2,
                cell.rowSpan * _cellSize!.height - widget.style.spacing * 2),
      );
      _children.add(LayoutId(
        id: cell.id,
        child: child,
      ));
    }
  }

  void _calculateAvailableCells() {
    _availableCells.clear();
    for (int row = 1; row <= widget.rows; row++) {
      var rowCells = <bool>[];
      for (int column = 1; column <= widget.columns; column++) {
        rowCells.add(true);
      }
      _availableCells.add(rowCells);
    }
    for (SpannableGridCellData cell in _cells.values) {
      // Skip empty cells (grid background) and selected cell
      if (cell.child == null || cell.id == _editingCell?.id) continue;
      for (int row = cell.row; row <= cell.row + cell.rowSpan - 1; row++) {
        for (int column = cell.column;
            column <= cell.column + cell.columnSpan - 1;
            column++) {
          _availableCells[row - 1][column - 1] = false;
        }
      }
    }
  }

  bool _canMoveNearby(SpannableGridCellData cell) {
    final minColumn = cell.column;
    final maxColumn = cell.column + cell.columnSpan - 1;
    final minRow = cell.row;
    final maxRow = cell.row + cell.rowSpan - 1;
    // Check top
    if (cell.row > 1) {
      bool sideResult = true;
      for (int column = minColumn; column <= maxColumn; column++) {
        if (!_availableCells[cell.row - 2][column - 1]) {
          sideResult = false;
          break;
        }
      }
      if (sideResult) return true;
    }
    // Bottom
    if (cell.row + cell.rowSpan - 1 < widget.rows) {
      bool sideResult = true;
      for (int column = minColumn; column <= maxColumn; column++) {
        if (!_availableCells[cell.row + cell.rowSpan - 1][column - 1]) {
          sideResult = false;
          break;
        }
      }
      if (sideResult) return true;
    }
    // Left
    if (cell.column > 1) {
      bool sideResult = true;
      for (int row = minRow; row <= maxRow; row++) {
        if (!_availableCells[row - 1][cell.column - 2]) {
          sideResult = false;
          break;
        }
      }
      if (sideResult) return true;
    }
    // Right
    if (cell.column + cell.columnSpan - 1 < widget.columns) {
      bool sideResult = true;
      for (int row = minRow; row <= maxRow; row++) {
        if (!_availableCells[row - 1][cell.column + cell.columnSpan - 1]) {
          sideResult = false;
          break;
        }
      }
      if (sideResult) return true;
    }
    return false;
  }
}
