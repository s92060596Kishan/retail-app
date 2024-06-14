import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skilltest/screens/addrecord.dart';
import 'package:skilltest/screens/home_screen.dart';

class DetailsScreen extends StatefulWidget {
  final String columnTitle;
  final List<Map<String, dynamic>> filteredData;

  const DetailsScreen({
    required this.columnTitle,
    required this.filteredData,
  });

  @override
  _DetailsScreenState createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  late int showingTooltip;

  @override
  void initState() {
    showingTooltip = -1;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print(widget.filteredData);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Details',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blueGrey,
       
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: widget.filteredData.isEmpty
                  ? Center(
                      child: Text('No data found'),
                    )
                  : Container(
                      padding: EdgeInsets.all(20),
                      child: DataTableWidget(
                        filteredData: widget.filteredData,
                        columnTitle: widget.columnTitle,
                      ),
                    ),
            ),
          ),
          SizedBox(height: 20), // Add spacing between table and chart
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: widget.filteredData.isEmpty
                      ? Center(
                          //child: Text('No data found'),
                          )
                      : BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: _getMaxValue(widget.filteredData),
                            titlesData: FlTitlesData(
                              bottomTitles: SideTitles(
                                showTitles: true,
                                getTextStyles: (value) => const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                margin: 10,
                                getTitles: (value) {
                                  int index = value.toInt();
                                  if (index >= 0 &&
                                      index < widget.filteredData.length) {
                                    // Get the title from the data
                                    String title = widget.filteredData[index]
                                            ['title']
                                        .toString();
                                    // Truncate long titles
                                    if (title.length > 7) {
                                      return title.substring(0, 7) + '...';
                                    } else {
                                      return title;
                                    }
                                  } else {
                                    return '';
                                  }
                                },
                              ),
                              leftTitles: SideTitles(
                                showTitles: true,
                                getTextStyles: (value) => const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                margin: 10,
                                reservedSize: 50,
                                getTitles: (value) {
                                  return value.toString();
                                },
                              ),
                            ),
                            borderData: FlBorderData(
                              show: true,
                            ),
                            barGroups: _getBarGroups(widget.filteredData),
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                tooltipBgColor: Colors.blueGrey,
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                  String title = widget
                                      .filteredData[group.x.toInt()]['title']
                                      .toString();
                                  String date = widget
                                      .filteredData[group.x.toInt()]['date']
                                      .toString();
                                  String value = widget
                                      .filteredData[group.x.toInt()]['value']
                                      .toString();
                                  return BarTooltipItem(
                                    title +
                                        '\n' +
                                        date +
                                        '\n' +
                                        '${widget.columnTitle}  : ' +
                                        value,
                                    TextStyle(color: Colors.white),
                                  );
                                },
                              ),
                              touchCallback: (barTouchResponse) {
                                setState(() {
                                  if (barTouchResponse.spot != null &&
                                      barTouchResponse.touchInput
                                          is! PointerUpEvent &&
                                      barTouchResponse.touchInput
                                          is! PointerExitEvent) {
                                    showingTooltip = barTouchResponse
                                        .spot!.touchedBarGroupIndex;
                                  } else {
                                    showingTooltip = -1;
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxValue(List<Map<String, dynamic>> data) {
    double maxValue = 0;
    for (var item in data) {
      if (item['value'] > maxValue) {
        maxValue = item['value'].toDouble();
      }
    }
    return maxValue;
  }

  List<BarChartGroupData> _getBarGroups(List<Map<String, dynamic>> data) {
    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < data.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              y: data[i]['value'].toDouble(),
              colors: [Colors.blue],
            ),
          ],
        ),
      );
    }
    return barGroups;
  }
}
