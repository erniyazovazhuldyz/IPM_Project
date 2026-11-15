import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qaz_route_mobile/src/core/app_colors.dart';
import 'package:qaz_route_mobile/src/repository/routes_repository.dart';
import 'package:qaz_route_mobile/src/router/app_router.dart';
import 'package:qaz_route_mobile/src/widget/qr_screen/qr_screen_controller.dart';

@RoutePage()
class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  late final MobileScannerController _controller;
  late final QrScreenController _qrScreenController;

  bool _isQRDetected = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
    _qrScreenController = QrScreenController(repository: RoutesRepository());
  }

  @override
  void dispose() {
    _qrScreenController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    // Handle one QR at a time; the camera reports the same code many times.
    if (_isQRDetected || capture.barcodes.isEmpty) return;

    final String scannedData = capture.barcodes.first.rawValue?.trim() ?? '';
    if (scannedData.isEmpty) return;

    _isQRDetected = true;
    final route = await _qrScreenController.getRouteById(scannedData);

    if (mounted) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();

      if (route != null) {
        // Correct QR: open this trail (US-07).
        context.router.navigate(RouteDetailsRoute(route: route));
      } else if (_qrScreenController.state == QrScreenState.noInternet) {
        // No connection: stay on the QR screen so the user can try again.
        messenger.showSnackBar(
          SnackBar(content: Text(_qrScreenController.errorMessage)),
        );
      } else {
        // Wrong QR: "Route not found" and the Home screen (US-08).
        messenger.showSnackBar(
          SnackBar(content: Text(_qrScreenController.errorMessage)),
        );
        context.router.navigate(
          const HomeRouteWrapper(children: [HomeRoute()]),
        );
      }
    }

    // Short pause so the same code is not handled twice.
    Future.delayed(const Duration(seconds: 2), () => _isQRDetected = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.lightGreen600,
        surfaceTintColor: AppColors.lightGreen600,
        centerTitle: false,
        title: Text(
          'Scan QR',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
              ),
            ),
            // Must be Positioned.fill: a non-positioned child would shrink
            // the whole Stack (and the camera view) to zero size.
            Positioned.fill(
              child: ListenableBuilder(
                listenable: _qrScreenController,
                builder: (context, child) {
                  if (_qrScreenController.state != QrScreenState.loading) {
                    return const SizedBox.shrink();
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: AppColors.white, width: 6),
                            top: BorderSide(color: AppColors.white, width: 6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 64),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(color: AppColors.white, width: 6),
                            top: BorderSide(color: AppColors.white, width: 6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 64),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: AppColors.white, width: 6),
                            bottom: BorderSide(
                              color: AppColors.white,
                              width: 6,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 64),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(color: AppColors.white, width: 6),
                            bottom: BorderSide(
                              color: AppColors.white,
                              width: 6,
                            ),
                          ),
                        ),
                      ),
                    ],
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
