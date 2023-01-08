import 'package:flutter/material.dart';
import 'package:spannable_grid/spannable_grid.dart';

class ScrollViewGrid extends StatefulWidget {
  const ScrollViewGrid({Key? key}) : super(key: key);

  @override
  State<ScrollViewGrid> createState() => _ScrollViewGridState();
}

class _ScrollViewGridState extends State<ScrollViewGrid> {
  // TODO test whether it would be possible to automatically scroll when draggable is at bottom/top of scrollable
  final ScrollController _controller = ScrollController();
  bool _bigGrid = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ScrollView Demo"),
      ),
      body: SingleChildScrollView(
        controller: _controller,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextButton(
                child: const Text('Big grid'),
                onPressed: () {
                  setState(() {
                    _bigGrid = !_bigGrid;
                  });
                },
              ),
            ),
            SpannableGrid(
              scrollController: _controller,
              gridSize: SpannableGridSize.parentWidth,
              cells: _getCells(context),
              columns: 4,
              rows: _bigGrid ? 20 : 10,
              compactingStrategy: SpannableGridCompactingStrategy.rowFirst,
              onCellChanged: (cell) {
                print(_controller.offset);
                print('Cell ${cell!.id} changed');
              },
            ),
          ],
        ),
      ),
    );
  }

  List<SpannableGridCellData> _getCells(BuildContext context) {
    List<SpannableGridCellData> result = [];
    if (_bigGrid) {
      result.addAll([
        SpannableGridCellData(
          column: 1,
          row: 1,
          columnSpan: 2,
          rowSpan: 1,
          id: "Test Cell 1",
          child: Container(
            color: Colors.lightBlueAccent,
            child: Center(
              child: Text(
                "Tile 2x1",
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          ),
        ),
        SpannableGridCellData(
          column: 2,
          row: 2,
          columnSpan: 2,
          rowSpan: 2,
          id: "Test Cell 2",
          child: Container(
            color: Colors.lime,
            child: Center(
              child: Text(
                "Tile 2x2",
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          ),
        ),
        SpannableGridCellData(
          column: 3,
          row: 1,
          columnSpan: 1,
          rowSpan: 1,
          id: "Test Cell 3",
          child: Container(
            color: Colors.lime,
            child: Center(
              child: Text(
                "Tile 1x1",
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          ),
        ),
        SpannableGridCellData(
          column: 1,
          row: 4,
          columnSpan: 4,
          rowSpan: 1,
          id: "Test Cell 4",
          child: Container(
            color: Colors.lightBlueAccent,
            child: Center(
              child: Text(
                "Tile 4x1",
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          ),
        ),
        SpannableGridCellData(
          column: 1,
          row: 5,
          columnSpan: 4,
          rowSpan: 3,
          id: "Test Cell 5",
          child: Container(
            color: Colors.lightBlueAccent,
            child: Center(
              child: Text(
                "Tile 4x3",
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          ),
        ),
        SpannableGridCellData(
          column: 2,
          row: 8,
          columnSpan: 2,
          rowSpan: 3,
          id: "Test Cell 6",
          child: Container(
            color: Colors.lightBlueAccent,
            child: Center(
              child: Text(
                "Tile 4x3",
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          ),
        ),
        SpannableGridCellData(
          column: 1,
          row: 11,
          columnSpan: 1,
          rowSpan: 1,
          id: "Test Cell 7",
          child: Container(
            color: Colors.lime,
            child: Center(
              child: Text(
                "Tile 1x1",
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          ),
        ),
        SpannableGridCellData(
          column: 3,
          row: 11,
          columnSpan: 1,
          rowSpan: 1,
          id: "Test Cell 8",
          child: Container(
            color: Colors.lime,
            child: Center(
              child: Text(
                "Tile 1x1",
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          ),
        ),
        SpannableGridCellData(
          column: 2,
          row: 12,
          columnSpan: 2,
          rowSpan: 1,
          id: "Test Cell 9",
          child: Container(
            color: Colors.lightBlueAccent,
            child: Center(
              child: Text(
                "Tile 2x1",
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          ),
        ),
        SpannableGridCellData(
          column: 4,
          row: 11,
          columnSpan: 1,
          rowSpan: 1,
          id: "Test Cell 10",
          child: Container(
            color: Colors.lime,
            child: Center(
              child: Text(
                "Tile 1x1",
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          ),
        ),
        SpannableGridCellData(
          column: 4,
          row: 12,
          columnSpan: 1,
          rowSpan: 2,
          id: "Test Cell 11",
          child: Container(
            color: Colors.lightBlueAccent,
            child: Center(
              child: Text(
                "Tile 1x2",
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          ),
        ),
        SpannableGridCellData(
          column: 1,
          row: 12,
          columnSpan: 1,
          rowSpan: 1,
          id: "Test Cell 12",
          child: Container(
            color: Colors.lime,
            child: Center(
              child: Text(
                "Tile 1x1",
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          ),
        ),
        SpannableGridCellData(
          column: 2,
          row: 13,
          columnSpan: 2,
          rowSpan: 1,
          id: "Test Cell 13",
          child: Container(
            color: Colors.lightBlueAccent,
            child: Center(
              child: Text(
                "Tile 2x1",
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          ),
        ),
        SpannableGridCellData(
          column: 2,
          row: 14,
          columnSpan: 1,
          rowSpan: 1,
          id: "Test Cell 14",
          child: Container(
            color: Colors.lime,
            child: Center(
              child: Text(
                "Tile 1x1",
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          ),
        ),
        SpannableGridCellData(
          column: 3,
          row: 14,
          columnSpan: 1,
          rowSpan: 1,
          id: "Test Cell 15",
          child: Container(
            color: Colors.lime,
            child: Center(
              child: Text(
                "Tile 2x1",
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          ),
        ),
        SpannableGridCellData(
          column: 3,
          row: 15,
          columnSpan: 2,
          rowSpan: 3,
          id: "Test Cell 16",
          child: Container(
            color: Colors.lightBlueAccent,
            child: Center(
              child: Text(
                "Tile 2x1",
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          ),
        ),
      ]);
    } else {
      result.addAll([
        SpannableGridCellData(
          column: 1,
          row: 1,
          columnSpan: 2,
          rowSpan: 1,
          id: "Test Cell 1",
          child: Container(
            color: Colors.lightBlueAccent,
            child: Center(
              child: Text(
                "Tile 2x1",
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          ),
        ),
        SpannableGridCellData(
          column: 2,
          row: 2,
          columnSpan: 2,
          rowSpan: 2,
          id: "Test Cell 2",
          child: Container(
            color: Colors.lime,
            child: Center(
              child: Text(
                "Tile 2x2",
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          ),
        ),
        SpannableGridCellData(
          column: 3,
          row: 1,
          columnSpan: 1,
          rowSpan: 1,
          id: "Test Cell 3",
          child: Container(
            color: Colors.lime,
            child: Center(
              child: Text(
                "Tile 1x1",
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          ),
        ),
        SpannableGridCellData(
          column: 1,
          row: 4,
          columnSpan: 4,
          rowSpan: 1,
          id: "Test Cell 4",
          child: Container(
            color: Colors.lightBlueAccent,
            child: Center(
              child: Text(
                "Tile 4x1",
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          ),
        ),
        SpannableGridCellData(
          column: 1,
          row: 5,
          columnSpan: 4,
          rowSpan: 3,
          id: "Test Cell 5",
          child: Container(
            color: Colors.lightBlueAccent,
            child: Center(
              child: Text(
                "Tile 4x3",
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          ),
        ),
        SpannableGridCellData(
          column: 2,
          row: 8,
          columnSpan: 2,
          rowSpan: 3,
          id: "Test Cell 6",
          child: Container(
            color: Colors.lightBlueAccent,
            child: Center(
              child: Text(
                "Tile 4x3",
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          ),
        ),
      ]);
    }
    return result;
  }
}
