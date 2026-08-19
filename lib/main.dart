import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const CurrencyApp());
}

class CurrencyApp extends StatelessWidget {
  const CurrencyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kalkulator Kurs',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const CurrencyCalculator(),
    );
  }
}

class CurrencyCalculator extends StatefulWidget {
  const CurrencyCalculator({super.key});

  @override
  State<CurrencyCalculator> createState() => _CurrencyCalculatorState();
}

class _CurrencyCalculatorState extends State<CurrencyCalculator> {
  final TextEditingController amountController =
      TextEditingController(text: '1');

  final List<String> currencies = [
    'IDR',
    'USD',
    'EUR',
    'SGD',
    'MYR',
    'JPY',
    'AUD',
    'GBP',
    'CNY',
    'THB',
  ];

  String fromCurrency = 'USD';
  String toCurrency = 'IDR';

  double? result;
  double? rate;
  bool loading = false;
  String? error;

  Future<void> convertCurrency() async {
  final amount = double.tryParse(
    amountController.text.replaceAll(' ', '').replaceAll(',', '.'),
  );

  if (amount == null) {
    setState(() {
      error = 'Masukkan jumlah yang benar.';
      result = null;
    });
    return;
  }

  setState(() {
    loading = true;
    error = null;
  });

  try {
    final prefs = await SharedPreferences.getInstance();

    final url = Uri.parse(
      'https://open.er-api.com/v6/latest/$fromCurrency',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil kurs.');
    }

    final data = jsonDecode(response.body);

    if (data['result'] != 'success') {
      throw Exception('Data kurs tidak tersedia.');
    }

    final rates = Map<String, dynamic>.from(data['rates']);
    final selectedRate = (rates[toCurrency] as num).toDouble();

    // Simpan kurs terakhir ke HP
    await prefs.setDouble(
      'rate_${fromCurrency}_$toCurrency',
      selectedRate,
    );

    // Simpan waktu pembaruan
    await prefs.setString(
      'rate_time_${fromCurrency}_$toCurrency',
      DateTime.now().toIso8601String(),
    );

    setState(() {
      rate = selectedRate;
      result = amount * selectedRate;
      loading = false;
    });
  } catch (e) {
    // Jika internet tidak tersedia,
    // gunakan kurs terakhir yang tersimpan di HP.
    final prefs = await SharedPreferences.getInstance();

    final savedRate = prefs.getDouble(
      'rate_${fromCurrency}_$toCurrency',
    );

    if (savedRate != null) {
      setState(() {
        rate = savedRate;
        result = amount * savedRate;
        loading = false;
        error = 'Offline: menggunakan kurs terakhir yang tersimpan.';
      });
    } else {
      setState(() {
        loading = false;
        result = null;
        rate = null;
        error =
            'Tidak ada internet dan belum ada kurs yang tersimpan.';
        });
      }
    }
  }

  void swapCurrencies() {
    setState(() {
      final temp = fromCurrency;
      fromCurrency = toCurrency;
      toCurrency = temp;
    });

    convertCurrency();
  }

  @override
  void initState() {
    super.initState();
    convertCurrency();
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalkulator Kurs'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              const Icon(
                Icons.currency_exchange,
                size: 70,
              ),

              const SizedBox(height: 15),

              const Text(
                'Konversi Mata Uang',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Kurs diperbarui dari internet',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),

              const SizedBox(height: 30),

              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Jumlah',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calculate),
                ),
                onSubmitted: (_) => convertCurrency(),
              ),

              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: fromCurrency,
                decoration: const InputDecoration(
                  labelText: 'Dari',
                  border: OutlineInputBorder(),
                ),
                items: currencies.map((currency) {
                  return DropdownMenuItem(
                    value: currency,
                    child: Text(currency),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      fromCurrency = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 12),

              Center(
                child: IconButton(
                  onPressed: swapCurrencies,
                  icon: const Icon(Icons.swap_vert),
                  iconSize: 36,
                  tooltip: 'Tukar mata uang',
                ),
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: toCurrency,
                decoration: const InputDecoration(
                  labelText: 'Ke',
                  border: OutlineInputBorder(),
                ),
                items: currencies.map((currency) {
                  return DropdownMenuItem(
                    value: currency,
                    child: Text(currency),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      toCurrency = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 25),

              ElevatedButton.icon(
                onPressed: loading ? null : convertCurrency,
                icon: const Icon(Icons.refresh),
                label: Text(
                  loading ? 'Mengambil kurs...' : 'KONVERSI',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

              const SizedBox(height: 30),

              if (loading)
                const Center(
                  child: CircularProgressIndicator(),
                ),

              if (error != null)
                Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              if (result != null && !loading)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          '${amountController.text} $fromCurrency',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 10),
                        const Icon(Icons.arrow_downward),
                        const SizedBox(height: 10),
                        Text(
                          '${result!.toStringAsFixed(2)} $toCurrency',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (rate != null) ...[
                          const SizedBox(height: 15),
                          Text(
                            '1 $fromCurrency = ${rate!.toStringAsFixed(6)} $toCurrency',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 25),

              const Text(
                'Kurs dapat berubah dan membutuhkan koneksi internet.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
