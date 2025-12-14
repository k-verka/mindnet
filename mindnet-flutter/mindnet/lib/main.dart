// main.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MindnetApp());
}

class MindnetApp extends StatelessWidget {
  const MindnetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mindnet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const MainScreen(
        token: 'mock-token-for-dev',
        userName: 'Developer',
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final String token;
  final String userName;

  const MainScreen({
    super.key,
    required this.token,
    required this.userName,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const ContactsScreen(),
          CollectionsScreen(token: widget.token),
          ProfileScreen(userName: widget.userName),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Контакты',
          ),
          NavigationDestination(
            icon: Icon(Icons.collections_bookmark_outlined),
            selectedIcon: Icon(Icons.collections_bookmark),
            label: 'Коллекции',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}

// ============= GRID NODE =============

class GridNode {
  final String id;
  final int x; // 1-10 (horizontal position)
  final int y; // 1-10 (vertical position, time)
  final String? parentId;
  final Color color;

  GridNode({
    required this.id,
    required this.x,
    required this.y,
    this.parentId,
    this.color = Colors.red,
  });

  String get timeLabel {
    final hour = y.toString().padLeft(2, '0');
    return '$hour:00';
  }
}

// ============= КОЛЛЕКЦИИ =============

class CollectionsScreen extends StatefulWidget {
  final String token;

  const CollectionsScreen({super.key, required this.token});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  List<GridNode> nodes = [];
  String? selectedNodeId;

  @override
  void initState() {
    super.initState();
    _initializeWithStartNode();
  }

  void _initializeWithStartNode() {
    // Начинаем с одной ноды в центре внизу (5, 1)
    nodes = [
      GridNode(
        id: '0',
        x: 5,
        y: 1,
        parentId: null,
        color: Colors.red,
      ),
    ];
  }

  void _addNode() {
    if (selectedNodeId == null) {
      // Если ничего не выбрано — добавляем в конец основной линии
      final lastMainNode = nodes.where((n) => n.x == 5).reduce(
            (a, b) => a.y > b.y ? a : b,
          );
      
      setState(() {
        nodes.add(GridNode(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          x: 5,
          y: lastMainNode.y + 1,
          parentId: lastMainNode.id,
          color: Colors.red,
        ));
      });
    } else {
      // Выбрана нода — создаём ответвление
      final parent = nodes.firstWhere((n) => n.id == selectedNodeId);
      
      // Определяем направление ответвления
      // Сначала проверяем есть ли уже дети справа/слева
      final childrenAtSameY = nodes.where((n) => 
        n.parentId == parent.id && n.y == parent.y
      ).toList();
      
      int newX;
      if (childrenAtSameY.isEmpty) {
        // Первое ответвление — идём вправо
        newX = parent.x + 1;
      } else {
        // Есть дети — находим свободное место
        final occupiedX = childrenAtSameY.map((n) => n.x).toSet();
        newX = parent.x + 1;
        while (occupiedX.contains(newX) && newX <= 10) {
          newX++;
        }
        // Если справа нет места — идём влево
        if (newX > 10) {
          newX = parent.x - 1;
          while (occupiedX.contains(newX) && newX >= 1) {
            newX--;
          }
        }
      }
      
      if (newX >= 1 && newX <= 10) {
        setState(() {
          nodes.add(GridNode(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            x: newX,
            y: parent.y,
            parentId: parent.id,
            color: Colors.orange,
          ));
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      body: SafeArea(
        child: Stack(
          children: [
            // Header
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'node',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    DateFormat('dd MMM').format(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

            // Title
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daily',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    DateFormat('dd MMM').format(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // Graph
            Positioned.fill(
              top: 120,
              bottom: 0,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onTapUp: (details) {
                      final tapPosition = details.localPosition;
                      _handleTap(tapPosition, constraints.maxWidth, constraints.maxHeight);
                    },
                    child: CustomPaint(
                      painter: GridGraphPainter(
                        nodes: nodes,
                        selectedNodeId: selectedNodeId,
                      ),
                      child: Container(),
                    ),
                  );
                },
              ),
            ),

            // Time labels
            Positioned(
              left: 10,
              top: 130,
              bottom: 10,
              child: _buildTimeLabels(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNode,
        backgroundColor: Colors.red,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _handleTap(Offset tapPosition, double width, double height) {
    // Calculate grid cell size
    final cellWidth = (width - 80) / 10; // 80 = padding for time labels
    final cellHeight = (height - 40) / 10; // 40 = padding top/bottom

    String? tappedNodeId;

    for (final node in nodes) {
      final nodeScreenX = 80 + (node.x - 1) * cellWidth + cellWidth / 2;
      final nodeScreenY = height - 20 - (node.y - 1) * cellHeight - cellHeight / 2;

      final distance = (Offset(nodeScreenX, nodeScreenY) - tapPosition).distance;
      if (distance < 25) {
        tappedNodeId = node.id;
        break;
      }
    }

    setState(() {
      selectedNodeId = tappedNodeId;
    });
  }

  Widget _buildTimeLabels() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(10, (index) {
        final y = 10 - index;
        return Text(
          '${y.toString().padLeft(2, '0')}:00',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        );
      }),
    );
  }
}

// ============= GRAPH PAINTER =============

class GridGraphPainter extends CustomPainter {
  final List<GridNode> nodes;
  final String? selectedNodeId;

  GridGraphPainter({
    required this.nodes,
    this.selectedNodeId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = (size.width - 80) / 10;
    final cellHeight = (size.height - 40) / 10;

    // Helper function to convert grid coords to screen coords
    Offset gridToScreen(int x, int y) {
      final screenX = 80 + (x - 1) * cellWidth + cellWidth / 2;
      final screenY = size.height - 20 - (y - 1) * cellHeight - cellHeight / 2;
      return Offset(screenX, screenY);
    }

    // Draw grid (optional, subtle)
    final gridPaint = Paint()
      ..color = Colors.black12
      ..strokeWidth = 0.5;

    for (int i = 1; i <= 10; i++) {
      // Vertical lines
      final x = 80 + (i - 1) * cellWidth;
      canvas.drawLine(
        Offset(x, 20),
        Offset(x, size.height - 20),
        gridPaint,
      );
      
      // Horizontal lines
      final y = size.height - 20 - (i - 1) * cellHeight;
      canvas.drawLine(
        Offset(80, y),
        Offset(size.width - 20, y),
        gridPaint,
      );
    }

    // Draw connections first
    final linePaint = Paint()
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final node in nodes) {
      if (node.parentId != null) {
        final parent = nodes.firstWhere((n) => n.id == node.parentId);
        final parentPos = gridToScreen(parent.x, parent.y);
        final nodePos = gridToScreen(node.x, node.y);

        linePaint.color = node.color;

        if (node.y == parent.y) {
          // Horizontal branch
          canvas.drawLine(parentPos, nodePos, linePaint);
        } else {
          // Vertical continuation
          canvas.drawLine(parentPos, nodePos, linePaint);
        }
      }
    }

    // Draw nodes
    for (final node in nodes) {
      final position = gridToScreen(node.x, node.y);
      final isSelected = node.id == selectedNodeId;

      // Shadow
      final shadowPaint = Paint()
        ..color = node.color.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(position, 22, shadowPaint);

      // Node
      final nodePaint = Paint()
        ..color = node.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(position, 20, nodePaint);

      // Selection ring
      if (isSelected) {
        final selectionPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawCircle(position, 26, selectionPaint);
      }
    }
  }

  @override
  bool shouldRepaint(GridGraphPainter oldDelegate) {
    return oldDelegate.selectedNodeId != selectedNodeId ||
        oldDelegate.nodes.length != nodes.length;
  }
}

// ============= ЗАГЛУШКИ =============

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Контакты')),
      body: const Center(child: Text('Coming soon')),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  final String userName;

  const ProfileScreen({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: const Center(child: Text('Coming soon')),
    );
  }
}