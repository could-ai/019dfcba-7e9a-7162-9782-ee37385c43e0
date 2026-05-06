import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const SurebetTrackerApp());
}

class SurebetTrackerApp extends StatelessWidget {
  const SurebetTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Surebet Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MainScreen(),
      },
    );
  }
}

// --- Models ---

class Bookmaker {
  String id;
  String name;
  double saldo;
  double depositos;

  Bookmaker({
    required this.id,
    required this.name,
    required this.saldo,
    required this.depositos,
  });

  double get lucro => saldo - depositos;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'saldo': saldo,
        'depositos': depositos,
      };

  factory Bookmaker.fromJson(Map<String, dynamic> json) => Bookmaker(
        id: json['id'],
        name: json['name'],
        saldo: (json['saldo'] as num).toDouble(),
        depositos: (json['depositos'] as num).toDouble(),
      );
}

class HistoryEntry {
  String date;
  double totalSaldo;
  double totalDepositos;
  double totalLucro;

  HistoryEntry({
    required this.date,
    required this.totalSaldo,
    required this.totalDepositos,
    required this.totalLucro,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'totalSaldo': totalSaldo,
        'totalDepositos': totalDepositos,
        'totalLucro': totalLucro,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        date: json['date'],
        totalSaldo: (json['totalSaldo'] as num).toDouble(),
        totalDepositos: (json['totalDepositos'] as num).toDouble(),
        totalLucro: (json['totalLucro'] as num).toDouble(),
      );
}

// --- Main Screen with Bottom Nav ---

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  List<Bookmaker> _bookmakers = [];
  List<HistoryEntry> _history = [];
  bool _isLoading = true;

  final String _bkKey = 'sbt-v104-bookmakers';
  final String _historyKey = 'sbt-v104-history';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Bookmakers
    final bkString = prefs.getString(_bkKey);
    if (bkString != null) {
      final List decoded = jsonDecode(bkString);
      _bookmakers = decoded.map((e) => Bookmaker.fromJson(e)).toList();
    } else {
      // Initial Data
      _bookmakers = [
        Bookmaker(id: '1', name: 'Betclic', saldo: 7.39, depositos: 40.0),
        Bookmaker(id: '2', name: 'Betano', saldo: 422.17, depositos: 240.0),
      ];
      _saveBookmakers();
    }

    // Load History
    final histString = prefs.getString(_historyKey);
    if (histString != null) {
      final List decoded = jsonDecode(histString);
      _history = decoded.map((e) => HistoryEntry.fromJson(e)).toList();
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveBookmakers() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_bookmakers.map((e) => e.toJson()).toList());
    await prefs.setString(_bkKey, encoded);
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_history.map((e) => e.toJson()).toList());
    await prefs.setString(_historyKey, encoded);
  }

  void _recordHistory() {
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    double totalSaldo = _bookmakers.fold(0, (sum, item) => sum + item.saldo);
    double totalDepositos = _bookmakers.fold(0, (sum, item) => sum + item.depositos);
    double totalLucro = totalSaldo - totalDepositos;

    // Remove entry for today if exists to overwrite
    _history.removeWhere((e) => e.date == dateStr);
    
    _history.add(HistoryEntry(
      date: dateStr,
      totalSaldo: totalSaldo,
      totalDepositos: totalDepositos,
      totalLucro: totalLucro,
    ));

    // Sort by date
    _history.sort((a, b) => a.date.compareTo(b.date));
    _saveHistory();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Histórico guardado com sucesso!')),
    );
    setState(() {});
  }

  void _updateBookmaker(Bookmaker bk, String name, double saldo, double depositos) {
    setState(() {
      bk.name = name;
      bk.saldo = saldo;
      bk.depositos = depositos;
    });
    _saveBookmakers();
  }

  void _addBookmaker(String name, double saldo, double depositos) {
    setState(() {
      _bookmakers.add(Bookmaker(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        saldo: saldo,
        depositos: depositos,
      ));
    });
    _saveBookmakers();
  }

  void _deleteBookmaker(Bookmaker bk) {
    setState(() {
      _bookmakers.remove(bk);
    });
    _saveBookmakers();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    double totalSaldo = _bookmakers.fold(0, (sum, item) => sum + item.saldo);
    double totalDepositos = _bookmakers.fold(0, (sum, item) => sum + item.depositos);
    double totalLucro = totalSaldo - totalDepositos;

    final List<Widget> screens = [
      DashboardScreen(
        totalSaldo: totalSaldo,
        totalDepositos: totalDepositos,
        totalLucro: totalLucro,
        history: _history,
        onRecordHistory: _recordHistory,
      ),
      BookmakersListScreen(
        bookmakers: _bookmakers,
        onAdd: _addBookmaker,
        onUpdate: _updateBookmaker,
        onDelete: _deleteBookmaker,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: screens[_currentIndex],
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
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Casas de Apostas',
          ),
        ],
      ),
    );
  }
}

