// ------------------ Smart Irrigation & Fertilizer AI Screen ------------------

void main() => runApp(KrishiBandhuApp());

class IrrigationFertilizerScreen extends StatefulWidget {
  @override
  _IrrigationFertilizerScreenState createState() => _IrrigationFertilizerScreenState();
}

class _IrrigationFertilizerScreenState extends State<IrrigationFertilizerScreen> {
  double moisture = 45; // percent
  double ph = 6.5;
  bool autoMode = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('💧 Smart Irrigation & Fertilizer')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Soil status summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Soil Status', style: TextStyle(fontWeight: FontWeight.bold)), SizedBox(height: 6), Text('Moisture: ${moisture.toStringAsFixed(0)}%\nPH: ${ph.toStringAsFixed(1)}\nNutrients: N:Medium, P:Low, K:Medium', style: TextStyle(color: Colors.grey[700]))]),
                    Spacer(),
                    Icon(Icons.thermostat),
                  ],
                ),
              ),
            ),

            SizedBox(height: 12),
            // Smart gauge (simple circular indicator)
            Container(
              height: 160,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CircularProgressIndicator(
                        value: moisture / 100,
                        strokeWidth: 16,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${moisture.toStringAsFixed(0)}%', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        Text('Soil Moisture')
                      ],
                    )
                  ],
                ),
              ),
            ),

            SizedBox(height: 12),
            // Fertilizer recommendation
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fertilizer Recommendation', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Apply 20 kg N, 10 kg P per hectare. Use urea blended fertilizer at seeding.'),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(onPressed: () {}, icon: Icon(Icons.play_arrow), label: Text('Start Irrigation')),
                        SizedBox(width: 8),
                        OutlinedButton.icon(onPressed: () {}, icon: Icon(Icons.history), label: Text('View Past Reports')),
                      ],
                    )
                  ],
                ),
              ),
            ),

            SizedBox(height: 12),
            // Irrigation control
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Irrigation Control', style: TextStyle(fontWeight: FontWeight.bold)), SizedBox(height: 6), Text(autoMode ? 'Auto Mode' : 'Manual Mode')]),
                    Spacer(),
                    Switch(value: autoMode, onChanged: (v) => setState(() => autoMode = v)),
                    SizedBox(width: 8),
                    ElevatedButton(onPressed: () {}, child: Text('Toggle ON/OFF'))
                  ],
                ),
              ),
            ),

            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(onPressed: () {}, icon: Icon(Icons.help_outline), label: Text('Ask Assistant')),
                TextButton.icon(onPressed: () {}, icon: Icon(Icons.save_alt), label: Text('Download Report')),
              ],
            )
          ],
        ),
      ),
    );
  }
}