import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sudoku',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SudokuScreen(),
    );
  }
}

class SudokuScreen extends StatefulWidget {
  const SudokuScreen({super.key});

  @override
  State<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> {
  // 0 represents an empty cell
  late List<List<int>> board;
  late List<List<bool>> initialPuzzle;

  Point<int>? selectedCell;
  Set<Point<int>> invalidCells = {};

  int lives = 3;
  bool isGameOver = false;
  bool isGameWon = false;

  int score = 0;

  // A sample puzzle. 0 means empty.
  final List<List<int>> samplePuzzle = [
    [5, 3, 0, 0, 7, 0, 0, 0, 0],
    [6, 0, 0, 1, 9, 5, 0, 0, 0],
    [0, 9, 8, 0, 0, 0, 0, 6, 0],
    [8, 0, 0, 0, 6, 0, 0, 0, 3],
    [4, 0, 0, 8, 0, 3, 0, 0, 1],
    [7, 0, 0, 0, 2, 0, 0, 0, 6],
    [0, 6, 0, 0, 0, 0, 2, 8, 0],
    [0, 0, 0, 4, 1, 9, 0, 0, 5],
    [0, 0, 0, 0, 8, 0, 0, 7, 9],
  ];

  // Sudoku Generator
  List<List<int>> _generatePuzzle() {
    List<List<int>> newBoard = List.generate(
      9,
      (_) => List.generate(9, (_) => 0),
    );
    _fillBoard(newBoard); // Generate a full solution

    // Poke holes to create the puzzle
    int holes = 45; // Difficulty: number of empty cells
    Random rand = Random();
    while (holes > 0) {
      int row = rand.nextInt(9);
      int col = rand.nextInt(9);
      if (newBoard[row][col] != 0) {
        newBoard[row][col] = 0;
        holes--;
      }
    }
    return newBoard;
  }

  bool _fillBoard(List<List<int>> board) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (board[r][c] == 0) {
          List<int> numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9]..shuffle();
          for (int num in numbers) {
            if (_isPlacementValid(board, r, c, num)) {
              board[r][c] = num;
              if (_fillBoard(board)) {
                return true;
              }
              board[r][c] = 0; // Backtrack
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  bool _isPlacementValid(List<List<int>> board, int row, int col, int num) {
    for (int i = 0; i < 9; i++) {
      if (board[row][i] == num || board[i][col] == num) return false;
    }
    final boxRowStart = (row ~/ 3) * 3;
    final boxColStart = (col ~/ 3) * 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (board[boxRowStart + i][boxColStart + j] == num) return false;
      }
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    final newPuzzle = _generatePuzzle();
    setState(() {
      board = newPuzzle.map((row) => List<int>.from(row)).toList();
      initialPuzzle = List.generate(
        9,
        (row) => List.generate(9, (col) => board[row][col] != 0),
      );
      selectedCell = null;
      invalidCells.clear();
      score = 0;
      lives = 3;
      isGameOver = false;
      isGameWon = false;
    });
  }

  void _onCellTapped(int row, int col) {
    setState(() {
      if (!initialPuzzle[row][col]) {
        selectedCell = Point(col, row);
      }
    });
  }

  void _onNumberTapped(int number) {
    if (selectedCell == null || isGameOver || isGameWon) return;

    final row = selectedCell!.y;
    final col = selectedCell!.x;

    // Prevent changing a cell that the user has already filled.
    if (board[row][col] != 0) {
      return;
    }

    setState(() {
      board[row][col] = number;
      bool isMoveValid = _isMoveValid(row, col, number);

      if (number != 0 && !isMoveValid) {
        invalidCells.add(Point(col, row));
        score -= 5; // Penalize for incorrect move
        lives--;
        if (lives <= 0) {
          isGameOver = true;
        }
      } else {
        invalidCells.remove(Point(col, row));
        if (number != 0) {
          score += 10; // Reward for correct move
        }
      }

      if (_isBoardCompleteAndCorrect()) {
        isGameWon = true;
      }
    });
  }

  bool _isMoveValid(int row, int col, int number) {
    if (number == 0) return true;

    // Check row
    for (int i = 0; i < 9; i++) {
      if (i != col && board[row][i] == number) return false;
    }

    // Check column
    for (int i = 0; i < 9; i++) {
      if (i != row && board[i][col] == number) return false;
    }

    // Check 3x3 box
    final boxRowStart = (row ~/ 3) * 3;
    final boxColStart = (col ~/ 3) * 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        final r = boxRowStart + i;
        final c = boxColStart + j;
        if (r != row && c != col && board[r][c] == number) return false;
      }
    }

    return true;
  }

  bool _isBoardCompleteAndCorrect() {
    if (invalidCells.isNotEmpty) return false;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (board[r][c] == 0) return false; // Found an empty cell
      }
    }
    return true; // All cells are filled and no invalid moves are marked
  }

  Widget _buildOverlay(String title, String buttonText, Color color) {
    return Container(
      color: Colors.black.withOpacity(0.75),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _resetGame, child: Text(buttonText)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Sudoku'),
            Text('Score: $score', style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 9,
                          ),
                      itemCount: 81,
                      itemBuilder: (context, index) {
                        final row = index ~/ 9;
                        final col = index % 9;
                        final cellValue = board[row][col];
                        final isInitial = initialPuzzle[row][col];
                        final isSelected =
                            selectedCell != null &&
                            selectedCell!.x == col &&
                            selectedCell!.y == row;
                        final isInvalid = invalidCells.contains(
                          Point(col, row),
                        );
                        bool isHighlighted = false;
                        if (selectedCell != null && !isSelected) {
                          if (row == selectedCell!.y ||
                              col == selectedCell!.x ||
                              (row ~/ 3 == selectedCell!.y ~/ 3 &&
                                  col ~/ 3 == selectedCell!.x ~/ 3)) {
                            isHighlighted = true;
                          }
                        }

                        // Determine border for 3x3 subgrids
                        final border = Border(
                          top: BorderSide(
                            width: row % 3 == 0 ? 2.0 : 0.5,
                            color: Colors.black,
                          ),
                          left: BorderSide(
                            width: col % 3 == 0 ? 2.0 : 0.5,
                            color: Colors.black,
                          ),
                          right: BorderSide(
                            width: col == 8 ? 2.0 : 0.5,
                            color: Colors.black,
                          ),
                          bottom: BorderSide(
                            width: row == 8 ? 2.0 : 0.5,
                            color: Colors.black,
                          ),
                        );

                        return GestureDetector(
                          onTap: () => _onCellTapped(row, col),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isInvalid
                                  ? Colors.red.shade200
                                  : isSelected
                                  ? Colors.blue.shade100
                                  : isHighlighted
                                  ? Colors.grey.shade200
                                  : Colors.white,
                              border: border,
                            ),
                            child: Center(
                              child: Text(
                                cellValue == 0 ? '' : '$cellValue',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: isInitial
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isInitial
                                      ? Colors.black
                                      : Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 24.0,
                ),
                child: Column(
                  children: [
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        ...List.generate(9, (index) {
                          final number = index + 1;
                          return SizedBox(
                            width: 60,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: () => _onNumberTapped(number),
                              child: Text(
                                '$number',
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: 128,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: _resetGame,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Restart'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade400,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isGameOver)
            _buildOverlay('Game Over', 'Try Again', Colors.red.shade400),
          if (isGameWon)
            _buildOverlay('You Won!', 'Play Again', Colors.green.shade400),
        ],
      ),
    );
  }
}
