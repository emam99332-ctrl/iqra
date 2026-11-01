import 'package:flutter/material.dart';
import 'package:iqra/styles/style.dart';
import 'package:iqra/services/hijri_date_service.dart';

String toArabicDigits(int n) => n
    .toString()
    .split('')
    .map((d) => String.fromCharCode(0x0660 + int.parse(d)))
    .join();

class HijriCard extends StatelessWidget {
  const HijriCard({
    super.key,
    required this.height,
    required this.width,
  });

  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          height: height * .15,
          width: width,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.grey,
                spreadRadius: 5,
                blurRadius: 7,
                offset: Offset(1.5, 3),
              ),
            ],
            image: DecorationImage(
              image: AssetImage('assets/dashboard.png'),
              fit: BoxFit.fill,
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  gold.withOpacity(.7),
                  read.withOpacity(.7),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * .03,
                    vertical: height * .02,
                  ),
                  child: SizedBox(
                    width: width * .4,
                    child: ListTile(
                      title: Text(
                        HijriDateService.getToday(),
                        style: TextStyle(
                          fontFamily: 'Kufi',
                          fontSize: 22,
                          color: emerald.withOpacity(.7),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Spacer(),
                Padding(
                  padding: EdgeInsets.only(right: width * .04),
                  child: Image.asset('assets/lamp.png', fit: BoxFit.fill),
                ),
              ],
            ),
          ),
        ));
  }
}
