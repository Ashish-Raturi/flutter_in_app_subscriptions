import 'package:flutter/material.dart';
import 'package:pim/color.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  _HomepageState createState() => _HomepageState();
}

String sub1Id = "starter plan";
String sub2Id = "pro plan";

class _HomepageState extends State<Homepage> {
  String activeSubId = "pro plan";

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            title: Text('Hi, Ashish',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 22,
                    color: Colors.black,
                    fontWeight: FontWeight.bold)),
          ),
          body: Stack(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 20,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        _buildMonthlySubTile(),
                        const SizedBox(
                          height: 20,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        _buildYearlySubTile(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )),
    );
  }

  _buildMonthlySubTile() {
    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: c1,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Product title',
                        style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            fontSize: 18)),
                    const SizedBox(
                      height: 5,
                    ),
                    Text('Price',
                        style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w500,
                            color: Colors.white)),
                    SizedBox(
                      height: 5,
                    ),
                    if (activeSubId == sub1Id)
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(06),
                            color: c2,
                          ),
                          // width: 200,
                          alignment: Alignment.center,
                          child: Text(
                            'Price Change',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                  ],
                ),
                Expanded(
                    child: SizedBox(
                  width: 3,
                )),
                Image.asset('assets/diamond1.png', width: 60),
              ],
            ),
            Divider(),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Description : product description',
                  style: TextStyle(color: c3, fontSize: 16)),
            ),
            const SizedBox(
              height: 20,
            ),
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(06),
                  color: activeSubId == sub1Id ? c4 : c2,
                ),
                // width: 200,
                alignment: Alignment.center,
                child: Text(
                  activeSubId == sub1Id ? 'Active' : 'Choose Plan ->',
                  style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
          ],
        ));
  }

  _buildYearlySubTile() {
    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: c1,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Product title',
                        style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            fontSize: 18)),
                    const SizedBox(
                      height: 5,
                    ),
                    Text('Price',
                        style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w500,
                            color: Colors.white)),
                    SizedBox(
                      height: 5,
                    ),
                    if (activeSubId == sub2Id)
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(06),
                            color: c2,
                          ),
                          // width: 200,
                          alignment: Alignment.center,
                          child: Text(
                            'Price Change',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                  ],
                ),
                Expanded(
                    child: SizedBox(
                  width: 3,
                )),
                Image.asset('assets/diamond2.png', width: 60),
              ],
            ),
            Divider(),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Description : product description',
                  style: TextStyle(color: c3, fontSize: 16)),
            ),
            const SizedBox(
              height: 20,
            ),
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(06),
                  color: activeSubId == sub2Id ? c4 : c2,
                ),
                // width: 200,
                alignment: Alignment.center,
                child: Text(
                  activeSubId == sub2Id ? 'Active' : 'Choose Plan ->',
                  style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
          ],
        ));
  }
}
