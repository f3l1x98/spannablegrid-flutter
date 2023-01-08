import 'dart:math';

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
  final GlobalKey rootKey = GlobalKey();
  //final _availableCells = <List<bool>>[];
  // Maps the grid to the id of the CellData in this cell (or null if empty)
  final _grid = <List<Object?>>[];

  final _cells = <Object, SpannableGridCellData>{};

  final _children = <Widget>[];

  Size? _cellSize;

  bool _isEditing = false;

  SpannableGridCellData? _editingCell;

  // When dragging started, contains a relative position of the pointer in the
  // dragging widget
  Offset? _dragLocalPosition;

  // When dragging this stores the row and col above the dragging widget currently hovers
  // dx is the column and dy the row
  Offset? _dragLastHoverCellPosition;

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
        key: rootKey,
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

  // TODO check if optimizing with new _grid is possible (iterating over _grid is bad in case of many empty cells)
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
          bool rowOccupied = _grid[rowAbove]
              .getRange(currentCellColumnStart, currentCellColumnEnd)
              .any((element) => element != null);
          if (!rowOccupied) {
            // Move cell up (update _availableCells and cell.row)
            for (int i = currentCellColumnStart;
                i < currentCellColumnEnd;
                i++) {
              _grid[rowAbove][i] = cell.id;
              // Mark row below as available
              _grid[currentCellRowEnd - 1][i] = null;
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

  // TODO check if optimizing with new _grid is possible (iterating over _grid is bad in case of many empty cells)
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
          bool columnOccupied = _grid
              .getRange(currentCellRowStart, currentCellRowEnd)
              .any((element) => element[columnLeft] != null);
          if (!columnOccupied) {
            // Move cell left (update _availableCells and cell.column)
            for (int i = currentCellRowStart; i < currentCellRowEnd; i++) {
              _grid[i][columnLeft] = cell.id;
              // Mark row below as available
              _grid[i][currentCellColumnEnd - 1] = null;
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
                    if (!_isCellAvailable(x - 1, y - 1)) {
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
          RenderBox? box =
              rootKey.currentContext?.findRenderObject() as RenderBox?;
          if (box != null && _cellSize != null) {
            Offset boxLocal = box.globalToLocal(details.globalPosition);

            // Check if above root container
            if (boxLocal.dx >= 0.0 && boxLocal.dy >= 0.0) {
              // Get column and row of cell the pointer is above
              int col = boxLocal.dx ~/ _cellSize!.width;
              int row = boxLocal.dy ~/ _cellSize!.height;
              print("(Row, Col) = (${row}, ${col})");

              // Check if above new cell
              if (_dragLastHoverCellPosition != null &&
                  (_dragLastHoverCellPosition!.dx != col ||
                      _dragLastHoverCellPosition!.dy != row)) {
                _dragLastHoverCellPosition =
                    Offset(col.toDouble(), row.toDouble());

                // TODO IDEA: JUST F IT AND PUSH EVERYTHING DOWN BY ROWSPAN
                // Check if enough space where placed
                if (!_canCellBePlacedAt(col, row, cell)) {
                  // Not enough space -> push other cells aside IF POSSIBLE

                  // Get list of all cells that block this space
                  Set<Object> blockingCellIds = {};
                  for (int r = row; r < row + cell.rowSpan; r++) {
                    for (int c = col; c < col + cell.columnSpan; c++) {
                      Object? cellId = _grid[r][c];
                      if (cellId != null) {
                        blockingCellIds.add(cellId);
                      }
                    }
                  }
                  // TODO each of this blocking cells has to be moved cell.rowSpan + THE NUMBER OF ROWS IT STARTS ABOVE row
                  int startRowOfLargestBlockingCell =
                      blockingCellIds.map((e) => _cells[e]!.row).reduce(min) -
                          1;
                  int requiredToPushAdditionally =
                      row - startRowOfLargestBlockingCell;
                  int totalRequiredToPush =
                      requiredToPushAdditionally + cell.rowSpan;

                  // TODO check if the blocking cells can be moved up (only them, not all cells above as well)

                  // Check if enough space at bottom
                  // TODO NOT ONLY BY cell.rowSpan BUT ALSO POTENTIALLY MORE IF A CELL THAT OCCUPIES THIS PLACE ALSO OCCUPIES SPACE ABOVE
                  bool notEnoughSpace = _grid
                      .getRange(
                          _grid.length - totalRequiredToPush, _grid.length)
                      .any((list) => list.any((element) => element != null));
                  if (!notEnoughSpace) {
                    // Move everything down by cell.rowSpan
                    // Store already updated cells inorder to prevent updating multiple times (happens if col- or rowSpan > 1)
                    List<Object> alreadyHandled = [cell.id];
                    for (int rowIndex = widget.rows - 1 - totalRequiredToPush;
                        rowIndex >= row;
                        rowIndex--) {
                      for (int colIndex = 0;
                          colIndex < widget.columns;
                          colIndex++) {
                        var cellId = _grid[rowIndex][colIndex];
                        if (cellId != null &&
                            !alreadyHandled.contains(cellId)) {
                          _cells[cellId]!.row += totalRequiredToPush;
                          alreadyHandled.add(cellId);
                        }
                      }
                    }
                    _updateCellsAndChildren();
                    setState(() {});
                  }
                }

                // Get cell at this pos and calc how/if pushing aside is possible
                // TODO IMPORTANT: THIS WILL BE RECURSIVE (this cell might need to push aside other cells (MULTIPLE AT ONCE))
                // TODO IGNORE DRAGGED CELL FOR THIS ONE (it does not need to be pushed aside)
                // TODO RECURSIVE FUNCTION
                //_pushAside(row, col, cell.rowSpan, cell.columnSpan);
                // TODO UPDATE POS FOR ALL CELLS THAT HAVE TO BE PUSHED ASIDE (SHOULD BE RETURNED BY _pushAside INC INDICATOR WHETHER POSSIBLE AT ALL)
              } else if (_dragLastHoverCellPosition == null) {
                // First time called -> most certainly still above start cell
                // TODO TEST IF THAT IS GUARANTEED
                _dragLastHoverCellPosition =
                    Offset(col.toDouble(), row.toDouble());
              }
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

  // TODO DOC
  // TODO return sth like ids of cells that would need to be adjusted AND bool whether pushing is even possible
  /*bool _pushAside(int row, int col, int pushedRows, int pushedCols) {

    for (int rowIndex = row; rowIndex < row + pushedRows; rowIndex++) {
      for (int colIndex = col; colIndex < col + pushedCols; colIndex++) {
        Object? currentCellId = _grid[rowIndex][colIndex];

        if (currentCellId == null) {
          // Empty -> nothing to do
        } else {
          int rowLeftToPush = pushedRows - (rowIndex - row);
          int colLeftToPush = pushedCols - (colIndex - col);
          _pushAside(, , rowLeftToPush, colLeftToPush);
        }
      }
    }



    // Get all (unique) ids of cells that occupy the required space
    Set<Object?> ids = {};
    for (int i = row; i < row + pushedRows; i++) {
      ids.addAll(_grid[i].getRange(col, col + pushedCols));
    }

    // TODO THIS PROBABLY HAS TO BE DONE IN CERTAIN ORDER
    // (otherwise if 2x2 space is required which is occupied by 1x1 cells -> first cell pushes second cell away which is later pushed again)
    // TODO FINAL UPDATE OF POS SHOULD BE DONE FOR ALL REQUIRED CHILDREN AT THE END OF EVERYTHING 
    //(otherwise some cells will be pushed only to later discover that pushing isn't even possible)
    bool pushingPossible = true;
    for (Object? id in ids) {
      if (id == null) {
        // Empty cell -> done
      } else {
        // Try to move aside
        // Check if this cell could be moved to right (enough space for it to the right of new element)
        // TODO
        // 
        // TODO decide how to push aside (first to right or down (inside row or col))
        // TODO the amount how much to push aside depends on current pos and 
        _pushAside(, , );
      }
    }
  }*/

  // TODO optimize for new _grid instead of _availableCells
  void _calculateAvailableCells() {
    // TODO optimize for new _grid instead of _availableCells
    _grid.clear();
    for (int row = 1; row <= widget.rows; row++) {
      var rowCells = <Object?>[];
      for (int column = 1; column <= widget.columns; column++) {
        rowCells.add(null);
      }
      _grid.add(rowCells);
    }
    for (SpannableGridCellData cell in _cells.values) {
      // Skip empty cells (grid background) and selected cell
      if (cell.child == null || cell.id == _editingCell?.id) continue;
      for (int row = cell.row; row <= cell.row + cell.rowSpan - 1; row++) {
        for (int column = cell.column;
            column <= cell.column + cell.columnSpan - 1;
            column++) {
          _grid[row - 1][column - 1] = cell.id;
        }
      }
    }
  }

  // TODO optimize for new _grid instead of _availableCells
  bool _canMoveNearby(SpannableGridCellData cell) {
    final minColumn = cell.column;
    final maxColumn = cell.column + cell.columnSpan - 1;
    final minRow = cell.row;
    final maxRow = cell.row + cell.rowSpan - 1;
    // Check top
    if (cell.row > 1) {
      bool sideResult = true;
      for (int column = minColumn; column <= maxColumn; column++) {
        if (!_isCellAvailable(column - 1, cell.row - 2)) {
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
        if (!_isCellAvailable(column - 1, cell.row + cell.rowSpan - 1)) {
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
        if (!_isCellAvailable(cell.column - 2, row - 1)) {
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
        if (!_isCellAvailable(cell.column + cell.columnSpan - 1, row - 1)) {
          sideResult = false;
          break;
        }
      }
      if (sideResult) return true;
    }
    return false;
  }

  bool _isCellAvailable(int x, int y) {
    return _grid[y][x] == null;
  }

  bool _canCellBePlacedAt(int x, int y, SpannableGridCellData cell) {
    int rowEnd = y + cell.rowSpan - 1;
    int colEnd = x + cell.columnSpan - 1;
    if (rowEnd >= widget.rows || colEnd >= widget.columns) {
      return false;
    }
    for (int row = y; row <= rowEnd; row++) {
      for (int col = x; col <= colEnd; col++) {
        if (!_isCellAvailable(col, row)) {
          return false;
        }
      }
    }
    return true;
  }
}
