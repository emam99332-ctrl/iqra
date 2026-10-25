
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:iqra/styles/style.dart';

class Qiblapage extends StatefulWidget {
  const Qiblapage({super.key});

  @override
  State<Qiblapage> createState() => _QiblapageState();
}

class _QiblapageState extends State<Qiblapage> {
  late Future<double> _qiblaFuture;

  @override
  void initState() {
    super.initState();
    _qiblaFuture = _getQiblaDirection();
  }

  Future<double> _getQiblaDirection() async {
    final serviceEnabled =
    await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('يرجى تشغيل خدمة الموقع GPS');
    }

    LocationPermission permission =
    await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('يجب السماح بالوصول إلى الموقع');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    // إحداثيات الكعبة المشرفة
    const kaabaLatitude = 21.4225;
    const kaabaLongitude = 39.8262;

    return Geolocator.bearingBetween(
      position.latitude,
      position.longitude,
      kaabaLatitude,
      kaabaLongitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: emerald,
      appBar: AppBar(
        foregroundColor: emerald,
        backgroundColor: cream,
        title: Text(
          'اتجاه القبلة',
          style: titleStyle(),
        ),
        centerTitle: true,
      ),
      body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/bckg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: FutureBuilder<double>(
            future: _qiblaFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: emerald,),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_off,
                          size: 50,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _qiblaFuture = _getQiblaDirection();
                            });
                          },
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final qiblaBearing = snapshot.data!;

              return StreamBuilder<CompassEvent>(
                stream: FlutterCompass.events,
                builder: (context, compassSnapshot) {
                  final heading = compassSnapshot.data?.heading;

                  if (heading == null) {
                    return const Center(
                      child: Text(
                        'البوصلة غير متاحة على هذا الجهاز',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  // الزاوية بين اتجاه الهاتف واتجاه القبلة
                  final direction = qiblaBearing - heading;

                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 150),
                        const Text(
                          'وجّه أعلى الهاتف نحو القبلة',
                          style: TextStyle(
                            color: gold,
                            fontSize: 18,
                            fontFamily: 'ar',
                          ),
                        ),
                        const SizedBox(height: 150),
                        Transform.rotate(
                            angle: direction * math.pi / 180,
                            child: Image.asset('assets/qibla.png', width: 200,height: 200,)
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          )
      )
    );
  }
}
