import 'dart:async';
import 'dart:io';
import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show PlatformDispatcher, defaultTargetPlatform, kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_restaurant/features/cart/providers/frequently_bought_provider.dart';
import 'package:flutter_restaurant/features/checkout/providers/checkout_provider.dart';
import 'package:flutter_restaurant/features/home/providers/sorting_provider.dart';
import 'package:flutter_restaurant/helper/notification_helper.dart';
import 'package:flutter_restaurant/helper/responsive_helper.dart';
import 'package:flutter_restaurant/helper/router_helper.dart';
import 'package:flutter_restaurant/localization/app_localization.dart';
import 'package:flutter_restaurant/features/auth/providers/auth_provider.dart';
import 'package:flutter_restaurant/features/home/providers/banner_provider.dart';
import 'package:flutter_restaurant/features/branch/providers/branch_provider.dart';
import 'package:flutter_restaurant/features/cart/providers/cart_provider.dart';
import 'package:flutter_restaurant/features/category/providers/category_provider.dart';
import 'package:flutter_restaurant/features/chat/providers/chat_provider.dart';
import 'package:flutter_restaurant/features/coupon/providers/coupon_provider.dart';
import 'package:flutter_restaurant/features/language/providers/language_provider.dart';
import 'package:flutter_restaurant/features/language/providers/localization_provider.dart';
import 'package:flutter_restaurant/features/address/providers/location_provider.dart';
import 'package:flutter_restaurant/common/providers/news_letter_provider.dart';
import 'package:flutter_restaurant/features/notification/providers/notification_provider.dart';
import 'package:flutter_restaurant/features/onboarding/providers/onboarding_provider.dart';
import 'package:flutter_restaurant/features/order/providers/order_provider.dart';
import 'package:flutter_restaurant/common/providers/product_provider.dart';
import 'package:flutter_restaurant/features/profile/providers/profile_provider.dart';
import 'package:flutter_restaurant/features/rate_review/providers/review_provider.dart';
import 'package:flutter_restaurant/features/search/providers/search_provider.dart';
import 'package:flutter_restaurant/features/setmenu/providers/set_menu_provider.dart';
import 'package:flutter_restaurant/features/splash/providers/splash_provider.dart';
import 'package:flutter_restaurant/common/providers/theme_provider.dart';
import 'package:flutter_restaurant/features/wallet/providers/wallet_provider.dart';
import 'package:flutter_restaurant/features/wishlist/providers/wishlist_provider.dart';
import 'package:flutter_restaurant/theme/dark_theme.dart';
import 'package:flutter_restaurant/theme/light_theme.dart';
import 'package:flutter_restaurant/utill/app_constants.dart';
import 'package:flutter_restaurant/common/widgets/third_party_chat_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_strategy/url_strategy.dart';
import 'di_container.dart' as di;
import 'features/order_track/providers/time_provider.dart';
import 'common/widgets/cookies_widget.dart';


final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

late AndroidNotificationChannel channel;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();



Future<void> main() async {

  if(ResponsiveHelper.isMobilePhone()) {
    HttpOverrides.global = MyHttpOverrides();
  }
  setPathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  if(kIsWeb) {
    await Firebase.initializeApp(options: const FirebaseOptions(
      apiKey: "AIzaSyAZhaJ7KtJsLc63qFhVd4s2xYuvGHlSmFk", ///current_key
      authDomain: "efood-58b8a.firebaseapp.com",
      projectId: "efood-58b8a", /// project_id
      storageBucket: "efood-58b8a.firebasestorage.app",
      messagingSenderId: "410522356318", // project_number
      appId: "1:435964737383:web:0271fbb6cfd0f71daca1c2", /// mobilesdk_app_id
      measurementId: "G-WX77NRZTXV",
    ));
  }else {
    await Firebase.initializeApp();

  }

  ///firebase crashlytics
  // FlutterError.onError = (errorDetails) {
  //   FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  // };
  //
  // PlatformDispatcher.instance.onError = (error, stack) {
  //   FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  //   return true;
  // };

  if(!kIsWeb && defaultTargetPlatform == TargetPlatform.android){
    await FirebaseMessaging.instance.requestPermission();
  }

  if(kIsWeb) {
    await FacebookAuth.instance.webAndDesktopInitialize(
      appId: "482889663914976",
      cookie: true,
      xfbml: true,
      version: "v13.0",
    );
  }

  await di.init();
  String? path;
  int? orderID;

  try {
    if (!kIsWeb) {
      path =  await initDynamicLinks();
      channel = const AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        importance: Importance.high,
      );
    }
    final RemoteMessage? remoteMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (remoteMessage != null) {
      orderID = remoteMessage.notification!.titleLocKey != null ? int.parse(remoteMessage.notification!.titleLocKey!) : null;
    }
    await NotificationHelper.initialize(flutterLocalNotificationsPlugin);
    FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);
    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);


  }catch(e) {
    debugPrint('error ===> $e');
  }
  GoRouter.optionURLReflectsImperativeAPIs = true;

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => di.sl<ThemeProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<SplashProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<LanguageProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<OnBoardingProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<CategoryProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<BannerProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<ProductProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<LocalizationProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<AuthProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<LocationProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<CartProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<OrderProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<ChatProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<SetMenuProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<ProfileProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<NotificationProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<CouponProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<WishListProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<SearchProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<NewsLetterProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<TimerProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<WalletProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<BranchProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<ReviewProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<ProductSortProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<CheckoutProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<FrequentlyBoughtProvider>()),
    ],
    child: MyApp(orderId: orderID, isWeb: !kIsWeb, route: path),
  ));
}

