import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../Providers/DocumentoProvider.dart';



class TelaDeCapturaDoQrCode extends StatefulWidget {
  /// Constructor for simple Mobile Scanner example
  const TelaDeCapturaDoQrCode({super.key});

  @override
  State<TelaDeCapturaDoQrCode> createState() => _TelaDeCapturaDoQrCodeState();
}

class _TelaDeCapturaDoQrCodeState extends State<TelaDeCapturaDoQrCode> {
  Barcode? _barcode;
  bool notScanned = true;

  Widget _barcodePreview(Barcode? value) {
    if (value == null) {
      return const Text(
        'Escaneie o QR Code do Extrato',
        textAlign: TextAlign.center,
        overflow: TextOverflow.fade,
        style: TextStyle(color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 20
        ),
      );
    }

    return Text(
      value.displayValue ?? 'No display value.',
      overflow: TextOverflow.fade,
      style: const TextStyle(color: Colors.white),
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    notScanned = true;
  }

  void _handleBarcode(BarcodeCapture barcodes) {
    if (mounted && notScanned) {
      setState(() {
        _barcode = barcodes.barcodes.firstOrNull;
        context.read<DocumentoProvider>().lerQrCode(_barcode);
      });
      _barcode = null;
      Navigator.pushNamed(context, '/TelaDeResultados');
      notScanned = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    double bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      appBar: AppBar(title: const Text('Escaneie o QR Code do Extrato',
      textAlign: TextAlign.center,
      ),
      backgroundColor: Colors.blue[700],
        titleTextStyle: TextStyle(

          fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white
        ),
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(onDetect: _handleBarcode),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              alignment: Alignment.bottomCenter,
              height: 100,
              color: const Color.fromRGBO(0, 0, 0, 0.4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Expanded(child: Center(child: _barcodePreview(_barcode))),
                      SizedBox(height: bottom),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MobileScannerAdvanced extends StatefulWidget {
  /// Constructor for simple Mobile Scanner example
  const MobileScannerAdvanced({super.key});

  @override
  State<MobileScannerAdvanced> createState() => _MobileScannerAdvancedState();
}

class _MobileScannerAdvancedState extends State<MobileScannerAdvanced> {
  Barcode? _barcode;

  Widget _barcodePreview(Barcode? value) {
    if (value == null) {
      return const Text(
        'Scan something!',
        overflow: TextOverflow.fade,
        style: TextStyle(color: Colors.white),
      );
    }

    return Text(
      value.displayValue ?? 'No display value.',
      overflow: TextOverflow.fade,
      style: const TextStyle(color: Colors.white),
    );
  }

  void _handleBarcode(BarcodeCapture barcodes) {
    if (mounted) {
      setState(() {
        _barcode = barcodes.barcodes.firstOrNull;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simple Mobile Scanner')),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(onDetect: _handleBarcode),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              alignment: Alignment.bottomCenter,
              height: 100,
              color: const Color.fromRGBO(0, 0, 0, 0.4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(child: Center(child: _barcodePreview(_barcode))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}