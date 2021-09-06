import 'dart:convert';

import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyApp(),
    )
  );
}

class MyApp extends StatefulWidget {
  const MyApp({ Key? key }) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  BluetoothPrint bluetoothPrint = BluetoothPrint.instance;

  String tips = 'no service connected';
  bool _connected = false;
  late List<BluetoothDevice> _devices = [];
  late List<BluetoothDevice> _selectedPrinter = [];

  @override
  void initState() {
    super.initState();

    bluetoothPrint.scanResults.listen((devices) async{
      setState(() {
        _devices = devices;
      });
    });
    _startScanDevices();
  }

  void _startScanDevices() async{
    setState(() {
      _devices = [];
    });
    bluetoothPrint.startScan(timeout: Duration(seconds: 4));
    bool? isConnected = await bluetoothPrint.isConnected;

    bluetoothPrint.state.listen((state) {
      switch (state) {
        case BluetoothPrint.CONNECTED:
        setState(() {
          _connected = true;
          tips = 'connect success';
        });
        break;
        case BluetoothPrint.DISCONNECTED:
        setState(() {
          _connected = false;
          tips = 'disconnect success';
        });
        break;
        default:
        break;
      }
    });

    if(!mounted) return;

    if(isConnected != null && isConnected) {
      setState(() {
        _connected = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Printer Example App'),
      ),
      body: StreamBuilder<List<BluetoothDevice>>(
        stream: bluetoothPrint.scanResults,
        builder: (_, snapshot){
          if(snapshot.hasData) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 9,
                  child: Column(
                    children: [
                      Container(
                        alignment: Alignment.center,
                        width: double.infinity,
                        height: 50.0,
                        child: InkWell(
                          onTap: () => _openDialog(context),
                          child: Text(_devices.length == 0 ? '*** No se encontraron dispositivos ***' : 'Se encontraron ${_devices.length} dispositivos.'),
                        ),
                      ),
                      Container(
                        alignment: Alignment.center,
                        width: double.infinity,
                        color: Colors.pinkAccent,
                        height: 50.0,
                        child: InkWell(
                          onTap: () => _openDialog(context),
                          child: Text('SELECCIONAR IMPRESORA'),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          alignment: Alignment.center,
                          child: Text(_selectedPrinter.length > 0 ? _selectedPrinter[0].name.toString() : 'Ninguna impresora seleccionada', style: TextStyle( fontSize: 18.0) ),
                        ),
                      ),                    
                    ],
                  )
                ),
                Flexible(
                  child: InkWell(
                    onTap: (){
                      print(_connected);
                      _connected == true ? _printTest() : _printSnackBar(context, 'DEBE SELECCIONAR UN DISPOSITIVO DE IMPRESIÓN');
                    },
                    child: Container(
                      alignment: Alignment.center,
                      color: Colors.greenAccent,
                      width: double.infinity,
                      child: Text('IMPRIMIR', style: TextStyle( fontWeight: FontWeight.bold),),
                    ),
                  )
                ),
              ],
            );
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: StreamBuilder(
        stream: bluetoothPrint.isScanning,
        initialData: false,
        builder: (_, snapshot){
          if(snapshot.hasData && snapshot.data == true){
            return FloatingActionButton(
              onPressed: () => bluetoothPrint.stopScan(),
              child: Icon(Icons.stop),
              backgroundColor: Colors.redAccent,
            );
          }else{
            return FloatingActionButton(
              onPressed: () => _startScanDevices(),
              child: Icon(Icons.search),
            );
          }
        },
      ),
    );
  }

  Future _openDialog (BuildContext _context){
    return showDialog(
      context: _context,
      builder: (_) => CupertinoAlertDialog(
        title: Column(
          children: [
            Text("Seleccione el dispositivo de impresion a conectar"),
            SizedBox(height: 15.0,),
          ],
        ),
        content: _setupDialogContainer(_context),
        actions: [
          TextButton(
            onPressed: (){
              Navigator.of(_context).pop();
            },
            child: Text('Cerrar')
          )
        ],
      )
    );
  }

  Widget _setupDialogContainer (BuildContext _context){
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 200.0,
          width: 300.0,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _devices.length,
            itemBuilder: (BuildContext _context, int index){
              return GestureDetector(
                onTap: () async {
                  await bluetoothPrint.connect(_devices[index]);
                  setState(() {
                    _selectedPrinter.add(_devices[index]);
                  });
                  Navigator.of(_context).pop();
                },
                child: Column(
                  children: [
                    Container(
                      height: 70.0,
                      padding: EdgeInsets.only(left: 10.0),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Icon(Icons.print),
                          SizedBox(width: 10.0,),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_devices[index].name ?? ''),
                                Text(_devices[index].address.toString()),
                                Flexible(
                                  child: Text(
                                    'Haga clic para seleccionar la impresora',
                                    style: TextStyle(color: Colors.grey[700]),
                                    textAlign: TextAlign.justify,
                                  )
                                ),
                              ],
                            )
                          ),
                        ],
                      ),
                    ),
                    Divider(),
                  ],
                ),
              );
            }
          ),
        )
      ],
    );
  }

  _printSnackBar(BuildContext _context, String _text){
    final snackBar = SnackBar(
      content: Text(_text),
      action: SnackBarAction(
        label: 'Cerrar',
        onPressed: (){}
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _printTest() async{
     Map<String, dynamic> config = Map();
    List<LineText> list = [];

    list.add(LineText(type: LineText.TYPE_TEXT, content: 'A Title', weight: 1, align: LineText.ALIGN_CENTER,linefeed: 1));
    list.add(LineText(type: LineText.TYPE_TEXT, content: 'this is conent left', weight: 0, align: LineText.ALIGN_LEFT,linefeed: 1));
    list.add(LineText(type: LineText.TYPE_TEXT, content: 'this is conent right', align: LineText.ALIGN_RIGHT,linefeed: 1));
    list.add(LineText(linefeed: 1));
    list.add(LineText(type: LineText.TYPE_BARCODE, content: 'A12312112', size:10, align: LineText.ALIGN_CENTER, linefeed: 1));
    list.add(LineText(linefeed: 1));
    list.add(LineText(type: LineText.TYPE_QRCODE, content: 'qrcode i', size:10, align: LineText.ALIGN_CENTER, linefeed: 1));
    list.add(LineText(linefeed: 1));

    //Getting Started

    ByteData data = await rootBundle.load("assets/logo.png");
    List<int> imageBytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    String base64Image = base64Encode(imageBytes);
    list.add(LineText(type: LineText.TYPE_IMAGE, content: base64Image, align: LineText.ALIGN_CENTER, linefeed: 1, weight: 200, height: 200));

    /*This project is a starting point for a Flutter
    [plug-in package](https://flutter.dev/developing-packages/),
    a specialized package that includes platform-specific implementation code for
    Android and/or iOS.*/

    await bluetoothPrint.printReceipt(config, list);
  }
}
