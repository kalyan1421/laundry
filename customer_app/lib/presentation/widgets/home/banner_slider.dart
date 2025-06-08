// import 'package:flutter/material.dart';
// import 'package:carousel_slider/carousel_slider.dart';
// import '../../../domain/models/banner_model.dart';
// import '../../../services/banner_service.dart';

// class BannerSlider extends StatelessWidget {
//   final BannerService _bannerService = BannerService();

//   BannerSlider({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<List<BannerModel>>(
//       future: _bannerService.getBanners(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const SizedBox(
//             height: 200,
//             child: Center(child: CircularProgressIndicator()),
//           );
//         }

//         if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
//           return const SizedBox.shrink();
//         }

//         final banners = snapshot.data!;

//         return CarouselSlider.builder(
//           itemCount: banners.length,
//           itemBuilder: (context, index, realIndex) {
//             final banner = banners[index];
//             return Container(
//               width: MediaQuery.of(context).size.width,
//               margin: const EdgeInsets.symmetric(horizontal: 5.0),
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(15),
//               ),
//               child: Stack(
//                 children: [
//                   // Banner Image
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(15),
//                     child: CachedNetworkImage(
//                       imageUrl: banner.imageUrl,
//                       fit: BoxFit.cover,
//                       width: double.infinity,
//                       height: double.infinity,
//                       placeholder: (context, url) => const Center(
//                         child: CircularProgressIndicator(),
//                       ),
//                       errorWidget: (context, url, error) => const Icon(Icons.error),
//                     ),
//                   ),
//                   // Gradient Overlay
//                   Container(
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(15),
//                       gradient: LinearGradient(
//                         begin: Alignment.topCenter,
//                         end: Alignment.bottomCenter,
//                         colors: [
//                           Colors.transparent,
//                           Colors.black.withOpacity(0.7),
//                         ],
//                       ),
//                     ),
//                   ),
//                   // Text Content
//                   Positioned(
//                     bottom: 20,
//                     left: 20,
//                     right: 20,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           banner.mainTagline,
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                             fontFamily: 'SF Pro Display',
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           banner.subTagline,
//                           style: TextStyle(
//                             color: Colors.white.withOpacity(0.9),
//                             fontSize: 16,
//                             fontFamily: 'SF Pro Display',
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//           options: CarouselOptions(
//             height: 200,
//             viewportFraction: 0.92,
//             initialPage: 0,
//             enableInfiniteScroll: true,
//             reverse: false,
//             autoPlay: true,
//             autoPlayInterval: const Duration(seconds: 5),
//             autoPlayAnimationDuration: const Duration(milliseconds: 800),
//             autoPlayCurve: Curves.fastOutSlowIn,
//             enlargeCenterPage: true,
//             scrollDirection: Axis.horizontal,
//           ),
//         );
//       },
//     );
//   }
// }