class MyApp extends StatefulWidget {
  final int? orderId;
  final bool isWeb;
  final String? route;
  const MyApp({super.key, required this.orderId, required this.isWeb, this.route});


  @override
  State<MyApp> createState() => _MyAppState();
}

Future<String?> initDynamicLinks() async {
  final appLinks = AppLinks();
  final uri = await appLinks.getInitialLink();
  String? path;
  if (uri != null) {
    path = uri.path;

  }else{
    path = null;
  }
  return path;

}


class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    if(kIsWeb || widget.route != null) {
      final CategoryProvider categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

      Provider.of<SplashProvider>(context, listen: false).initSharedData();
      Provider.of<CartProvider>(context, listen: false).getCartData(context);
      Provider.of<SplashProvider>(context, listen: false).getPolicyPage();

      if(Provider.of<AuthProvider>(context, listen: false).isLoggedIn()) {
        Provider.of<ProfileProvider>(context, listen: false).getUserInfo(true);
      }
      if(categoryProvider.categoryList == null) {
        categoryProvider.getCategoryList(true);
      }


      _route();
    }

  }
  void _route(){

    final SplashProvider splashProvider = Provider.of<SplashProvider>(context, listen: false);

    final BranchProvider branchProvider = Provider.of<BranchProvider>(context, listen: false);
    if(branchProvider.getBranchId() != -1){
      splashProvider.getDeliveryInfo(branchProvider.getBranchId());
    }

    splashProvider.initConfig(context).then((bool isSuccess) async{

      if (isSuccess) {

        Timer(Duration(seconds: ResponsiveHelper.isMobilePhone() ? 1 : 0), () async {

          if (Provider.of<AuthProvider>(context, listen: false).isLoggedIn()) {
            Provider.of<AuthProvider>(context, listen: false).updateToken();
          }
        }

        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);

    List<Locale> locals = [];
    for (var language in AppConstants.languages) {
      locals.add(Locale(language.languageCode!, language.countryCode));
    }

    return Consumer<SplashProvider>(
      builder: (context, splashProvider, child){

        return (kIsWeb && splashProvider.configModel == null) ? const SizedBox() : MaterialApp.router(
          routerConfig: RouterHelper.goRoutes,
          title: splashProvider.configModel != null ? splashProvider.configModel!.restaurantName ?? '' : AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: Provider.of<ThemeProvider>(context).darkTheme ? dark : light,
          locale: Provider.of<LocalizationProvider>(context).locale,
          localizationsDelegates: const [
            AppLocalization.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: locals,
          scrollBehavior: const MaterialScrollBehavior().copyWith(dragDevices: {
            PointerDeviceKind.mouse, PointerDeviceKind.touch, PointerDeviceKind.stylus, PointerDeviceKind.unknown
          }),
          builder: (context, child)=> MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(size.width < 380 ?  0.9 : 1)),
            child: Scaffold(
              body: Stack(
                children: [
                  child!,

                  if(ResponsiveHelper.isDesktop(context)) const Positioned.fill(
                    child: Align(alignment: Alignment.bottomRight, child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 50, horizontal: 20), child: ThirdPartyChatWidget(),
                    )),
                  ),

                  if(kIsWeb && (splashProvider.configModel?.cookiesManagement?.status ?? false)
                      && !splashProvider.getAcceptCookiesStatus(splashProvider.configModel?.cookiesManagement?.content)
                      && splashProvider.cookiesShow)
                    const Positioned.fill(child: Align(alignment: Alignment.bottomCenter, child: CookiesWidget())),

                ],
              ),
            ),
          ),
        );
      },

    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class Get {
  static BuildContext? get context => navigatorKey.currentContext;
  static NavigatorState? get navigator => navigatorKey.currentState;
}


