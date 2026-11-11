import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:qaz_route_mobile/src/core/app_colors.dart';

@RoutePage()
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final List<Map<String, dynamic>> _subscriptionsPlans = [
    {'price': '999,00 KZT', 'duration': '1 MONTH', 'isRecommended': false},
    {'price': '1999,00 KZT', 'duration': '3 MONTHS', 'isRecommended': true},
  ];

  final _carouselItems = [
    'assets/premium/IMG_5088.PNG',
    'assets/premium/IMG_5089.PNG',
    'assets/premium/IMG_5090.PNG',
  ];

  int _selectedSubscriptionPlan = 1;

  void _changeSubscriptionPlan(int planIndex) {
    setState(() => _selectedSubscriptionPlan = planIndex);
  }

  late final PageController _pageController;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _timer = Timer.periodic(Duration(milliseconds: 2400), (_) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 600),
        curve: Curves.linear,
      );
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.lightGreen600,
        surfaceTintColor: AppColors.lightGreen600,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => context.router.maybePop(),
        ),
        title: Text(
          'Subscription',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 380,
                  child: PageView.builder(
                    controller: _pageController,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _carouselItems.length * 60,
                    itemBuilder: (context, index) {
                      return Image.asset(
                        _carouselItems[index % _carouselItems.length],
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        width: double.infinity,
                      );
                    },
                  ),
                ),
                Container(
                  height: 100,
                  width: double.infinity,
                  color: AppColors.white,
                  padding: EdgeInsets.all(16),
                  child: Column(
                    spacing: 4,
                    children: [
                      Text(
                        'QazRoute Premium',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'All features included',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 36),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ..._subscriptionsPlans.mapIndexed(
                  (i, e) => SubscriptionTile(
                    price: e['price'],
                    duration: e['duration'],
                    isRecommended: e['isRecommended'],
                    isSelected: i == _selectedSubscriptionPlan,
                    onTap: () => _changeSubscriptionPlan(i),
                  ),
                ),
              ],
            ),
            SizedBox(height: 48),
            ElevatedButton(
              onPressed: () async {},
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.maxFinite, 48),
                backgroundColor: AppColors.lightGreen600,
                foregroundColor: AppColors.white,
                disabledBackgroundColor: AppColors.supplementary600,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 8,
              ),
              child: Text(
                'Subscribe',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SubscriptionTile extends StatelessWidget {
  const SubscriptionTile({
    super.key,
    required this.price,
    required this.duration,
    required this.isSelected,
    required this.isRecommended,
    required this.onTap,
  });

  final String price;
  final String duration;
  final bool isSelected;
  final bool isRecommended;
  final VoidCallback onTap;

  Color get _color =>
      isSelected ? AppColors.lightGreen600 : AppColors.neutral500;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 24, horizontal: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _color, width: 2),
            ),
            child: Column(
              spacing: 8,
              children: [
                Text(
                  duration,
                  style: TextStyle(color: _color, fontWeight: FontWeight.bold),
                ),
                Text(
                  price,
                  style: TextStyle(color: _color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          if (isRecommended)
            Positioned(
              top: -8,
              right: -8,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.supplementary600600,
                ),
                child: Text(
                  'BEST VALUE',
                  style: TextStyle(fontSize: 10, color: AppColors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