// --- Dashboard Screen ---

class DashboardScreen extends StatelessWidget {
  final double totalSaldo;
  final double totalDepositos;
  final double totalLucro;
  final List<HistoryEntry> history;
  final VoidCallback onRecordHistory;

  const DashboardScreen({
    super.key,
    required this.totalSaldo,
    required this.totalDepositos,
    required this.totalLucro,
    required this.history,
    required this.onRecordHistory,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'pt_PT', symbol: '€');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Visão Geral',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: onRecordHistory,
                icon: const Icon(Icons.save),
                label: const Text('Gravar Dia'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              int columns = constraints.maxWidth > 600 ? 3 : 1;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: columns == 1 ? 3 : 1.5,
                children: [
                  _SummaryCard(
                    title: 'Banca Atual',
                    value: currencyFormatter.format(totalSaldo),
                    icon: Icons.account_balance_wallet,
                    color: Colors.blue,
                  ),
                  _SummaryCard(
                    title: 'Depósitos',
                    value: currencyFormatter.format(totalDepositos),
                    icon: Icons.input,
                    color: Colors.orange,
                  ),
                  _SummaryCard(
                    title: 'Lucro Total',
                    value: currencyFormatter.format(totalLucro),
                    icon: Icons.trending_up,
                    color: totalLucro >= 0 ? Colors.green : Colors.red,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            'Evolução do Lucro',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (history.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: Text('Sem dados no histórico. Grave o dia para ver o gráfico.')),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: 300,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 && value.toInt() < history.length) {
                                // show date as day/month
                                final dateStr = history[value.toInt()].date;
                                final parts = dateStr.split('-');
                                if (parts.length == 3) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text('${parts[2]}/${parts[1]}', style: const TextStyle(fontSize: 10)),
                                  );
                                }
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: history.asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(), e.value.totalLucro);
                          }).toList(),
                          isCurved: true,
                          color: Colors.green,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.green.withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              radius: 24,
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Bookmakers List Screen ---

class BookmakersListScreen extends StatelessWidget {
  final List<Bookmaker> bookmakers;
  final Function(String, double, double) onAdd;
  final Function(Bookmaker, String, double, double) onUpdate;
  final Function(Bookmaker) onDelete;

  const BookmakersListScreen({
    super.key,
    required this.bookmakers,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
  });

  void _showBookmakerDialog(BuildContext context, [Bookmaker? bk]) {
    final nameController = TextEditingController(text: bk?.name ?? '');
    final saldoController = TextEditingController(text: bk?.saldo.toString() ?? '');
    final depositosController = TextEditingController(text: bk?.depositos.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(bk == null ? 'Nova Casa de Apostas' : 'Editar ${bk.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                TextField(
                  controller: saldoController,
                  decoration: const InputDecoration(labelText: 'Saldo Atual'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: depositosController,
                  decoration: const InputDecoration(labelText: 'Depósitos'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final saldo = double.tryParse(saldoController.text.replaceAll(',', '.')) ?? 0.0;
                final depositos = double.tryParse(depositosController.text.replaceAll(',', '.')) ?? 0.0;
                
                if (name.isNotEmpty) {
                  if (bk == null) {
                    onAdd(name, saldo, depositos);
                  } else {
                    onUpdate(bk, name, saldo, depositos);
                  }
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'pt_PT', symbol: '€');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Casas de Apostas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showBookmakerDialog(context),
          ),
        ],
      ),
      body: bookmakers.isEmpty
          ? const Center(child: Text('Sem casas de apostas. Clique no + para adicionar.'))
          : ListView.builder(
              itemCount: bookmakers.length,
              itemBuilder: (context, index) {
                final bk = bookmakers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(bk.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      'Saldo: ${currencyFormatter.format(bk.saldo)} | Depósitos: ${currencyFormatter.format(bk.depositos)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currencyFormatter.format(bk.lucro),
                          style: TextStyle(
                            color: bk.lucro >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _showBookmakerDialog(context, bk),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Confirmar'),
                                content: Text('Tem a certeza que deseja eliminar ${bk.name}?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      onDelete(bk);
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBookmakerDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
